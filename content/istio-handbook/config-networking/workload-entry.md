---
weight: 40
title: WorkloadEntry
date: '2022-05-18T00:00:00+08:00'
type: book
---

`WorkloadEntry` 使运维能够描述单个非 Kubernetes 工作负载的属性，如虚拟机或裸机服务器，以加入网格。`WorkloadEntry` 必须同时配置 Istio `ServiceEntry`，通过适当的标签选择工作负载，并提供 `MESH_INTERNAL` 服务的服务定义（主机名、端口属性等）。`ServiceEntry` 对象可以根据服务条目中指定的标签选择器来选择多个工作负载条目以及 Kubernetes pod。

当工作负载连接到 `istiod` 时，自定义资源中的状态字段将被更新，以表明工作负载的健康状况以及其他细节，类似于 Kubernetes 更新 pod 状态的方式。

## 示例

下面的例子声明了一个 WorkloadEntry 条目，代表 `details.bookinfo.com` 服务的一个虚拟机。这个虚拟机安装了 sidecar，并使用 `details-legacy` 服务账户进行引导。该服务通过 80 端口暴露给网格中的应用程序。通往该服务的 HTTP 流量被 Istio mTLS 封装，并被发送到目标端口 8080 的虚拟机上的 sidecar，后者又将其转发到同一端口的 localhost 上的应用程序。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadEntry
metadata:
  name: details-svc
spec:
  # 使用服务账户表明工作负载有一个用该服务账户引导的 sidecar 代理。有 sidecar 的 pod 会自动使用 istio mTLS 与工作负载通信。
  serviceAccount: details-legacy
  address: 2.2.2.2
  labels:
    app: details-legacy
    instance-id: vm1
```

与其相关的 ServiceEntry 如下。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: details-svc
spec:
  hosts:
  - details.bookinfo.com
  location: MESH_INTERNAL
  ports:
  - number: 80
    name: http
    protocol: HTTP
    targetPort: 8080
  resolution: STATIC
  workloadSelector:
    labels:
      app: details-legacy
```

下面的例子使用其完全限定的 DNS 名称声明了同一个虚拟机工作负载。ServiceEntry 的解析模式应改为 DNS，以表明客户端侧设备在转发请求之前应在运行时动态地解析 DNS 名称。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadEntry
metadata:
  name: details-svc
spec:
  # 使用服务账户表明工作负载有一个用该服务账户引导的 sidecar 代理。有 sidecar 的 pod 会自动使用 istio mTLS 与工作负载通信。
  serviceAccount: details-legacy
  address: vm1.vpc01.corp.net
  labels:
    app: details-legacy
    instance-id: vm1
```

与其相关的 ServiceEntry 如下。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: details-svc
spec:
  hosts:
  - details.bookinfo.com
  location: MESH_INTERNAL
  ports:
  - number: 80
    name: http
    protocol: HTTP
    targetPort: 8080
  resolution: DNS
  workloadSelector:
    labels:
      app: details-legacy
```

## 配置项

下图是 WorkloadEntry 资源的配置拓扑图。

{{< figure src="../../images/workloadentry.png" alt="WorkloadEntry"  caption="WorkloadEntry  资源配置拓扑图" width="50%">}}

WorkloadEntry 资源的顶级配置项如下：

- `address`：字符串类型。与网络端点相关的地址，不含端口。当且仅当解析被设置为 DNS 时，可以使用域名，并且必须是完全限定的，没有通配符。对于 Unix 域套接字端点，使用 `unix://absolute/path/to/socket` 格式。

- `ports`：与端点相关的端口集。如果指定了端口映射，必须是`servicePortName` 到这个端点的端口映射，这样，到服务端口的流量将被转发到映射到服务的 `portName` 的端点端口。如果省略，而目标端口被指定为服务的端口规范的一部分，那么到服务端口的流量将被转发到指定的目标端口上的一个端点。如果没有指定`targetPort`和端点的端口映射，到服务端口的流量将被转发到同一端口的端点上。

  注意1：不要用于`unix://`地址。

  注意2：端点的端口映射优先于 targetPort。

- `labels`：与端点相关的一或多个标签。

- `network`：字符串类型。`network` 使Istio能够将位于同一L3域/网络中的端点分组。同一网络中的所有端点都被认为是可以相互直连的。当不同网络中的端点不能直连时，可以使用Istio Gateway来建立连接（通常在Gateway服务器中使用`AUTO_PASSTHROUGH`模式）。这是一个高级配置，通常用于在多个集群上跨越Istio网格。

- `locality`：字符串类型。与端点相关的位置。`locality` 对应于一个故障域（例如，国家/地区/区域）。例如，在US的一个端点，在US-East-1地区，在可用区az-1内，在数据中心机架r11内，其位置可以表示为`us/us-east-1/az-1/r11`。Istio将配置sidecar，使其路由到与sidecar相同地域的端点。如果该地区的端点都不可用，将选择父地区的端点（但在同一网络ID内）。例如，如果有两个端点在同一个网络中（networkID `n1`），比如e1的位置是`us/us-east-1/az-1/r11`，e2的位置是`us/us-east-1/az-2/r12`，来自`us/us-east-1/az-1/r11`位置的sidecar会选择同一位置的e1而不是来自不同位置的e2。端点e2可以是与网关（连接网络n1和n2）相关的IP，或与标准服务端点相关的IP。

- `weight`：`unit32` 类型。与端点相关的负载均衡权重。权重较高的端点将按比例获得较高的流量。

- `serviceAccount`：字符串类型。如果工作负载中存在 sidecar，则为与工作负载相关的服务账户。该服务账户必须与配置（`WorkloadEntry` 或 `ServiceEntry`）存在于同一命名空间。

关于 WorkloadEntry 配置的详细用法请参考 [Istio 官方文档](https://istio.io/latest/docs/reference/config/networking/workload-entry/)。

## 参考

- [WorkloadEntry - istio.io](https://istio.io/latest/docs/reference/config/networking/workload-entry/)

