---
title: TSB 常见问题解答
description: 关于 TSB 的常见问题
---

## 如何确定 Envoy 是否正常？

确定 Envoy 是否正常的最佳方法是检查其健康和就绪端点（`healthz`）。要检查已加入的集群中应用程序的 Envoy 的 `healthz` 端点，你需要直接连接到应用程序的旁路 Envoy 边车。

假设你在集群的 `bookinfo` 命名空间中有一个名为 `details-v1-57f8794694-hc7gd` 的 Pod，该 Pod 托管你的应用程序。

使用 `kubectl port-forward` 建立本地机器到 Envoy 边车上的端口 `15021` 的端口转发：

```bash
kubectl port-forward -n bookinfo details-v1-57f8794694-hc7gd 15021:15021
```

一旦上述命令成功执行，你现在应该能够将你喜爱的工具指向 URL `http://localhost:15021/healthz/ready` 并直接访问 Envoy 的 `healthz` 端点。请避免使用浏览器进行此操作，因为如果正确配置并运行，则 Envoy 代理将返回一个带有空主体的 `200 OK` 响应。

例如，你可以使用 `curl` 以详细模式执行如下：

```bash
curl -v http://localhost:15021/healthz/ready
```

这应该会产生类似以下的输出。如果响应状态为 `200 OK`，则 Envoy 正常工作。

```bash
curl -v http://localhost:15021/healthz/ready
*   Trying 127.0.0.1:15021...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 15021 (#0)
> GET /healthz/ready HTTP/1.1
> Host: localhost:15021
> User-Agent: curl/7.68.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< date: Fri, 02 Jul 2021 13:32:05 GMT
< content-length: 0
< x-envoy-upstream-service-time: 0
< server: envoy
<
* Connection #0 to host localhost left intact
```

## `tctl` 连接到集群失败

请检查你的 `tctl` 配置文件中是否包含与集群相关的正确组织和租户信息。

首先，通过执行以下命令获取当前活动配置文件：

```bash
tctl config profiles list
```

你应该会看到类似以下的输出。

```
  CURRENT  NAME     CLUSTER  ACCOUNT
           default  default  admin-user
  *        gke-tsb  gke-tsb  gke-user
```

带有星号（`*`）的条目是当前活动配置文件。要配置当前配置文件 `gke-tsb`，使 `gke-user` 使用组织名称 `organization-name` 和租户名称 `tenant-name` 连接到集群，请执行以下命令：

```bash
tctl config users set "gke-user" \
  --org <organization-name> \
  --tenant <tenant-name> \
  --username <username> \
  --password <password>
```

组织名称和租户名称可以通过 Web 用户界面获取。

此后，当你执行 `tctl` 命令时，将会针对指定的组织和租户运行。对于需要身份验证的每个 `tctl` 子命令，也可以通过显式指定 `--org` 和 `--tenant` 参数来完成相同的操作。

## 是否可以在多个集群之间共享单个 TSB 实例？

