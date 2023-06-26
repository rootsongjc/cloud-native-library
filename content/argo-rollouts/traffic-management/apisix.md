---
weight: 3
title: "Apache APISIX"
linkTitle: "APISIX"
date: '2023-06-21T16:00:00+08:00'
type: book
tags: ["APISIX","Argo Rollouts"]
---

你可以使用 [Apache APISIX](https://apisix.apache.org/) 和 [Apache APISIX Ingress Controller](https://apisix.apache.org/docs/ingress-controller/getting-started/) 来进行 Argo Rollouts 的流量管理。

当使用 Apache APISIX Ingress Controller 作为 Ingress 时，[ApisixRoute](https://apisix.apache.org/docs/ingress-controller/concepts/apisix_route/) 是支持 [基于权重的流量分流](https://apisix.apache.org/docs/ingress-controller/concepts/apisix_route/#weight-based-traffic-split) 的对象。

本指南展示了如何将 ApisixRoute 与 Argo Rollouts 集成，以将其用作加权轮询负载均衡器。

## 先决条件

Argo Rollouts 需要 Apache APISIX v2.15 或更新版本以及 Apache APISIX Ingress Controller v1.5.0 或更新版本。

使用 Helm v3 安装 Apache APISIX 和 Apache APISIX Ingress Controller：

```bash
helm repo add apisix https://charts.apiseven.com
kubectl create ns apisix

helm upgrade -i apisix apisix/apisix --version=0.11.3 \
--namespace apisix \
--set ingress-controller.enabled=true \
--set ingress-controller.config.apisix.serviceNamespace=apisix
```

## 引导

首先，我们需要使用其加权轮询负载平衡功能创建 ApisixRoute 对象。

```yaml
apiVersion: apisix.apache.org/v2
kind: ApisixRoute
metadata:
  name: rollouts-apisix-route
spec:
  http:
    - name: rollouts-apisix
      match:
        paths:
          - /*
        hosts:
          - rollouts-demo.apisix.local
      backends:
        - serviceName: rollout-apisix-canary-stable
          servicePort: 80
        - serviceName: rollout-apisix-canary-canary
          servicePort: 80
```

```bash
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-rollouts/master/examples/apisix/route.yaml
```

请注意，我们不指定 `weight` 字段。它需要与 ArgoCD 同步。如果我们指定此字段并且 Argo Rollouts 控制器更改它，则 ArgoCD 控制器将注意到它并显示此资源不同步（如果你正在使用 Argo CD 管理你的 Rollout）。

其次，我们需要创建 Argo Rollouts 对象。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: rollout-apisix-canary
spec:
  replicas: 5
  strategy:
    canary:
      canaryService: rollout-apisix-canary-canary
      stableService: rollout-apisix-canary-stable
      trafficRouting:
        managedRoutes:
          - name: set-header
        apisix:
          route:
            name: rollouts-apisix-route
            rules:
              - rollouts-apisix
      steps:
        - setCanaryScale:
            replicas: 1
          setHeaderRoute:
            match:
              - headerName: trace
                headerValue:
                  exact: debug
            name: set-header
        - setWeight: 20
        - pause: {}
        - setWeight: 40
        - pause:
            duration: 15
        - setWeight: 60
        - pause:
            duration: 15
        - setWeight: 80
        - pause:
            duration: 15
  revisionHistoryLimit: 2
  selector:
    matchLabels:
      app: rollout-apisix-canary
  template:
    metadata:
      labels:
        app: rollout-apisix-canary
    spec:
      containers:
        - name: rollout-apisix-canary
          image: argoproj/rollouts-demo:blue
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
          resources:
            requests:
              memory: 32Mi
              cpu: 5m
```

```bash
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-rollouts/master/examples/apisix/rollout.yaml
```

最后，我们需要为 Argo Rollouts 对象创建服务。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: rollout-apisix-canary-canary
spec:
  ports:
    - port: 80
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app: rollout-apisix-canary
   # 此选择器将更新为 canary ReplicaSet 的 pod-template-hash，例如：
   # rollouts-pod-template-hash: 7bf84f9696
---
apiVersion: v1
kind: Service
metadata:
  name: rollout-apisix-canary-stable
spec:
  ports:
    - port: 80
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app: rollout-apisix-canary
   # 此选择器将更新为 stable ReplicaSet 的 pod-template-hash，例如：
   # rollouts-pod-template-hash: 789746c88d
```

```bash
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-rollouts/master/examples/apisix/services.yaml
```

任何 Rollout 的初始创建将立即将副本扩展到 100%（跳过任何金丝雀升级步骤、分析等等），因为没有发生任何升级。

Argo Rollouts kubectl 插件允许你可视化 Rollout、其相关资源（ReplicaSets、Pods、AnalysisRuns）并呈现状态更改。要在部署过程中观察 Rollout，请从插件中运行 `get rollout --watch` 命令：

```bash
kubectl argo rollouts get rollout rollout-apisix-canary --watch
```

## 更新 Rollout

接下来是执行更新的时候。与 Deployments 一样，对 Pod 模板字段（`spec.template`）的任何更改都会导致部署新版本（即 ReplicaSet）。更新 Rollout 包括修改 rollout spec，通常是使用新版本更改容器镜像字段，然后针对新清单运行 `kubectl apply`。作为方便起见，rollouts 插件提供了一个 `set image` 命令，它针对现场的 rollout 对象执行这些步骤。运行以下命令，将 `rollout-apisix-canary` Rollout 更新为容器的 "yellow" 版本：

```bash
kubectl argo rollouts set image rollout-apisix-canary rollouts-demo=argoproj/rollouts-demo:yellow
```

在升级期间，控制器将按照 Rollout 的更新策略进行进展。示例 Rollout 将将 20% 的流量权重分配给 canary，并无限期地暂停 Rollout，直到执行用户操作以取消暂停/升级 Rollout。

你可以通过以下命令检查 ApisixRoute 的后端权重：

```bash
kubectl describe apisixroute rollouts-apisix-route

......
Spec:
  Http:
    Backends:
      Service Name:  rollout-apisix-canary-stable
      Service Port:  80
      Weight:        80
      Service Name:  rollout-apisix-canary-canary
      Service Port:  80
      Weight:        20
......
```

`rollout-apisix-canary-canary` 服务通过 Apache APISIX 获得 20% 的流量。

你可以通过以下命令检查 SetHeader ApisixRoute 的匹配：

```bash
kubectl describe apisixroute set-header

......
Spec:
  Http:
    Backends:
      Service Name:  rollout-apisix-canary-canary
      Service Port:  80
      Weight:        100
    Match:
      Exprs:
        Op:  Equal
        Subject:
          Name:   trace
          Scope:  Header
        Value:    debug
......
```
