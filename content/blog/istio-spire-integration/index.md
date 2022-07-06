---
title: 如何在 Istio 中集成 SPIRE
summary: Istio 1.14 版本增加了对 SPIRE 集成的支持，这篇文章将指导你如何在 Istio 中集成 SPIRE。
date: '2022-06-06T11:00:00+08:00'
lastmod: '2022-06-06T11:00:00+08:00'
draft: false
featured: false
image:
  caption: '© [**jimmysong.io**](https://jimmysong.io)'
  focal_point: 'right'
  placement: 2
  preview_only: false
authors: ["Istio"]
tags: ["Istio","SPIRE"]
categories: ["Istio"]
aliases: ["/translation/istio-spire-integration"]
links:
  - icon: language
    icon_pack: fa
    name: 阅读英文版原文
    url: https://istio.io/latest/docs/ops/integrations/spire/
---

## 编者的话

Istio 1.14 版本增加了对 SPIRE 集成的支持，这篇文章将指导你如何在 Istio 中集成 SPIRE。

[SPIRE](https://spiffe.io/docs/latest/spire-about/spire-concepts/) 是 SPIFFE 规范的一个生产就绪的实现，它可以执行节点和工作负载证明，以便安全地将加密身份发给在异构环境中运行的工作负载。通过与 [Envoy 的 SDS API](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret) 集成，SPIRE 可以被配置为 Istio 工作负载的加密身份来源。Istio 可以检测到一个 UNIX 域套接字的存在，该套接字在定义的套接字路径上实现了 Envoy SDS API，允许 Envoy 直接从它那里进行通信和获取身份。

这种与 SPIRE 的集成提供了灵活的认证选项，这是默认的 Istio 身份管理所不具备的，同时利用了 Istio 强大的服务管理。例如，SPIRE 的插件架构能够提供多样化的工作负载认证选项，超越 Istio 提供的 Kubernetes 命名空间和服务账户认证。SPIRE 的节点认证将认证扩展到工作负载运行的物理或虚拟硬件上。

关于这种 SPIRE 与 Istio 集成的快速演示，请参阅[通过 Envoy 的 SDS API 将 SPIRE 作为 CA 进行集成](https://github.com/istio/istio/tree/release-1.14/samples/security/spire)。

请注意，这个集成需要 1.14 版本的 `istioctl` 和数据平面。

该集成与 Istio 的升级兼容。

## 安装 SPIRE

### 选项 1: 快速启动

Istio 提供了一个基本的安装示例，以快速启动和运行 SPIRE。

```bash
$ kubectl apply -f samples/security/spire/spire-quickstart.yaml
```

这将把 SPIRE 部署到你的集群中，同时还有两个额外的组件：[SPIFFE CSI 驱动](https://github.com/spiffe/spiffe-csi) —— 用于与整个节点的其他 pod 共享 SPIRE Agent 的 UNIX 域套接字，以及 [SPIRE Kubernetes 工作负载注册器](https://github.com/spiffe/spire/tree/main/support/k8s/k8s-workload-registrar)，这是一个在 Kubernetes 内执行自动工作负载注册的促进器。参见[安装 Istio](https://istio.io/latest/docs/ops/integrations/spire/#install-istio) 以配置 Istio 并与 SPIFFE CSI 驱动集成。

### 选项 2：配置一个自定义的 SPIRE 安装

请参阅 [SPIRE 的 Kubernetes 快速入门指南](https://spiffe.io/docs/latest/try/getting-started-k8s/)，将 SPIRE 部署到 Kubernetes 环境中。请参阅 SPIRE [CA 集成先决条件](https://istio.io/latest/docs/ops/integrations/spire/#spire-ca-integration-prerequisites)，了解有关配置 SPIRE 以与 Istio 部署集成的更多信息。

#### SPIRE CA 集成的先决条件

将 SPIRE 部署与 Istio 集成，配置 SPIRE：

1. 访问 [SPIRE 代理参考](https://spiffe.io/docs/latest/deploying/spire_agent/#agent-configuration-file)，配置 SPIRE 代理套接字路径，以匹配 Envoy SDS 定义的套接字路径。

   ```bash
   socket_path = "/run/secrets/workload-spiffe-uds/socket"
   ```

2. 通过部署 [SPIFFE CSI 驱动](https://github.com/spiffe/spiffe-csi)，与节点内的 pod 共享 SPIRE 代理套接字。

参见[安装 Istio](https://istio.io/latest/docs/ops/integrations/spire/#install-istio) 以配置 Istio 与 SPIFFE CSI 驱动集成。

注意，你必须在将 Istio 安装到你的环境中之前部署 SPIRE，以便 Istio 可以检测到它是一个 CA。

## 安装 Istio

1. [下载 Istio 1.14 + 版本](https://istio.io/latest/docs/setup/getting-started/#download)。

2. 在[将 SPIRE 部署](https://istio.io/latest/docs/ops/integrations/spire/#install-spire)到你的环境中，并验证所有的部署都处于 `Ready` 状态后，为 Ingress-gateway 以及 istio-proxy 安装 Istio 的定制补丁。

   ```yaml
   $ istioctl install --skip-confirmation -f - <<EOF
   apiVersion: install.istio.io/v1alpha1
   kind: IstioOperator
   metadata:
     namespace: istio-system
   spec:
     profile: default
     meshConfig:
       trustDomain: example.org
     values:
       global:
       # This is used to customize the sidecar template
       sidecarInjectorWebhook:
         templates:
           spire: |
             spec:
               containers:
               - name: istio-proxy
                 volumeMounts:
                 - name: workload-socket
                   mountPath: /run/secrets/workload-spiffe-uds
                   readOnly: true
               volumes:
                 - name: workload-socket
                   csi:
                     driver: "csi.spiffe.io"          
     components:
       ingressGateways:
         - name: istio-ingressgateway
           enabled: true
           label:
             istio: ingressgateway
           k8s:
             overlays:
               - apiVersion: apps/v1
                 kind: Deployment
                 name: istio-ingressgateway
                 patches:
                   - path: spec.template.spec.volumes.[name:workload-socket]
                     value:
                       name: workload-socket
                       csi:
                         driver: "csi.spiffe.io"
                   - path: spec.template.spec.containers.[name:istio-proxy].volumeMounts.[name:workload-socket]
                     value:
                       name: workload-socket
                       mountPath: "/run/secrets/workload-spiffe-uds"
                       readOnly: true
   EOF
   ```
   这将与 Ingress Gateway 和将被注入工作负载 pod 的 sidecars 共享 `spiffe-csi-driver`，允许它们访问 SPIRE Agent 的 UNIX 域套接字。
   
1. 使用 [sidecar 注入](https://istio.io/latest/docs/setup/additional-setup/sidecar-injection)，将 `istio-proxy` 容器注入到网格内的 pod 中。关于如何将自定义的 `spire` 模板应用到 `istio-proxy` 中的信息，请参见[自定义模板](https://istio.io/latest/docs/setup/additional-setup/sidecar-injection/#custom-templates-experimental)。这使得 CSI 驱动能够在 sidecar 上安装 UDS。

   检查 Ingress-gateway pod 状态。

   ```bash
   $ kubectl get pods -n istio-system
   
   NAME                                    READY   STATUS    RESTARTS   AGE
   istio-ingressgateway-5b45864fd4-lgrxs   0/1     Running   0          17s
   istiod-989f54d9c-sg7sn                  1/1     Running   0          23s
   ```

只有在 SPIRE 服务器上为它们创建了相应的注册条目时，数据平面容器才会到达 `Ready`。然后，Envoy 将能够从 SPIRE 获取加密身份。请参阅[注册工作负载](#register-workloads) ，为你的网格中的服务注册条目。

## 注册工作负载{#register-workloads}

本节介绍在 SPIRE 服务器中注册工作负载的可用选项。

### 选项 1：使用 SPIRE 工作负载注册器自动登记

通过将 [SPIRE Kubernetes Workload Registrar](https://github.com/spiffe/spire/tree/main/support/k8s/k8s-workload-registrar) 与 SPIRE 服务器一起部署，每创建一个新的 pod，就会自动注册新的条目。

请参阅” [验证身份是否为工作负载创建](https://istio.io/latest/docs/ops/integrations/spire/#verifying-that-identities-were-created-for-workloads) "，以检查已发布的身份。

请注意，在[快速启动](https://istio.io/latest/docs/ops/integrations/spire/#option-1:-quick-start)部分使用了 `SPIRE工作负载注册器`。

### 选项 2：手动注册

为了提高工作负载证明的安全稳健性，SPIRE 能够根据不同的参数，针对一组选择器的值进行验证。如果你按照[快速启动](https://istio.io/latest/docs/ops/integrations/spire/#option-1:-quick-start)安装 `SPIRE`，则跳过这些步骤，因为它使用自动注册。

1. 为 Ingress Gateway 生成一个条目，其中有一组选择器，如 pod 名称和 pod UID：

   ```bash
   $ INGRESS_POD=$(kubectl get pod -l istio=ingressgateway -n istio-system -o jsonpath="{.items[0].metadata.name}" )
   $ INGRESS_POD_UID=$(kubectl get pods -n istio-system $INGRESS_POD -o jsonpath='{.metadata.uid}')
   ```

2. 获取 spire-server pod：

   ```bash
   $ SPIRE_SERVER_POD=$(kubectl get pod -l app=spire-server -n spire -o jsonpath="{.items[0].metadata.name}" )
   ```

3. 为节点上运行的 SPIRE 代理注册一个条目。

   ```yaml
   $ kubectl exec -n spire $SPIRE_SERVER_POD -- \
   /opt/spire/bin/spire-server entry create \
       -spiffeID spiffe://example.org/ns/spire/sa/spire-agent \
       -selector k8s_psat:cluster:demo-cluster \
       -selector k8s_psat:agent_ns:spire \
       -selector k8s_psat:agent_sa:spire-agent \
       -node -socketPath /run/spire/sockets/server.sock
   
   Entry ID         : d38c88d0-7d7a-4957-933c-361a0a3b039c
   SPIFFE ID        : spiffe://example.org/ns/spire/sa/spire-agent
   Parent ID        : spiffe://example.org/spire/server
   Revision         : 0
   TTL              : default
   Selector         : k8s_psat:agent_ns:spire
   Selector         : k8s_psat:agent_sa:spire-agent
   Selector         : k8s_psat:cluster:demo-cluster
   ```

4. 为 Ingress-gateway pod 注册一个条目。

   ```bash
   $ kubectl exec -n spire $SPIRE_SERVER_POD -- \
   /opt/spire/bin/spire-server entry create \
       -spiffeID spiffe://example.org/ns/istio-system/sa/istio-ingressgateway-service-account \
       -parentID spiffe://example.org/ns/spire/sa/spire-agent \
       -selector k8s:sa:istio-ingressgateway-service-account \
       -selector k8s:ns:istio-system \
       -selector k8s:pod-uid:$INGRESS_POD_UID \
       -dns $INGRESS_POD \
       -dns istio-ingressgateway.istio-system.svc \
       -socketPath /run/spire/sockets/server.sock
   
   Entry ID         : 6f2fe370-5261-4361-ac36-10aae8d91ff7
   SPIFFE ID        : spiffe://example.org/ns/istio-system/sa/istio-ingressgateway-service-account
   Parent ID        : spiffe://example.org/ns/spire/sa/spire-agent
   Revision         : 0
   TTL              : default
   Selector         : k8s:ns:istio-system
   Selector         : k8s:pod-uid:63c2bbf5-a8b1-4b1f-ad64-f62ad2a69807
   Selector         : k8s:sa:istio-ingressgateway-service-account
   DNS name         : istio-ingressgateway.istio-system.svc
   DNS name         : istio-ingressgateway-5b45864fd4-lgrxs
   ```

5. 部署一个工作负载的例子。

   ```bash
   $ istioctl kube-inject --filename @samples/security/spire/sleep-spire.yaml | kubectl apply -f -
   ```

   请注意，工作负载将需要 SPIFFE CSI 驱动卷来访问 SPIRE 代理套接字。要做到这一点，你可以利用[安装 Istio](https://istio.io/latest/docs/ops/integrations/spire/#install-istio) 部分的 `spire `pod 注释模板，或将 CSI 卷添加到工作负载的部署规范中。这两种方法在下面的示例片段中都有强调。

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
   name: sleep
   spec:
   replicas: 1
   selector:
       matchLabels:
       app: sleep
   template:
       metadata:
       labels:
           app: sleep
       # Injects custom sidecar template
       annotations:
           inject.istio.io/templates: "sidecar,spire"
       spec:
       terminationGracePeriodSeconds: 0
       serviceAccountName: sleep
       containers:
       - name: sleep
           image: curlimages/curl
           command: ["/bin/sleep", "3650d"]
           imagePullPolicy: IfNotPresent
           volumeMounts:
           - name: tmp
           mountPath: /tmp
           securityContext:
           runAsUser: 1000
       volumes:
       - name: tmp
           emptyDir: {}
       # CSI volume
       - name: workload-socket
           csi:
           driver: "csi.spiffe.io"
   ```

6. 获取 pod 信息。

   ```bash
   $ SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath="{.items[0].metadata.name}")
   $ SLEEP_POD_UID=$(kubectl get pods $SLEEP_POD -o jsonpath='{.metadata.uid}')
   ```

7. 注册工作负载。

   ```bash
   $ kubectl exec -n spire spire-server-0 -- \
   /opt/spire/bin/spire-server entry create \
       -spiffeID spiffe://example.org/ns/default/sa/sleep \
       -parentID spiffe://example.org/ns/spire/sa/spire-agent \
       -selector k8s:ns:default \
       -selector k8s:pod-uid:$SLEEP_POD_UID \
       -dns $SLEEP_POD \
       -socketPath /run/spire/sockets/server.sock
   ```

工作负载的 SPIFFE ID 必须遵循 Istio SPIFFE ID 模式：`spiffe://<trust.domain>/ns/<namespace>/sa/<service-account>。`

请参阅 [SPIRE 关于注册工作负载的帮助](https://spiffe.io/docs/latest/deploying/registering/)，了解如何为工作负载创建新条目，并使用多个选择器加强验证标准，使其得到验证。

## 验证是否为工作负载创建了身份

使用下面的命令来确认为工作负载创建了身份：

```bash
$ kubectl exec -i -t $SPIRE_SERVER_POD -n spire -c spire-server -- /bin/sh -c "bin/spire-server entry show -socketPath /run/spire/sockets/server.sock"

Found 3 entries
Entry ID         : c8dfccdc-9762-4762-80d3-5434e5388ae7
SPIFFE ID        : spiffe://example.org/ns/istio-system/sa/istio-ingressgateway-service-account
Parent ID        : spiffe://example.org/ns/spire/sa/spire-agent
Revision         : 0
TTL              : default
Selector         : k8s:ns:istio-system
Selector         : k8s:pod-uid:88b71387-4641-4d9c-9a89-989c88f7509d
Selector         : k8s:sa:istio-ingressgateway-service-account
DNS name         : istio-ingressgateway-5b45864fd4-lgrxs

Entry ID         : af7b53dc-4cc9-40d3-aaeb-08abbddd8e54
SPIFFE ID        : spiffe://example.org/ns/default/sa/sleep
Parent ID        : spiffe://example.org/ns/spire/sa/spire-agent
Revision         : 0
TTL              : default
Selector         : k8s:ns:default
Selector         : k8s:pod-uid:ee490447-e502-46bd-8532-5a746b0871d6
DNS name         : sleep-5f4d47c948-njvpk

Entry ID         : f0544fd7-1945-4bd1-88dc-0a5513fdae1c
SPIFFE ID        : spiffe://example.org/ns/spire/sa/spire-agent
Parent ID        : spiffe://example.org/spire/server
Revision         : 0
TTL              : default
Selector         : k8s_psat:agent_ns:spire
Selector         : k8s_psat:agent_sa:spire-agent
Selector         : k8s_psat:cluster:demo-cluster
```

检查 Ingress-gateway pod 状态。

```bash
$ kubectl get pods -n istio-system

NAME                                    READY   STATUS    RESTARTS   AGE
istio-ingressgateway-5b45864fd4-lgrxs   1/1     Running   0          60s
istiod-989f54d9c-sg7sn                  1/1     Running   0          45s
```

在为 Ingress-gateway pod 注册条目后，Envoy 会收到由 SPIRE 签发的身份，并将其用于所有 TLS 和 mTLS 通信。

### 检查工作负载身份是否是由 SPIRE 签发的

1. 使用 `istioctl proxy-config secret` 命令检索 sleep 的 SVID 身份文件。

   ```bash
   $ istioctl proxy-config secret $SLEEP_POD -o json | jq -r \
   '.dynamicActiveSecrets[0].secret.tlsCertificate.certificateChain.inlineBytes' | base64 --decode > chain.pem
   ```

2. 检查证书并核实 SPIRE 是发行人。

   ```bash
   $ openssl x509 -in chain.pem -text | grep SPIRE
   Subject: C = US, O = SPIRE, CN = sleep-5f4d47c948-njvpk
   ```

## SPIFFE 联邦

SPIRE 服务器能够对来自不同信任域的 SPIFFE 身份进行认证。这被称为 SPIFFE 联邦。

SPIRE Agent 可以被配置为通过 Envoy SDS API 向 Envoy 推送联合身份包，允许 Envoy 使用[验证上下文](https://spiffe.io/docs/latest/microservices/envoy/#validation-context)来验证对等的证书并信任来自另一个信任域的工作负载。为了使 Istio 能够通过 SPIRE 集成来联合 SPIFFE 身份，请查阅 [SPIRE Agent SDS 配置](https://github.com/spiffe/spire/blob/main/doc/spire_agent.md#sds-configuration)，并为你的 SPIRE Agent 配置文件设置以下 SDS 配置值。

| 配置                       | 描述                                                         | 资源名称 |
| :------------------------- | :----------------------------------------------------------- | :------- |
| `default_svid_name`        | TLS 证书资源名称，用于 Envoy SDS 的默认 X509-SVID。          | default  |
| `default_bundle_name`      | 用于 Envoy SDS 的默认 X.509 捆绑包的验证上下文资源名称。     | null     |
| `default_all_bundles_name` | 所有使用 Envoy SDS 的捆绑包（包括联合包）所使用的验证上下文资源名称。 | ROOTCA   |

这让 Envoy 可以直接从 SPIRE 获得联合捆绑包。

### 创建联合注册条目

如果使用 SPIRE Kubernetes 工作负载注册器，通过向服务部署规范添加 pod 注释 `spiffe.io/federatesWith`，指定你希望 pod 与之联合的信任域，为工作负载创建联合条目：

```yaml
podAnnotations:
  spiffe.io/federatesWith: "<trust.domain>"
```

关于手动注册，请参见[为联邦创建注册条目](https://spiffe.io/docs/latest/architecture/federation/readme/#create-registration-entries-for-federation)。

## 清理 SPIRE

如果你使用 Istio 提供的快速启动 SPIRE 部署来安装 SPIRE，使用以下命令来删除这些 Kubernetes 资源：

```bash
$ kubectl delete CustomResourceDefinition spiffeids.spiffeid.spiffe.io
$ kubectl delete -n spire serviceaccount spire-agent
$ kubectl delete -n spire configmap spire-agent
$ kubectl delete -n spire deployment spire-agent
$ kubectl delete csidriver csi.spiffe.io
$ kubectl delete -n spire configmap spire-server
$ kubectl delete -n spire service spire-server
$ kubectl delete -n spire serviceaccount spire-server
$ kubectl delete -n spire statefulset spire-server
$ kubectl delete clusterrole spire-server-trust-role spire-agent-cluster-role
$ kubectl delete clusterrolebinding spire-server-trust-role-binding spire-agent-cluster-role-binding
$ kubectl delete namespace spire
```