是的。单个 TSB [管理平面](../../concepts/terminology/#management-plane) 能够管理大量集群。你需要将要关联到同一管理平面的每个集群都加入。此外，请参阅文档 [TSB 资源消耗和容量规划](../../setup/resource_planning) 以获取有关随着参与集群数量增加可能需要的资源量的详细信息。

如果需要为每个集群配置不同的权限或团队，请使用 [工作区](../../concepts/terminology/#workspace) 和 [组](../../concepts/terminology/#group) 进行逻辑分区。

请查看我们的安装指南，了解如何将集群加入 [TSB](../../setup/self_managed/onboarding-clusters)。

## 使用自定义证书时出现 "OPENSSL_VERIFY 失败" 错误。

当你使用[中间 CA](../../operations/vault/istiod-ca)或自己的证书时，客户端 Envoy 可能会出现 "OPENSSL_VERIFY 失败" 错误。

"OPENSSL_VERIFY 失败" 错误可能由多种原因引起。你应该采取的一般方法是获取证书并验证其内容。请注意，诊断证书本身不在本文档的范围之内，你将不得不自行准备进行此操作。

`istioctl` 提供了用于比较工作负载之间的 CA 包的内置命令：`istioctl proxy-config rootca-compare pod/<pod-1>.<namespace-1> pod/<pod-2>.<namespace-2>`。该命令自动化了下面的手动过程，并应该是在诊断 OPENSSL_VERIFY 错误时的首选选择。

### 手动检查证书

要获取目标 Envoy 实例正在使用的证书，可以使用以下示例中的 `istioctl`。将 `<server-pod-ID>` 替换为你正在调试的 Envoy 实例的适当值：

```bash
istioctl proxy-config secret <server-pod-ID> -ojson > server-tls.json
```

文件 `server-tls.json`

 将包含 Istio 互联网 TLS 证书，我们可以从中提取单独的证书。

```bash
cat server-tls.json | \
  jq -r `.dynamicActiveSecrets[0].secret.tlsCertificate.certificateChain.inlineBytes' | \
  base64 --decode > server.crt
```

在以下示例中，我们将分离出服务器证书和其余链以进行演示，并使用 `openssl verify` 来检查证书。将以下 bash 脚本复制到名为 `check-chain.sh` 的文件中：

```bash
#!/bin/bash

# 用户提供的文件名。
usercert=$1

# 临时文件和清理
tmpfirst=$(mktemp)
tmpchain=$(mktemp)
function cleanup_tmpfiles {
        [ -f "$tmpfirst" ] && rm -f "$tmpfirst";
        [ -f "$tmpchain" ] && rm -f "$tmpchain";
}

trap cleanup_tmpfiles EXIT
trap 'trap - EXIT; cleanup_tmpfiles; exit -1' INT PIPE TERM

outfile="$tmpfirst"
count=0
while IFS= read -r line
do
        if [[ "$line" == *-"BEGIN CERTIFICATE"-* ]]; then
                ((count = $count + 1))
                if [[ $count == 2 ]]; then
                        outfile="$tmpchain"
                fi
        fi
        echo $line >> "$outfile"
done < "$usercert"

openssl verify -CAfile "$tmpchain" "$tmpfirst" > /dev/null
if [[ $? == 0 ]]; then
        echo "OK"
fi
```

然后针对你在上一步中获得的文件运行它：

```bash
$ bash check-chain.sh server.crt
```

如果在执行上述脚本时验证失败，则证书未正确链接。例如，CA 证书主体可能与工作负载证书的发行者不匹配。

## Istio CNI 如何与像 Cilium 或 Calico 这样的 Kubernetes CNI 协同工作？它会替代它们吗？

Istio 的 CNI 不会替代 Cilium 或 Calico 等 CNI 插件，但 Istio 的 CNI 会作为这些插件的附加组件与任何其他 Kubernetes CNI 协同工作（在 CNI 规范的术语中称为 "[链接插件](https://github.com/containernetworking/cni/blob/master/SPEC#section-2-execution-protocol)"）。

你的主要 CNI 插件将运行并构建你的 Pod 的 Kubernetes 网络，然后 Istio 的 CNI 将运行并重写网络规则以通过 Envoy 捕获流量。Istio 的 CNI 执行与 `istio-init` 容器完全相同的代码来重写这些网络规则（请查看 [Istio 网站上的此博客](https://istio.io/latest/blog/2019/data-plane-setup/#traffic-flow-from-application-container-to-sidecar-proxy) 以深入了解流量拦截的工作原理）。

来自 [官方网站](https://istio.io/latest/docs/setup/additional-setup/cni/) 的解释描述得很好：

> 默认情况下，Istio 在部署到网格中的 Pod 中注入一个名为 `istio-init` 的初始化容器。`istio-init` 容器设置了将流量重定向到/从 Istio sidecar 代理的 Pod 网络流量。这需要部署到网格中的用户或服务帐户具有足够的 Kubernetes RBAC 权限以部署具有 `NET_ADMIN` 和 `NET_RAW` 能力的 [容器](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container)。要求 Istio 用户具备提升的 Kubernetes RBAC 权限对某些组织的安全合规性来说是有问题的。Istio CNI 插件是 `istio-init` 容器的替代品，执行相同的网络功能，但无需 Istio 用户启用提升的 Kubernetes RBAC 权限。

## 如何在 TSB 中启用 Istio CNI？

请查看我们的 [Istio CNI 管理指南](../../operations/features/istio_cni#enable-istio-cni-in-control-plane)，了解如何在 TSB 中配置 Istio CNI。

## 如果更改我的 CNI 插件，我需要在 TSB 或 Istio 中进行哪些操作？

不需要进行任何操作：Istio 的 CNI 插件会自行配置以在主要插件之后运行。更改你的 CNI 提供程序并重新构建集群会确保 Istio 的 CNI 仍然在主要插件之后运行。

## 配置 AWS 内部 ELB

在某些情况下，你可能希望部署在 EKS 集群中的服务所产生的 AWS 负载均衡器是内部的，而不是暴露给互联网。TSB 运算符 API 为你提供了在每个特定组件的 Kubernetes 服务中设置注释的途径，以便你可以添加 `service.beta.kubernetes.io/aws-load-balancer-scheme` 或 `service.beta.kubernetes.io/aws-load-balancer-internal` 注释。

例如，以下代码片段：

```yaml
spec:
  components:
    frontEnvoy:
      kubeSpec:
        service:
          annotations:
            service.beta.kubernetes.io/aws-load-balancer-scheme: internal
```

将配置前端 Envoy（TSB API 和 UI 的主要入口点）的 Kubernetes 服务为内部负载均衡器。类似地，你可以为集群中部署的网关执行相同操作。

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: bookinfo
  namespace: bookinfo
spec:
  kubeSpec:
    service:
      annotations:
            service.beta.kubernetes.io/aws-load-balancer-scheme: internal    
```
