---
weight: 1
linkTitle: 概览
title: 分析和渐进式交付
date: '2023-06-21T16:00:00+08:00'
type: book
---

Argo Rollouts 提供了多种形式的分析方法来驱动渐进式交付。本文档描述了如何实现不同形式的渐进式交付，包括分析执行的时间点、频率和发生次数。

## 自定义资源定义

| CRD                     | 描述                                                         |
| ----------------------- | ------------------------------------------------------------ |
| Rollout                 | Rollout 作为 Deployment 资源的替代品，提供了额外的蓝绿和金丝雀更新策略。这些策略可以在更新过程中创建 AnalysisRuns 和 Experiments，这些 AnalysisRuns 和 Experiments 可以推进更新，或者中止更新。 |
| AnalysisTemplate        | AnalysisTemplate 是一个模板规范，定义了如何执行金丝雀分析，例如应该执行的指标、其频率以及被视为成功或失败的值。AnalysisTemplates 可以使用输入值进行参数化。 |
| ClusterAnalysisTemplate | ClusterAnalysisTemplate 类似于 AnalysisTemplate，但它不限于其命名空间。它可以被任何 Rollout 在整个集群中使用。 |
| AnalysisRun             | AnalysisRun 是 AnalysisTemplate 的一个实例化。AnalysisRuns 类似于 Job，它们最终会完成。完成的运行被认为是成功、失败或不确定的，该运行的结果影响 Rollout 的更新是否继续、中止或暂停。 |
| Experiment              | Experiment 是用于分析目的的一个或多个 ReplicaSets 的有限运行。实验通常运行一段预定的时间，但也可以一直运行直到停止。实验可以引用一个 AnalysisTemplate，在实验期间或之后运行。实验的典型用例是并行启动基线和金丝雀部署，并比较基线和金丝雀 pod 产生的指标以进行相等的比较。 |

## 背景分析

可以在金丝雀通过其滚动更新步骤时运行分析。

下面的示例每 10 分钟逐渐增加金丝雀权重 20%，直到达到 100%。在后台，基于名为 `success-rate` 的 `AnalysisTemplate` 启动了 `AnalysisRun`。`success-rate` 模板查询 Prometheus 服务器，在 5 分钟的间隔/采样内测量 HTTP 成功率。它没有结束时间，并且会一直持续直到停止或失败。如果度量小于 95%，并且有三个这样的度量，那么分析将被视为失败。失败的分析会导致 Rollout 中止，将金丝雀权重设置回零，Rollout 将被视为 `Degraded`。否则，如果滚动更新完成了所有的金丝雀步骤，则滚动更新将被视为成功，控制器会停止分析运行。

这个例子强调了：

- 背景分析风格的渐进式交付
- 使用 Prometheus 查询执行测量
- 能够将分析参数化
- 推迟分析运行的启动时间，直到第三步（设置重量为 40%）

Rollout

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: guestbook
spec:
...
  strategy:
    canary:
      analysis:
        templates:
        - templateName: success-rate
        startingStep: 2 # delay starting analysis run until setWeight: 40%
        args:
        - name: service-name
          value: guestbook-svc.default.svc.cluster.local
      steps:
      - setWeight: 20
      - pause: {duration: 10m}
      - setWeight: 40
      - pause: {duration: 10m}
      - setWeight: 60
      - pause: {duration: 10m}
      - setWeight: 80
      - pause: {duration: 10m}
```

AnalysisTemplate

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
spec:
  args:
  - name: service-name
  metrics:
  - name: success-rate
    interval: 5m
    # 注意：Prometheus 查询以向量形式返回结果。因此，通常访问返回的数组的索引 0 以获取值
    successCondition: result[0] >= 0.95
    failureLimit: 3
    provider:
      prometheus:
        address: <http://prometheus.example.com:9090>
        query: |
          sum(irate(
            istio_requests_total{reporter="source",destination_service=~"{{args.service-name}}",response_code!~"5.*"}[5m]
          )) /
          sum(irate(
            istio_requests_total{reporter="source",destination_service=~"{{args.service-name}}"}[5m]
          ))
```

## 内联分析

分析也可以作为一个内联的“分析”步骤作为部署步骤来执行。当分析被执行时，“内联”，会在到达该步骤时启动一个 `AnalysisRun`，并阻塞部署，直到运行完成。分析运行的成功或失败决定了部署是否继续到下一步，或者完全中止。

