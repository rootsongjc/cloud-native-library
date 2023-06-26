---
weight: 10
linkTitle: 实验
title: 实验 CRD
date: '2023-06-21T16:00:00+08:00'
type: book
---

## 什么是实验 CRD？

实验 CRD 允许用户对一个或多个 ReplicaSet 进行短暂运行。除了运行短暂 ReplicaSet 外，实验 CRD 还可以在 ReplicaSet 旁边启动 AnalysisRuns。通常，这些 AnalysisRun 用于确认新的 ReplicaSet 是否按预期运行。

如果设置了权重（需要流量路由）或该实验的 Service 属性，则还会生成一个服务，用于将流量路由到实验 ReplicaSet。

## 实验用例

- 用户想要运行应用程序的两个版本以进行 Kayenta 风格的分析来启用。实验 CRD 基于实验的 `spec.templates` 字段创建 2 个 ReplicaSet（基线和金丝雀），并等待两者都健康。经过一段时间后，实验会缩小 ReplicaSet 的规模，用户可以开始 Kayenta 分析运行。
- 用户可以使用实验来启用 A/B/C 测试，通过为不同版本的应用程序启动多个实验来进行长时间测试。每个实验都有一个 PodSpec 模板，定义用户要运行的特定版本。实验允许用户同时启动多个实验，并保持每个实验的独立性。
- 使用不同的标签启动现有应用程序的新版本，以避免从 Kubernetes 服务中接收流量。用户可以在继续 Rollout 之前在新版本上运行测试。

## 实验规范

以下是创建两个具有 1 个副本的 ReplicaSet 并在两者可用后运行它们 20 分钟的实验示例。此外，还运行了多个 AnalysisRun 以针对实验的 pod 进行分析。

```yaml
 apiVersion: argoproj.io/v1alpha1
 kind: Experiment
 metadata:
   name: example-experiment
 spec:
   # 实验持续时间，从所有 ReplicaSet 变为健康状态开始（可选）
   # 如果省略，将无限期运行，直到终止或所有标记为“requiredForCompletion”的分析都完成。
   duration: 20m

   # 一个 ReplicaSet 应在其中取得进展的截止时间（以秒为单位）。
   # 如果超过，则实验将失败。
   progressDeadlineSeconds: 30

   # 要在实验中运行的 Pod 模板规范列表，作为 ReplicaSets
   templates:
   - name: purple
     # 要运行的副本数（可选）。如果省略，将运行单个副本
     replicas: 1
     # 创建此实验的服务标志（可选）
     # 如果未指定，则不会创建服务。
     service:
       # 服务名称（可选）。如果省略，则 service: {} 也可以接受。
       name: service-name
     selector:
       matchLabels:
         app: canary-demo
         color: purple
     template:
       metadata:
         labels:
           app: canary-demo
           color: purple
       spec:
         containers:
         - name: rollouts-demo
           image: argoproj/rollouts-demo:purple
           imagePullPolicy: Always
           ports:
           - name: http
             containerPort: 8080
             protocol: TCP
   - name: orange
     replicas: 1
     minReadySeconds: 10
     selector:
       matchLabels:
         app: canary-demo
         color: orange
     template:
       metadata:
         labels:
           app: canary-demo
           color: orange
       spec:
         containers:
         - name: rollouts-demo
           image: argoproj/rollouts-demo:orange
           imagePullPolicy: Always
           ports:
           - name: http
             containerPort: 8080
             protocol: TCP

   # 要在实验期间执行的 AnalysisTemplate 引用列表
   analyses:
   - name: purple
     templateName: http-benchmark
     args:
     - name: host
       value: purple
   - name: orange
     templateName: http-benchmark
     args:
     - name: host
       value: orange
   - name: compare-results
     templateName: compare
     # 如果对于分析引用设置了 requiredForCompletion 为 true，则在此分析完成之前，实验不会完成
     requiredForCompletion: true
     args:
     - name: host
       value: purple
```

## 实验生命周期

实验旨在临时运行一个或多个模板。实验的生命周期如下：

1. 为 `spec.templates` 下指定的每个 Pod 模板创建并扩展一个 ReplicaSet。如果在一个 Pod 模板下指定了 `service`，则还会为该 Pod 创建一个服务。
2. 等待所有 ReplicaSet 达到完全可用性。如果 ReplicaSet 在 `spec.progressDeadlineSeconds` 内未变为可用，则实验将失败。一旦可用，实验将从“挂起”状态转换为“运行”状态。
3. 一旦实验被视为“运行中”，它将为 `spec.analyses` 下引用的每个 AnalysisTemplate 开始一个 AnalysisRun。
4. 如果在 `spec.duration` 下指定了持续时间，则实验将等待持续时间结束，然后完成实验。
5. 如果 AnalysisRun 失败或出错，则实验将过早结束，状态等于不成功的 AnalysisRun（即“失败”或“错误”）。
6. 如果其中一个引用的 AnalysisTemplates 被标记为 `requiredForCompletion：true`，则实验将不会在这些 AnalysisRuns 完成之前完成，即使超过实验持续时间。
7. 如果未指定 `spec.duration` 或 `requiredForCompletion：true`，则实验将无限期运行，直到显式终止（通过设置 `spec.terminate：true`）。
8. 一旦实验完成，ReplicaSets 将缩小到零，并终止任何未完成的 AnalysisRuns。

