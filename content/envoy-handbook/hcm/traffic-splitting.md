---
weight: 5
title: 流量分割
date: '2022-05-18T00:00:00+08:00'
type: book
---

Envoy 支持在同一虚拟主机内将流量分割到不同的路由。我们可以在两个或多个上游集群之间分割流量。

有两种不同的方法。第一种是使用运行时对象中指定的百分比，第二种是使用加权集群。

## 使用运行时的百分比进行流量分割

使用运行时对象的百分比很适合于金丝雀发布或渐进式交付的场景。在这种情况下，我们想把流量从一个上游集群逐渐转移到另一个。

实现这一目标的方法是提供一个 `runtime_fraction` 配置。让我们用一个例子来解释使用运行时百分比的流量分割是如何进行的。

```yaml
route_config:
  virtual_hosts:
  - name: hello_vhost
    domains: ["hello.io"]
    routes:
      - match:
          prefix: "/"
          runtime_fraction:
            default_value:
              numerator: 90
              denominator: HUNDRED
        route:
          cluster: hello_v1
      - match:
          prefix: "/"
        route:
          cluster: hello_v2
```

上述配置声明了两个版本的 hello 服务：`hello_v1` 和 `hello_v2`。

在第一个匹配中，我们通过指定分子（`90`）和分母（`HUNDRED`）来配置 `runtime_fraction` 字段。Envoy 使用分子和分母来计算最终的分数值。在这种情况下，最终值是 90%（`90/100 = 0.9 = 90%`）。

Envoy 在 `[0，分母]` 范围内生成一个随机数（例如，在我们的案例中是 [0，100]）。如果随机数小于分子值，路由器就会匹配该路由，并将流量发送到我们案例中的集群 `hello_v1`。

如果随机数大于分子值，Envoy 继续评估其余的匹配条件。由于我们有第二条路由的精确前缀匹配，所以它是匹配的，Envoy 会将流量发送到集群 `hello_v2`。一旦我们把分子值设为 0，所有随机数会大于分子值。因此，所有流量都会流向第二条路由。

我们也可以在运行时键中设置分子值。例如：

```yaml
route_config:
  virtual_hosts:
  - name: hello_vhost
    domains: ["hello.io"]
    routes:
      - match:
          prefix: "/"
          runtime_fraction:
            default_value:
              numerator: 0
              denominator: HUNDRED
            runtime_key: routing.hello_io
        route:
          cluster: hello_v1
      - match:
          prefix: "/"
        route:
          cluster: hello_v2
...
layered_runtime:
  layers:
  - name: static_layer
    static_layer:
      routing.hello_io: 90
```

在这个例子中，我们指定了一个名为 `routing.hello_io` 的运行时键。我们可以在配置中的分层运行时字段下设置该键的值——这也可以从文件或通过运行时发现服务（RTDS）动态读取和更新。为了简单起见，我们在配置文件中直接设置。

当 Envoy 这次进行匹配时，它将看到提供了`runtime_key`，并将使用该值而不是分子值。有了运行时键，我们就不必在配置中硬编码这个值了，我们可以让 Envoy 从一个单独的文件或 RTDS 中读取它。

当你有两个集群时，使用运行时百分比的方法效果很好。但是，当你想把流量分到两个以上的集群，或者你正在运行 A/B 测试或多变量测试方案时，它就会变得复杂。

## 使用加权集群进行流量分割

当你在两个或多个版本的服务之间分割流量时，加权集群的方法是理想的。在这种方法中，我们为多个上游集群分配了不同的权重。而带运行时百分比的方法使用了许多路由，我们只需要为加权集群提供一条路由。

我们将在下一个模块中进一步讨论上游集群。为了解释用加权集群进行的流量分割，我们可以把上游集群看成是流量可以被发送到的终端的集合。

我们在路由内指定多个加权集群（`weighted_clusters`），而不是设置一个集群（`cluster）`。

继续前面的例子，我们可以这样重写配置，以代替使用加权集群。

```yaml
route_config:
  virtual_hosts:
  - name: hello_vhost
    domains: ["hello.io"]
    routes:
      - match:
          prefix: "/"
        route:
          weighted_clusters:
            clusters:
              - name: hello_v1
                weight: 90
              - name: hello_v2
                weight: 10
```

在加权的集群下，我们也可以设置 `runtime_key_prefix`，它将从运行时密钥配置中读取权重。注意，如果运行时密钥配置不在那里，Envoy 会使用每个集群旁边的权重。

```yaml
route_config:
  virtual_hosts:
  - name: hello_vhost
    domains: ["hello.io"]
    routes:
      - match:
          prefix: "/"
        route:
          weighted_clusters:
            runtime_key_prefix: routing.hello_io
            clusters:
              - name: hello_v1
                weight: 90
              - name: hello_v2
                weight: 10
...
layered_runtime:
  layers:
  - name: static_layer
    static_layer:
      routing.hello_io.hello_v1: 90
      routing.hello_io.hello_v2: 10
```

权重代表 Envoy 发送给上游集群的流量的百分比。所有权重的总和必须是 100。然而，使用 `total_weight` 字段，我们可以控制所有权重之和必须等于的值。例如，下面的片段将 `total_weight` 设置为 15。

```yaml
route_config:
  virtual_hosts:
  - name: hello_vhost
    domains: ["hello.io"]
    routes:
      - match:
          prefix: "/"
        route:
          weighted_clusters:
            runtime_key_prefix: routing.hello_io
            total_weight: 15
            clusters:
              - name: hello_v1
                weight: 5
              - name: hello_v2
                weight: 5
              - name: hello_v3
                weight: 5
```

为了动态地控制权重，我们可以设置 `runtime_key_prefix`。路由器使用运行时密钥前缀值来构建与每个集群相关的运行时密钥。如果我们提供了运行时密钥前缀，路由器将检查 `runtime_key_prefix + "." + cluster_name` 的值，其中 `cluster_name` 表示集群数组中的条目（例如 `hello_v1`、`hello_v2`）。如果 Envoy 没有找到运行时密钥，它将使用配置中指定的值作为默认值。