该示例将金丝雀权重设置为 20%，暂停 5 分钟，然后运行分析。如果分析成功，则继续进行部署，否则中止。

这个例子演示了：

- 作为步骤的一部分调用分析的能力

  ```yaml
  apiVersion: argoproj.io/v1alpha1
  kind: Rollout
  metadata:
    name: guestbook
  spec:
  ...
    strategy:
      canary:
        steps:
        - setWeight: 20
        - pause: {duration: 5m}
        - analysis:
            templates:
            - templateName: success-rate
            args:
            - name: service-name
              value: guestbook-svc.default.svc.cluster.local
  ```

在这个例子中，`AnalysisTemplate` 与背景分析示例相同，但由于没有指定时间间隔，因此分析将执行一次测量并完成。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
spec:
  args:
  - name: service-name
  - name: prometheus-port
    value: 9090
  metrics:
  - name: success-rate
    successCondition: result[0] >= 0.95
    provider:
      prometheus:
        address: "http://prometheus.example.com:{{args.prometheus-port}}"
        query: |
          sum(irate(
            istio_requests_total{reporter="source",destination_service=~"{{args.service-name}}",response_code!~"5.*"}[5m]
          )) /
          sum(irate(
            istio_requests_total{reporter="source",destination_service=~"{{args.service-name}}"}[5m]
          ))
```

可以通过指定 `count` 和 `interval` 字段来执行多个度量，以在较长的持续时间内执行多个度量：

```yaml hl_lines="4 5"
  metrics:
  - name: success-rate
    successCondition: result[0] >= 0.95
    interval: 60s
    count: 5
    provider:
      prometheus:
        address: http://prometheus.example.com:9090
        query: ...
```

## ClusterAnalysisTemplates

🔔 重要提示：从 v0.9.0 开始可用

Rollout 可以引用一个名为 ClusterAnalysisTemplate 的集群作用域 AnalysisTemplate。当你希望在多个 Rollout 中共享 AnalysisTemplate 时，这可能非常有用。在不同的命名空间中，避免在每个命名空间中重复相同的模板。使用 `clusterScope: true` 字段引用 ClusterAnalysisTemplate 而不是 AnalysisTemplate。

Rollout

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: guestbook
spec:
...
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {duration: 5m}
      - analysis:
          templates:
          - templateName: success-rate
            clusterScope: true
          args:
          - name: service-name
            value: guestbook-svc.default.svc.cluster.local
```

ClusterAnalysisTemplate

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ClusterAnalysisTemplate
metadata:
  name: success-rate
spec:
  args:
  - name: service-name
  - name: prometheus-port
    value: 9090
  metrics:
  - name: success-rate
    successCondition: result[0] >= 0.95
    provider:
      prometheus:
        address: "http://prometheus.example.com:{{args.prometheus-port}}"
        query: |
          sum(irate(
            istio_requests_total{reporter="source",destination_service=~"{{args.service-name}}",response_code!~"5.*"}[5m]
          )) /
          sum(irate(
            istio_requests_total{reporter="source",destination_service=~"{{args.service-name}}"}[5m]
          ))
```

🔔 注意：结果的 `AnalysisRun` 仍将在 `Rollout` 的命名空间中运行

## 使用多个模板的分析

Rollout 可以在构建 AnalysisRun 时引用多个 AnalysisTemplates。这允许用户从多个 AnalysisTemplate 中组合分析。如果引用了多个模板，则控制器将合并这些模板。控制器组合所有模板的 `metrics` 和 `args` 字段。

Rollout

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: guestbook
spec:
...
  strategy:
    canary:
      analysis:
        templates:
        - templateName: success-rate
        - templateName: error-rate
        args:
        - name: service-name
          value: guestbook-svc.default.svc.cluster.local
```

AnalysisTemplate

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
spec:
  args:
  - name: service-name
  metrics:
  - name: success-rate
    interval: 5m
    successCondition: result[0] >= 0.95
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus.example.com:9090
        query: |
          sum(irate(
            istio_requests_total{reporter="source",destination_service=~"{{args.service-name}}",response_code!~"5.*"}[5m]
          )) /
          sum(irate(
            istio_requests_total{reporter="source",destination_service=~"{{args.service-name}}"}[5m]
          ))
