---
weight: 9
title: "Traefik"
linkTitle: "Traefik"
date: '2023-06-21T16:00:00+08:00'
type: book
tags: ["traefik","Argo Rollouts"]
---

你可以使用[Traefik Proxy](https://traefik.io/traefik/)来进行 Traffic Management with Argo Rollouts。

[TraefikService](https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/#kind-traefikservice)是支持[Traefik 作为 ingress 时加权轮询负载均衡](https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/#weighted-round-robin)和[Traefik 作为 ingress 时流量镜像](https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/#mirroring)能力的对象。

## 如何将 TraefikService 与 Argo Rollouts 集成，作为加权轮询负载均衡器

首先，我们需要使用 TraefikService 对象的加权轮询负载平衡能力创建 TraefikService 对象。

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: TraefikService
metadata:
  name: traefik-service
spec:
  weighted:
    services:
      - name: stable-rollout # 为稳定应用程序版本创建的 k8s 服务名称
        port: 80
      - name: canary-rollout # 为新应用程序版本创建的 k8s 服务名称
        port: 80
```

请注意，我们不指定“weight”字段。它需要与 ArgoCD 同步。如果我们指定此字段，而 Argo Rollouts 控制器更改它，则 ArgoCD 控制器将注意到并将显示此资源不同步（如果你正在使用 Argo CD 管理 Rollout）。

其次，我们需要创建 Argo Rollouts 对象。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: rollouts-demo
spec:
  replicas: 5
  strategy:
    canary:
      canaryService: canary-rollout
      stableService: stable-rollout
      trafficRouting:
        traefik:
          weightedTraefikServiceName: traefik-service # 指定我们之前创建的 traefikService 资源的名称
      steps:
      - setWeight: 30
      - pause: {}
      - setWeight: 40
      - pause: {duration: 10}
      - setWeight: 60
      - pause: {duration: 10}
      - setWeight: 80
      - pause: {duration: 10}
  ...
```

## 如何将 TraefikService 与 Argo Rollouts 集成，作为流量镜像

首先，我们还需要创建 TraefikService 对象，但使用其流量镜像功能。

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: TraefikService
metadata:
  name: traefik-service
spec:
  mirroring:
    name: some-service
    port: 80
    mirrors:
      - name: stable-rollout # 为稳定应用程序版本创建的 k8s 服务名称
        port: 80
      - name: canary-rollout # 为新应用程序版本创建的 k8s 服务名称
        port: 80
```

请注意，我们不指定“percent”字段。它需要与 ArgoCD 同步。如果我们指定此字段，而 Argo Rollouts 控制器更改它，则 ArgoCD 控制器将注意到并将显示此资源不同步（如果你正在使用 Argo CD 管理 Rollout）。

其次，我们需要创建 Argo Rollouts 对象。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: rollouts-demo
spec:
  replicas: 5
  strategy:
    canary:
      canaryService: canary-rollout
      stableService: stable-rollout
      trafficRouting:
        traefik:
          mirrorTraefikServiceName: traefik-service # 指定我们之前创建的 traefikService 资源的名称
      steps:
      - setWeight: 30
      - pause: {}
      - setWeight: 40
      - pause: {duration: 10}
      - setWeight: 60
      - pause: {duration: 10}
      - setWeight: 80
      - pause: {duration: 10}
  ...
```
