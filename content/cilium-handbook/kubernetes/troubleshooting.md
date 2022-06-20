---
weight: 9
title: 故障排除
date: '2022-06-17T12:00:00+08:00'
type: book
---

## 验证安装 

检查 [`DaemonSet`](https://docs.cilium.io/en/stable/glossary/#term-daemonset) 的状态并验证所有需要的实例都处于 `ready` 状态：

``` bash
$ kubectl --namespace kube-system get ds
NAME      DESIRED   CURRENT   READY     NODE-SELECTOR   AGE
cilium    1         1         0         <none>          3s
```

在此示例中，我们看到 1 个期望的状态，0 个 ready 状态。这表明有问题。下一步是通过在  `k8s-app=cilium` 标签上匹配列出所有 cilium pod，并根据每个 pod 的重启次数对列表进行排序，以便轻松识别失败的 pod：

``` bash
$ kubectl --namespace kube-system get pods --selector k8s-app=cilium \
          --sort-by='.status.containerStatuses[0].restartCount'
NAME           READY     STATUS             RESTARTS   AGE
cilium-813gf   0/1       CrashLoopBackOff   2          44s
```

`cilium-813gf` pod 失败并且已经重新启动了 2 次。让我们打印该 pod 的日志文件来调查原因：

``` bash
$ kubectl --namespace kube-system logs cilium-813gf
INFO      _ _ _
INFO  ___|_| |_|_ _ _____
INFO |  _| | | | | |     |
INFO |___|_|_|_|___|_|_|_|
INFO Cilium 0.8.90 f022e2f Thu, 27 Apr 2017 23:17:56 -0700 go version go1.7.5 linux/amd64
CRIT kernel version: NOT OK: minimal supported kernel version is >= 4.8
```

在此示例中，失败的原因是在工作节点上运行的 Linux 内核不符合[系统要求](https://docs.cilium.io/en/stable/operations/system_requirements/#admin-system-reqs)。

如果根据这些简单的步骤无法发现问题的原因，请来我们的 [Slack channel](https://docs.cilium.io/en/stable/glossary/#term-slack-channel)。

## 集群外的 APIserver

如果你出于某种原因在集群外部运行 Kubernetes Apiserver（例如将主节点保留在防火墙后面），请确保您也在主节点上运行 Cilium。否则，由 Apiserver 创建的 Kubernetes pod 代理将无法路由到 pod IP，并且你在尝试将流量代理到 pod 时可能会遇到错误。

你可以将 Cilium 作为[静态 pod](https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/) 运行，或者为 Cilium DaemonSet 设置[容忍](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/)，以确保将 Cilium pod 安排在你的主节点上。执行此操作的确切方法取决于你的设置。