---
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: error-rate
spec:
  args:
  - name: service-name
  metrics:
  - name: error-rate
    interval: 5m
    successCondition: result[0] <= 0.95
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus.example.com:9090
        query: |
          sum(irate(
            istio_requests_total{reporter="source",destination_service=~"{{args.service-name}}",response_code=~"5.*"}[5m]
          )) /
          sum(irate(
            istio_requests_total{reporter="source",destination_service=~"{{args.service-name}}"}[5m]
          ))
```

AnalysisRun

```yaml
# NOTE: Generated AnalysisRun from the multiple templates
apiVersion: argoproj.io/v1alpha1
kind: AnalysisRun
metadata:
  name: guestbook-CurrentPodHash-multiple-templates
spec:
  args:
  - name: service-name
    value: guestbook-svc.default.svc.cluster.local
  metrics:
  - name: success-rate
    interval: 5m
    successCondition: result[0] >= 0.95
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus.example.com:9090
        query: |
          sum(irate(
            istio_requests_total{reporter="source",destination_service=~"{{args.service-name}}",response_code!~"5.*"}[5m]
          )) /
          sum(irate(
            istio_requests_total{reporter="source",destination_service=~"{{args.service-name}}"}[5m]
          ))
  - name: error-rate
    interval: 5m
    successCondition: result[0] <= 0.95
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus.example.com:9090
        query: |
          sum(irate(
            istio_requests_total{reporter="source",destination_service=~"{{args.service-name}}",response_code=~"5.*"}[5m]
          )) /
          sum(irate(
            istio_requests_total{reporter="source",destination_service=~"{{args.service-name}}"}[5m]
          ))
```

🔔 注意：当合并模板时，如果：

* 模板中的多个指标具有相同的名称
* 拥有相同名称的两个参数具有不同的默认值，无论 Rollout 中的参数值如何

控制器将出现错误。

## 分析模板参数

AnalysisTemplates 可以声明一组参数，这些参数可以由 Rollouts 传递。然后可以将 args 用作度量配置，并在创建 AnalysisRun 时解析它们。参数占位符定义为 `{{ args.<name> }}`。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: args-example
spec:
  args:
  # required in Rollout due to no default value
  - name: service-name
  - name: stable-hash
  - name: latest-hash
  # optional in Rollout given the default value
  - name: api-url
    value: http://example/measure
  # from secret
  - name: api-token
    valueFrom:
      secretKeyRef:
        name: token-secret
        key: apiToken
  metrics:
  - name: webmetric
    successCondition: result == 'true'
    provider:
      web:
        # placeholders are resolved when an AnalysisRun is created
        url: "{{ args.api-url }}?service={{ args.service-name }}"
        headers:
          - key: Authorization
            value: "Bearer {{ args.api-token }}"
        jsonPath: "{$.results.ok}"
```

在创建 AnalysisRun 时，Rollout 定义的分析参数与 AnalysisTemplate 的 args 合并。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: guestbook
spec:
...
  strategy:
    canary:
      analysis:
        templates:
        - templateName: args-example
        args:
        # required value
        - name: service-name
          value: guestbook-svc.default.svc.cluster.local
        # override default value
        - name: api-url
          value: http://other-api
        # pod template hash from the stable ReplicaSet
        - name: stable-hash
          valueFrom:
            podTemplateHashValue: Stable
        # pod template hash from the latest ReplicaSet
        - name: latest-hash
          valueFrom:
            podTemplateHashValue: Latest
```

分析参数还支持 valueFrom 以读取元数据字段并将其作为参数传递给 AnalysisTemplate。例如，可以引用元数据标签如 env 和 region 并将其传递给 AnalysisTemplate。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: guestbook
  labels:
    appType: demo-app
    buildType: nginx-app
    ...
    env: dev
    region: us-west-2
spec:
...
  strategy:
    canary:
      analysis:
        templates:
        - templateName: args-example
        args:
        ...
        - name: env
          valueFrom:
            fieldRef:
              fieldPath: metadata.labels['env']
        # region where this app is deployed
        - name: region
          valueFrom:
            fieldRef:
              fieldPath: metadata.labels['region']
```

🔔 重要提醒：从 v1.2 开始可用 分析参数还支持 valueFrom 以读取 Rollout 状态中的任何字段并将其作为参数传递给 AnalysisTemplate。以下示例引用 Rollout 状态字段，如 aws canaryTargetGroup 名称，并将它们传递给 AnalysisTemplate。

