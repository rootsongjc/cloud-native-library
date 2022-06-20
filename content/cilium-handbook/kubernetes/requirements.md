---
weight: 3
title: 要求
date: '2022-06-17T12:00:00+08:00'
type: book
---

## Kubernetes 版本

以下列出的所有 Kubernetes 版本都经过 e2e 测试，并保证与此 Cilium 版本兼容。此处未列出的旧 Kubernetes 版本不支持 Cilium。较新的 Kubernetes 版本未列出，这取决于新版本的的向后兼容性。

- 1.16
- 1.17
- 1.18
- 1.19
- 1.20
- 1.21
- 1.22
- 1.23

## 系统要求

Cilium 需要 Linux 内核 `>= 4.9`。有关所有系统要求的完整详细信息，请参阅[系统要求](https://docs.cilium.io/en/stable/operations/system_requirements/#admin-system-reqs)。

## 在 Kubernetes 中启用 CNI

CNI（容器网络接口）是 Kubernetes 用来委托网络配置的插件层。必须在 Kubernetes 集群中启用 CNI 才能安装 Cilium。这是通过将 `--network-plugin=cni` 参数在所有节点上传递给 kubelet 来完成的。有关更多信息，请参阅[Kubernetes CNI 网络插件文档](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/)。

## 启用自动节点 CIDR 分配（推荐）

Kubernetes 具有自动分配每个节点 IP CIDR 的能力。如果启用，Cilium 会自动使用此功能。这是在 Kubernetes 集群中处理 IP 分配的最简单方法。要启用此功能，只需在启动时添加以下标志 `kube-controller-manager`：

```bash
--allocate-node-cidrs
```

此选项不是必需的，但强烈推荐。
