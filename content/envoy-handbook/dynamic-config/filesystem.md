---
weight: 20
title: 来自文件系统的动态配置
date: '2022-05-18T00:00:00+08:00'
type: book
---

动态提供配置另一种方式是通过指向文件系统上的文件。为了使动态配置发挥作用，我们需要在 `node` 字段下提供信息。如果我们可能有多个 Envoy 代理指向相同的配置文件，那么 `node` 字段是用来识别一个特定的 Envoy 实例。

![](../../images/008i3skNly1gz9lmh814jj31ha0u00ur.jpg "动态配置")

为了指向动态资源，我们可以使用 `dynamic_resources` 字段来告诉 Envoy 在哪里可以找到特定资源的动态配置。例如：

```yaml
node:
  cluster: my-cluster
  id: some-id

dynamic_resources:
  lds_config:
    path: /etc/envoy/lds.yaml
  cds_config:
    path: /etc/envoy/cds.yaml
```

上面的片段是一个有效的 Envoy 配置。如果我们把 LDS 和 CDS 作为静态资源来提供，它们的单独配置将非常相似。唯一不同的是，我们必须指定资源类型和版本信息。下面是 CDS 配置的一个片段。

```yaml
version_info: "0"
resources:
- "@type": type.googleapis.com/envoy.config.cluster.v3.Cluster
  name: instance_1
  connect_timeout: 5s
  load_assignment:
    cluster_name: instance_1
    endpoints:
    - lb_endpoints:
      - endpoint:
          address:
            socket_address:
              address: 127.0.0.1
              port_value: 3030
```

如果我们想使用 EDS 为集群提供端点，我们可以这样写上面的配置。

```yaml
version_info: "0"
resources:
- "@type": type.googleapis.com/envoy.config.cluster.v3.Cluster
  name: instance_1
  type: EDS
  eds_cluster_config:
    eds_config:
      path: /etc/envoy/eds.yaml
```

另外，注意我们已经把集群的类型设置为 `EDS`。EDS 的配置会是这样的。

```yaml
version_info: "0"
resources:
- "@type": type.googleapis.com/envoy.config.endpoint.v3.ClusterLoadAssignment
  cluster_name: instance_1
  endpoints:
  - lb_endpoints:
    - endpoint:
        address:
          socket_address:
            address: 127.0.0.1
            port_value: 3030
```

当任何一个文件被更新时，Envoy 会自动重新加载配置。如果配置无效，Envoy 会输出错误，但会保持现有（工作）配置的运行。