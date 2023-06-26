---
weight: 13
linkTitle: "迁移到 Rollouts"
title: "迁移到 Rollouts"
date: '2023-06-21T16:00:00+08:00'
type: book
---

有两种方法可以迁移到 Rollout：

- 将现有的 Deployment 资源转换为 Rollout 资源。
- 使用 `workloadRef` 字段从 Rollout 引用现有的 Deployment。

## 将 Deployment 转换为 Rollout

将 Deployment 转换为 Rollout 时，需要更改三个字段：

1. 将 `apiVersion` 从 `apps/v1` 更改为 `argoproj.io/v1alpha1`
2. 将 `kind` 从 `Deployment` 更改为 `Rollout`
3. 使用蓝绿或金丝雀策略替换部署策略

以下是使用金丝雀策略的 Rollout 资源示例。

```yaml
 apiVersion: argoproj.io/v1alpha1  # 从 apps/v1 更改而来
 kind: Rollout                     # 从 Deployment 更改而来
 metadata:
   name: rollouts-demo
 spec:
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
         ports:
         - containerPort: 8080
   strategy:
     canary:                        # 从 rollingUpdate 或 recreate 更改而来
       steps:
       - setWeight: 20
       - pause: {}
```

🔔 注意：在迁移已经提供实时生产流量的 Deployment 时，应先在 Deployment 旁边运行 Rollout，然后再删除 Deployment 或缩小 Deployment。 不遵循此方法可能导致停机。这也允许在删除原始部署之前测试 Rollout。

## 从 Rollout 引用 Deployment

不要删除 Deployment，而是将其缩小为零，并从 Rollout 资源中引用它：

1. 创建一个 Rollout 资源。
2. 使用 `workloadRef` 字段引用现有的 Deployment。
3. 通过更改现有 Deployment 的 `replicas` 字段将现有 Deployment 缩小为零。
4. 要执行更新，应更改 Deployment 的 Pod 模板字段。

以下是引用 Deployment 的 Rollout 资源示例。

```yaml
 apiVersion: argoproj.io/v1alpha1               # 创建一个 rollout 资源
 kind: Rollout
 metadata:
   name: rollout-ref-deployment
 spec:
   replicas: 5
   selector:
     matchLabels:
       app: rollout-ref-deployment
   workloadRef:                                 # 使用 workloadRef 字段引用现有的 Deployment
     apiVersion: apps/v1
     kind: Deployment
     name: rollout-ref-deployment
   strategy:
     canary:
       steps:
         - setWeight: 20
         - pause: {duration: 10s}
 ---
 apiVersion: apps/v1
 kind: Deployment
 metadata:
   labels:
     app.kubernetes.io/instance: rollout-canary
   name: rollout-ref-deployment
 spec:
   replicas: 0                                  # 缩小现有部署
   selector:
     matchLabels:
       app: rollout-ref-deployment
   template:
     metadata:
       labels:
         app: rollout-ref-deployment
     spec:
       containers:
         - name: rollouts-demo
           image: argoproj/rollouts-demo:blue
           imagePullPolicy: Always
           ports:
             - containerPort: 8080
```

如果你的 Deployment 在生产中运行，请考虑以下内容：

### 同时运行 Rollout 和 Deployment

创建 Rollout 后，它会与 Deployment Pod 并排启动所需数量的 Pod。Rollout 不会尝试管理现有的 Deployment Pod。这意味着你可以安全地将 Rollout 添加到生产环境中而不会中断任何操作，但是在迁移期间会运行两倍的 Pod。

Argo-rollouts 控制器使用注释 `rollout.argoproj.io/workload-generation` 对 Rollout 对象的 spec 进行修补，该注释等于引用部署的生成。用户可以通过检查 Rollout 状态中的`workloadObservedGeneration`来检测 Rollout 是否与所需的部署生成匹配。

### 迁移期间的流量管理

Rollout 提供流量管理功能，可管理路由规则并将流量流向应用程序的不同版本。例如，蓝绿部署策略操纵 Kubernetes 服务选择器并仅将生产流量定向到“绿色”实例。

如果你正在使用此功能，则 Rollout 将切换生产流量到其管理的 Pod。切换发生 仅在所需数量的 Pod 正在运行且健康时才会发生，因此在生产环境中是安全的。然而，如果你 想要更加小心，请考虑创建一个临时的 Service 或 Ingress 对象来验证 Rollout 行为。一旦完成测试，删除临时 Service / Ingress 并将 Rollout 切换到生产模式。

# 迁移到部署

如果用户想要回滚到从 Rollout 到部署类型，那么与 Migrating to Rollouts 中的情况相一致，有两种情况。

- 将 Rollout 资源转换为 Deployment 资源。
- 使用 `workloadRef` 字段从 Rollout 引用现有的 Deployment。

## 将 Rollout 转换为 Deployment

将 Rollout 转换为 Deployment 时，需要更改三个字段：

1. [将 apiVersion 从 argoproj.io/v1alpha1 更改为 apps/v1](http://xn--apiversionargoproj-o642ao74q.io/v1alpha1更改为apps/v1)
2. 将 kind 从 Rollout 更改为 Deployment
3. 在 `spec.strategy.canary` 或 `spec.strategy.blueGreen` 中删除 Rollout 策略

🔔 注意：在迁移已经提供实时生产流量的 Rollout 时，应先在 Rollout 旁边运行 Deployment，然后再删除 Rollout 或缩小 Rollout。 不遵循此方法可能导致停机。这也允许在删除原始 Rollout 之前测试 Deployment。

## 从 Rollout 引用 Deployment

当 Rollout 引用部署时：

1. 通过将其 `replicas` 字段更改为所需的 Pod 数来增加现有的 Deployment。
2. 等待 Deployment Pod 变为 Ready。
3. 通过将其 `replicas` 字段更改为零来缩小现有 Rollout。

请参见同时运行 Rollout 和 Deployment 和迁移期间的流量管理以获取注意事项。
