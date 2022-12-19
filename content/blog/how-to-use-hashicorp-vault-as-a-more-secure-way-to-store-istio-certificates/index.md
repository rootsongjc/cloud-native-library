---
title: "如何使用 Hashicorp Vault 作为一种更安全的方式来存储 Istio 证书"
date: 2022-12-19T13:00:00+08:00
draft: false
authors: ["Tetrate"]
summary: "本文是将指导你使用 Vault 存储 Istio 的证书。"
tags: ["Vault","零信任","安全","Istio","证书"]
categories: ["Istio"]
links:
  - icon: globe
    icon_pack: fa
    name: 原文
    url: https://tetrate.io/blog/how-to-use-hashicorp-vault-as-a-more-secure-way-to-store-istio-certificates/
---

在本文中，我们将探讨如何使用 Hashicorp Vault 作为一种比使用 Kubernetes [Secret](https://kubernetes.io/docs/concepts/configuration/secret) 更安全的方式来存储 Istio 证书。默认情况下，Secret 使用 base64 编码存储在 *etcd* 中。在安全策略严格的环境中，这可能是不可接受的，因此需要额外的措施来保护它们。一种此类解决方案涉及将机密存储在外部机密存储提供程序中，例如 [HashiCorp Vault](https://www.vaultproject.io/)。

Vault 可以托管在 Kubernetes 集群内部和外部。在本案例中，我们将探索使用托管在 Kubernetes 外部的 Vault，以便它可以同时为多个集群提供秘密。该设置也非常适合探索 Istio 的[多集群功能](https://istio.io/latest/docs/setup/install/multicluster)，它需要一个共享的信任域。

利用 `vault-agent-init` 容器，我们可以将证书和私钥材料注入实际的 Istio 控制平面 Pod，以便它们使用外部 CA 证书进行引导。这避免了依赖 Secret 来引导 Istio 控制平面。该技术也完全适用于入口和出口证书。

有关如何在 Istio 中使用和管理证书的更多信息，请参见官方文档：

- [身份和证书管理](https://istio.io/latest/zh/docs/concepts/security/#pki)
- [插入 CA 证书](https://istio.io/latest/zh/docs/tasks/security/cert-management/plugin-ca-cert)
- [使用 Kubernetes CSR 的自定义 CA 集成](https://istio.io/latest/zh/docs/tasks/security/cert-management/custom-ca-k8s)

有关基于实际生产经验的最佳实践，另请查看以下 [Tetrate](https://tetrate.io/) 的博客文章：

- [信任链：Istio 对现有 PKI 的信任](https://tetrate.io/blog/istio-trust)
- [在生产中大规模自动化 Istio CA 轮换](https://tetrate.io/blog/automate-istio-ca-rotation-in-production-at-scale)

这篇博文附带的代码可以在以下存储库中找到：

https://github.com/tetratelabs/istio-vault-ext-certs

## **Istiod 证书处理**

尽管上述博文中解释了一些决策逻辑，但也值得参考[源代码](https://github.com/istio/istio/blob/master/pilot/pkg/bootstrap/istio_ca.go)以查找一些未记录的行为。

在 Istio 的源码 `istio/pilot/pkg/bootstrap/istio_ca.go` 文件中，你将看到：为了向后兼容，Istio 保留了对用于自签名证书 `cacerts` Secret 的支持。它安装在相同的位置，如果发现了就会被使用——创建秘密就足够了，不需要额外的选项。在旧安装程序中，`LocalCertDir` 被硬编码到 `/etc/cacerts` 并使用 `cacerts`  Secret 安装。已删除对签署其他根 CA 的支持——太危险，没有明确的用例。

默认配置，用于向后兼容 Citadel：

- 如果 `istio-system` 中存在 `cacerts` 秘密，将被挂载。它可能包含一个可选的 `root-cert.pem`，
带有额外的根和可选的 `{ca-key, ca-cert, cert-chain}.pem` 由用户提供的根 CA。
- 如果未找到用户提供的根 CA，则使用 `istio-ca-secret` Secret ，以及 `ca-cert.pem` 和 `ca-key.pem` 文件。
- 如果两者均未找到，将创建 `istio-ca-secret`。
- 带有 `caTLSRootCert` 文件的 `istio-security` ConfigMap 将用于根证书，并在需要时创建。该 ConfigMap 由节点代理使用，不再可能在 sds-agent 中使用，但我们仍保留它以向后兼容。将与 node-agent 一起删除。sds-agent 使用 K8S root 直接调用 `NewCitadelClient` 。

为了指示 Istio 从其他地方获取证书，而不是标准 Kubernetes Secret，我们将利用 *istio-pilot*（又名 istiod 或 Istio 控制平面）的环境变量（[见此文档](https://istio.io/latest/docs/reference/commands/pilot-discovery)），从 Kubernetes Pod 中的另一个位置获取证书。这是必需的，因为 `vault-agent-init` 注入容器将创建一个新的挂载卷 `/vault/secrets` ，以放置从外部 Vault 服务器拉出的证书和私钥。

| 变量名称      | 类型   | 默认值         | 描述                         |
| ------------- | ------ | -------------- | ---------------------------- |
| `ROOT_CA_DIR` | 字符串 | `/etc/cacerts` | 本地或安装的 CA 根目录的位置 |

## Pod 内的 `vault-agent-init` 容器注解

我们将利用 Vault 注入器注解来指示 Sidecar 提取哪些数据以及在这样做时使用什么 Vault 角色。我们还确保容器在我们实际的主容器之前运行，因此后者可以获取证书和密钥材料以正确引导自身。[此处](https://developer.hashicorp.com/vault/docs/platform/k8s/injector/annotations)列举并记录了 Vault 注解。我们将在本教程中使用的相关注释如下：

| **注解**                                     | **默认值** | **描述**                                                     |
| -------------------------------------------- | ---------- | ------------------------------------------------------------ |
| `vault.hashicorp.com/agent-inject`           | false      | 配置是否为 Pod 显式启用或禁用注入。这应该设置为 true 或 false。 |
| `vault.hashicorp.com/agent-init-first`       | false      | 如果为 true，则将 Pod 配置为首先运行 Vault Agent init 容器（如果为 false，则最后运行）。当其他 init 容器需要预填充的秘密时，这很有用。这应该设置为 true 或 false。 |
| `vault.hashicorp.com/role`                   | –          | 配置 Vault 代理自动验证方法使用的 Vault 角色。`vault.hashicorp.com/agent-configmap` 未设置时需要。 |
| `vault.hashicorp.com/auth-path`              | –          | 配置 Kubernetes 身份验证方法的身份验证路径。默认为 `auth/kubernetes`。 |
| `vault.hashicorp.com/agent-inject-secret-`   | –          | 配置 Vault 代理以从容器所需的 Vault 中检索秘密。Secret 的名称是 `vault.hashicorp.com/agent-inject-secret-` 之后的任意唯一字符串，例如 `vault.hashicorp.com/agent-inject-secret-foobar` 该值是 secret 所在的 Vault 中的路径。 |
| `vault.hashicorp.com/agent-inject-template-` | –          | 配置 Vault Agent 应该用于呈现秘密的模板。模板的名称是 v`ault.hashicorp.com/agent-inject-template-` 之后的任何唯一字符串，例如 `vault.hashicorp.com/agent-inject-template-foobar`。这应该映射到 `vault.hashicorp.com/agent-inject-secret-` 中提供的相同唯一值。如果未提供，则使用默认的通用模板。 |

## Vault 服务器注意事项 {#vault-server-considerations}

Vault 支持多种客户端验证自己的方法。我们将利用 [Kubernetes 身份验证后端](https://developer.hashicorp.com/vault/docs/auth/kubernetes)，这意味着我们将利用 Kubernetes ServiceAccount JWT 令牌验证。请注意，自 Kubernetes 1.24 以来，不再自动生成 ServiceAccount 令牌。您仍然可以手动创建这些 API 令牌，如[此处所述](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#manually-create-an-api-token-for-a-serviceaccount)。

至于证书和私钥材料的存储，我们有两种选择：

- [PKI 秘密引擎](https://developer.hashicorp.com/vault/docs/secrets/pki)
- [KV 秘密引擎](https://developer.hashicorp.com/vault/docs/secrets/kv)

因为 PKI 秘密引擎不提供精简的 API 来检索我们需要的证书和私钥，并且因为 PKI 秘密引擎会为每次调用（例如，每次 *istiod* 重启）生成一个新的中间证书，我们将使用通用的 KV 秘密引擎，将我们需要的所有值存储在一个简单的键值数据结构中。我们假设中间证书的更新是通过一些服务门户或 CI/CD 过程在外部处理的，这些过程也将更新的中间证书存储在 Vault 服务器中。

Istio 的控制平面 Pod 需要以下文件才能在 CA 中正确引导其构建：

| Key            | 值（PEM 编码） | 细节                                    |
| -------------- | -------------- | --------------------------------------- |
| ca-key.pem     | 私钥           | 中间证书的私钥，用作 *istiod* 的根 CA。 |
| ca-cert.pem    | CA 公共证书    | 中间证书，用作 *istiod* 的根 CA。       |
| root-cert.pem  | CA 根证书      | 我们新生成的中间证书的信任根。          |
| cert-chain.pem | 完整的证书链   | 中间证书在顶部，根证书在底部。          |

## 设置

如果要遵循本地设置，则安装软件的先决条件包括：

- *kubectl* 与 Kubernetes 集群交互（[下载](https://kubernetes.io/docs/tasks/tools/#kubectl)）
- *helm* 安装 Vault injector 和 Istio chart（[下载](https://helm.sh/docs/intro/install)）
- 用于配置 Vault 服务器的 *vault cli* 工具（[下载](https://developer.hashicorp.com/vault/tutorials/getting-started/getting-started-install#install-vault)）

如果您想要本地演示环境，请按照[此处](https://github.com/tetratelabs/istio-vault-ext-certs/blob/main/local-setup.md)的说明进行操作，该说明使用 `docker-compose` 启动一个 Vault 服务器和两个独立的 k3s 集群。如果您使用自己的 Kubernetes 集群和外部托管的 Vault 实例，请跳至下一节。

- *docker-compose* 启动本地环境（[下载](https://github.com/docker/compose/releases)）

为了取得进展，我们希望根据您的环境设置以下 shell 变量。

```bash
export VAULT_SERVER=
export K8S_API_SERVER_1=
export K8S_API_SERVER_2=
```

## **Vault Kubernetes 身份验证后端**

正如在有关 [Vault 服务器注意事项](#vault-server-considerations)的介绍部分中提到的，我们将使用 [Kubernetes 身份验证后端](https://developer.hashicorp.com/vault/docs/auth/kubernetes)。由于 *istiod* 将从 Vault 服务器获取证书和私钥材料，让我们从在两个集群中创建相应的服务账户开始。

```bash
kubectl --kubeconfig kubecfg1.yml create ns istio-system
kubectl --kubeconfig kubecfg2.yml create ns istio-system
kubectl --kubeconfig kubecfg1.yml apply -f istio-sa.yml
kubectl --kubeconfig kubecfg2.yml apply -f istio-sa.yml
```

ServiceAccount、Secret 和 ClusterRoleBinding 如下：

```yaml
# istio-sa.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: istiod
  namespace: istio-system
  labels: # added for istio helm installation
    app: istiod
    app.kubernetes.io/managed-by: Helm
    release: istio-istiod
  annotations: # added for istio helm installation
    meta.helm.sh/release-name: istio-istiod
    meta.helm.sh/release-namespace: istio-system
---
apiVersion: v1
kind: Secret
metadata:
  name: istiod
  namespace: istio-system
  annotations:
    kubernetes.io/service-account.name: istiod
type: kubernetes.io/service-account-token
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: role-tokenreview-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
  - kind: ServiceAccount
    name: istiod
    namespace: istio-system
```

> 注意：*我们在 istiod ServiceAccount 上添加了 Helm 标签和注解，以免与稍后的 Istio Helm 部署发生冲突。*

在两个集群中创建 ServiceAccount 后，让我们将它们的 Secret 令牌和 ca.cert 值存储在 output 文件夹中：

```bash
mkdir -p ./output
kubectl --kubeconfig kubecfg1.yml get secret -n istio-system istiod -o go-template="{{ .data.token }}" | base64 --decode > output/istiod1.jwt
kubectl --kubeconfig kubecfg1.yml config view --raw --minify --flatten -o jsonpath="{.clusters[].cluster.certificate-authority-data}" | base64 --decode > output/k8sapi-cert1.pem
kubectl --kubeconfig kubecfg2.yml get secret -n istio-system istiod -o go-template="{{ .data.token }}" | base64 --decode > output/istiod2.jwt
kubectl --kubeconfig kubecfg2.yml config view --raw --minify --flatten -o jsonpath="{.clusters[].cluster.certificate-authority-data}" | base64 --decode > output/k8sapi-cert2.pem
```

关于 Kubernetes API 证书和 istiod ServiceAccount JWT 令牌的详细内容的更多信息可以在[这里](https://github.com/tetratelabs/istio-vault-ext-certs/blob/main/output)找到，在这里我们也更深入地描述了 Vault 的交互过程，即通过 REST API 调用来验证和获取秘密。在调试权限拒绝的问题时，这些可以派上用场。

让我们根据刚刚检索到的 Kubernetes CA 证书和 JWT 令牌创建必要的 Vault 身份验证配置：

```bash
export VAULT_ADDR=http://localhost:8200
vault login root
vault auth enable --path=kubernetes-cluster1 kubernetes
vault auth enable --path=kubernetes-cluster2 kubernetes
vault write auth/kubernetes-cluster1/config \
  kubernetes_host="$K8S_API_SERVER_1" \
  kubernetes_ca_cert=@output/k8sapi-cert1.pem \
  token_reviewer_jwt=`cat output/istiod1.jwt` \
  disable_local_ca_jwt="true"
vault write auth/kubernetes-cluster2/config \
  kubernetes_host="$K8S_API_SERVER_2" \
  kubernetes_ca_cert=@output/k8sapi-cert2.pem \
  token_reviewer_jwt=`cat output/istiod2.jwt` \
  disable_local_ca_jwt="true"
```

> 注意：如果您使用的是 *docker-compose* 提供的环境，则 `VAULT_ADDR` 设置为 localhost。

## *Vault kv* Secret 中的 Istio 证书和私钥

接下来我们将创建一个新的自签名根证书并为我们的两个集群生成中间证书。我们将在[这里](https://github.com/istio/istio/tree/master/tools/certs)使用上游 Istio 提供的辅助 *Makefile* 脚本：

```bash
cd certs
make -f ../certs-gen/Makefile.selfsigned.mk root-ca
make -f ../certs-gen/Makefile.selfsigned.mk istiod-cluster1-cacerts
make -f ../certs-gen/Makefile.selfsigned.mk istiod-cluster2-cacerts
cd ..
```

有关实际内容和正在设置的 X509v3 扩展的更多详细信息，请参见[此处](https://github.com/tetratelabs/istio-vault-ext-certs/blob/main/certs)。您可以通过[此处](https://github.com/tetratelabs/istio-vault-ext-certs/blob/main/certs-gen)的 *Makefile*文档和相应的 *Makefile* 覆盖值微调证书。

让我们将生成的证书和私钥添加到 Vault *kv* secret 中：

```bash
export VAULT_ADDR=http://localhost:8200
vault login root
vault secrets enable -path=kubernetes-cluster1-secrets kv
vault secrets enable -path=kubernetes-cluster2-secrets kv
vault kv put kubernetes-cluster1-secrets/istiod-service/certs \
  ca_key=@certs/istiod-cluster1/ca-key.pem \
  ca_cert=@certs/istiod-cluster1/ca-cert.pem \
  cert_chain=@certs/istiod-cluster1/cert-chain.pem \
  root_cert=@certs/istiod-cluster1/root-cert.pem
vault kv put kubernetes-cluster2-secrets/istiod-service/certs \
  ca_key=@certs/istiod-cluster2/ca-key.pem \
  ca_cert=@certs/istiod-cluster2/ca-cert.pem \
  cert_chain=@certs/istiod-cluster2/cert-chain.pem \
  root_cert=@certs/istiod-cluster2/root-cert.pem
```

通过限制对每个集群的这些证书和私钥的访问，绑定到基于 Kubernetes *istiod* ServiceAccount 的身份验证后端：

```bash
echo 'path "kubernetes-cluster1-secrets/istiod-service/certs" {
  capabilities = ["read"]
}' | vault policy write istiod-certs-cluster1 -
echo 'path "kubernetes-cluster2-secrets/istiod-service/certs" {
  capabilities = ["read"]
}' | vault policy write istiod-certs-cluster2 -
vault write auth/kubernetes-cluster1/role/istiod \
  bound_service_account_names=istiod \
  bound_service_account_namespaces=istio-system \
  policies=istiod-certs-cluster1 \
  ttl=24h
vault write auth/kubernetes-cluster2/role/istiod \
  bound_service_account_names=istiod \
  bound_service_account_namespaces=istio-system \
  policies=istiod-certs-cluster2  \
  ttl=24h
```

## 部署 *vault-inject* 和 Istio Helm Charts

为了部署 Vault 注入器，我们将利用官方 Vault [Helm chart](https://github.com/hashicorp/vault-helm)。

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
kubectl --kubeconfig kubecfg1.yml create ns vault
kubectl --kubeconfig kubecfg2.yml create ns vault
helm --kubeconfig kubecfg1.yml install -n vault vault-inject hashicorp/vault --set "injector.externalVaultAddr=$VAULT_SERVER"
helm --kubeconfig kubecfg2.yml install -n vault vault-inject hashicorp/vault --set "injector.externalVaultAddr=$VAULT_SERVER"
kubectl --kubeconfig kubecfg1.yml -n vault get pods
kubectl --kubeconfig kubecfg2.yml -n vault get pods
```

```
NAME                                           READY   STATUS    RESTARTS   AGE
vault-inject-agent-injector-5776975795-9vt9w   1/1     Running   0          92s
NAME                                           READY   STATUS    RESTARTS   AGE
vault-inject-agent-injector-5776975795-9vjnx   1/1     Running   0          91s
```

要安装 Istio，我们将使用 Tetrate Istio Distro [Helm chart](https://github.com/tetratelabs/helm-charts)。

```bash
helm repo add tetratelabs https://tetratelabs.github.io/helm-charts
helm repo update
helm --kubeconfig kubecfg1.yml install -n istio-system istio-base tetratelabs/base
helm --kubeconfig kubecfg2.yml install -n istio-system istio-base tetratelabs/base
helm --kubeconfig kubecfg1.yml install -n istio-system istio-istiod tetratelabs/istiod --values=./cluster1-values.yaml
helm --kubeconfig kubecfg2.yml install -n istio-system istio-istiod tetratelabs/istiod --values=./cluster2-values.yaml
kubectl --kubeconfig kubecfg1.yml -n istio-system get pods
kubectl --kubeconfig kubecfg2.yml -n istio-system get pods
```

请注意我们如何利用多个 Istio Helm chart 值覆盖来我们预期的目标：

- 注入一个 pilot Pod 环境变量 `ROOT_CA_DIR` 来告诉 *istiod* 从哪里获取证书和私钥
- 告诉 `vault-agent-init` 容器在 *istiod* 容器之前运行，因此秘密安装在 `/vault/secrets` 的卷中可用
- 指示 Vault 注入器从正确的位置和数据密钥获取机密
- 这样做时承担 Vault *istiod* 角色
- 覆盖默认的 Kubernetes auth-path，因为我们有多个集群 

```yaml
pilot:
  env:
    ROOT_CA_DIR: /vault/secrets
  podAnnotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/agent-init-first: "true"
    vault.hashicorp.com/agent-inject-secret-ca-key.pem: "kubernetes-cluster1-secrets/istiod-service/certs"
    vault.hashicorp.com/agent-inject-template-ca-key.pem: |
        {{- with secret "kubernetes-cluster1-secrets/istiod-service/certs" -}}
        {{ .Data.ca_key }}
        {{ end -}}
    vault.hashicorp.com/agent-inject-secret-ca-cert.pem: "kubernetes-cluster1-secrets/istiod-service/certs"
    vault.hashicorp.com/agent-inject-template-ca-cert.pem: |
        {{- with secret "kubernetes-cluster1-secrets/istiod-service/certs" -}}
        {{ .Data.ca_cert }}
        {{ end -}}
    vault.hashicorp.com/agent-inject-secret-root-cert.pem: "kubernetes-cluster1-secrets/istiod-service/certs"
    vault.hashicorp.com/agent-inject-template-root-cert.pem: |
        {{- with secret "kubernetes-cluster1-secrets/istiod-service/certs" -}}
        {{ .Data.root_cert }}
        {{ end -}}
    vault.hashicorp.com/agent-inject-secret-cert-chain.pem: "kubernetes-cluster1-secrets/istiod-service/certs"
    vault.hashicorp.com/agent-inject-template-cert-chain.pem: |
        {{- with secret "kubernetes-cluster1-secrets/istiod-service/certs" -}}
        {{ .Data.cert_chain }}
        {{ end -}}
    vault.hashicorp.com/role: "istiod"
    vault.hashicorp.com/auth-path: "auth/kubernetes-cluster1"
```

当我们查看 `vault-agent-init` 容器日志时，我们应该看到类似这样的内容。我们的控制平面已经正确地获取了 Vault 注入的秘密。

```bash
kubectl --kubeconfig kubecfg1.yml logs -n istio-system -l app=istiod -c vault-agent-init --tail=-1
```

```
==> Vault agent started! Log data will stream in below:

  ==> Vault agent configuration:

                      Cgo: disabled
                Log Level: info
                  Version: Vault v1.12.0, built 2022-10-10T18:14:33Z
              Version Sha: 558abfa75702b5dab4c98e86b802fb9aef43b0eb

  2022-11-18T11:01:21.398Z [INFO]  sink.file: creating file sink
  2022-11-18T11:01:21.398Z [INFO]  sink.file: file sink configured: path=/home/vault/.vault-token mode=-rw-r-----
  2022-11-18T11:01:21.398Z [INFO]  template.server: starting template server
  2022-11-18T11:01:21.398Z [INFO]  sink.server: starting sink server
  2022-11-18T11:01:21.398Z [INFO]  auth.handler: starting auth handler
  2022-11-18T11:01:21.398Z [INFO]  auth.handler: authenticating
  2022-11-18T11:01:21.398Z [INFO] (runner) creating new runner (dry: false, once: false)
  2022-11-18T11:01:21.398Z [INFO] (runner) creating watcher
  2022-11-18T11:01:21.402Z [INFO]  auth.handler: authentication successful, sending token to sinks
  2022-11-18T11:01:21.402Z [INFO]  auth.handler: starting renewal process
  2022-11-18T11:01:21.402Z [INFO]  sink.file: token written: path=/home/vault/.vault-token
  2022-11-18T11:01:21.402Z [INFO]  sink.server: sink server stopped
  2022-11-18T11:01:21.402Z [INFO]  sinks finished, exiting
  2022-11-18T11:01:21.402Z [INFO]  template.server: template server received new token
  2022-11-18T11:01:21.402Z [INFO] (runner) stopping
  2022-11-18T11:01:21.402Z [INFO] (runner) creating new runner (dry: false, once: false)
  2022-11-18T11:01:21.402Z [INFO] (runner) creating watcher
  2022-11-18T11:01:21.402Z [INFO] (runner) starting
  2022-11-18T11:01:21.403Z [INFO]  auth.handler: renewed auth token
  2022-11-18T11:01:21.515Z [INFO] (runner) rendered "(dynamic)" => "/vault/secrets/root-cert.pem"
  2022-11-18T11:01:21.515Z [INFO] (runner) rendered "(dynamic)" => "/vault/secrets/ca-cert.pem"
  2022-11-18T11:01:21.515Z [INFO] (runner) rendered "(dynamic)" => "/vault/secrets/cert-chain.pem"
  2022-11-18T11:01:21.516Z [INFO] (runner) rendered "(dynamic)" => "/vault/secrets/ca-key.pem"
  2022-11-18T11:01:21.516Z [INFO] (runner) stopping
  2022-11-18T11:01:21.516Z [INFO]  template.server: template server stopped
  2022-11-18T11:01:21.516Z [INFO] (runner) received finish
  2022-11-18T11:01:21.516Z [INFO]  auth.handler: shutdown triggered, stopping lifetime watcher
  2022-11-18T11:01:21.516Z [INFO]  auth.handler: auth handler stopped
```

当我们查看 `discovery` 容器日志时，我们应该看到如下内容：

```bash
kubectl --kubeconfig kubecfg1.yml logs -n istio-system -l app=istiod -c discovery --tail=-1
```

```
 info	Using istiod file format for signing ca files
  info	Use plugged-in cert at /vault/secrets/ca-key.pem
  info	x509 cert - Issuer: "CN=Intermediate CA,O=Istio,L=istiod-cluster1", Subject: "", SN: 39f67569f10d36a1fc91e9d82156b07d, NotBefore: "2022-11-18T11:11:59Z", NotAfter: "2032-11-15T11:13:59Z"
  info	x509 cert - Issuer: "CN=Root CA,O=Istio", Subject: "CN=Intermediate CA,O=Istio,L=istiod-cluster1", SN: dedf298a147681d6, NotBefore: "2022-11-17T22:01:54Z", NotAfter: "2024-11-16T22:01:54Z"
  info	x509 cert - Issuer: "CN=Root CA,O=Istio", Subject: "CN=Root CA,O=Istio", SN: f5bcd7e89bdb6248, NotBefore: "2022-11-17T22:01:52Z", NotAfter: "2032-11-14T22:01:52Z"
  info	Istiod certificates are reloaded
  info	spiffe	Added 1 certs to trust domain cluster.local in peer cert verifier
```

我们可以看到我们的 Istio 控制平面已经正确地获取了我们的 Vault 注入证书和私钥。任务完成！

## 结论

在本文中，我们已经使用外部 Vault 存储的证书和私钥成功引导了 Istio 控制平面。实现这一目标的步骤包括：

- 将证书和私钥存储在每个集群专用的 Vault 秘密安装路径中
- 为每个集群设置 Kubernetes Vault 身份验证后端，链接到正确的 ServiceAccount
- 定义适当的角色和策略以允许从 *istiod* ServiceAccount 访问 Vault 机密
- 将 Istio Pilot 引导程序参数调整为：
  - 注入 *vault-agent-init* sidecar
  - 获取包含我们的证书和私钥的正确 Vault 机密
  - 使用正确的角色和身份验证后端来这样做
  - 从正确的 vault secret 安装路径中获取证书和私钥

我们可以使用完全相同的技术来注入*入口网关*和*出口网关*证书。创建 Istio [Gateway](https://istio.io/latest/docs/reference/config/networking/gateway/#ServerTLSSettings) 对象时，请确保将 *serverCertificate*、*privateKey* 和 *caCertificates* 指向 `/vault/secrets` 挂载卷中的正确文件。我们将把它作为练习留给读者。

通过将证书注入绑定到 Kubernetes ServiceAccount，我们现在已将证书生命周期管理委托给外部秘密 Vault 实例。现在可以使用专用角色和写入/更新策略创建服务门户或 CI/CD 管道等外部流程，以提供必要的证书生命周期管理安全性。
