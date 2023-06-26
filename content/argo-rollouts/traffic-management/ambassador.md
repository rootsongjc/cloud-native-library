---
weight: 2
title: "Ambassador Edge Stack"
linkTitle: "Ambassador"
date: '2023-06-21T16:00:00+08:00'
type: book
tags: ["Ambassador","Argo Rollouts"]
---

[Ambassador Edge Stack](https://www.getambassador.io/products/edge-stack/) 提供了你在 Kubernetes 集群边缘所需的功能（因此称为“边缘堆栈”）。这包括 API 网关、入口控制器、负载均衡器、开发人员门户、金丝雀流量路由等。它提供了一组 CRD，用户可以配置以启用不同的功能。

Argo-Rollouts 提供了一个集成，利用了 Ambassador 的 [金丝雀路由功能](https://www.getambassador.io/docs/latest/topics/using/canary/)。这允许你的应用程序的流量在部署新版本时逐步增加。

## 工作原理

Ambassador Edge Stack 提供了一个名为“Mapping”的资源，用于配置如何将流量路由到服务。通过创建具有相同 URL 前缀并指向不同服务的 2 个映射，可以实现 Ambassador 金丝雀部署。考虑以下示例：

```yaml
 apiVersion: getambassador.io/v2
 kind:  Mapping
 metadata:
   name: stable-mapping
 spec:
   prefix: /someapp
   rewrite: /
   service: someapp-stable:80
 ---
 apiVersion: getambassador.io/v2
 kind:  Mapping
 metadata:
   name: canary-mapping
 spec:
   prefix: /someapp
   rewrite: /
   service: someapp-canary:80
   weight: 30
```

在上面的示例中，我们正在配置 Ambassador 以将来自`<public ingress>/someapp` 的 30% 流量路由到服务 `someapp-canary`，其余流量将进入服务 `someapp-stable`。如果用户想逐步增加到金丝雀服务的流量，则必须手动或自动化地更新 `canary-mapping` 权重的值。

使用 Argo-Rollouts 无需创建 `canary-mapping`。Argo-Rollouts 控制器完全自动化创建它并逐步更新其权重的过程。以下示例说明如何配置 `Rollout` 资源以使用 Ambassador 作为金丝雀部署的流量路由器：

```yaml
 apiVersion: argoproj.io/v1alpha1
 kind: Rollout
 ...
 spec:
   strategy:
     canary:
       stableService: someapp-stable
       canaryService: someapp-canary
       trafficRouting:
         ambassador:
           mappings:
             - stable-mapping
       steps:
       - setWeight: 30
       - pause: {duration: 60s}
       - setWeight: 60
       - pause: {duration: 60s}
```

在 `spec.strategy.canary.trafficRouting.ambassador` 下有 2 个可能的属性：

- `mappings`：必需。Argo-Rollouts 必须提供至少一个 Ambassador 映射才能管理金丝雀部署。如果有多个路由到服务的路由（例如，你的服务具有多个端口或可以通过不同的 URL 访问），则还支持多个映射。如果未提供映射，则 Argo-Rollouts 将发送错误事件，并且回滚将中止。

当在清单的 `trafficRouting` 中配置了 Ambassador 时，Rollout 控制器将：

1. 为 Rollout manifest 中提供的每个 stable mapping 创建一个金丝雀映射
2. 根据配置继续执行步骤，更新金丝雀映射权重
3. 在流程结束时，Argo-Rollout 将删除所有创建的金丝雀映射

## 端点解析器

默认情况下，Ambassador 使用 kube-proxy 将流量路由到 Pod。但是，我们应该将其配置为绕过 kube-proxy 并直接将流量路由到 pod。这将提供真正的 L7 负载平衡，在金丝雀工作流中是可取的。这种方法称为 [endpoint routing](https://www.getambassador.io/docs/latest/topics/running/load-balancer/)，可以通过配置 [endpoint resolvers](https://www.getambassador.io/docs/latest/topics/running/resolvers/#the-kubernetes-endpoint-resolver) 实现。

要将 Ambassador 配置为使用端点解析器，必须在集群中应用以下资源：

```yaml
 apiVersion: getambassador.io/v2
 kind: KubernetesEndpointResolver
 metadata:
   name: endpoint
```

然后配置映射以使用它设置 `resolver` 属性：

```yaml
 apiVersion: getambassador.io/v2
 kind:  Mapping
 metadata:
   name: stable-mapping
 spec:
   resolver: endpoint
   prefix: /someapp
   rewrite: /
   service: someapp-stable:80
```

有关 Ambassador 和 Argo-Rollouts 集成的更多详细信息，请参见 [Ambassador Argo 文档](https://deploy-preview-508--datawire-ambassador.netlify.app/docs/pre-release/argo/)。
