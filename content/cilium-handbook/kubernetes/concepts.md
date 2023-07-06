---
weight: 2
title: 概念
date: '2022-06-17T12:00:00+08:00'
type: book
---

## 部署

标准 Cilium Kubernetes 部署的配置包括几个 Kubernetes 资源：

- `DaemonSet ` 资源：描述部署到每个 Kubernetes 节点的 Cilium pod。这个 pod 运行 `cilium-agent` 和相关的守护进程。这个 DaemonSet 的配置包括指示 Cilium docker 容器的确切版本（例如 v1.0.0）的镜像标签和传递给 `cilium-agent` 的命令行选项。
- 资源：描述传递给 `cilium-agent` 的`ConfigMap` 常用配置值，例如 kvstore 端点和凭据、启用/禁用调试模式等。
- `ServiceAccount`、`ClusterRole` 和 `ClusterRoleBindings 资源：当启用 Kubernetes RBAC 时，`cilium-agent` 用于访问 Kubernetes API 服务器的身份和权限。
- 资源：如果 `Secret` 需要，描述用于访问 etcd kvstore 的凭据。

## 现有 Pod 的联网

如果在部署 Cilium 之前 pod 已经在运行 [DaemonSet](https://docs.cilium.io/en/stable/glossary/#term-daemonset)，这些 pod 仍将根据 CNI 配置使用以前的网络插件连接。一个典型的例子是默认运行在 `kube-system` 命名空间中的  `kube-dns`  服务。

改变这种现有 pod 的网络的一个简单方法是依靠 Kubernetes 在 Deployment 中的 pod 被删除时自动重新启动的事实，所以我们可以简单地删除原来的 `kube-dns` pod，紧接着启动的替换 pod 将由 Cilium 管理网络。在生产部署中，这个步骤可以作为 `kube-dns` pod 的滚动更新来执行，以避免 DNS 服务的停机。

```bash
$ kubectl --namespace kube-system delete pods -l k8s-app=kube-dns
pod "kube-dns-268032401-t57r2" deleted
```

运行 `kubectl get pods` 将显示 Kubernetes 启动了一组新的 `kube-dns` pod，同时终止了旧的 pod：

```bash
$ kubectl --namespace kube-system get pods
NAME                          READY     STATUS        RESTARTS   AGE
cilium-5074s                  1/1       Running       0          58m
kube-addon-manager-minikube   1/1       Running       0          59m
kube-dns-268032401-j0vml      3/3       Running       0          9s
kube-dns-268032401-t57r2      3/3       Terminating   0          57m
```

## 默认允许本地主机的入口流量

Kubernetes 具有[通过存活探针和就绪探针](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)向用户指示其应用程序当前运行状况的功能。为了让 `kubelet` 对每个 pod 运行这些健康检查，默认情况下，Cilium 将始终允许从本地主机到每个 pod 的所有入口流量。