从 Rollout 状态

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: guestbook
  labels:
    appType: demo-app
    buildType: nginx-app
    ...
    env: dev
    region: us-west-2
spec:
...
  strategy:
    canary:
      analysis:
        templates:
        - templateName: args-example
        args:
        ...
        - name: canary-targetgroup-name
          valueFrom:
            fieldRef:
              fieldPath: status.alb.canaryTargetGroup.name
```

## 蓝绿色提前推广分析

使用蓝绿色策略的 Rollout 可以在切换流量到新版本之前使用预推广启动 AnalysisRun。这可用于阻止 Service 选择器切换，直到 AnalysisRun 成功完成。AnalysisRun 的成功或失败决定 Rollout 是否切换流量，或者完全中止 Rollout。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: guestbook
spec:
...
  strategy:
    blueGreen:
      activeService: active-svc
      previewService: preview-svc
      prePromotionAnalysis:
        templates:
        - templateName: smoke-tests
        args:
        - name: service-name
          value: preview-svc.default.svc.cluster.local
```

在此示例中，Rollout 在新 ReplicaSet 完全可用后创建预推广 AnalysisRun。直到分析运行成功才会将流量切换到新版本。

注意：如果指定了 `autoPromotionSeconds` 字段，并且 Rollout 等待了自动推广秒数的时间，那么 Rollout 将标记 AnalysisRun 成功，并自动将流量切换到新版本。如果 AnalysisRun 在此之前完成，则 Rollout 不会创建另一个 AnalysisRun，并等待剩余的 `autoPromotionSeconds`。

## 蓝绿色后推广分析

使用蓝绿色策略的 Rollout 可以在流量切换到新版本后启动分析运行，使用后推广分析。如果后推广分析失败或出错，则 Rollout 进入中止状态，并将流量切换回先前的稳定 Replicaset。当后分析成功时，Rollout 被认为已完全推广，新 ReplicaSet 将被标记为稳定。然后，旧的 ReplicaSet 将根据 `scaleDownDelaySeconds`（默认为 30 秒）进行缩放。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: guestbook
spec:
...
  strategy:
    blueGreen:
      activeService: active-svc
      previewService: preview-svc
      scaleDownDelaySeconds: 600 # 10 minutes
      postPromotionAnalysis:
        templates:
        - templateName: smoke-tests
        args:
        - name: service-name
          value: preview-svc.default.svc.cluster.local
```

## 失败条件和失败限制

`failureCondition` 可用于导致分析运行失败。`failureLimit` 是允许的分析运行的最大失败次数。以下示例不断轮询定义的 Prometheus 服务器，每 5 分钟获取总错误数（即，HTTP 响应代码 >= 500），如果遇到十个或更多错误，则导致测量失败。三次失败的度量将使整个分析运行失败。

```yaml hl_lines="4 5"
  metrics:
  - name: total-errors
    interval: 5m
    failureCondition: result[0] >= 10
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus.example.com:9090
        query: |
          sum(irate(
            istio_requests_total{reporter="source",destination_service=~"{{args.service-name}}",response_code=~"5.*"}[5m]
          ))
```

## Dry-Run 运行模式

🔔 重要提醒：从 v1.2 开始可用

`dryRun` 可以用于指示是否在干运行模式下评估度量。在干运行模式下运行的度量不会影响部署或实验的最终状态，即使它失败或评估结果为不确定。

以下示例每 5 分钟查询 Prometheus，以获取 4XX 和 5XX 错误的总数，即使监视 5XX 错误率的度量失败，分析运行也会通过。

```yaml hl_lines="1 2"
  dryRun:
  - metricName: total-5xx-errors
  metrics:
  - name: total-5xx-errors
    interval: 5m
    failureCondition: result[0] >= 10
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus.example.com:9090
        query: |
          sum(irate(
            istio_requests_total{reporter="source",destination_service=~"{{args.service-name}}",response_code~"5.*"}[5m]
          ))
  - name: total-4xx-errors
    interval: 5m
    failureCondition: result[0] >= 10
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus.example.com:9090
        query: |
          sum(irate(
            istio_requests_total{reporter="source",destination_service=~"{{args.service-name}}",response_code~"4.*"}[5m]
          ))
