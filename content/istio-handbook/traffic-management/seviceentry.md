---
weight: 90
title: ServiceEntry
date: '2022-05-18T00:00:00+08:00'
type: book
---

通过 ServiceEntry 资源，我们可以向 Istio 的内部服务注册表添加额外的条目，并使不属于我们网格的外部服务或内部服务看起来像是我们服务网格的一部分。

当一个服务在服务注册表中时，我们就可以使用流量路由、故障注入和其他网格功能，就像我们对其他服务一样。

下面是一个 ServiceEntry 资源的例子，它声明了一个可以通过 HTTPS 访问的外部 API（`api.external-svc.com`）。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: external-svc
spec:
  hosts:
    - api.external-svc.com
  ports:
    - number: 443
      name: https
      protocol: TLS
  resolution: DNS
  location: MESH_EXTERNAL
```

`hosts` 字段可以包含多个外部 API，在这种情况下，Envoy sidecar 会根据下面的层次结构来进行检查。如果任何一项不能被检查，Envoy 就会转到层次结构中的下一项。

- HTTP Authority 头（在HTTP/2中）和 Host 头（HTTP/1.1中）
- SNI
- IP 地址和端口

如果上述数值都无法检查，Envoy 会根据 Istio 的安装配置，盲目地转发请求或放弃该请求。

与 WorkloadEntry 资源一起，我们可以处理虚拟机工作负载向 Kubernetes 迁移的问题。在 WorkloadEntry 中，我们可以指定在虚拟机上运行的工作负载的细节（名称、地址、标签），然后使用 ServiceEntry 中的 `workloadSelector` 字段，使虚拟机成为 Istio 内部服务注册表的一部分。

例如，假设 `customers` 的工作负载正在两个虚拟机上运行。此外，我们已经有在 Kubernetes 中运行的 Pod，其标签为 `app: customers`。

让我们这样来定义 WorkloadEntry 资源：

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadEntry
metadata:
  name: customers-vm-1
spec:
  serviceAccount: customers
  address: 1.0.0.0
  labels:
    app: customers
    instance-id: vm1
---
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadEntry
metadata:
  name: customers-vm-2
spec:
  serviceAccount: customers
  address: 2.0.0.0
  labels:
    app: customers
    instance-id: vm2
```

现在我们可以创建一个 ServiceEntry 资源，该资源同时跨越 Kubernetes 中运行的工作负载和虚拟机：

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: customers-svc
spec:
  hosts:
  - customers.com
  location: MESH_INTERNAL
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: STATIC
  workloadSelector:
    labels:
      app: customers
```

在位置字段中设置 `MESH_INTERNAL`，我们是说这个服务是网格的一部分。这个值通常用于包括未管理的基础设施（VM）上的工作负载的情况。这个字段的另一个值，`MESH_EXTERNAL`，用于通过 API 消费的外部服务。`MESH_INTERNAL` 和 `MESH_EXTERNAL` 设置控制了网格中的 sidecar 如何尝试与工作负载进行通信，包括它们是否会默认使用 Istio 双向 TLS。