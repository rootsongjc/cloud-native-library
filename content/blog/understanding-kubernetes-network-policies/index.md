---
title: "Kubernetes 网络策略入门：概念、示例和最佳实践"
summary: "这篇文章介绍了 Kubernetes 网络策略的概念、作用和使用方法。Kubernetes 网络策略可以让你配置和执行一套规则，来控制集群内部的流量。它们可以提高安全性、符合合规性和简化故障排除。文章分析了网络策略的不同组成部分，包括选择器、入口规则和出口规则，并给出了不同的策略示例和最佳实践。文章的目标是让读者对使用 Kubernetes 网络策略来保护和管理流量有一个坚实的理解。"
date: '2023-07-12T10:00:00+08:00'
draft: false
featured: false
authors: ["Daniel Olaogun"]
tags: ["Kubernetes"]
categories: ["Kubernetes"]
links:
  - icon: language
    icon_pack: fa
    name: 阅读英文版原文
    url: https://deploy.equinix.com/blog/understanding-kubernetes-network-policies/
---

在 Kubernetes 中，同一命名空间中的任何 Pod 都可以使用其 IP 地址相互通信，无论它属于哪个部署或服务。虽然这种默认行为适用于小规模应用，但在规模扩大和复杂度增加的情况下，Pod 之间的无限通信可能会增加攻击面并导致安全漏洞。

在集群中实施 Kubernetes 网络策略可以改善以下方面：

1. **安全性：** 使用 Kubernetes 网络策略，你可以指定允许哪些 Pod 或服务相互通信，以及应该阻止哪些流量访问特定的资源。这样可以更容易地防止未经授权的访问敏感数据或服务。
2. **合规性：** 在医疗保健或金融服务等行业，合规性要求不可妥协。通过确保流量仅在特定的工作负载之间流动，以满足合规要求。
3. **故障排除：** 通过提供关于应该相互通信的 Pod 和服务的可见性，可以更轻松地解决网络问题，特别是在大型集群中。策略还可以帮助你确定网络问题的源，从而加快解决速度。

## Kubernetes 网络策略组件

强大的网络策略包括：

- **策略类型：** Kubernetes 网络策略有两种类型：入口和出口。入口策略允许你控制流入 Pod 的流量，而出口策略允许你控制从 Pod 流出的流量。它们在 `NetworkPolicy` 资源的 `policyTypes` 字段中指定。
- **入口规则：** 这些定义了 Pod 的传入流量策略，指定在 `NetworkPolicy` 资源的 `ingress` 字段中。你可以定义流量的来源，可以是 Pod、命名空间或 IP 块，以及允许访问流量的目标端口或端口。
- **出口规则：** 这些定义了 Pod 的传出流量策略。在这里，你将指定流量的目标，可以是 Pod、命名空间或 IP 块，以及允许访问流量的目标端口或端口。
- **Pod 选择器：** 这些选择要应用策略的 Pod。为选择器指定标签，与选择器匹配的 Pod 将受到策略中指定的规则的约束。
- **命名空间选择器：** 类似于 Pod 选择器，这些允许你选择要应用策略的命名空间。
- **IP 地址块选择器：** IP 地址块选择器指定要允许或拒绝流量的 IP 地址范围。你可以使用[CIDR 表示法](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing)来指定 IP 地址范围。

## 实施网络策略

现在，让我们进入创建、更新和删除 Kubernetes 中的网络策略。本教程将通过创建三个演示应用程序（frontend、backend 和 database），来演示如何在应用程序之间限制和允许网络流量。