```

正则表达式匹配也受支持。`.*` 可以用于使所有指标都在干运行模式下运行。在以下示例中，即使一个或两个指标失败，分析运行也会通过。

```yaml hl_lines="1 2"
  dryRun:
  - metricName: .*
  metrics:
  - name: total-5xx-errors
    interval: 5m
    failureCondition: result[0] >= 10
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus.example.com:9090
        query: |
          sum(irate(
            istio_requests_total{reporter="source",destination_service=~"{{args.service-name}}",response_code~"5.*"}[5m]
          ))
  - name: total-4xx-errors
    interval: 5m
    failureCondition: result[0] >= 10
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus.example.com:9090
        query: |
          sum(irate(
            istio_requests_total{reporter="source",destination_service=~"{{args.service-name}}",response_code~"4.*"}[5m]
          ))
```

### 模拟运行摘要

如果一个或多个指标处于模拟运行模式，则将模拟运行结果的摘要附加到分析运行消息中。假设在上面的示例中，`total-4xx-errors`指标失败，但`total-5xx-errors`成功，最终的模拟运行摘要如下。

```yaml hl_lines="4 5 6 7"
Message: Run Terminated
Run Summary:
  ...
Dry Run Summary: 
  Count: 2
  Successful: 1
  Failed: 1
Metric Results:
...
```

### 模拟运行 Rollouts

如果一个发布要进行分析的模拟运行，只需将`dryRun`字段指定为其`analysis`结构。在以下示例中，来自`random-fail`和`always-pass`的所有指标都会被合并并以模拟运行模式执行。

```yaml hl_lines="9 10"
kind: Rollout
spec:
...
  steps:
  - analysis:
      templates:
      - templateName: random-fail
      - templateName: always-pass
      dryRun:
      - metricName: .*
```

### 模拟运行实验

如果一个实验要进行分析的模拟运行，只需在其规范下指定`dryRun`字段。在以下示例中，与正则表达式规则`test.*`匹配的`analyze-job`中的所有指标将以模拟运行模式执行。

```yaml hl_lines="20 21"
kind: Experiment
spec:
  templates:
  - name: baseline
    selector:
      matchLabels:
        app: rollouts-demo
    template:
      metadata:
        labels:
          app: rollouts-demo
      spec:
        containers:
        - name: rollouts-demo
          image: argoproj/rollouts-demo:blue
  analyses:
  - name: analyze-job
    templateName: analyze-job
  dryRun:
  - metricName: test.*
```

## 测量保留

🔔 重要提示：自 v1.2 以来可用

`measurementRetention`可用于保留其他模式（干/非干）中运行的度量除最新十个结果之外的结果。将此选项设置为`0`将禁用它，控制器将恢复保留最新十个测量值的现有行为。

以下示例每 5 分钟查询 Prometheus 以获取 4XX 和 5XX 错误的总数，并保留 5XX 度量运行结果的最新 20 个测量值，而不是默认的十个。


```yaml hl_lines="1 2 3"
  measurementRetention:
  - metricName: total-5xx-errors
    limit: 20
  metrics:
  - name: total-5xx-errors
    interval: 5m
    failureCondition: result[0] >= 10
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus.example.com:9090
        query: |
          sum(irate(
            istio_requests_total{reporter="source",destination_service=~"{{args.service-name}}",response_code~"5.*"}[5m]
          ))
  - name: total-4xx-errors
    interval: 5m
    failureCondition: result[0] >= 10
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus.example.com:9090
        query: |
          sum(irate(
            istio_requests_total{reporter="source",destination_service=~"{{args.service-name}}",response_code~"4.*"}[5m]
          ))
```

也支持正则表达式匹配。`.*`可用于将相同的保留规则应用于所有指标。在以下示例中，控制器将保留所有指标的最新二十个运行结果，而不是默认的十个结果。

```yaml hl_lines="1 2 3"
  measurementRetention:
  - metricName: .*
    limit: 20
  metrics:
  - name: total-5xx-errors
    interval: 5m
    failureCondition: result[0] >= 10
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus.example.com:9090
        query: |
          sum(irate(
            istio_requests_total{reporter="source",destination_service=~"{{args.service-name}}",response_code~"5.*"}[5m]
          ))
  - name: total-4xx-errors
    interval: 5m
    failureCondition: result[0] >= 10
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus.example.com:9090
        query: |
          sum(irate(
            istio_requests_total{reporter="source",destination_service=~"{{args.service-name}}",response_code~"4.*"}[5m]
          ))
