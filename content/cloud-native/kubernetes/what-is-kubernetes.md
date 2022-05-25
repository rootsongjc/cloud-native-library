---
title: 什么是 Kubernetes?
linktitle: 什么是 Kubernetes?
type: book
date: '2022-05-25T10:00:00+08:00'
weight: 1
---

## Kubernetes 是云原生时代的 POSIX

在单机时代，POSIX 是类 UNIX 系统的通用 API，而在云原生时代，Kubernetes 是云操作系统的的 POSIX，它定义了基于云的分布式系统的 API。下表将 Kubernetes 与 POSIX 进行了对比。

| 对比项   | Linux           | Kubernetes                |
| -------- | --------------- | ------------------------- |
| 隔离单元 | 进程            | Pod                       |
| 硬件     | 单机            | 数据中心                  |
| 并发     | 线程            | 容器                      |
| 资源管理 | 进程内存&CPU    | 内存、CPU Limit/Request   |
| 存储     | 文件            | ConfigMap、Secret、Volume |
| 网络     | 端口绑定        | Service                   |
| 终端     | tty、pty、shell | kubectl exec              |
| 网络安全 | IPtables        | NetworkPolicy             |
| 权限     | 用户、文件权限  | ServiceAccount、RBAC      |

{{% callout 注意 %}}
我们不能说 Linux 就是 POSIX，只能说 Linux 是 UNIX 兼容的。
{{% /callout %}}

## 参考

- [Kubernetes is the POSIX of the cloud - home.robusta.dev](https://home.robusta.dev/blog/kubernetes-is-the-new-posix/)