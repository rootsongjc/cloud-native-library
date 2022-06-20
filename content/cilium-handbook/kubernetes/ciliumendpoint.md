---
weight: 6
title: 端点 CRD
date: '2022-06-17T12:00:00+08:00'
type: book
---

在 Kubernetes 中管理 pod 时，Cilium 将创建一个 `CiliumEndpoint` 的自定义资源定义（CRD）。每个由 Cilium 管理的 pod 都会创建一个 `CiliumEndpoint`，名称相同且在同一命名空间。`CiliumEndpoint` 对象包含的信息与 `cilium endpoint get` 在`.status` 字段下的 json 输出相同，但可以为集群中的所有 pod 获取。添加 `-o json` 将导出每个端点的更多信息。这包括端点的标签、安全身份和对其有效的策略。

例如：

``` {.shell-session}
$ kubectl get ciliumendpoints --all-namespaces
NAMESPACE     NAME                     AGE
default       app1-55d7944bdd-l7c8j    1h
default       app1-55d7944bdd-sn9xj    1h
default       app2                     1h
default       app3                     1h
kube-system   cilium-health-minikube   1h
kube-system   microscope               1h
```

{{<callout note 提示>}}
每个 `cilium-agent` pod 都会创建一个 `CiliumEndpoint` 来代表自己的 agent 间健康检查端点。这些不是 Kubernetes 中的 pod，而是在 `kube-system` 命名空间中。它们被命名为 `cilium-health-<节点名>`。
{{</callout>}}
