---
weight: 10
title: Telemetry API
date: '2022-05-18T00:00:00+08:00'
type: book
---

Istio 1.11 引入了 [Telemetry API](https://istio.io/latest/docs/tasks/observability/telemetry/)，并在 1.13 中进行了完善。使用该 API，你可以一站式的灵活地配置[指标](https://istio.io/latest/docs/tasks/observability/metrics/)、[访问日志](https://istio.io/latest/docs/tasks/observability/logs/)和[追踪](https://istio.io/latest/docs/tasks/observability/distributed-tracing/)。

## 使用 API

下面将向你介绍如何使用 Telemetry API。

### 范围、继承和重写

Telemetry API 资源从 Istio 配置中继承的顺序：

1. 根配置命名空间（例如：`istio-system`）
2. 本地命名空间（命名空间范围内的资源，没有工作负载 `selector`）
3. 工作负载（具有工作负载 `selector` 的命名空间范围的资源）

根配置命名空间（通常是 `istio-system`）中的 Telemetry API 资源提供网格范围内的默认行为。根配置命名空间中的任何特定工作负载选择器将被忽略 / 拒绝。在根配置命名空间中定义多个网格范围的 Telemetry API 资源是无效的。

要想在某个特定的命名空间内覆盖网格范围的配置，可以通过在该命名空间中应用新的 Telemetry 资源（无需工作负载选择器）来实现。命名空间配置中指定的任何字段将完全覆盖父配置（根配置命名空间）中的字段。

要想覆盖特定工作负载的遥测配置，可以在其命名空间中应用带有工作负载选择器的新的 Telemetry 资源来实现。

### 工作负载选择

命名空间内的单个工作负载是通过 `selector` 选择的，该选择器允许基于标签选择工作负载。

让两个不同的 Telemetry 资源使用 `selector` 选择同一个工作负载是无效的。同样，在一个命名空间中有两个不同的 Telemetry 资源而没有指定 `selector` 也是无效的。

### 提供者选择

Telemetry API 使用提供者（Provider）的概念来表示要使用的协议或集成类型。提供者可以在 [`MeshConfig`](https://istio.io/latest/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider) 中进行配置。

下面是一个 MeshConfig 中配置提供者的例子。

```yaml
data:
  mesh: |-
      extensionProviders: # The following content defines two example tracing providers.
      - name: "localtrace"
        zipkin:
          service: "zipkin.istio-system.svc.cluster.local"
          port: 9411
          maxTagLength: 56
      - name: "cloudtrace"
        stackdriver:
          maxTagLength: 256
```

为方便起见，Istio 在开箱时就配置了一些默认设置的提供者。

| 提供者名称    | 功能                 |
| ------------- | -------------------- |
| `prometheus`  | 指标                 |
| `stackdriver` | 指标、追踪、日志记录 |
| `envoy`       | 日志记录             |

此外，还可以设置一个默认的提供者，当 Telemetry 资源没有指定提供者时使用。

## 示例

Telemetry API 资源继承自网格的根配置命名空间，通常是 `istio-system`。要配置整个网格的行为，在根配置命名空间中添加一个新的（或编辑现有的）Telemetry 资源。

下面是一个使用上一节中提供者配置的例子。

```yaml
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  tracing:
  - providers:
    - name: localtrace
    customTags:
      foo:
        literal:
          value: bar
    randomSamplingPercentage: 100
```

这个配置覆盖了 `MeshConfig` 的默认提供者，将 Mesh 默认设置为 `localtrace` 提供者。它还设置了 Mesh 范围内的采样百分比为 100，并配置了一个标签，将其添加到所有追踪跨度中，名称为 `foo`，值为 `bar`。

### 配置命名空间范围内的跟踪行为

要为单个命名空间定制行为，请为所需的命名空间添加 Telemetry 资源。在命名空间资源中指定的任何字段将完全覆盖从配置层次中继承的字段配置。

例如：

```yaml
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: namespace-override
  namespace: myapp
spec:
  tracing:
  - customTags:
      userId:
        header:
          name: userId
          defaultValue: unknown
```

当部署到一个具有先前 Mesh 范围范例配置的 Mesh 中时，这将导致 myapp 命名空间中的追踪行为，将追踪跨度发送到 localtrace 提供者，并以 100% 的速率随机选择请求进行追踪，但为每个跨度设置自定义标签，名称为 `userId`，其值取自 `userId` 请求头。重要的是，来自父配置的 `foo: bar` 标签将不会在 myapp 命名空间中使用。自定义标签的行为完全覆盖了 `mesh-default.istio-system` 资源中配置的行为。

注意：Telemetry 资源中的任何配置都会完全覆盖配置层次中其父资源的配置。这包括提供者的选择。

### 配置针对工作负载的行为

要为个别工作负载定制行为，请将遥测资源添加到所需的命名空间并使用 `selector`。工作负载特定资源中指定的任何字段将完全覆盖配置层次中的继承字段配置。

例如：

```yaml
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: workload-override
  namespace: myapp
spec:
  selector:
    matchLabels:
      service.istio.io/canonical-name: frontend
  tracing:
  - disableSpanReporting: true
```

在这个例子中，对于 `myapp` 命名空间中的 `frontend` 工作负载，追踪功能将被禁用。Istio 仍将转发追踪头信息，但不会向配置的追踪提供者报告任何跨度。

注意：让两个带有工作负载选择器的 Telemetry 资源选择相同的工作负载是无效的。此时，行为是未定义的。

## 参考

- [Telemetry API - istio.io](https://istio.io/latest/docs/tasks/observability/telemetry/)
- [Telemetry configuration - istio.io](https://istio.io/latest/docs/reference/config/telemetry/)