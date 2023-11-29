---
title: 管理已载入的工作负载
weight: 4
---

## 工作负载命名

加入到 mesh 中的工作负载由 Kubernetes 资源 [`WorkloadAutoRegistration`](../../../refs/onboarding/config/runtime/v1alpha1/registration) 表示。

当新的工作负载加入到 mesh 中并加入到给定的 [`WorkloadGroup`](https://istio.io/latest/docs/reference/config/networking/workload-group/) 时，工作负载载入端点会在该 `WorkloadGroup` 的命名空间中创建一个 `WorkloadAutoRegistration` 资源。

每个 `WorkloadAutoRegistration` 资源都被分配一个唯一的名称，格式为：

```text
<workload-group-name>-<workload-identity>
```

其中 `workload-identity` 是由 TSB 生成的唯一名称。对于在 AWS EC2 实例上运行的工作负载，它的 `workload-identity` 将采用以下格式：

```text
aws-<aws-partition>-<aws-account>-<aws-zone>-ec2-<aws-ec2-instance-id>
```

综合起来，工作负载的唯一名称可能看起来像下面的例子：

```text
ratings-aws-aws-123456789012-us-east-2b-ec2-i-1234567890abcdef0
```

## 列出已载入的工作负载

要列出已载入的工作负载，请对 `war` 资源发出 `kubectl get` 命令。`war` 是 `WorkloadAutoRegistration` 的别名。

以下命令将列出在所有 Kubernetes 命名空间中注册的工作负载：

```bash
kubectl get war -A 
```

你将看到类似于以下输出：

```text
NAMESPACE   NAME                                                              AGENT CONNECTED   AGE
bookinfo    ratings-aws-aws-123456789012-us-east-2b-ec2-i-1234567890abcdef0   True              1m
```

`AGENT CONNECTED` 列显示了工作负载载入代理的状态。如果值为 `True`，则代理当前已连接到工作负载载入端点，并且工作负载被视为健康。如果值为 `False`，则代理不再连接。工作负载本身可能健康也可能不健康。

## 描述已载入的工作负载

要查看已载入工作负载的详细信息，请运行 `kubectl describe war` 命令：

```
kubectl describe war <war-name>
```

你将看到类似于以下输出：

```yaml
Name:         ratings-aws-aws-123456789012-us-east-2b-ec2-i-1234567890abcdef0
Namespace:    bookinfo
API Version:  runtime.onboarding.tetrate.io/v1alpha1
Kind:         WorkloadAutoRegistration
Spec:
  Identity:                                # (1)
    Aws:
      Account:  123456789012
      ec2:
        Instance Id:  i-1234567890abcdef0
      Partition:      aws
      Region:         us-east-2
      Zone:           us-east-2b
  Registration:
    Agent:
      Version:  v1.4.0
    Host:
      Addresses:
        Ip:    172.31.5.254
        Type:  VPC
    Settings:
      Connected Over:  VPC
    Sidecar:
      Istio:
        Version:  1.9.8-15bc6e5e32
    Workload:
      Labels:
        Version:  v5
Status:
  Conditions:
    Last Transition Time:  2021-10-09T10:56:41.380102645Z
    Reason:                AgentEstablishedConnection
    Status:                True
    Type:                  AgentConnected
```

`Spec.Identity` 部分（1）描述了工作负载的*已验证身份*，在这种情况下是工作负载正在运行的 VM 的身份。这些信息可能对于验证已载入的工作负载的来源很有用，而不是信任工作负载本身报告的信息。

## 检查 Istio Sidecar 的状态

你可以使用 `istioctl proxy-status` 命令来检查已载入工作负载的 Istio sidecar 的状态。

运行：

```bash
istioctl proxy-status
```

你应该会得到类似于以下的输出：

```text
NAME                                                                         CDS        LDS        EDS        RDS        ISTIOD                      VERSION
ratings-aws-aws-123456789012-us-east-2b-ec2-i-1234567890abcdef0.bookinfo     SYNCED     SYNCED     SYNCED     SYNCED     istiod-6449df9b98-prvqd     1.9.8-15bc6e5e32
...
```

`istioctl proxy-status` 命令显示了当前连接到 Istio 控制平面的所有 Istio 代理（包括 sidecar 和网关）的状态。

侧车的名称将与工作负载的名称相同。

## 自动删除已载入的工作负载

工作负载载入端点组件不知道通过工作负载载入代理注册的工作负载的生命周期。例如，如果运行工作负载的 AWS EC2 实例被终止，工作负载载入端点只知道工作负载载入代理不再连接

到它。

为了避免无限期保留悬挂的工作负载载入，工作负载载入端点在工作负载载入代理断开连接并且在预先配置的宽限期内没有重新连接时，将工作负载视为不再活动。此宽限期的默认值为 5 分钟。

## 更新 WorkloadGroups

在工作负载载入功能中使用的 Istio [WorkloadGroup](https://istio.io/latest/docs/reference/config/networking/workload-group/) 扮演着类似于 Kubernetes Deployment 的角色。`WorkloadGroup` 用于定义在组中的每个单独实例中使用的配置模板。

Kubernetes Deployments 和 `WorkloadGroup` 之间有一个重要的区别。前者由一个控制逻辑支持，该逻辑知道如何逐渐使用新配置替换 Pod 并推出对 Deployment 资源所做的更改，而后者则没有这样的功能。

这意味着，尽管你对 `WorkloadGroup` 进行的任何更改都将影响将来加入该组的工作负载，但之前已经加入的工作负载将保留其旧配置。

### 应用 `WorkloadGroup` 更新

`WorkloadGroup` 定义了 Istio sidecar 的核心配置集，该配置集无法在不重新启动 sidecar 的情况下更新。

因此，如果我们要将新配置应用于所有工作负载，所有工作负载都必须同时终止。这对于生产环境来说是不安全的。

同样，在 Istio sidecar 重新连接到控制平面时应用配置也是不安全的，因为由于网络故障，可能会出现多个 sidecar 同时重新连接的可能性。

另一方面，加入到 mesh 中的每个个体工作负载都由 `WorkloadAutoRegistration` 资源表示。

为了确保工作负载 Istio sidecar 的核心配置始终保持稳定，`WorkloadAutoRegistration` 携带在工作负载加入 mesh 时采取的 `WorkloadGroup` 的快照。

`WorkloadAutoRegistration` 捕获有关工作负载的主要信息，例如 IP 地址、流量重定向的使用等，这些都影响该工作负载的 Istio sidecar 的核心配置。

因此，在创建 `WorkloadAutoRegistration` 后，如果要使工作负载观察到 `WorkloadGroup` 的新更改，就需要删除并重新创建 `WorkloadAutoRegistration`。

总之，你应该在对 `WorkloadGroup` 进行更改后删除 `WorkloadAutoRegistration` 资源。在对 `WorkloadGroup` 进行更改后运行以下命令：

```bash
kubectl delete war <war-name> 
```

删除 `WorkloadAutoRegistration` 资源将导致 Workload 载入代理再次执行 Workload 载入流程，进而重新创建 `WorkloadAutoRegistration`。这将捕获 `WorkloadGroup` 配置的最新版本。