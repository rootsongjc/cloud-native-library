---
weight: 100
title: Sidecar
date: '2022-05-18T00:00:00+08:00'
type: book
---

默认情况下，注入的 sidecar 代理的配置方式是，它们接受所有端口的流量，并且在转发流量时可以到达网格中的任何服务。

在某些情况下，你可能想改变这种配置，配置代理，所以它只能使用特定的端口和访问某些服务。要做到这一点，你可以在 Istio 中使用 Sidecar 资源。

Sidecar 资源可以被部署到 Kubernetes 集群内的一个或多个命名空间，但如果没有定义工作负载选择器，每个命名空间只能有一个 sidecar 资源。

Sidecar 资源由三部分组成，一个工作负载选择器、一个入口（ingress）监听器和一个出口（egress）监听器。

## 工作负载选择器

工作负载选择器决定了哪些工作负载会受到 sidecar 配置的影响。你可以决定控制一个命名空间中的所有 sidecar，而不考虑工作负载，或者提供一个工作负载选择器，将配置只应用于特定的工作负载。

例如，这个 YAML 适用于默认命名空间内的所有代理，因为没有定义选择器。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Sidecar
metadata:
  name: default-sidecar
  namespace: default
spec:
  egress:
  - hosts:
    - "default/*"
    - "istio-system/*"
    - "staging/*"
```

在 egress 部分，我们指定代理可以访问运行在 `default`、`istio-system` 和 `staging` 命名空间的服务。要将资源仅应用于特定的工作负载，我们可以使用 `workloadSelector` 字段。例如，将选择器设置为 `version: v1 将只适用于有该标签设置的工作负载。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Sidecar
metadata:
  name: default-sidecar
  namespace: default
spec:
  workloadSelector:
    labels:
      version: v1
  egress:
  - hosts:
    - "default/*"
    - "istio-system/*"
    - "staging/*"
```

## 入口和出口监听器

资源的入口（ingress）监听器部分定义了哪些入站流量被接受。同样地，通过出口（egress）监听器，你可以定义出站流量的属性。

每个入口监听器都需要一个端口设置，以便接收流量（例如，下面的例子中的 3000）和一个默认的端点。默认端点可以是一个回环 IP 端点或 Unix 域套接字。端点配置了流量将被转发到哪里。

```yaml
...
  ingress:
  - port:
      number: 3000
      protocol: HTTP
      name: somename
    defaultEndpoint: 127.0.0.1:8080
...
```

上面的片段将入口监听器配置为在端口 3000 上监听，并将流量转发到服务监听的端口 8080 上的回环 IP。此外，我们可以设置 `bind` 字段，以指定一个 IP 地址或域套接字，我们希望代理监听传入的流量。最后，字段 `captureMode` 可以用来配置如何以及是否捕获流量。

出口监听器有类似的字段，但增加了`hosts` 字段。通过 `hosts` 字段，你可以用 `namespace/dnsName` 的格式指定服务主机。例如， `myservice.default` 或 `default/*`。在 `hosts` 字段中指定的服务可以是来自网格注册表的实际服务、外部服务（用 ServiceEntry 定义），或虚拟服务。

```yaml
  egress:
  - port:
      number: 8080
      protocol: HTTP
    hosts:
    - "staging/*"
```

通过上面的 YAML，sidecar 代理了运行在 `staging` 命名空间的服务的 8080 端口的流量。