```

### 用于 Rollouts 分析的测量保留

如果一个发布要保留其分析指标的更多结果，只需将`measurementRetention`字段指定为其`analysis`结构。在以下示例中，来自`random-fail`和`always-pass`的所有指标都会被合并，并保留它们的最新 20 个测量值，而不是默认的十个。

```yaml hl_lines="9 10 11"
kind: Rollout
spec:
...
  steps:
  - analysis:
      templates:
      - templateName: random-fail
      - templateName: always-pass
      measurementRetention:
      - metricName: .*
        limit: 20
```

### 为AnalysisRun定义自定义标签/注释

如果要使用自定义标签注释`AnalysisRun`，则可以通过指定`analysisRunMetadata`字段来实现。

```yaml hl_lines="9 10 11"
kind: Rollout
spec:
...
  steps:
  - analysis:
      templates:
      - templateName: my-template
      analysisRunMetadata:
        labels:
          my-custom-label: label-value
        annotations:
          my-custom-annotation: annotation-value
```

### 用于实验的测量保留

如果一个实验要保留其分析指标的更多结果，只需在其规范下指定`measurementRetention`字段。在以下示例中，与正则表达式规则`test.*`匹配的`analyze-job`中的所有指标的最新 20 个测量值将被保留，而不是默认的十个。

```yaml hl_lines="20 21 22"
kind: Experiment
spec:
  templates:
  - name: baseline
    selector:
      matchLabels:
        app: rollouts-demo
    template:
      metadata:
        labels:
          app: rollouts-demo
      spec:
        containers:
        - name: rollouts-demo
          image: argoproj/rollouts-demo:blue
  analyses:
  - name: analyze-job
    templateName: analyze-job
  measurementRetention:
  - metricName: test.*
    limit: 20
```

## 不确定的运行

分析运行也可以被视为`不确定的`，这表示运行既不成功也不失败。不确定的运行会导致发布在其当前步骤被暂停。然后需要手动干预才能恢复发布或中止。分析运行可能变为`不确定的`的一个例子是当一个指标没有定义成功或失败条件时。

```yaml
  metrics:
  - name: my-query
    provider:
      prometheus:
        address: http://prometheus.example.com:9090
        query: ...
```

当指定了成功和失败条件但测量值没有满足任何一个条件时，`不确定`的分析运行也可能发生。

```yaml
  metrics:
  - name: success-rate
    successCondition: result[0] >= 0.90
    failureCondition: result[0] < 0.50
    provider:
      prometheus:
        address: http://prometheus.example.com:9090
        query: ...
```

`不确定的`分析运行的一个使用案例是使 Argo Rollouts 能够自动执行分析运行，并收集测量值，但仍然允许人类判断测量值是否可接受，并决定继续或中止。

## 延迟分析运行

如果分析运行不需要立即启动（即让度量提供程序收集金丝雀版本的度量），则分析运行可以延迟特定的度量分析。每个指标可以配置不同的延迟。除了度量特定的延迟之外，具有后台分析的发布可以延迟创建分析运行，直到达到某个步骤为止

延迟特定的分析指标：

```yaml hl_lines="3 4"
  metrics:
  - name: success-rate
    # Do not start this analysis until 5 minutes after the analysis run starts
    initialDelay: 5m
    successCondition: result[0] >= 0.90
    provider:
      prometheus:
        address: http://prometheus.example.com:9090
        query: ...
```

延迟启动后台分析运行，直到第 3 步（设置权重 40％）：

```yaml hl_lines="11"
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: guestbook
spec:
  strategy:
    canary:
      analysis:
        templates:
        - templateName: success-rate
        startingStep: 2
      steps:
      - setWeight: 20
      - pause: {duration: 10m}
      - setWeight: 40
      - pause: {duration: 10m}
```

## 引用秘密

AnalysisTemplates 和 AnalysisRuns 可以在`.spec.args`中引用秘密对象。这允许用户将身份验证信息（如登录凭据或 API 令牌）安全地传递给度量提供程序。

AnalysisRun 只能引用与其在其中运行的相同命名空间中的秘密。这仅适用于 AnalysisRuns，因为 AnalysisTemplates 不会解析秘密。

在以下示例中，AnalysisTemplate 引用 API 令牌并将其传递给 Web 度量提供程序。

此示例演示了：

- 在 AnalysisTemplate`.spec.args`中引用秘密的能力
- 将秘密参数传递给度量提供程序的能力

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
spec:
  args:
  - name: api-token
    valueFrom:
      secretKeyRef:
        name: token-secret
        key: apiToken
  metrics:
  - name: webmetric
    provider:
      web:
        headers:
        - key: Authorization
          value: "Bearer {{ args.api-token }}"
```