首先，你需要运行一个集群。为了在你的机器上创建本地集群，我建议使用[minikube](https://minikube.sigs.k8s.io/docs/)。由于 minikube 默认不支持网络策略，因此请使用类似[Calico](https://www.projectcalico.org/)或[Weave Net](https://www.weave.works/oss/net)的网络插件启动 minikube。

使用以下命令启动 minikube，以便你拥有带有网络支持的 minikube 集群：

```bash
minikube start --network-plugin=cni --cni=calico
```

有了运行中的集群，本教程使用专用命名空间来保持集群的组织性：

```bash
kubectl create namespace network-policy-tutorial
```

在该命名空间中创建三个示例 Pod（Backend、Database 和 Frontend）：

```bash
kubectl run backend --image=nginx --namespace=network-policy-tutorial
kubectl run database --image=nginx --namespace=network-policy-tutorial
kubectl run frontend --image=nginx --namespace=network-policy-tutorial
```

验证 Pod 是否正在运行：

```bash
kubectl get pods --namespace=network-policy-tutorial
```

你应该会得到以下响应：

```bash
NAME       READY   STATUS    RESTARTS   AGE
backend    1/1     Running    0         12s
database   1/1     Running    0         12s
frontend   1/1     Running    0         22s
```

为 Pod 创建相应的服务：

```bash
kubectl expose pod backend --port 80 --namespace=network-policy-tutorial
kubectl expose pod database --port 80 --namespace=network-policy-tutorial
kubectl expose pod frontend --port 80 --namespace=network-policy-tutorial
```

获取相应服务的 IP：

```bash
kubectl get service --namespace=network-policy-tutorial
```

你应该会得到类似以下的响应：

```bash
NAME       TYPE        CLUSTER-IP               EXTERNAL-IP   PORT(S)   AGE
backend    ClusterIP   <BACKEND-CLUSTER-IP>     <none>        80/TCP    24s
database   ClusterIP   <DATABASE-CLUSTER-IP>    <none>        80/TCP    24s
frontend   ClusterIP   <FRONTEND-CLUSTER-IP>    <none>        80/TCP    24s
```

检查`frontend`是否可以与`backend`和`database`通信：

```bash
kubectl exec -it frontend --namespace=network-policy-tutorial -- curl <BACKEND-CLUSTER-IP>
kubectl exec -it frontend --namespace=network-policy-tutorial -- curl <DATABASE-CLUSTER-IP>
```

将<`BACKEND-CLUSTER-IP`>和<`DATABASE-CLUSTER-IP`>替换为它们各自的 IP。通过运行`kubectl get service --namespace=network-policy-tutorial`找到它们。

你会得到以下回应：

![](1.png)

### 示例 1：在命名空间中限制流量

此示例演示如何在`network-policy-tutorial`命名空间内限制流量。你将阻止`frontend`应用程序与`backend`和`database`应用程序通信。

首先，创建一个名为`namespace-default-deny.yaml`的策略，该策略拒绝命名空间中的所有流量：

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: namespace-default-deny
  namespace: network-policy-tutorial
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

然后运行以下命令，将网络策略配置应用于集群：

```bash
kubectl apply -f namespace-default-deny.yaml --namespace=network-policy-tutorial
```

现在，再次尝试从 `frontend` 访问 `backend` 和 `database` ，你会发现 `frontend` 和 `backend` 以及 `database` 之间已经无法通信了。

```bash
kubectl exec -it frontend --namespace=network-policy-tutorial -- curl <BACKEND-CLUSTER-IP>
kubectl exec -it frontend --namespace=network-policy-tutorial -- curl <DATABASE-CLUSTER-IP>
```

### 示例 2：允许特定 Pod 的流量

现在，我们看看能否在集群中允许以下外部流量：

```
frontend -> backend -> database
```

这样， `frontend` 只能向 `backend` 发送外部流量，而 `backend` 只能从 `frontend` 接收内部流量。同样， `backend` 只能向 `database` 发送外部流量，而 `database` 只能从 `backend` 接收内部流量。

创建一个名为 `frontend-default-policy.yaml` 的新策略，并将以下代码粘贴到其中：

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-default
  namespace: network-policy-tutorial
spec:
  podSelector:
    matchLabels:
      run: frontend
  policyTypes:
    - Egress
  egress:
    - to:
        - podSelector:
            matchLabels:
              run: backend
```

然后运行以下命令来应用该策略：

```bash
kubectl apply -f frontend-default-policy.yaml --namespace=network-policy-tutorial
```

对于 `backend` ，创建一个名为 `backend-default-policy.yaml` 的新策略，并将以下代码粘贴到其中：

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-default
  namespace: network-policy-tutorial
spec:
  podSelector:
    matchLabels:
      run: backend
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              run: frontend
  egress:
    - to:
        - podSelector:
            matchLabels:
              run: database
```

再次运行以下命令以应用该策略：

```bash
kubectl apply -f backend-default-policy.yaml --namespace=network-policy-tutorial
```

然后，按照类似的方式为 `database` 创建一个新策略 `database-default-policy.yaml`，并将以下代码粘贴到其中：

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-default
  namespace: network-policy-tutorial
spec:
  podSelector:
    matchLabels:
      run: database
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              run: backend
```

运行以下命令以应用该策略：

```bash
kubectl apply -f database-default-policy.yaml --namespace=network-policy-tutorial
```

现在，已应用这些网络策略配置后，请执行以下操作以接收响应：

```bash
kubectl exec -it frontend --namespace=network-policy-tutorial -- curl <BACKEND-CLUSTER-IP>
kubectl exec -it backend --namespace=network-policy-tutorial -- curl <DATABASE-CLUSTER-IP>
```

但是，如果执行*下面的这段代码*，你将不会收到响应，因为在该命名空间中未打开流量流：

```bash
kubectl exec -it backend --namespace=network-policy-tutorial -- curl <FRONTEND-CLUSTER-IP>
kubectl exec -it database --namespace=network-policy-tutorial -- curl <FRONTEND-CLUSTER-IP>
kubectl exec -it database --namespace=network-policy-tutorial -- curl <BACKEND-CLUSTER-IP>
```

### 示例 3：在单个策略中组合入站和出站规则

当你需要控制集群中应用程序的入站和出站流量时，你不必为每个流量流创建单独的网络策略。相反，你可以将入站和出站流量组合到一个网络策略中，就像在这个 `backend-default-policy.yaml` 文件的内容中所示：

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-default
  namespace: network-policy-tutorial
spec:
  podSelector:
    matchLabels:
      run: backend
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              run: frontend
  egress:
    - to:
        - podSelector:
            matchLabels:
              run: database
```

### 示例 4：阻止对特定 IP 范围的出站流量

实际上，我们再来看一个例子。你也可以配置某些应用程序向你的集群中的特定 IP 发送流量。

而不是创建一个新的`yaml`配置文件，让我们更新你之前创建的`backend-default-policy.yaml`文件。你将替换`yaml`配置的出站部分。不使用`podSelector`来限制 IP 到数据库，而是使用`ipBlock`。

打开文件，并使用以下代码更新文件的内容：

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-default
  namespace: network-policy-tutorial
spec:
  podSelector:
    matchLabels:
      run: backend
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              run: frontend
  egress:
    - to:
        - ipBlock:
             cidr: <DATABASE-CLUSTER-IP>/24
```

在此更新的`backend-default-policy.yaml`配置中，你将阻止前端应用程序向这个 IP 范围（<`DATABASE-CLUSTER-IP`>`/24`）发送出站流量，这个 IP 范围包含你的数据库。这意味着，如果你的 <`DATABASE-CLUSTER-IP`> 是`10.10.10.10`，那么从`10.10.10.0`到`10.10.10.255`的所有 IP 请求都被阻止。

在应用配置之前，首先检查网络策略。你应该看到以下内容：

```bash
kubectl get networkpolicy --namespace=network-policy-tutorial

NAME                    POD-SELECTOR   AGE
backend-default         run=backend    6m16s
database-default        run=database   5m48s
frontend-default        run=frontend   6m50s
namespace-default-deny  <none>         8m22s
```

现在，在你的集群中应用`backend-default-policy.yaml`的更新配置：

```bash
kubectl apply -f backend-default-policy.yaml --namespace=network-policy-tutorial
```

请注意，没有添加新的网络策略。这是因为你没有更改`metadata.name`标签，Kubernetes 更新了网络策略的配置，而不是创建新的网络策略。

现在，如果你尝试从 `frontend` 访问 `database` ，就不再可能了：

```bash
kubectl exec -it backend --namespace=network-policy-tutorial -- curl <DATABASE-CLUSTER-IP>
```

你可以使用 `kubectl delete` 命令删除网络策略。例如，你可以这样删除 `backend-default-policy`：

```bash
kubectl delete -f backend-default-policy.yaml --namespace=network-policy-tutorial
```

配置使 `backend` 能够从 `frontend` 接收流量的网络策略已被删除； `frontend` 应用程序无法再访问 `backend` 。

## Kubernetes 网络策略使用的最佳实践

当然，在创建 Kubernetes 网络策略时，有一些最佳实践需要记住。让我们看看其中几个最重要的实践。

### 确保适当的隔离

由于 Kubernetes 网络策略允许你控制 pod 之间的网络流量，因此定义它们以确保适当的隔离至关重要。

确保适当隔离的第一步是确定哪些 pod 应该允许彼此通信，哪些应该相互隔离。然后定义规则来强制执行这些策略。

你还应该：

- 使用命名空间将工作负载彼此隔离。
- 为每个命名空间定义网络策略，根据最小权限原则限制流量。
- 将 pod 和服务之间的网络流量限制为仅满足其操作所需的内容。
- 使用标签和选择器将网络策略应用于特定的 pod 和/或服务。

### 监控和记录网络策略活动

监控和记录网络策略活动是检测和调查安全事件、排除网络问题并识别优化机会的关键，监控可以确保网络策略被正确执行，没有漏洞或配置不当。

使用 Kubernetes 工具如 `kubectl logs` 和 `kubectl describe`，你可以查看网络策略的日志和状态信息。你也可以使用第三方监控和日志解决方案来获得更多的网络流量和策略执行的可见性。

### 在大型集群中扩展网络策略

当你的集群开始增长，特别是当你在集群中拥有多个应用程序时，集群中的 Pod 数量和网络策略数量将显着增加。设计你的网络策略，使它们可以随着集群的增长、工作负载和节点数量的增加而扩展。

你可以通过使用选择性 Pod 标签和 Pod 匹配规则、避免过度限制策略以及使用高效的网络策略实现来实现可扩展性。不要忘记定期审查和优化你的网络策略，以确保它们仍然是必要和有效的。

### 评估第三方网络策略解决方案

虽然 Kubernetes 包含了对网络策略的内置支持，但你也可以使用提供额外功能的第三方解决方案。

对它们进行评估时，应考虑以下因素：

- 部署的易用性
- 与你现有的网络基础设施的兼容性
- 性能和可扩展性
- 易用性和维护性

当然，确保你使用的任何第三方解决方案都遵守 Kubernetes API 标准，并且与你的 Kubernetes 集群版本兼容。

## 结论

显然，Kubernetes 网络策略是一种强大的工具，用于在集群中的工作负载之间安全地控制网络流量。它们允许你在细粒度级别上定义和执行网络安全策略，确保适当的隔离并降低未经授权的访问或数据泄露的风险。

现在你已经学会了 Kubernetes 网络策略的基础知识，可以使用 `kubectl` 命令创建和执行策略，阻止对特定 IP 范围的出站流量以及限制不同名称空间中的 Pod 之间的流量。你还学会了一些实施网络策略的最佳实践，例如监视和记录策略活动以及评估第三方网络策略解决方案。

## 其他资源

如果你想了解更多关于 Kubernetes 网络和网络策略的信息，Kubernetes 的官方文档当然是一个不错的起点。其他有用的资源包括 Kubernetes 社区论坛、博客和在线课程：

- [Kubernetes 网络策略](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Kubernetes 网络概念](https://kubernetes.io/docs/concepts/cluster-administration/networking/)
- [NetworkPolicy API 参考](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.27/#networkpolicy-v1-networking-k8s-io)

请记住，尽管 Kubernetes 网络策略是一种强大的工具，但它们需要仔细规划才能发挥作用。遵循最佳实践并利用正确的资源，你可以确保你的网络策略为 Kubernetes 集群提供强大的安全性和控制。
