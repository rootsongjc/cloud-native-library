---
weight: 4
title: "AWS Load Balancer Controller (ALB)"
linkTitle: "AWS ALB"
date: '2023-06-21T16:00:00+08:00'
type: book
tags: ["AWS","Argo Rollouts"]
---

## 要求

- AWS 负载均衡器控制器 v1.1.5 或更高版本

## 概述

[AWS 负载均衡器控制器](https://github.com/kubernetes-sigs/aws-load-balancer-controller)（也称为 AWS ALB Ingress Controller）通过配置 AWS 应用程序负载均衡器（ALB）以将流量路由到一个或多个 Kubernetes 服务的 Ingress 对象，实现流量管理。ALB 通过[加权目标组](https://aws.amazon.com/blogs/aws/new-application-load-balancer-simplifies-deployment-with-weighted-target-groups/)的概念提供了高级流量分割功能。AWS 负载均衡器控制器通过对 Ingress 对象的注解进行配置“操作”来支持此功能。

## 工作原理

ALB 通过侦听器和包含操作的规则进行配置。侦听器定义客户端的流量如何进入，规则定义如何使用各种操作处理这些请求。一种操作类型允许用户将流量转发到多个目标组（每个目标组都定义为 Kubernetes 服务）。你可以在[此处](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html)阅读有关 ALB 概念的更多信息。

由 AWS 负载均衡器控制器管理的 Ingress 通过注解和规范控制 ALB 的侦听器和规则。为了在多个目标组（例如不同的 Kubernetes 服务）之间分割流量，AWS 负载均衡器控制器查看 Ingress 上的特定“操作”注解，[`alb.ingress.kubernetes.io/actions.<service-name>`](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/guide/ingress/annotations/#actions)。这个注解是通过 Rollout 自动注入和更新的，根据所需的流量权重进行更新。

## 用法

要配置 Rollout 使用 ALB 集成并在更新期间在金丝雀和稳定服务之间分割流量，请使用以下字段配置 Rollout：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
...
spec:
  strategy:
    canary:
      # canaryService 和 stableService 是对 Service 的引用，Rollout 将使用它们来指定
      # canary ReplicaSet 和 stable ReplicaSet (必填)。
      canaryService: canary-service
      stableService: stable-service
      trafficRouting:
        alb:
          # 引用的 Ingress 将被注入自定义 action annotation，指示 AWS Load Balancer Controller
          # 按照所需的流量权重在 canary 和 stable Service 之间分配流量 (必填)。
          ingress: ingress
          # Ingress 必须在其中一个规则中指向的 Service 的引用 (可选)。
          # 如果省略，使用 canary.stableService。
          rootService: root-service
          # Service 端口是 Service 监听的端口 (必填)。
          servicePort: 443
```

所引用的 Ingress 应部署具有匹配 Rollout 服务的 Ingress 规则：

```yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: ingress
  annotations:
    kubernetes.io/ingress.class: alb
spec:
  rules:
  - http:
      paths:
      - path: /*
        backend:
          # serviceName 必须匹配 canary.trafficrouting.alb.rootservice(如果指定了)，或者 canary.rootservice.stableService(如果忽略了 rootService)
          serviceName: root-service
          # servicePort 必须是 use-annotation 的值
          # 这将指示 AWS 负载平衡器控制器查看有关如何引导流量的注解
          servicePort: use-annotation
```

在更新期间，Rollout 控制器注入`alb.ingress.kubernetes.io/actions.<SERVICE-NAME>`注解，其中包含 AWS Load Balancer 控制器理解的 JSON 有效负载，指示它根据当前金丝雀权重在`canaryService`和`stableService`之间分割流量。

以下是我们的示例 Ingress 在 Rollout 注入将流量分割为金丝雀服务和稳定服务，流量权重分别为 10 和 90 的自定义操作注解后的示例：

```yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/actions.root-service: |
      {
        "Type":"forward",
        "ForwardConfig":{
          "TargetGroups":[
            {
                "Weight":10,
                "ServiceName":"canary-service",
                "ServicePort":"80"
            },
            {
                "Weight":90,
                "ServiceName":"stable-service",
                "ServicePort":"80"
            }
          ]
        }
      }
spec:
  rules:
  - http:
      paths:
      - path: /*
        backend:
          serviceName: root-service
          servicePort: use-annotation
```

🔔 注意：Argo rollouts 另外注入一个注解`rollouts.argoproj.io/managed-alb-actions`，用于记账目的。注解指示 Rollout 对象正在管理哪些操作（因为多个 Rollout 可以引用一个 Ingress）。在回滚删除时，回滚控制器查找此注解以了解此操作不再受管理，并将其重置为仅指向带有 100 权重的稳定服务。

### rootService

默认情况下，Rollout 将使用在`spec.strategy.canary.stableService`下指定的服务/操作名称在服务/操作名称下注入`alb.ingress.kubernetes.io/actions.<SERVICE-NAME>`注解。但是，可能需要指定与`stableService`不同的显式服务/操作名称。例如，one pattern 是使用包含三个不同规则以单独到达金丝雀，稳定和根服务的单个 Ingress（例如，用于测试目的）。在这种情况下，你可能希望将“根”服务指定为服务/操作名称，而不是稳定服务。要这样做，请在 alb 规范下引用`rootService`下的服务：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
spec:
  strategy:
    canary:
      canaryService: guestbook-canary
      stableService: guestbook-stable
      trafficRouting:
        alb:
          rootService: guestbook-root
...
```

### 粘性会话

因为使用至少两个目标组（金丝雀和稳定），所以目标组粘性需要额外的配置：

必须通过目标组激活粘性会话

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
spec:
  strategy:
    canary:
...
      trafficRouting:
        alb:
          stickinessConfig:
            enabled: true
            durationSeconds: 3600
...
```

有关更多信息，请参见[AWS ALB API](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/sticky-sessions.html)

### 使用 AWS TargetGroup 验证进行零停机更新

当与 AWS LoadBalancer 控制器一起使用时，Argo Rollouts 包含两个功能可帮助确保零停机更新：TargetGroup IP 验证和 TargetGroup 权重验证。这两个功能都涉及 Rollout 控制器向 AWS 执行附加的安全性检查，以验证对 Ingress 对象所做的更改是否反映在基础 AWS TargetGroup 中。

### TargetGroup IP 验证

🔔 注意：Target Group IP 验证自 Argo Rollouts v1.1 起提供

AWS 负载均衡器控制器可以运行在以下两种模式之一：

- [Instance mode](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/how-it-works/#instance-mode)
- [IP mode](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/how-it-works/#ip-mode)

当使用 AWS 负载均衡器控制器的 IP 模式（例如使用 AWS CNI）时，只有在 AWS 负载均衡器控制器处于 IP 模式时，才适用于 TargetGroup IP 验证。在 IP 模式下使用 AWS 负载均衡器控制器时，ALB 负载均衡器将目标组定位到单个 Pod IP，而不是 K8s 节点实例。针对 Pod IP 进行定位在更新期间存在更高的风险，因为来自底层 AWS TargetGroup 的 Pod IP 可以更容易地从实际可用性和 Pod 状态过时，从而导致当 TargetGroup 指向已经缩小的 Pod 时，发生 HTTP 502 错误。

为了减轻这种风险，AWS 建议在 IP 模式下运行 AWS 负载均衡器控制器时使用[pod readiness gate injection](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/deploy/pod_readiness_gate/)。Readiness gates 允许 AWS 负载均衡器控制器在将新创建的 Pod 标记为“ready”之前验证 TargetGroups 是否准确，从而防止较旧的 ReplicaSet 的过早缩小。

Pod readiness gate injection 使用一个变异的 webhook，在创建 Pod 时根据以下条件决定是否注入准备就绪的门：

- 在同一命名空间中存在与 Pod 标签匹配的服务
- 存在至少一个引用匹配的服务的目标组绑定

另一种描述这种方式的方法是：AWS 负载均衡器控制器仅在从（ALB）Ingress 到达 Pod 的情况下将就绪门注入到 Pod 中。如果（ALB）Ingress 引用与 Pod 标签匹配的服务，则将 Pod 视为可达。它忽略所有其他 Pod。

使用这种方式的一个挑战是，Service 选择器标签（`spec.selector`）的修改不允许 AWS 负载均衡器控制器注入就绪门，因为在那时 Pod 已经创建（就绪门是不可变的）。请注意，这是更改*任何*ALB 服务的服务选择器的问题，而不仅仅是 Argo Rollouts。

由于 Argo Rollout 的蓝绿策略通过在推广期间修改 activeService 选择器以指向新的 ReplicaSet 标签来工作，因此它存在一个问题，即无法注入 `spec.strategy.blueGreen.activeService` 的可读性门。这意味着在从 V1 更新到 V2 的以下问题场景中存在可能的停机时间：

1. 触发更新并增加 V2 ReplicaSet 堆栈
2. V2 ReplicaSet pods 变得完全可用并准备好进行推广
3. Rollout 通过将活动服务的标签选择器更新为指向 V2 堆栈（从 V1）来推广 V2
4. 由于未知问题（例如，AWS 负载均衡器控制器停机，AWS 速率限制），V2 Pod IP 的注册未发生或延迟。
5. V1 ReplicaSet 被缩小以完成更新

在第 5 步之后，当 V1 ReplicaSet 被缩小时，过时的 TargetGroup 仍将指向不再存在的 V1 Pods IPs，从而导致停机时间。

为了允许零停机更新，Argo Rollouts 具有执行 TargetGroup IP 验证作为更新的附加安全措施的能力。当启用此功能时，每当进行服务选择器修改时，Rollout 控制器都会阻止更新的进展，直到它可以验证 TargetGroup 正确地针对 `bluegreen.activeService` 的新 Pod IP。通过查询 AWS API 来描述底层 TargetGroup，迭代其已注册的 IP 并确保所有活动服务的 `Endpoints` 列表的 Pod IP 都在 TargetGroup 中注册，可以实现验证。验证必须在运行 postPromotionAnalysis 或缩小旧的 ReplicaSet 之前成功。

类似于金丝雀策略，在将 `canary.stableService` 选择器标签更新为指向新的 ReplicaSet 后，TargetGroup IP 验证功能允许控制器阻止缩小旧的 ReplicaSet，直到它验证稳定服务 TargetGroup 后面的 Pod IP 是否准确。

### TargetGroup 权重验证

🔔 注意：TargetGroup 权重验证自 Argo Rollouts v1.0 起可用

TargetGroup 重量验证解决了与 TargetGroup IP 验证类似的问题，但是与验证服务的 Pod IPs 是否准确反映在 TargetGroup 中不同，控制器验证流量 *权重* 是否与 ingress 注解中设置的权重相同。权重验证适用于以 IP 模式或实例模式运行的 AWS 负载均衡器控制器。

在 Argo Rollouts 通过更新 Ingress 注解调整金丝雀权重后，它会进入下一步。但是，由于外部因素（例如，AWS 速率限制，AWS 负载均衡器控制器停机），在底层 TargetGroup 中可能未能生效对 Ingress 的权重修改。这是潜在的危险，因为控制器将相信安全地缩小旧的稳定堆栈，而实际上过时的 TargetGroup 可能仍然指向它。

使用 TargetGroup 重量验证功能，滚动控制器将在 `setWeight` 金丝雀步骤后*验证*金丝雀权重。它通过直接查询 AWS LoadBalancer APIs 来实现此目的，以确认规则、操作和 TargetGroups 是否反映了 Ingress 注解的期望。

### 用法

要启用 AWS 目标组验证，请将 `--aws-verify-target-group` 标志添加到 rollout-controller 标志中：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: argo-rollouts
spec:
  template:
    spec:
      containers:
      - name: argo-rollouts
        args: [--aws-verify-target-group]
        # 注意：在 v1.0 中，应该使用 ——alb-verify-weight 标志
```

要使此功能正常工作，argo-rollouts 部署需要在以下 [弹性负载平衡 API](https://docs.aws.amazon.com/elasticloadbalancing/latest/APIReference/Welcome.html) 下拥有以下 AWS API 权限：


```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeListeners",
                "elasticloadbalancing:DescribeRules",
                "elasticloadbalancing:DescribeTags",
                "elasticloadbalancing:DescribeTargetHealth"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
```

授予 AWS 权限的各种方法高度取决于你的集群 AWS 环境，并且超出了本文档的范围。一些解决方案包括：

- AWS 访问和秘密密钥
- [kiam](https://github.com/uswitch/kiam)
- [kube2iam](https://github.com/jtblin/kube2iam)
- [EKS ServiceAccount IAM 角色](https://docs.aws.amazon.com/eks/latest/userguide/specify-service-account-role.html)

### Ping-Pong 功能实现零停机更新

上面介绍了 AWS 推荐的解决零停机问题的方法。是在 IP 模式下运行 AWS LoadBalancer 时使用 [pod readiness gate injection](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/deploy/pod_readiness_gate/)。这种方法存在问题，即服务选择器标签 (`spec.selector`) 的修改不允许 AWS LoadBalancer 控制器突变就绪门。Ping-Pong 功能有助于解决这个问题。在某个特定时刻，其中一个服务（例如 ping）“戴着稳定的一顶帽子”，另一个服务（例如 pong）则“戴着金丝雀的一顶帽子”。在推广步骤结束时，所有流量的 100％ 发送到“金丝雀”（例如 pong）。然后，Rollout 交换了 ping 和 pong 服务的帽子，使 pong 成为稳定的。Rollout 状态对象保存当前稳定的 ping 或 pong 的值 (`status.canary.currentPingPong`)。这种方法允许 rollout 使用 pod readiness gate injection，因为服务在 rollout 进度结束时不会更改其标签。

🔔 重要提醒：Ping-Pong 功能自 Argo Rollouts v1.2 起可用

## 示例

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: example-rollout
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.15.4
        ports:
        - containerPort: 80
  strategy:
    canary:
      pingPong: #Indicates that the ping-pong services enabled
        pingService: ping-service
        pongService: pong-service
      trafficRouting:
        alb:
          ingress: alb-ingress
          servicePort: 80
      steps:
      - setWeight: 20
      - pause: {}
```

### 自定义注解前缀

AWS 负载平衡器控制器允许用户使用控制器的标志 `--annotations-prefix` 来自定义 [注解前缀](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/guide/ingress/annotations/#ingress-annotations)。如果你的 AWS 负载均衡器控制器已自定义以使用不同的注解前缀，那么应该指定 `annotationPrefix` 字段，以便 Ingress 对象以集群的 aws 负载平衡器控制器能够理解的方式进行注解。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
spec:
  strategy:
    canary:
      trafficRouting:
        alb:
          annotationPrefix: custom.alb.ingress.kubernetes.io
```

### 自定义 Ingress 类

默认情况下，Argo Rollout 将在具有注解的 Ingress 上运行：

```yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: alb
```

或者使用 `ingressClassName`：

```yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
spec:
  ingressClassName: alb
```

要配置控制器以在具有不同类名的 Ingress 上运行，可以通过控制器命令行参数中的 `--alb-ingress-classes` 标志指定不同的值。

请注意，如果 Argo Rollouts 控制器应在没有 `kubernetes.io/ingress.class` 或 `spec.ingressClassName` 的任何 Ingress 上运行，则可以使用空字符串（例如 `--alb-ingress-classes ''`）指定该标志。
