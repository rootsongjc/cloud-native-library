---
title: 分布式跟踪集成
description: "了解如何将你的跟踪生态系统与 TSB 集成。"
weight: 5
---

{{<callout warning "需要基本的分布式跟踪知识">}}
本文假设读者具有基本的分布式跟踪概念和名词的知识。如果对分布式跟踪不熟悉，建议在阅读本文和调整 TSB 的分布式跟踪配置之前，首先了解分布式跟踪。关于分布式跟踪概念的很好的介绍，请阅读 Nic Munroe 的[优秀博客](https://medium.com/nikeengineering/hit-the-ground-running-with-distributed-tracing-core-concepts-ff5ad47c7058)。
{{</callout>}}

{{<callout note "所需的服务行为">}}
分布式跟踪不会自动工作，因为重要的是你的部署服务传播跟踪上下文。如果不在服务中启用上下文传播，你将遇到跟踪中断问题，并且在跟踪中看到大大降低的价值。我们建议至少支持传播 B3 和 W3C 跟踪上下文头，以及`x-request-id`以进行请求关联。另请参阅 Istio 文档中的[跟踪上下文传播解释](https://istio.io/v1.17/docs/tasks/observability/distributed-tracing/overview/#trace-context-propagation)。除了上下文传播，将`x-request-id`（以及分布式跟踪的`trace id`，如果有的话）包含在服务的所有请求绑定日志行中是一个很好的主意。这样可以在请求跟踪和服务日志之间实现几乎无需努力的关联，并加速故障排除。
{{</callout>}}

默认情况下，TSB 提供了一个基于[SkyWalking](https://skywalking.apache.org/)的分布式跟踪后端，与[Zipkin](https://zipkin.io/)兼容。在 TSB 控制下的所有[Envoy](https://www.envoyproxy.io/)入口网关和 sidecar 都具有其内部 Zipkin 跟踪仪器，用于将跨度数据直接发送到 TSB 的 SkyWalking 收集器。还可以通过 TSB 的[ControlPlane 资源对象](../../../../refs/install/controlplane/v1alpha1/spec)配置固定的全局采样率。

如果需要更灵活地设置更精细的采样率、使用不同的跟踪仪器或将跨度数据发送到不同的后端，本文将为你提供所需的上下文信息以进行必要的更改。

## Istio Telemetry API
Istio Telemetry API 通过使用作用域限定的`Telemetry`对象在运行时提供了调整可观测性信号的精细和灵活的方法。在 Istio Telemetry API 之前，需要调整 TSB 控制平面和数据平面运算符配置对象来配置具有固定采样率的单个分布式跟踪器。

通过 TSB 控制平面运算符配置对象启用 Istio Telemetry API 的跟踪[扩展提供程序](https://istio.io/v1.17/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider)后，可以使用 Istio Telemetry 对象为不同的命名空间设置具有不同采样率的特定跟踪器。

{{<callout note "Telemetry API 功能状态">}}
虽然 Telemetry API 自 Istio 1.12 以来一直存在，但它仍被标记为 alpha 状态。这主要是因为具有许多跟踪、度量和日志的潜在边缘配置的能力。我们已经测试和验证了针对 Zipkin、OpenCensus 和 OpenTelemetry 跟踪提供程序的集群级别跟踪配置在功能上是有效的，但不保证超出这一范围的配置用例的成功使用。Istio 不会在没有使用 Telemetry API 的情况下提供原生 OpenTelemetry 支持。
{{</callout>}}

有关 Istio Telemetry API 的更多信息，请参阅[Istio Telemetry API](https://istio.io/v1.17/docs/tasks/observability/telemetry/)。

## W3C 跟踪上下文传播
默认情况下，通过 Envoy 的本地 Zipkin 跟踪仪器，TSB 使用了众所周知的`B3`跟踪上下文传播方法。`B3`是一种针对各种分布式跟踪生态系统都非常好支持的传播方法，因为它一直是许多早期采用分布式跟踪的站点所有者的事实标准（例如 Netflix）。

{{<callout note "为什么叫 B3？">}}
Zipkin 生态系统起源于 Twitter，那里的大多数服务都有鸟的名称。Zipkin 的后端内部项目名称是 Big Brother Bird。当 Zipkin 生态系统开源时，`B3`跟踪上下文头保持不变。
{{</callout>}}

在 2019 年的一个分布式跟踪研讨会上，由 Zipkin 开源社区主持，邀请了来自不同组织的几位工程师汇聚在一起，以找出一种新的上下文传播方法，使跟踪系统能够互操作，即使其中一些系统具有不同的（可选）元数据要求（特别是来自 Microsoft、AWS 和 DynaTrace 的项目）。这个想法是在一个

标题为`traceparent`的标题中具有所有系统都理解的公共基本上下文，另一个标题（`tracestate`）可以包含来自不同跟踪供应商的多个元数据块。如果理解特定的元数据块，它可以进行交互。跟踪器可以添加自己的元数据，但需要传播其他跟踪供应商的元数据，直到标题值的最大大小。然后以 FIFO 方式清除元数据块。

为了更有力地支持新提出的解决方案，该工作被提交给了 W3C，因此这个传播格式被称为`W3C跟踪上下文`。当 OpenTelemetry 通过 CNCF 指定合并 Google 的 OpenCensus 项目（当时使用`B3`进行传播）和供应商联盟支持的 OpenTracing（对于跟踪上下文传播根本没有任何保证，每个供应商都使用自己的传播方法）而出现时，决定将默认从`B3`切换到`W3C跟踪上下文`。然而，大多数 OpenTelemetry 仪器在进行小的配置更改后仍支持`B3`。

从`B3`上下文传播切换到 TSB 环境中的`W3C跟踪上下文`可以通过更改活动的 Envoy 跟踪实现。对于 TSB 1.6 集群，唯一的选择是`OpenCensus`。建议不要继续使用此跟踪器，因为 OpenCensus 已被弃用并不再维护。未来版本的 Envoy Proxy 和 OpenTelemetry 收集器也很有可能删除该跟踪器。当升级到 TSB 1.7 及更高版本时，建议切换到`OpenTelemetry`跟踪器。

## 用于跟踪的 OpenTelemetry Collector
OpenTelemetry Collector 是跨度数据管理的“瑞士军刀”。它可以接收来自不同跟踪仪器的不同格式的跨度数据，并将这些数据导出到多个后端，可能使用不同的跨度数据格式。在本文中，我们将展示如何使用 OpenTelemetry Collector 接收来自传入 Zipkin、OpenCensus 和 OpenTelemetry 跟踪仪器的跨度数据，以导出到与 OpenTelemetry 兼容的后端以及 TSB 的嵌入式跟踪后端。

## 启用 TSB 中的跟踪的 Telemetry API
要根据本文所述的跟踪配置更改 TSB 的跟踪配置，首先需要在 TSB 中启用 Istio Telemetry API 的跟踪扩展提供程序。为此，你需要调整环境中每个群集的 TSB [ControlPlane](../../../refs/install/controlplane/v1alpha1/spec)资源对象。

TSB 运算符使用其`ControlPlane`资源对象来管理其 Istio 依赖的配置和部署。当应用 TSB ControlPlane 对象时，TSB 运算符将创建一个[IstioOperator](https://istio.io/v1.17/docs/reference/config/istio.operator.v1alpha1/)资源对象。然后使用此生成的`IstioOperator`资源对象通过 TSB`ControlPlane`对象使用`overlay`来进行（重新）配置 Istio 部署。要启用跟踪，需要通过 TSB`ControlPlane`对象为`IstioOperator`对象添加一个补丁。

### TSB ControlPlane 资源对象覆盖
为了确保不覆盖在`ControlPlane`对象中找到的重要自定义配置，首先需要下载当前状态。需要为要调整的每个群集重复以下步骤。

通过运行以下命令获取 ControlPlane 资源对象：

```bash
kubectl get -n istio-system controlplane controlplane \
  -o yaml > controlplane.yaml
```

{{<callout note "集群名称">}}
记下在`managementPlane`部分中找到的`clusterName`的值。在配置 Istio`Telemetry`对象时将需要此值。
{{</callout>}}

通过添加用于`IstioOperator`对象的补丁来编辑 ControlPlane 对象，如下所示：

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  ...
spec:
  components:
    ...
    istio:
      kubeSpec:
        # 开始覆盖
        overlays:
          - apiVersion: install.istio.io/v1alpha1
            kind: IstioOperator
            name: tsb-istiocontrolplane
            patches:
              - path: spec.meshConfig.extensionProviders
                value:
                # 在此处列出多个跟踪配置！
                # 它们可以是不同的跟踪器，也可以是相同跟踪仪器的不同配置
                  - name: <tracing-config-name>
                  <extensionProvider>
                    service: <ip_or_host>
                    port: <port_number>
              # 可选的默认扩展提供程序补丁；不是必需的
              # 警告：这将注入跟踪头，即使对于特定命名空间禁用了跟踪也是如此。确保这是所需的副作用。
              - path: spec.meshConfig.defaultProviders.tracing
                value:
                  tracing:
                  # 即使这是一个列表，也只支持一个默认跟踪器！
                   - <tracing-config-name>
        # 结束覆盖
        deployment:
          ...
```

要安装已调整的 ControlPlane 资源对象：

```bash
kubectl apply -f controlplane.yaml
```

以下是翻译：

补丁的必需部分是为[spec.meshConfig.extensionProviders](https://istio.io/v1.17/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider)配置类型提供一个或多个跟踪配置。设置一个补丁用于`spec.meshConfig.defaultProviders.tracing`的配置会产生副作用，即使你的 Telemetry API 配置没有为传入请求明确设置跟踪配置，所有请求流量都将使用默认跟踪配置仪器的跟踪头进行增强。我们的建议是不要将默认配置作为补丁设置，而是依赖于你的 Telemetry API 资源对象，除非你在日志中使用跟踪 ID 进行请求关联，即使分布式跟踪被禁用也是如此。

以下是一个灵活的设置配置的示例，其中包含多个跟踪配置，允许同时使用 `B3` 和 `W3C trace-context` 跟踪器，并具有将数据发送到 TSB、外部 Jaeger 跟踪后端或两者的能力。

{{<callout note "多个跟踪后端">}}
请注意，可以多次添加相同的跟踪器类型，但每个跟踪器类型可以具有不同的端点配置。这对于指定一个用于故障排除目的的跟踪后端或为应用团队提供自己的设置非常方便。
{{</callout>}}

{{<callout note "Jaeger 后端的原生 Zipkin 和 OpenTelemetry 支持">}}
可以通过以下命令行参数 `--collector.zipkin.host-port=:9411` 激活 Jaeger 的 Zipkin 支持。在下面的示例中，这是必需的，因为它启用了 "jaeger-b3" 跟踪配置，以直接将数据发送到 Jaeger，而无需在中间使用 OpenTelemetry 收集器。<br />
Jaeger 版本 v1.35 及更高版本具有对 OpenTelemetry 的 OTLP 传输的原生支持，较早版本需要在其中使用 OpenTelemetry 收集器。在下面的示例中，假定支持 OTLP，因为它启用了 "jaeger-w3c" 跟踪配置，以直接将数据发送到 Jaeger，而无需在中间使用 OpenTelemetry 收集器。
{{</callout>}}

```yaml
patches:
  - path: spec.meshConfig.extensionProviders
    value:
      - name: tsb-b3 # 发送到 TSB 后端的 Zipkin 跟踪器
        zipkin:
          service: "zipkin.istio-system.svc.cluster.local"
          port: 9411
      - name: jaeger-b3 # 发送到 Jaeger 后端的 Zipkin 跟踪器
        zipkin:
          service: "jaeger-collector.default.svc.cluster.local"
          port: 9411
      - name: jaeger-w3c # 发送到 Jaeger 后端的 OTel 跟踪器
        opentelemetry:
          service: "jaeger-collector.default.svc.cluster.local"
          port: 4317
      - name: both-b3 # 发送到 OTel 收集器的 Zipkin 跟踪器
        zipkin:
          service: "otel-collector.default.svc.cluster.local"
          port: 9411
      - name: both-w3c # 发送到 OTel 收集器的 OTel 跟踪器
        opentelemetry:
          service: "otel-collector.default.svc.cluster.local"
          port: 4317
```

{{<callout note "检查 TSB 运算符日志">}}
由于在处理覆盖和编辑的资源对象时很容易出错，通常情况下，如果 yaml 语法正确，资源对象通常不会被拒绝，因此建议在应用资源对象时尾随 TSB 运算符的日志以检查是否成功处理覆盖。如果看到应用错误，很可能是在补丁中犯了拼写错误或应用了不正确的缩进。
{{</callout>}}

要尾随 TSB 运算符日志以检查覆盖是否成功处理，请运行以下命令：

```bash
kubectl logs -n istio-system -l name=tsb-operator -f
```

### 设置用于跟踪的 OpenTelemetry 收集器
在上面的扩展提供程序配置示例中，假定将跨度数据发送到 OpenTelemetry 收集器会导致此收集器将数据发送到 OTLP 兼容的 Jaeger 后端，以及 TSB 的期望 Zipkin 数据的 SkyWalking 收集器。默认的 OpenTelemetry 收集器支持 OTLP 和 Zipkin 接收器和导出器。

{{<callout note "供应商特定的 OpenTelemetry 发行版">}}
如果使用供应商特定的 OpenTelemetry 收集器（例如 Splunk OpenTelemetry 分发），则通常会广泛支持接收器，但对导出器的支持非常有限（通常只有 OTLP 和本机供应商导出器）。在这些情况下，你需要创建自己的 OpenTelemetry 分发，以支持供应商的导出器以及 Zipkin 导出器，如果需要将跨度数据反馈到 TSB。如果可用 OTLP 导出，则可以使用串联的 OpenTelemetry 收集器解决方案，尽管效率较低。
{{</callout>}}

如果要设置一个 OpenTelemetry 收集器以支持此处呈现的用例，helm chart values 对象可能如下所示：

{{<callout warning "演示配置">}}
这不是生产就绪的 OpenTelemetry 配置。
{{</callout>}}

```yaml
mode: deployment
fullnameOverride: otel-collector # 这将设置为 otel 服务名称，默认情况下非常详细


replicaCount: 1
config:
  extensions:
    health_check: {}
  processors:
    batch: {}
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: ${env:MY_POD_IP}:4317
        http:
          endpoint: ${env:MY_POD_IP}:4318
    zipkin:
      endpoint: ${env:MY_POD_IP}:9411
  exporters:
    zipkin/tsb:
      endpoint: http://zipkin.istio-system.svc:9411/api/v2/spans
    otlp/jaeger:
      endpoint: jaeger-collector.default.svc:4317
      tls:
        insecure: true
  service:
    extensions:
      - health_check
    pipelines:
      traces:
        receivers:
          - otlp
          - zipkin
        processors:
          - batch
        exporters:
          - zipkin/tsb
          - otlp/jaeger

```

通过 helm 安装 OpenTelemetry 收集器，命令如下：

```bash
helm install otel-trace open-telemetry/opentelemetry-collector \
  --values otel-collector-values.yaml
```

### 设置 Jaeger 后端
在这个示例中，我们假设有一个 Jaeger 后端可用。以下是使用 Jaeger 运算符部署 Jaeger 的演示配置。

安装 Jaeger 运算符：

```bash
kubectl create namespace observability
kubectl create -n observability -f \
    https://github.com/jaegertracing/jaeger-operator/releases/download/v1.49.0/jaeger-operator.yaml
```

{{<callout warning "演示配置">}}
这不是生产就绪的 Jaeger 配置。
{{</callout>}}

成功安装 Jaeger 运算符后，你可以创建所需的 Jaeger 部署配置。在此示例中，我们将使用内存存储的演示全合一镜像，并启用 Jaeger 的 Zipkin 收集器。

```yaml
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: jaeger
  namespace: default
spec:
  strategy: allInOne
  allInOne:
    options:
      collector:
        zipkin:
          host-port: ":9411"
```

应用 Jaeger 对象以配置和部署 Jaeger All-in-one 解决方案：

```bash
kubectl apply -f jaeger.yaml
```

应用对象后，你应该在默认命名空间中看到 jaeger 实例正在部署：

```bash
kubectl get pods -l app.kubernetes.io/instance=jaeger
```

默认情况下，Jaeger 运算符会为你创建一个用于访问 UI 的入口路由。你可以通过执行以下命令检索地址信息：

```bash
kubectl get ingress
```

{{<callout warning "未受保护的 UI 访问">}}
Jaeger 的默认入口创建行为相当不安全。如果对此行为感到不舒服，请调整 Jaeger 配置。有关 Jaeger 配置的更多信息，请参阅[Jaeger 运算符文档](https://www.jaegertracing.io/docs/1.49/operator)。
{{</callout>}}

## 使用 Telemetry API
通过启用扩展提供程序，我们已经将传统的 Zipkin 仪器静音。TSB 不会跟踪未通过 Istio Telemetry API 指定所需行为的请求。

{{<callout warning "仅允许一个全局遥测对象">}}
Istio Telemetry API 规范规定，只能为根命名空间 `istio-system` 应用一个全局范围的 Telemetry 对象。某些版本的 TSB v1.7.x 在安装/升级过程中会自动创建一个名为 `xcp-mesh-default` 的全局 Telemetry 对象，用于处理所使用的 Istio 部署的改进全局度量配置。在 TSB v1.8 及更高版本中，不再创建或使用此全局 Telemetry 对象。如果在此对象中添加了自己的全局 Telemetry 配置，则可以继续使用它。还允许删除此对象并创建一个具有你选择的对象名称和内容的新对象。
{{</callout>}}

要启用使用先前注册的 "both-b3" 跟踪配置的全网默认设置，你可以创建一个新的全局 Telemetry 对象，如下所示。

```yaml
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  tracing:
  - providers:
    - name: "both-b3" # 在此处使用扩展提供程序跟踪配置之一
    customTags:
      cluster:
        literal:
          value: "app-cluster-1" # 在此处使用 TSB clusterName！
      tracer: # 最好添加一个跟踪器标签，以突出显示使用的配置
        literal:
          value: "both-b3"
    randomSamplingPercentage: 100.0 # 在此处使用所需的采样率
```

```bash
kubectl apply -f mesh-default.yaml
```

通过切换跟踪提供程序配置名称，你可以在 B3 和 W3C 上下文传播之间切换，以及直接发送到 TSB、直接发送到 Jaeger，或用于同时馈送 TSB 和 Jaeger 的 OpenTelemetry 收集器。

有关更多信息和示例，请参阅[Istio Telemetry API 文档](https://istio.io/v1.17/docs/tasks/observability/telemetry/)。