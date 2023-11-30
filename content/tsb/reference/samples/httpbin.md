---
title: 安装 httpbin
weight: 1
---

[`httpbin`](https://httpbin.org) 是一个简单的 HTTP 请求和响应服务，用于测试。

在 TSB 文档中的许多示例中都使用了 `httpbin` 服务。本文档提供了该服务的基本安装过程。

请确保参考每个 TSB 文档，以了解特定的注意事项或所需的自定义，以使示例正常工作，因为本文档描述了最通用的安装步骤。

以下示例假设你已经设置了 TSB，并且已经将 Kubernetes 集群注册到要安装 `httpbin` 工作负载的 TSB 上。

除非另有说明，使用 `kubectl` 命令的示例必须指向相同的集群。在运行这些命令之前，请确保你的 `kubeconfig` 指向所需的集群。

## 命名空间

除非另有说明，假定 `httpbin` 服务已安装在 `httpbin` 命名空间中。如果尚未存在，请在目标集群中创建此命名空间。

运行以下命令以创建命名空间（如果尚不存在）：

```bash
kubectl create namespace httpbin
```

此命名空间中的 `httpbin` pod 必须运行 Istio sidecar 代理。要自动启用此 sidecar 对所有 pod 的注入，请执行以下操作：

```bash
kubectl label namespace httpbin istio-injection=enabled --overwrite=true
```

这将告诉 Istio 需要向稍后创建的 pod 注入 sidecar。

## 部署 `httpbin` Pod 和服务

下载在 Istio 存储库中找到的 [`httpbin.yaml`](https://raw.githubusercontent.com/istio/istio/master/samples/httpbin/httpbin.yaml) 清单。

运行以下命令，在 `httpbin` 命名空间中部署 `httpbin` 服务：

```bash
kubectl apply -n httpbin -f httpbin.yaml
```

## 暴露 `httpbin` 服务

下一步可能需要根据使用情况进行或不进行，如果需要 Ingress Gateway，则创建一个名为 `httpbin-ingress-gateway.yaml` 的文件，其中包含以下内容。

```
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: httpbin-ingress-gateway
  namespace: httpbin
spec:
  kubeSpec:
    service:
      type: LoadBalancer
```

然后使用 `kubectl` 部署它：

```bash
kubectl apply -f httpbin-ingress-gateway.yaml
```

## 创建证书

下一步可能需要根据使用情况进行或不进行，如果需要 TLS 证书，可以按照以下步骤准备它们。

下载脚本 [`gen-cert.sh`](../../../assets/quickstart/gen-cert.sh) 并执行以下操作以生成必要的文件。有关更多详细信息，请参阅[此文档](../../../quickstart/ingress-gateway)。

```bash
chmod +x ./gen-cert.sh
mkdir certs
./gen-cert.sh httpbin httpbin.tetrate.com certs
```

上述假设你已将 `httpbin` 服务公开为 `httpbin.tetrate.com`。如果需要，请相应更改其值。

一旦你在 `certs` 目录中生成了必要的文件，请创建 Kubernetes 密钥。

```bash
kubectl -n httpbin create secret tls httpbin-certs \
  --key certs/httpbin.key \
  --cert certs/httpbin.crt
```

## 创建 `httpbin` 工作区

下一步可能需要根据使用情况进行或不进行，如果要创建 TSB 工作区，则按照以下步骤操作。

在此示例中，我们假设你已经在组织中创建了一个租户。如果尚未创建，请阅读[文档中的示例并创建一个](../../../quickstart/tenant)。

创建名为 `httpbin-workspace.yaml` 的文件，其中包含类似以下示例的内容。请确保将组织、租户和集群名称替换为适当的值。

{{<callout note 注意>}}
如果你已经[安装了 `demo` 配置文件](../../../setup/self-managed/demo-installation)，则已经存在名为 `tetrate` 的组织和一个名为 `demo` 的集群。
{{</callout>}}

```
apiversion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: <organization>
  tenant: <tenant>
  name: httpbin
spec:
  displayName: Httpbin Workspace
  namespaceSelector:
    names:
      - "<cluster>/httpbin"
```

使用 `tctl` 应用清单：

```bash
tctl apply -f httpbin-workspace.yaml
```

## 创建配置组

下一步可能需要根据使用情况进行或不进行，如果要为此服务创建配置组，则按照以下步骤操作。

在此示例中，我们假设你已经在组织中创建了一个租户和一个工作区。如果尚未创建，请阅读[文档中的示例并创建一个](../../../quickstart/tenant)，以及创建 `httpbin` 工作区中的说明。

创建名为 `httpbin-groups.yaml` 的文件，其中包含类似以下示例的内容。请确保将组织、租户、工作区和集群名称替换为适当的值。

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
  organization: <organization>
  tenant: <tenant>
  workspace: httpbin
  name: httpbin-gateway
spec:
  namespaceSelector:
    names:
      - "<cluster>/httpbin"
  configMode: BRIDGED
---
apiVersion: traffic.tsb.tetrate.io/v2
kind: Group
Metadata:
  organization: <organization>
  tenant: <tenant>
  workspace: httpbin
  name: httpbin-traffic
spec:
  namespaceSelector:
    names:
      - "<cluster>/httpbin"
  configMode: BRIDGED
---
apiVersion: security.tsb.tetrate.io/v2
kind: Group


Metadata:
  organization: <organization>
  tenant: <tenant>
  workspace: httpbin
  name: httpbin-security
spec:
  namespaceSelector:
    names:
      - "<cluster>/httpbin"
  configMode: BRIDGED
```

使用 `tctl` 应用清单：

```
tctl apply -f httpbin-groups.yaml
```

完成后，你应该得到 3 个组，一个[网关组](../../../refs/tsb/gateway/v2/gateway_group) (`httpbin-gateway`)，一个[流量组](../../../refs/tsb/traffic/v2/traffic-group) (`httpbin-traffic`) 和一个[安全组](../../../refs/tsb/security/v2/security-group) (`httpbin-security`)。

## 注册 `httpbin` 应用程序

下一步可能需要根据使用情况进行或不进行，如果要创建 TSB 应用程序，则按照以下步骤操作。

首先，确保你已经创建了 `httpbin` 工作区。

在此工作区中创建一个应用程序。创建名为 `httpbin-application.yaml` 的文件，其中包含类似以下示例的内容。请确保将组织和租户名称替换为适当的值。

```
apiVersion: application.tsb.tetrate.io/v2
kind: Application
metadata:
  name: httpbin
  organization: <organization>
  tenant: <tenant>
spec:
  displayName: httpbin
  workspace: organizations/<organization>/tenants/<tenant>/workspaces/httpbin
  gatewayGroup: organizations/<organization>/tenants/<tenant>/workspaces/httpbin/gatewaygroups/httpbin-gateway
```

使用 `tctl` 应用清单：

```bash
tctl apply -f httpbin-application.yaml
```
