---
weight: 4
title: AppMesh 快速开始
linktitle: AWS AppMesh
date: '2023-06-21T16:00:00+08:00'
type: book
tags: ["AppMesh","AWS","Argo Rollouts"]
---

本指南介绍了如何让 Argo Rollouts 与由 [AWS App Mesh](https://docs.aws.amazon.com/app-mesh/latest/userguide/what-is-app-mesh.html) 管理的服务网格集成。本指南基于 基本入门指南 的概念构建。

要求

- 安装了 AWS App Mesh Controller for K8s 的 Kubernetes 集群

🔔 提示：请参阅 [App Mesh Controler Installation instructions](<https://docs.aws.amazon.com/app-mesh/latest/userguide/getting-started-kubernetes.html>) 以了解如何开始使用 Kubernetes 的 App Mesh。

## 1. 部署 Rollout、服务和 App Mesh CRD

当 App Mesh 用作流量路由器时，Rollout canary 策略必须定义以下强制字段：

```yaml
apiVersion: argoproj.io/v1alpha1
 kind: Rollout
 metadata:
   name: my-rollout
 spec:
   strategy:
     canary:
       # canaryService 和 stableService 是指向 Rollout 将要修改的服务的引用，以便针对金丝雀 ReplicaSet 和稳定 ReplicaSet（均为必需）。
       canaryService: my-svc-canary
       stableService: my-svc-stable
       trafficRouting:
         appMesh:
           # 引用的虚拟服务将用于确定虚拟路由器，后者将被操纵以更新金丝雀权重。
           virtualService:
             # 虚拟服务 App Mesh CR 的名称
             name: my-svc
             # 要更新的路由的可选集。如果为空，则更新与虚拟服务关联的所有路由。
             routes:
             - http-primary
           # virtualNodeGroup 是一个结构，用于引用 App Mesh 虚拟节点 CR，该节点对应于金丝雀和稳定版本
           virtualNodeGroup:
             # canaryVirtualNodeRef 指的是对应于金丝雀版本的虚拟节点的引用。Rollouts 控制器将会
             # 更新这个虚拟节点的 podSelector 以匹配控制器生成的最新的 canary pod-hash。
             canaryVirtualNodeRef:
               name: my-vn-canary
             # stableVirtualNodeRef 指的是对应于稳定版本的虚拟节点的引用。Rollouts 控制器将会
             # 更新这个虚拟节点的 podSelector 以匹配控制器生成的最新的 stable pod-hash。
             stableVirtualNodeRef:
               name: my-vn-stable
       steps:
       - setWeight: 25
       - pause: {}
       ...
```

在本指南中，这两个服务分别是：`my-svc-canary` 和 `my-svc-stable`。这两个服务对应的是两个名为 `my-vn-canary` 和 `my-vn-stable` 的虚拟节点 CR。此外，还有一个名为 `rollout-demo-vsvc` 的虚拟服务，它由一个名为 `rollout-demo-vrouter` 的虚拟路由器 CR 提供。这个虚拟路由器需要至少有一个路由，用于将流量转发到 canary 和 stable 虚拟节点。最初，canary 的权重设置为 0%，而 stable 的权重设置为 100%。在部署期间，控制器将根据 `steps[N].setWeight` 中定义的配置修改路由的权重。

canary 和 stable 服务的配置为无头服务。这是必要的，以便 App Mesh 正确处理由 canary 到 stable 重新分配的 pod 的连接池。

总之，运行以下命令以部署服务：

- 两个服务（stable 和 canary）
- 一个服务（用于 VIP 和 DNS 查询）
- 两个 App Mesh 虚拟节点（stable 和 canary）
- 一个具有指向虚拟节点的路由的 App Mesh 虚拟路由器
- 一个对应 VIP 服务的 App Mesh 虚拟服务
- 一个 rollout

```bash
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-rollouts/master/examples/appmesh/canary-service.yaml
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-rollouts/master/examples/appmesh/canary-rollout.yaml
```

## 2. 验证服务

首先确保 rollout 稳定。

```bash
kubectl argo rollouts get rollout my-rollout -n argo-examples -w
```

然后确保服务正常运行。

```bash
kubectl -n argo-examples port-forward svc/my-svc 8181:80
```

## 3. 部署新版本

现在是部署新版本的时候了。使用新镜像更新 rollout。

```bash
kubectl argo rollouts set image my-rollout demo=argoproj/rollouts-demo:green -n argo-examples
```

Rollout 应该会部署一个新的 canary 修订版本，并在虚拟路由器下更新权重。

```bash
kubectl get -n argo-examples virtualrouter my-vrouter -o json | jq ".spec.routes[0].httpRoute.action.weightedTargets"
 [
   {
     "virtualNodeRef": {
       "name": "my-vn-canary"
     },
     "weight": 25
   },
   {
     "virtualNodeRef": {
       "name": "my-vn-stable"
     },
     "weight": 75
   }
 ]
```

现在手动批准无限期暂停的 rollout，并继续观察路由更新

```bash
kubectl argo rollouts promote my-rollout -n argo-examples

watch -d 'kubectl get -n argo-examples virtualrouter my-vrouter -o json | jq ".spec.routes[0].httpRoute.action.weightedTargets"'
```
