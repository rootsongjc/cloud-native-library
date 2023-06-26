---
weight: 2
linkTitle: "Rollout 规范"
title: "Rollout 规范"
date: '2023-06-21T16:00:00+08:00'
type: book
---

以下描述了 Rollout 的所有可用字段：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: example-rollout-canary
spec:
  # 期望的 Pod 数量。
  # 默认为 1。
  replicas: 5
  analysis:
    # 限制存储历史上成功的分析运行和实验的数量
    # 默认为 5。
    successfulRunHistoryLimit: 10
    # 限制存储历史上不成功的分析运行和实验的数量。
    # 不成功的阶段有："Error"，"Failed"，"Inconclusive"
    # 默认为 5。
    unsuccessfulRunHistoryLimit: 10

  # Pod 的标签选择器。被选择的 Pod 的现有副本集将受到此 Rollout 的影响。它必须与 Pod 模板的标签匹配。
  selector:
    matchLabels:
      app: guestbook

  # WorkloadRef 包含对提供 Pod 模板（例如 Deployment）的工作负载的引用。如果使用，则不使用 Rollout 模板属性。
  workloadRef:
    apiVersion: apps/v1
    kind: Deployment
    name: rollout-ref-deployment

  # 模板描述将被创建的 Pod。与 deployment 相同。
  # 如果使用，则不使用 Rollout workloadRef 属性。
  template:
    spec:
      containers:
      - name: guestbook
        image: argoproj/rollouts-demo:blue

  # 新创建的 Pod 必须准备好而没有任何容器崩溃的最小秒数，
  # 才能被视为可用。默认为 0（Pod 将在准备就绪后立即被视为可用）
  minReadySeconds: 30

  # 要保留的旧 ReplicaSet 的数量。
  # 默认为 10。
  revisionHistoryLimit: 3

  # Pause 允许用户在任何时候手动暂停 Rollout。
  # 在手动暂停期间，Rollout 将不会通过其步骤前进，但是 HPA 自动扩展将仍然发生。
  # 通常不在清单中明确设置，而是通过工具（例如 kubectl argo rollouts pause）进行控制。
  # 如果在 Rollout 的初始创建时为 true，则不会从零自动扩展副本，除非手动推广。
  paused: true

  # 在更新期间，Rollout 必须取得进展的最大时间（以秒为单位），
  # 否则将被视为失败。Argo Rollouts 将继续处理失败的 Rollout，
  # 并在 Rollout 状态中显示具有 ProgressDeadlineExceeded 原因的条件。
  # 请注意，进度不会在 Rollout 暂停期间估计。
  # 默认为 600 秒
  progressDeadlineSeconds: 600

  # 当超过 ProgressDeadlineSeconds 时，是否中止更新。
  # 可选，默认值为 false。
  progressDeadlineAbort: false

  # UTC 时间戳，Rollout 应该按顺序重新启动所有的 Pod。
  # 由“kubectl argo rollouts restart ROLLOUT”命令使用。
  # 控制器将确保所有 Pod 的 creationTimestamp 大于或等于此值。
  restartAt: "2020-03-30T21:19:35Z"

  # 回滚窗口提供了一种快速跟踪到以前部署的版本的方法。
  # 可选，默认未设置。
  rollbackWindow:
    revisions: 3

  strategy:

    # 蓝绿更新策略
    blueGreen:

      # Rollout 修改的服务的引用作为活动服务。
      # 必填项。
      activeService: active-service

      # 促销之前执行分析的运行，以在服务切换之前执行分析。+可选
      prePromotionAnalysis:
        templates:
        - templateName: success-rate
        args:
        - name: service-name
          value: guestbook-svc.default.svc.cluster.local

      # 促销后执行分析的运行，以在服务切换之后执行分析。+可选
      postPromotionAnalysis:
        templates:
        - templateName: success-rate
        args:
        - name: service-name
          value: guestbook-svc.default.svc.cluster.local

      # Rollout 修改的服务的名称作为预览服务的名称。+可选
      previewService: preview-service

      # 在切换之前，在预览服务下运行的副本数。
      # 一旦 Rollout 恢复，新的 ReplicaSet 将完全扩展，
      # 然后才会发生切换 +可选
      previewReplicaCount: 1

      # 指示 Rollout 是否应自动将新的 ReplicaSet 提升为活动服务，
      # 还是进入暂停状态。如果未指定，则默认值为 true。+可选
      autoPromotionEnabled: false

      # 在新的 ReplicaSet 准备就绪后，自动将当前 ReplicaSet 提升为活动状态
      # 经过指定的暂停延迟时间（以秒为单位）。如果省略，则 Rollout 将进入暂停状态，
      # 直到通过将 spec.Paused 重置为 false 手动恢复。
      autoPromotionSeconds: 30

      # 在缩放之前添加延迟以缩小先前的 ReplicaSet。如果省略，
      # Rollout 将在缩小先前的 ReplicaSet 之前等待 30 秒。建议至少等待 30 秒，
      # 以确保在集群中的节点之间进行 IP 表传播。
      scaleDownDelaySeconds: 30

      # 在被缩放之前可运行的旧 RS 的数量限制。
      # 默认为 nil。
      scaleDownDelayRevisionLimit: 2

      # 如果更新被中止，则在缩小预览副本集之前添加延迟。
      # 0 表示不缩小。默认为 30 秒。
      abortScaleDownDelaySeconds: 30

      # 所需和先前 ReplicaSet 之间的反亲和力配置。
      # 只能指定一个
      antiAffinity:
        requiredDuringSchedulingIgnoredDuringExecution: {}
        preferredDuringSchedulingIgnoredDuringExecution:
          weight: 1 # 在 1-100 之间

      # activeMetadata 将合并并即时更新到活动 Pod 的 ReplicaSet 的 spec.template.metadata 中。+可选
      activeMetadata:
        labels:
          role: active

      # 只在预览阶段将分配给预览 Pod 的元数据。
      # +可选
      previewMetadata:
        labels:
          role: preview

    # 金丝雀更新策略
    canary:

      # 控制器将更新以选择金丝雀 Pod 的服务的引用。用于流量路由。
      # 必需的。
      canaryService: canary-service

      # 控制器将更新以选择稳定 Pod 的服务的引用。用于流量路由。
      # 必需的。
      stableService: stable-service

      # 将附加到金丝雀 Pod 的元数据。此元数据仅在更新期间存在，因为在完全推广的 Rollout 中没有金丝雀 Pod。
      canaryMetadata:
        annotations:
          role: canary
        labels:
          role: canary

      # 将附加到稳定 Pod 的元数据。
      stableMetadata:
        annotations:
          role: stable
        labels:
          role: stable

      # 在更新期间可以不可用的最大 Pod 数。
      # 值可以是绝对数（例如 5），也可以是开始更新时总 Pod 数的百分比（例如 10％）。
      # 绝对数由百分比四舍五入计算。如果 MaxSurge 为 0，则不能为 0。默认情况下，使用固定值 1。
      # 例如：将此设置为 30％时，可以在滚动更新开始时立即将旧 RC 缩减 30％。
      # 一旦新的 Pod 准备就绪，旧的 RC 可以进一步缩减，然后才能扩展新的 RC，从而确保
      # 在更新期间始终至少有 70％的原始 Pod 数可用。
      # +可选
      maxUnavailable: 1

      # 可以调度的 Pod 的最大数量，超过原始 Pod 数量。
      # 值可以是绝对数（例如 5）或开始更新时总 Pod 数量的百分比（例如 10％）。
      # 如果 MaxUnavailable 为 0，则不能为 0。绝对数从百分比计算，四舍五入。默认情况下，使用值 1。
      # 例如：将此设置为 30％时，可以在滚动更新开始时立即将新的 RC 扩展 30％。
      # 一旦旧 Pod 被杀死，新的 RC 可以进一步扩展，以确保在更新期间运行的 Pod 的总数最多为原始 Pod 的 130％。
      # +可选
      maxSurge: "20%"

      # 当使用流量路由的金丝雀策略时，添加在缩小先前的 ReplicaSet 之前的延迟（默认为 30 秒）。
      # 在将稳定服务选择器切换到指向新的 ReplicaSet 之后，需要在缩小先前的 ReplicaSet 之前延迟，以便为流量提供程序提供时间
      # 重新定位新的 Pod。在基本的，基于副本权重的金丝雀策略中使用此值时，将忽略它。
      scaleDownDelaySeconds: 30

      # 在使用流量路由的金丝雀时，每个 ReplicaSet 将请求的最小 Pod 数量。
      # 这是为了确保每个 ReplicaSet 的高可用性。默认为 1。+可选
      minPodsPerReplicaSet: 2

      # 在被缩放之前可运行的旧 RS 的数量限制。
      # 默认为 nil。
      scaleDownDelayRevisionLimit: 2

      # 在滚动更新期间运行的后台分析。在滚动更新的初始部署时跳过。+可选
      analysis:
        templates:
        - templateName: success-rate
        args:
        - name: service-name
          value: guestbook-svc.default.svc.cluster.local

        # valueFrom.podTemplateHashValue 是一种方便的方法，用于提供稳定 ReplicaSet 或最新 ReplicaSet 的 rollouts-pod-template-hash 值
        - name: stable-hash
          valueFrom:
            podTemplateHashValue: Stable
        - name: latest-hash
          valueFrom:
            podTemplateHashValue: Latest

        # valueFrom.fieldRef 允许提供有关 Rollout 的元数据作为分析的参数。
        - name: region
          valueFrom:
            fieldRef:
              fieldPath: metadata.labels['region']

      # 步骤定义了在更新金丝雀时要执行的步骤序列。
      # 在 Rollout 的初始部署时跳过。+可选
      steps:

      # 将金丝雀 ReplicaSet 的比例设置为 20％
      - setWeight: 20

      # 暂停 Rollout 一小时。支持的单位：s，m，h
      - pause:
          duration: 1h

      # 无限期暂停，直到手动恢复
      - pause: {}

      # 设置金丝雀规模为显式计数，而不更改流量权重
      # （仅在 trafficRouting 中支持）
      - setCanaryScale:
          replicas: 3

      # 将金丝雀规模设置为 spec.replicas 的百分比，而不更改流量权重
      # （仅在 trafficRouting 中支持）
      - setCanaryScale:
          weight: 25

      # 将金丝雀规模设置为匹配金丝雀流量权重（默认行为）
      - setCanaryScale:
          matchTrafficWeight: true

      # 基于标头值设置标头路由
      # 设置基于标头的路由将会将所有流量发送到金丝雀，对于请求头“version”中指定的请求
      # （仅在 trafficRouting 中受支持，目前仅适用于 Istio）
      - setHeaderRoute:
          # argo rollouts 将创建的路由的名称，这也必须在 spec.strategy.canary.trafficRouting.managedRoutes 中配置
          name: "header-route-1"
          # 标头路由的匹配规则，如果缺少，它将作为路由的删除
          match:
              # headerName 应用匹配规则的标头名称
            - headerName: "version"
              # headerValue 必须包含一个精确、正则表达式或前缀字段。并非所有的流量路由器都支持所有类型
              headerValue:
                # 精确匹配只有在标头值完全相同的情况下才会匹配
                exact: "2"
                # 如果正则表达式匹配，则会匹配该规则
                regex: "2.0.(.*)"
                # 前缀将是标头值的前缀匹配
                prefix: "2.0"

        # 使用指定的匹配规则设置阴影路由
        # 在部署期间，流量将在配置的百分比下被镜像到金丝雀服务
        # （仅在 trafficRouting 中受支持，目前仅适用于 Istio）
      - setMirrorRoute:
          # argo rollouts 将创建的路由的名称，这也必须在 spec.strategy.canary.trafficRouting.managedRoutes 中配置
          name: "header-route-1"
          # 匹配流量的百分比，将流量复制到金丝雀
          percentage: 100
          # 阴影路由的匹配规则，如果缺少，它将作为路由的删除
          # 单个 match 块内的所有条件都有 AND 语义，而 match 块列表具有 OR 语义。
          # 每个 match 中的类型（方法、路径、标头）必须具有一种且仅一种匹配类型（exact、regex、prefix）
          # 并非所有的匹配类型（exact、regex、prefix）都被所有流量路由器支持。
          match:
            - method: # 匹配哪种 HTTP 方法
                exact: "GET"
                regex: "P.*"
                prefix: "POST"
              path: # 匹配哪些 HTTP URL 路径。
                exact: "/test"
                regex: "/test/.*"
                prefix: "/"
              headers:
                agent-1b: # 在匹配中使用的 HTTP 标头名称。
                  exact: "firefox"
                  regex: "firefox2(.*)"
                  prefix: "firefox"

      # 内联分析步骤
      - analysis:
          templates:
          - templateName: success-rate

      # 内联实验步骤
      - experiment:
          duration: 1h
          templates:
          - name: baseline
            specRef: stable
            # 可选，如果设置，将为实验创建一个服务
            service:
              # 可选，如果未包括名称，则 service: {} 也可以接受
              name: test-service
          - name: canary
            specRef: canary
            # 可选，设置路由到该版本的流量权重
            weight: 10
          analyses:
          - name : mann-whitney
            templateName: mann-whitney
            # 附加到 AnalysisRun 的元数据。
            analysisRunMetadata:
              labels:
                app.service.io/analysisType: smoke-test
              annotations:
                link.argocd.argoproj.io/external-link: <http://my-loggin-platform.com/pre-generated-link>

      # 期望和先前的 ReplicaSet 之间的反亲和性配置。
      # 只能指定一个。
      antiAffinity:
        requiredDuringSchedulingIgnoredDuringExecution: {}
        preferredDuringSchedulingIgnoredDuringExecution:
          weight: 1 # 在 1-100 之间

      # 流量路由指定 Ingress 控制器或服务网格
      # 配置以实现高级流量分割。如果省略，
      # 会通过金丝雀和稳定 ReplicaSet 之间的加权副本计数实现流量分割。
      trafficRouting:
        # 这是 Argo Rollouts 有权管理的路由列表，目前仅对 setMirrorRoute 和 setHeaderRoute 必需。
        # managedRoutes 数组的顺序还设置了流量路由器中的优先级。Argo Rollouts 将按上面指定的顺序将这些路由置于
        # 任何已定义于使用的流量路由器中的路由之上，如果存在。这里的名称必须与 setHeaderRoute 和 setMirrorRoute 步骤中的名称相匹配。
        managedRoutes:
          - name: set-header
          - name: mirror-route
        # Istio 流量路由器配置
        istio:
          # virtualService 或 virtualServices 都可以配置。
          virtualService:
            name: rollout-vsvc  # 必需
            routes:
            - primary # 如果 VirtualService 中只有一个路由，则为可选项，否则为必需项
          virtualServices:
          # 可配置一个或多个 virtualServices
          - name: rollouts-vsvc1  # 必需
            routes:
              - primary # 如果 VirtualService 中只有一个路由，则为可选项，否则为必需项
          - name: rollouts-vsvc2  # 必需
            routes:
              - secondary # 如果 VirtualService 中只有一个路由，则为可选项，否则为必需项

        # NGINX Ingress 控制器路由配置
        nginx:
          # 必须配置 stableIngress 或 stableIngresses，但不能同时配置两者。
          stableIngress: primary-ingress
          stableIngresses:
            - primary-ingress
            - secondary-ingress
            - tertiary-ingress
          annotationPrefix: customingress.nginx.ingress.kubernetes.io # 可选
          additionalIngressAnnotations:   # 可选
            canary-by-header: X-Canary
            canary-by-header-value: iwantsit

        # ALB Ingress 控制器路由配置
        alb:
          ingress: ingress  # 必需
          servicePort: 443  # 必需
          annotationPrefix: custom.alb.ingress.kubernetes.io # 可选

        # 服务网格接口路由配置
        smi:
          rootService: root-svc # 可选
          trafficSplitName: rollout-example-traffic-split # 可选

      # 在使用流量路由的金丝雀策略中，更新中止之前的金丝雀 Pod 缩减的延迟时间。
      # 0 表示不缩减金丝雀 Pod。默认为 30 秒。
      abortScaleDownDelaySeconds: 30

status:
  pauseConditions:
  - reason: StepPause
    startTime: 2019-10-00T1234
  - reason: BlueGreenPause
    startTime: 2019-10-00T1234
  - reason: AnalysisRunInconclusive
    startTime: 2019-10-00T1234
```
## 示例

你可以在以下位置找到 Rollouts 示例：

 * [example 目录](https://github.com/argoproj/argo-rollouts/tree/master/examples)
 * [Argo Rollouts Demo 应用](https://github.com/argoproj/rollouts-demo)
