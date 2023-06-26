---
weight: 6
title: "Nginx"
linkTitle: "Nginx"
date: '2023-06-21T16:00:00+08:00'
type: book
tags: ["Nginx","Argo Rollouts"]
---

[Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/) 允许通过一个或多个 Ingress 对象进行流量管理，以配置直接将流量路由到 Pod 的 Nginx 部署。每个 Nginx Ingress 都包含多个注释，可以修改 Nginx 部署的行为。对于应用程序不同版本之间的流量管理，Nginx Ingress 控制器提供了通过引入第二个 Ingress 对象（称为金丝雀 Ingress）进行流量拆分的功能。你可以在官方的 [金丝雀注释文档页面](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#canary) 上阅读更多关于这些金丝雀注释的信息。金丝雀 Ingress 忽略任何其他非金丝雀 nginx 注释。取而代之，它利用来自主要 Ingress 的注释设置。

Rollout 控制器始终会在金丝雀 Ingress 上设置以下两个注释（使用你配置的或默认的 `nginx.ingress.kubernetes.io` 前缀）：

- `canary: true` 表示这是金丝雀 Ingress
- `canary-weight: <num>` 表示将发送到金丝雀的流量百分比。如果所有流量都路由到稳定服务，则设置为 `0`

你可以通过 `additionalIngressAnnotations` 字段提供其他注释以添加到金丝雀 Ingress，以启用按标头或 cookie 进行路由等功能。

## 与 Argo Rollouts 集成

使用 Nginx 发送版本间的分割流量需要在 Rollout 中有几个必需字段。以下是一个带有这些字段的 Rollout 示例：

```yaml
 apiVersion: argoproj.io/v1alpha1
 kind: Rollout
 spec:
   ...
   strategy:
     canary:
       canaryService: canary-service  # 必需
       stableService: stable-service  # 必需
       trafficRouting:
         nginx:
           # 必须配置 stableIngress 或 stableIngress 中的一个，但不能同时配置。
           stableIngress: primary-ingress
           stableIngresses:
             - primary-ingress
             - secondary-ingress
             - tertiary-ingress
           annotationPrefix: customingress.nginx.ingress.kubernetes.io # 可选的
           additionalIngressAnnotations:   # 可选的
             canary-by-header: X-Canary
             canary-by-header-value: iwantsit
```

稳定 Ingress 字段是对 Rollout 同一命名空间中的 Ingress 的引用。Rollout 需要主要 Ingress 将流量路由到稳定服务。Rollout 通过确认 Ingress 是否具有与 Rollout 的 stableService 匹配的后端来检查该条件。

控制器通过创建具有金丝雀注释的第二个 Ingress 来将流量路由到金丝雀服务。随着 Rollout 经过金丝雀步骤，控制器更新金丝雀 Ingress 的金丝雀注释，以反映 Rollout 的所需状态，从而实现两个不同版本之间的流量分配。

由于 Nginx Ingress 控制器允许用户配置用于 Ingress 控制器的注释前缀，因此 Rollout 可以指定可选的 `annotationPrefix` 字段。如果设置了该字段，则金丝雀 Ingress 将使用该前缀而不是默认的 `nginx.ingress.kubernetes.io`。

## 在一个服务中使用多个 NGINX Ingress 控制器与 Argo Rollouts

从 v1.5 开始，argo rollouts 支持多个 Nginx Ingress 控制器指向具有金丝雀部署的一个服务。如果只需要一个 Ingress 控制器，请使用现有的键 `stableIngress`。如果需要多个 Ingress 控制器（例如，分离内部和外部流量），请改用键 `stableIngresses`。它接受一个字符串值数组，这些字符串值是 Ingress 控制器的名称。金丝雀步骤在所有 Ingress 控制器上应用相同的方式。

## 在自定义 NGINX ingress 控制器名称中使用 Argo Rollouts

默认情况下，Argo Rollouts 控制器仅在具有 `kubernetes.io/ingress.class` 注释或 `spec.ingressClassName` 设置为 `nginx` 的 Ingress 上运行。用户可以通过指定 `--nginx-ingress-classes` 标志将控制器配置为在具有不同类名的 Ingress 上运行。如果 Argo Rollouts 控制器应该在多个值上运行，则用户可以多次列出 `--nginx-ingress-classes` 标志。这解决了集群具有在不同类值上运行的多个 Ingress 控制器的情况。

如果用户希望控制器在没有 `kubernetes.io/ingress.class` 注释或 `spec.ingressClassName` 的任何 Ingress 上运行，则用户应添加以下内容 `--nginx-ingress-classes ''`。