## 处理度量结果

### NaN 和 Infinity

度量提供程序有时可能会返回 NaN（不是数字）和无限值。用户可以编辑`successCondition`和`failureCondition`字段以相应地处理这些情况。

以下是三个例子，其中 NaN 的度量结果被认为是成功的，不确定的和失败的。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisRun
  ...
    successCondition: isNaN(result) || result >= 0.95
status:
  metricResults:
  - count: 1
    measurements:
    - finishedAt: "2021-02-10T00:15:26Z"
      phase: Successful
      startedAt: "2021-02-10T00:15:26Z"
      value: NaN
    name: success-rate
    phase: Successful
    successful: 1
  phase: Successful
  startedAt: "2021-02-10T00:15:26Z"
```

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisRun
  ...
    successCondition: result >= 0.95
    failureCondition: result < 0.95
status:
  metricResults:
  - count: 1
    measurements:
    - finishedAt: "2021-02-10T00:15:26Z"
      phase: Inconclusive
      startedAt: "2021-02-10T00:15:26Z"
      value: NaN
    name: success-rate
    phase: Inconclusive
    successful: 1
  phase: Inconclusive
  startedAt: "2021-02-10T00:15:26Z"
```

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisRun
  ...
    successCondition: result >= 0.95
status:
  metricResults:
  - count: 1
    measurements:
    - finishedAt: "2021-02-10T00:15:26Z"
      phase: Failed
      startedAt: "2021-02-10T00:15:26Z"
      value: NaN
    name: success-rate
    phase: Failed
    successful: 1
  phase: Failed
  startedAt: "2021-02-10T00:15:26Z"
```

以下是两个例子，其中无限度量结果被认为是成功和失败的。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisRun
  ...
    successCondition: result >= 0.95
status:
  metricResults:
  - count: 1
    measurements:
    - finishedAt: "2021-02-10T00:15:26Z"
      phase: Successful
      startedAt: "2021-02-10T00:15:26Z"
      value: +Inf
    name: success-rate
    phase: Successful
    successful: 1
  phase: Successful
  startedAt: "2021-02-10T00:15:26Z"
```

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisRun
  ...
    failureCondition: isInf(result)
status:
  metricResults:
  - count: 1
    measurements:
    - finishedAt: "2021-02-10T00:15:26Z"
      phase: Failed
      startedAt: "2021-02-10T00:15:26Z"
      value: +Inf
    name: success-rate
    phase: Failed
    successful: 1
  phase: Failed
  startedAt: "2021-02-10T00:15:26Z"
```

### 空数组

### Prometheus

度量提供程序有时可能会返回空数组，例如，从 Prometheus 查询未返回任何数据。

以下是两个例子，其中空数组的度量结果被认为是成功和失败的。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisRun
  ...
    successCondition: len(result) == 0 || result[0] >= 0.95
status:
  metricResults:
  - count: 1
    measurements:
    - finishedAt: "2021-09-08T19:15:49Z"
      phase: Successful
      startedAt: "2021-09-08T19:15:49Z"
      value: '[]'
    name: success-rate
    phase: Successful
    successful: 1
  phase: Successful
  startedAt:  "2021-09-08T19:15:49Z"
```

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisRun
  ...
    successCondition: len(result) > 0 && result[0] >= 0.95
status:
  metricResults:
  - count: 1
    measurements:
    - finishedAt: "2021-09-08T19:19:44Z"
      phase: Failed
      startedAt: "2021-09-08T19:19:44Z"
      value: '[]'
    name: success-rate
    phase: Failed
    successful: 1
  phase: Failed
  startedAt: "2021-09-08T19:19:44Z"
```

### Datadog

如果在没有度量的时间间隔内进行查询，则 Datadog 查询可能会返回空结果。如果查询结果为空，则 Datadog 提供程序将返回一个`nil`值，在评估阶段产生错误，例如：

```
invalid operation: < (mismatched types <nil> and float64)
```

但是，使用`default（）`函数可以处理返回值为`nil`的空查询结果。以下是使用`default（）`函数的成功示例：

```
 successCondition: default(result, 0) < 0.05
```