🔔 注意：ReplicaSet 名称是通过将实验名称与模板名称组合而成的。

## 与 Rollouts 集成

使用金丝雀策略的 Rollout 可以使用 `experiment` 步骤创建一个实验。实验步骤作为 Rollout 的阻塞步骤，只有当实验成功时，Rollout 才会继续。Rollout 会使用 Rollout 实验步骤中的配置创建实验。如果实验失败或出错，则 Rollout 将中止。

🔔 注意：实验名称是通过将 Rollout 的名称、新 ReplicaSet 的 PodHash、Rollout 的当前版本和当前步骤索引组合而成的。

```yaml
 apiVersion: argoproj.io/v1alpha1
 kind: Rollout
 metadata:
   name: guestbook
   labels:
     app: guestbook
 spec:
 ...
   strategy:
     canary:
       steps:
       - experiment:
           duration: 1h
           templates:
           - name: baseline
             specRef: stable
           - name: canary
             specRef: canary
           analyses:
           - name : mann-whitney
             templateName: mann-whitney
             args:
             - name: baseline-hash
               value: "{{templates.baseline.podTemplateHash}}"
             - name: canary-hash
               value: "{{templates.canary.podTemplateHash}}"
apiVersion: [argoproj.io/v1alpha1](<http://argoproj.io/v1alpha1>)
 kind: Rollout
 metadata:
   name: guestbook
   labels:
     app: guestbook
 spec:
 ...
 strategy:
   canary:
     trafficRouting:
       alb:
         ingress: ingress
         ...
     steps:
       - experiment:
           duration: 1h
           templates:
             - name: experiment-baseline
               specRef: stable
               weight: 5
             - name: experiment-canary
               specRef: canary
               weight: 5
```

在上面的示例中，在 Rollout 的更新期间，Rollout 将启动一个实验。实验将创建两个 ReplicaSets：`baseline` 和 `canary`，每个 ReplicaSet 都有一个副本，并将运行一个小时。`baseline` 模板使用稳定 ReplicaSet 的 PodSpec，而 `canary` 模板使用金丝雀 ReplicaSet 的 PodSpec。

此外，实验将使用名为 `mann-whitney` 的 AnalysisTemplate 进行分析。AnalysisRun 会提供基线和金丝雀的 pod-hash 详细信息，以执行必要的指标查询，使用 `{{templates.baseline.podTemplateHash}}` 和 `{{templates.canary.podTemplateHash}}` 变量。

🔔 注意：实验的 `baseline`/`canary` ReplicaSets 创建的 pod-hash 值与 Rollout 创建的 `stable`/`canary` ReplicaSets 的 pod-hash 值不同。这是有意行为，以便允许对实验的 pod 进行分隔和单独查询指标，而不是和 Rollout 的 pod 混淆。

## 带流量路由的加权实验步骤

🔔 重要提醒：从 v1.1 开始可用

使用金丝雀策略和流量路由的 Rollout 可以将流量以细粒度的方式分配到实验堆栈中。启用流量路由时，Rollout 实验步骤允许将流量转移到实验 pod。

🔔 注意：目前，此功能仅适用于 SMI、ALB 和 Istio 流量路由器。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: guestbook
  labels:
    app: guestbook
spec:
...
strategy:
  canary:
    trafficRouting:
      alb:
        ingress: ingress
        ...
    steps:
      - experiment:
          duration: 1h
          templates:
            - name: experiment-baseline
              specRef: stable
              weight: 5
            - name: experiment-canary
              specRef: canary
              weight: 5
```

在上面的示例中，在更新期间，第一步将启动基线与金丝雀实验。当 Pod 准备就绪时（实验进入运行阶段），Rollout 将将 5% 的流量分配到 `experiment-canary`，并将 5% 的流量分配到 `experiment-baseline`，使其余 90% 的流量留给旧堆栈。

!!! note 当使用带有流量路由的加权实验步骤时，将为每个实验模板自动创建服务。流量路由器使用此服务将流量发送到实验 pod。

默认情况下，生成的 Service 具有 ReplicaSet 的名称，并从 specRef 定义中继承端口和选择器。可以使用 `{{templates.baseline.replicaset.name}}` 或 `{{templates.canary.replicaset.name}}` 变量分别访问它们。

## 不使用权重创建实验服务

如果你不想使用流量路由进行实验，但仍想为它们创建服务，你可以设置一个 Service 对象，该对象使用可选的名称，而无需为它们设置权重。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: guestbook
  labels:
    app: guestbook
spec:
...
strategy:
  canary:
    steps:
      - experiment:
          duration: 1h
          templates:
            - name: experiment-baseline
              specRef: stable
              service:
                name: test-service
            - name: experiment-canary
              specRef: canary
```

在上述示例中，在更新期间，第一步会开始一个基准 vs. 金丝雀实验。这次，即使没有为它设置权重或流量路由，也将为 `experiment-baseline` 创建一个服务。
