---
weight: 5
title: "Istio"
date: '2023-06-21T16:00:00+08:00'
type: book
tags: ["Istio","Argo Rollouts"]
---

[Istio](https://istio.io/) 是一种服务网格，通过一组 CRD 提供了丰富的功能集，用于控制流向 Web 服务的流量。Istio 通过调整 [Istio VirtualService](https://istio.io/latest/docs/reference/config/networking/virtual-service/) 中定义的流量权重来实现此功能。使用 Argo Rollouts 时，用户可以部署包含至少一个 [HTTP 路由](https://istio.io/latest/docs/reference/config/networking/virtual-service/#HTTPRoute) 的 VirtualService，其中包含两个 [HTTP 路由目标](https://istio.io/latest/docs/reference/config/networking/virtual-service/#HTTPRouteDestination)：一个路由目标针对金丝雀 ReplicaSet 的 pod，一个路由目标针对稳定 ReplicaSet 的 pod。Istio 提供了两种带权流量分割方法，这两种方法都可以作为 Argo Rollouts 的选项。

1. 主机级流量分割
2. 子集级流量分割

## 主机级流量分割

使用 Argo Rollouts 和 Istio 进行流量分割的第一种方法是在两个主机名或 Kubernetes Service 之间进行分割：一个金丝雀 Service 和一个稳定 Service。这种方法类似于所有其他 Argo Rollouts mesh/ingress-controller 集成方式的工作方式（例如 ALB、SMI、Nginx）。使用此方法，用户需要部署以下资源：

- Rollout
- Service（金丝雀）
- Service（稳定）
- VirtualService

Rollout 应定义以下字段：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: rollout-example
spec:
  ...
  strategy:
    canary:
      canaryService: canary-svc  # 必需
      stableService: stable-svc  # 必需
      trafficRouting:
        istio:
          virtualService:
            name: rollout-vsvc   # 必需
            routes:
            - primary            # 如果 VirtualService 中只有一条路由，则为可选，否则为必需
      steps:
      - setWeight: 5
      - pause:
          duration: 10m
```

VirtualService 必须包含一个 HTTP 路由，其名称在 Rollout 中引用，包含两个路由目标，其 `host` 值与 Rollout 中引用的 `canaryService` 和 `stableService` 匹配。如果 VirtualService 定义在与 rollout 不同的命名空间中，则其名称应为 `rollout-vsvc.<vsvc 命名空间名称>`。请注意，Istio 要求所有权重总和为 100，因此初始权重可以是 100％ 的稳定和 0％ 的金丝雀。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: rollout-vsvc
spec:
  gateways:
  - istio-rollout-gateway
  hosts:
  - istio-rollout.dev.argoproj.io
  http:
  - name: primary        # 在 canary.trafficRouting.istio.virtualService.routes 中被引用
    route:
    - destination:
        host: stable-svc # 在 canary.stableService 中被引用
      weight: 100
    - destination:
        host: canary-svc # 在 canary.canaryService 中被引用
      weight: 0
```

最后，应部署金丝雀和稳定的 Service。这些 Service 的选择器将在更新期间由 Rollout 修改，以对齐金丝雀和稳定 ReplicaSet pod。请注意，如果 VirtualService 和目标主机位于不同的命名空间中（例如，VirtualService 和 Rollout 不在同一命名空间中），则应在目标主机中包含命名空间（例如，`stable-svc.<namespace>`）。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: canary-svc
spec:
  ports:
  - port: 80
    targetPort: http
    protocol: TCP
    name: http
  selector:
    app: rollouts-demo
    # 这个选择器将使用 canary ReplicaSet 的pod-template-hash进行更新。例如：rollouts-pod-template-hash: 7bf84f9696
---
apiVersion: v1
kind: Service
metadata:
  name: stable-svc
spec:
  ports:
  - port: 80
    targetPort: http
    protocol: TCP
    name: http
  selector:
    app: rollouts-demo
    # 这个选择器将使用 stable ReplicaSet 的pod-template-hash进行更新。例如：rollouts-pod-template-hash: 123746c88d
```

在 Rollout 更新的生命周期中，Argo Rollouts 将不断地：

- 修改金丝雀 Service `spec.selector`，以包含金丝雀 ReplicaSet 的 `rollouts-pod-template-hash` 标签
- 修改稳定 Service `spec.selector`，以包含稳定 ReplicaSet 的 `rollouts-pod-template-hash` 标签
- 修改 VirtualService `spec.http[].route[].weight`，以匹配当前所需的金丝雀权重

🔔 注意：Rollout 不会对 VirtualService 或 Istio 网络中的其他字段做出任何假设。如果需要，用户可以为 VirtualService 指定其他配置，例如主要路由或任何其他路由的 URI 重写规则。用户还可以为每个服务创建特定的 DestinationRules。

## 子集级流量分割

🔔 重要提示：自 v1.0 起可用。

使用 Argo Rollouts 和 Istio 进行流量分割的第二种方法是在两个 Istio [DestinationRule Subsets](https://istio.io/latest/docs/reference/config/networking/destination-rule/#Subset) 之间进行分割：一个金丝雀子集和一个稳定子集。在按 DestinationRule 子集进行拆分时，需要用户部署以下资源：

- Rollout
- Service
- VirtualService
- DestinationRule

Rollout 应定义以下字段：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: rollout-example
spec:
  ...
  strategy:
    canary:
      trafficRouting:
        istio:
          virtualService:
            name: rollout-vsvc        # 必需
            routes:
            - primary                 # 如果 VirtualService 中只有一条路由，则为可选，否则为必需
          destinationRule:
            name: rollout-destrule    # 必需
            canarySubsetName: canary  # 必需
            stableSubsetName: stable  # 必需
      steps:
      - setWeight: 5
      - pause:
          duration: 10m
```

应定义一个服务，该服务针对 Rollout pods。请注意，与第一种方法不同，在第一种方法中，流量拆分针对多个 Service，这些 Service 被修改为包含金丝雀/稳定 ReplicaSets 的 rollout-pod-template-hash，而此 Service 不会被 rollout 控制器修改。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: rollout-example
spec:
  ports:
  - port: 80
    targetPort: http
    protocol: TCP
    name: http
  selector:
    app: rollout-example
```

VirtualService 必须包含一个 HTTP 路由，其名称在 Rollout 中引用，包含两个路由目标，其 `subset` 值与 Rollout 中引用的 `canarySubsetName` 和 `stableSubsetName` 匹配。请注意，Istio 要求所有权重总和为 100，因此初始权重可以是 100％ 的稳定和 0％ 的金丝雀。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: rollout-vsvc
spec:
  gateways:
  - istio-rollout-gateway
  hosts:
  - istio-rollout.dev.argoproj.io
  http:
  - name: primary       # 在 canary.trafficRouting.istio.virtualService.routes 中被引用
    route:
    - destination:
        host: rollout-example
        subset: stable  # 在 canary.trafficRouting.istio.destinationRule.stableSubsetName 中被引用
      weight: 100
    - destination:
        host: rollout-example
        subset: canary  # 在 canary.trafficRouting.istio.destinationRule.canarySubsetName 中被引用
      weight: 0
```

最后，包含在 Rollout 中引用的金丝雀和稳定子集的 DestinationRule。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: rollout-destrule
spec:
  host: rollout-example
  subsets:
  - name: canary   # 在 canary.trafficRouting.istio.destinationRule.canarySubsetName 中引用
    labels:        # 标签将注入 canary 部署的 pod 模板哈希值
      app: rollout-example
  - name: stable   # 在 canary.trafficRouting.istio.destinationRule.stableSubsetName 中引用
    labels:        # 标签将注入 stable 部署的 pod 模板哈希值
      app: rollout-example
```

在使用 Istio DestinationRule 的 Rollout 生命周期中，Argo Rollouts 将不断地：

- 修改 VirtualService `spec.http[].route[].weight`，以匹配当前所需的金丝雀权重
- 修改 DestinationRule `spec.subsets[].labels`，以包含金丝雀和稳定 ReplicaSets 的 `rollouts-pod-template-hash` 标签

## TCP 流量分割

🔔 重要提示：自 v1.2.2 起可用。

支持拆分 TCP 流量，并要求 Rollout 定义以下字段：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: rollout-example
spec:
  ...
  strategy:
    canary:
      canaryService: canary-svc  # 必需
      stableService: stable-svc  # 必需
      trafficRouting:
        istio:
          virtualService:
            name: rollout-vsvc   # 必需
            tcpRoutes:
              # 下面的字段是可选的，但如果定义了，必须与 VirtualService 中至少一个 TCP 路由匹配规则完全匹配
              - port: 3000 # 仅在你想匹配包含此端口的 VirtualService 中的任何规则时才需要
      steps:
      - setWeight: 5
      - pause:
          duration: 10m
```

VirtualService 必须包含与 Rollout 中引用的匹配端口的 TCP 路由：

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: rollout-vsvc
spec:
  gateways:
    - istio-rollout-gateway
  hosts:
    - istio-rollout.dev.argoproj.io
  tcp:
    - match:
        - port: 3000
      route:
        - destination:
            host: stable-svc # 在 canary.stableService 中引用
          weight: 100
        - destination:
            host: canary-svc # 在 canary.canaryService 中引用
          weight: 0
```

## 多集群设置

如果你有 [Istio 多集群设置](https://istio.io/latest/docs/setup/install/multicluster/)，其中主 Istio 集群不同于运行 Argo Rollout 控制器的集群，则需要执行以下设置：

1. 在 Istio 主集群中创建一个 `ServiceAccount`。

   ```yaml
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: argo-rollouts-istio-primary
     namespace: <any-namespace-preferrably-config-namespace>
   ```

2. 创建一个 `ClusterRole`，为 Istio 主集群中的 Rollout 控制器提供访问权限。

   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRole
   metadata:
     name: argo-rollouts-istio-primary
   rules:
   - apiGroups:
     - networking.istio.io
     resources:
     - virtualservices
     - destinationrules
     verbs:
     - get
     - list
     - watch
     - update
     - patch
   ```

   注意：如果 Argo Rollout 控制器也安装在 Istio 主集群中，则可以重用 argo-rollouts-clusterrole ClusterRole，而无需创建新的 ClusterRole。

3. 将 `ClusterRole` 与 Istio 主集群中的 `ServiceAccount` 进行连接。

   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRoleBinding
   metadata:
     name: argo-rollouts-istio-primary
   roleRef:
     apiGroup: rbac.authorization.k8s.io
     kind: ClusterRole
     name: argo-rollouts-istio-primary
   subjects:
   - kind: ServiceAccount
     name: argo-rollouts-istio-primary
     namespace: <namespace-of-the-service-account>
   ```

4. 现在，使用以下命令为 Rollout 控制器生成一个密钥，以便访问 Istio 主集群。该密钥将应用于运行 Argo Rollout 的集群（即，Istio 远程集群），但将从 Istio 主集群生成。此秘密可以在第 1 步之后立即生成，只需要 `ServiceAccount` 存在即可。[命令的参考](https://istio.io/latest/docs/reference/commands/istioctl/#istioctl-experimental-create-remote-secret)。

   ```bash
   istioctl x create-remote-secret --type remote --name <cluster-name> \
       --namespace <namespace-of-the-service-account> \
       --service-account <service-account-created-in-step1> \
       --context="<ISTIO_PRIMARY_CLUSTER>" | \
       kubectl apply -f - --context="<ARGO_ROLLOUT_CLUSTER/ISTIO_REMOTE_CLUSTER>"
   ```

5. 标记密钥。

   ```bash
   kubectl label secret <istio-remote-secret> istio.argoproj.io/primary-cluster="true" -n <namespace-of-the-secret>
   ```

## 方法比较

主机级流量分割与子集级流量分割存在一些优缺点。

### DNS 要求

使用主机级分割时，VirtualService 需要不同的 `host` 值以在两个目标之间进行拆分。但是，使用两个主机值意味着需要使用不同的 DNS 名称（一个用于金丝雀，另一个用于稳定）。对于北南流量，该流量通过 Istio 网关到达服务，使用多个 DNS 名称以访问金丝雀与稳定 pod 可能无关紧要。但是，对于东西向或集群内流量，它会强制微服务通信选择是要命中稳定还是金丝雀 DNS 名称，是否要通过网关，或者是否要为 VirtualServices 添加 DNS 条目。在这种情况下，DestinationRule 子集流量分割将是集群内金丝雀的更好选择。

### 指标

根据选择主机级分割还是子集级分割，将有不同风格的 prometheus 指标可用。例如，如果使用主机级分割，则金丝雀与稳定的度量将出现在 Istio 服务度量仪表板中：

![Istio 服务度量指标](istio-service-metrics.png)

另一方面，当通过子集进行拆分时，需要使用不同的参数查询 Prometheus，例如工作负载名称：

![Istio 工作负载指标](istio-workload-metrics.png)

## 与 GitOps 集成

之前已经解释了 VirtualService 应该使用初始金丝雀和稳定权重为 0 和 100 进行部署，例如以下示例：

```yaml
  http:
  - name: primary
    route:
    - destination:
        host: stable-svc
      weight: 100
    - destination:
        host: canary-svc
      weight: 0
```

这会给 GitOps 练习的用户带来问题。由于 Rollout 将在其步骤中修改这些 VirtualService 权重，因此不幸的是会导致 VirtualService 与 git 版本不同步。此外，如果在 Rollout 处于此状态（在服务之间分流流量）时应用 git 中的 VirtualService，则应用将将权重恢复为 git 中的值（即 100 至 stable，0 至金丝雀）。

在 Argo Rollouts 中实现的一种保护是，它不断地监视管理的 VirtualService 的更改。如果使用 git 中的 VirtualService 进行 `kubectl apply`，则 Rollout 控制器会立即检测到更改，并立即将 VirtualService 权重设置回适用于 Rollout 给定步骤的金丝雀权重。但是由于权重的瞬时抖动，应该了解这种行为。

在使用 Argo CD 与 Argo Rollouts 时遵循的一些最佳实践，以防止出现此行为，是利用以下 Argo CD 功能：

1. 配置应用程序以忽略 VirtualService 中的差异。例如：

   ```yaml
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: guestbook
   spec:
     ignoreDifferences:
     - group: networking.istio.io
       kind: VirtualService
       jsonPointers:
       - /spec/http/0
   ```

   忽略 VirtualServices 的 HTTP 路由中的差异，防止 gitops 差异在 VirtualService HTTP 路由中对 Argo CD 应用程序的总同步状态产生影响。这增加了一个额外的好处，可以防止触发自动同步操作。

2. 将应用程序配置为仅应用 OutOfSync 资源：

   ```yaml
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: guestbook
   spec:
     syncPolicy:
       syncOptions:
       - ApplyOutOfSyncOnly=true
   ```

   默认情况下，当 Argo CD 同步应用程序时，它会对与应用程序相关的 git 中的所有资源运行 `kubectl apply`。 `ApplyOutOfSyncOnly=true` 同步选项指示 Argo CD 跳过已经认为是“同步”的资源应用，仅应用“OutOfSync”的资源。当与 `ignoreDifferences` 功能一起使用时，提供了一种管理 Argo CD 和 Argo Rollouts 之间 VirtualService 所需状态冲突的方法。

Argo CD 还有一个[开放问题](https://github.com/argoproj/argo-cd/issues/2913)，它将有助于解决此问题。拟议的解决方案是在资源中引入注释，指示 Argo CD 尊重并保留指定路径中的差异，以允许其他控制器（例如 Argo Rollouts）管理它们。

## 考虑的替代方案

### Rollout 对 Virtual Service 的所有权

早期的设计替代方案是，控制器不修改所引用的 VirtualService，而是 Rollout 控制器将创建、管理和拥有 Virtual Service。虽然这种方法对 GitOps 友好，但它引入了其他问题：

- 为了提供与 Rollout 引用 VirtualService 相同的灵活性，Rollout 需要内联 Istio 规范的大部分内容。网络是 Rollout 的责任范畴之外，使 Rollout 规范变得不必要地复杂。
- 如果 Istio 引入了一项功能，则该功能在 Argo Rollouts 中将不可用，直到在 Argo Rollouts 中实现。

与引用 Virtual Service 相比，这两个问题为用户和 Argo Rollouts 开发人员增加了更多的复杂性。

### 通过 [SMI Adapter for Istio](https://github.com/servicemeshinterface/smi-adapter-istio) 支持 Istio

[SMI](https://smi-spec.io/) 是服务网格接口，它作为服务网格所有常见特性的标准接口。该功能对 GitOps 友好，但原生 Istio 具有 SMI 目前不提供的额外功能。
