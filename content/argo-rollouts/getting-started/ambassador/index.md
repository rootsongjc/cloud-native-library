---
weight: 2
title: Argo Rollouts 和 Ambassador 快速开始
linktitle: Ambassador
date: '2023-06-21T16:00:00+08:00'
type: book
tags: ["Ambassador","Argo Rollouts"]
---

本教程将指导你如何配置 Argo Rollouts 与 Ambassador 配合以实现金丝雀发布。本指南中使用的所有文件都可在此存储库的 [examples](https://github.com/argoproj/argo-rollouts/blob/master/examples/ambassador) 目录中找到。

## 要求

- Kubernetes 集群
- 在集群中安装 Argo-Rollouts

------

**注意**

如果使用 Ambassador Edge Stack 或 Emissary-ingress 2.0+，则需要安装 Argo-Rollouts 版本 v1.1+，并需要向 `argo-rollouts` 部署提供 `--ambassador-api-version getambassador.io/v3alpha1`。

## 1. 安装和配置 Ambassador Edge Stack

如果你的集群中没有 Ambassador，可以按照 [Edge Stack 文档](https://www.getambassador.io/docs/latest/topics/install/) 进行安装。

默认情况下，Edge Stack 通过 Kubernetes 服务路由。为了获得更好的金丝雀性能，我们建议你使用端点路由。通过将以下配置保存在名为 `resolver.yaml` 的文件中，启用群集上的端点路由：

```yaml
 apiVersion: getambassador.io/v2
 kind: KubernetesEndpointResolver
 metadata:
   name: endpoint
```

将此配置应用于你的集群：`kubectl apply -f resolver.yaml`。

## 2. 创建 Kubernetes 服务

我们将创建两个 Kubernetes 服务，分别命名为 `echo-stable` 和 `echo-canary`。将此配置保存到名为 `echo-service.yaml` 的文件中。

```yaml
 apiVersion: v1
 kind: Service
 metadata:
   labels:
     app: echo
   name: echo-stable
 spec:
   type: ClusterIP
   ports:
   - name: http
     port: 80
     protocol: TCP
     targetPort: 8080
   selector:
     app: echo
 ---
 apiVersion: v1
 kind: Service
 metadata:
   labels:
     app: echo
   name: echo-canary
 spec:
   type: ClusterIP
   ports:
   - name: http
     port: 80
     protocol: TCP
     targetPort: 8080
   selector:
     app: echo
```

我们还将为服务创建 Edge Stack 路由。将以下配置保存到名为 `echo-mapping.yaml` 的文件中。

```yaml
 apiVersion: getambassador.io/v2
 kind:  Mapping
 metadata:
   name:  echo
 spec:
   prefix: /echo
   rewrite: /echo
   service: echo-stable:80
   resolver: endpoint
```

将这两个配置都应用于 Kubernetes 集群：

```bash
 kubectl apply -f echo-service.yaml
 kubectl apply -f echo-mapping.yaml
```

## 3. 部署 Echo 服务

创建一个 Rollout 资源并将其保存到名为 `rollout.yaml` 的文件中。注意 `trafficRouting` 属性，它告诉 Argo 使用 Ambassador Edge Stack 进行路由。

```yaml
 apiVersion: argoproj.io/v1alpha1
 kind: Rollout
 metadata:
   name: echo-rollout
 spec:
   selector:
     matchLabels:
       app: echo
   template:
     metadata:
       labels:
         app: echo
     spec:
       containers:
         - image: hashicorp/http-echo
           args:
             - "-text=VERSION 1"
             - -listen=:8080
           imagePullPolicy: Always
           name: echo-v1
           ports:
             - containerPort: 8080
   strategy:
     canary:
       stableService: echo-stable
       canaryService: echo-canary
       trafficRouting:
         ambassador:
           mappings:
             - echo
       steps:
       - setWeight: 30
       - pause: {duration: 30s}
       - setWeight: 60
       - pause: {duration: 30s}
       - setWeight: 100
       - pause: {duration: 10}
```

将 Rollout 应用于你的集群 `kubectl apply -f rollout.yaml`。注意，由于这是部署的服务的第一个版本，因此不会进行金丝雀部署。

## 4. 测试服务

现在，我们将测试此部署是否按预期工作。打开一个新的终端窗口。我们将使用它来发送请求到群集。获取 Edge Stack 的外部 IP 地址：

```bash
 export AMBASSADOR_LB_ENDPOINT=$(kubectl -n ambassador get svc ambassador -o "go-template={{range .status.loadBalancer.ingress}}{{or .ip .hostname}}{{end}}")
```

发送请求到 `echo` 服务：

```bash
 curl -Lk "https://$AMBASSADOR_LB_ENDPOINT/echo/"
```

你应该会得到一个 "VERSION 1" 的响应。

## 5. 部署新版本

现在是时候部署服务的新版本了。将 `rollout.yaml` 中的 echo 容器更新为显示 "VERSION 2"：

```yaml
 apiVersion: argoproj.io/v1alpha1
 kind: Rollout
 metadata:
   name: echo-rollout
 spec:
   selector:
     matchLabels:
       app: echo
   template:
     metadata:
       labels:
         app: echo
     spec:
       containers:
         - image: hashicorp/http-echo
           args:
             - "-text=VERSION 2"
             - -listen=:8080
           imagePullPolicy: Always
           name: echo-v1
           ports:
             - containerPort: 8080
   strategy:
     canary:
       stableService: echo-stable
       canaryService: echo-canary
       trafficRouting:
         ambassador:
           mappings:
             - echo
       steps:
       - setWeight: 30
       - pause: {duration: 30s}
       - setWeight: 60
       - pause: {duration: 30s}
       - setWeight: 100
       - pause: {duration: 10}
```

通过键入 `kubectl apply -f rollout.yaml` 将 Rollout 应用于集群。这将通过在 30 秒内将 30% 的流量路由到服务，然后在另外 30 秒内将 60% 的流量路由到服务来部署服务的第 2 个版本。

你可以在命令行上监视 Rollout 的状态：

```bash
 kubectl argo rollouts get rollout echo-rollout --watch
```

将显示类似于以下内容的输出：

```
 Name:            echo-rollout
 Namespace:       default
 Status:          ॥ Paused
 Message:         CanaryPauseStep
 Strategy:        Canary
   Step:          1/6
   SetWeight:     30
   ActualWeight:  30
 Images:          hashicorp/http-echo (canary, stable)
 Replicas:
   Desired:       1
   Current:       2
   Updated:       1
   Ready:         2
   Available:     2

 NAME                                      KIND        STATUS        AGE    INFO
 ⟳ echo-rollout                            Rollout     ॥ Paused      2d21h
 ├──# revision:3
 │  └──⧉ echo-rollout-64fb847897           ReplicaSet  ✔ Healthy     2s     canary
 │     └──□ echo-rollout-64fb847897-49sg6  Pod         ✔ Running     2s     ready:1/1
 ├──# revision:2
 │  └──⧉ echo-rollout-578bfdb4b8           ReplicaSet  ✔ Healthy     3h5m   stable
 │     └──□ echo-rollout-578bfdb4b8-86z6n  Pod         ✔ Running     3h5m   ready:1/1
 └──# revision:1
    └──⧉ echo-rollout-948d9c9f9            ReplicaSet  • ScaledDown  2d21h
```

在其他终端窗口中，你可以通过循环发送请求来验证金丝雀是否正在适当地进行：

```bash
 while true; do curl -k https://$AMBASSADOR_LB_ENDPOINT/echo/; sleep 0.2; done
```

这将显示一个来自服务的响应的运行列表，这些响应将逐渐从 VERSION 1 字符串转换为 VERSION 2 字符串。

有关 Ambassador 和 Argo-Rollouts 集成的更多详细信息，请参见 [Ambassador Argo 文档](https://www.getambassador.io/docs/argo/latest/quick-start/)。

