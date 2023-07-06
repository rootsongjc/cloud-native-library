---
weight: 5
title: Kubernetes 网络策略
date: '2022-06-17T12:00:00+08:00'
type: book
---

本节介绍 Kubernetes 的网络策略方面。

## 命名空间

[命名空间](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/) 用于在 Kubernetes 中创建虚拟集群。包括 NetworkPolicy 和 CiliumNetworkPolicy 在内的所有 Kubernetes 对象都属于一个特定的命名空间。根据定义和创建策略的方式，会自动考虑 Kubernetes 命名空间：

- [作为 CiliumNetworkPolicy](https://docs.cilium.io/en/stable/concepts/kubernetes/policy/#ciliumnetworkpolicy) CRD 和 [NetworkPolicy](https://docs.cilium.io/en/stable/concepts/kubernetes/policy/#networkpolicy) 创建和导入的网络策略适用于命名空间内，即该策略仅适用于该命名空间内的 pod。但是，可以授予对其他命名空间中的 pod 的访问权限，如下所述。
- [通过 API 参考](https://docs.cilium.io/en/stable/api/#api-ref) 直接导入的网络策略适用于所有命名空间，除非如下所述指定命名空间选择器。

{{<callout note 提示>}}
虽然有意支持通过 `fromEndpoints` 和 `toEndpoints` 中的 `k8s:io.kubernetes.pod.namespace` 标签指定命名空间。禁止在 `endpointSelector` 中指定命名空间，因为这将违反 Kubernetes 的命名空间隔离原则。`endpointSelector` 总是适用于与 `CiliumNetworkPolicy` 资源本身相关的命名空间的 pod。
{{</callout>}}

###  示例：强制命名空间边界

此示例演示如何为命名空间强制实施基于 Kubernetes 命名空间的边界，`ns1` 和 `ns2` 通过在任一命名空间的所有 pod 上启用默认拒绝，然后允许来自同一命名空间内的所有 pod 的通信。

```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "isolate-ns1"
  namespace: ns1
spec:
  endpointSelector:
    matchLabels:
      {}
  ingress:
  - fromEndpoints:
    - matchLabels:
        {}
---
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "isolate-ns1"
  namespace: ns2
spec:
  endpointSelector:
    matchLabels:
      {}
  ingress:
  - fromEndpoints:
    - matchLabels:
        {}
```

### 示例：跨命名空间公开 pod

以下示例将所有 `ns1` 命名空间所有具有 `name=leia` 标签的 pod 暴露给 `ns2` 命名空间具有 `name=luke` 标签的 pod。

请参阅[示例 YAML 文件](https://raw.githubusercontent.com/cilium/cilium/1.11.6/examples/policies/kubernetes/namespace/demo-pods.yaml) 以获取完整的功能示例，包括部署到不同命名空间的 pod。

```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "k8s-expose-across-namespace"
  namespace: ns1
spec:
  endpointSelector:
    matchLabels:
      name: leia
  ingress:
  - fromEndpoints:
    - matchLabels:
        k8s:io.kubernetes.pod.namespace: ns2
        name: luke
```

### 示例：允许 egress 到 kube-system 命名空间中的 kube-dns

以下示例允许 `public` 创建策略的命名空间中的所有 pod 与 `kube-system` 空间中 53/UDP  端口上的 kube-dns 通信。

```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "allow-to-kubedns"
  namespace: public
spec:
  endpointSelector:
    {}
  egress:
  - toEndpoints:
    - matchLabels:
        k8s:io.kubernetes.pod.namespace: kube-system
        k8s-app: kube-dns
    toPorts:
    - ports:
      - port: '53'
        protocol: UDP
```

## 服务账户

Kubernetes [服务账户](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/)用于将身份与 Kubernetes 管理的 pod 或进程相关联，并授予身份对 Kubernetes 资源和机密的访问权限。Cilium 支持基于 Pod 的服务账户身份来规范网络安全策略。

Pod 的服务账户可以通过[服务账户准入控制器](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#serviceaccount)定义，也可以直接在 Pod、Deployment、ReplicationController 资源中指定，如下所示：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  serviceAccountName: leia
  ...
```

### 例子

以下示例授予在“luke”服务账户下运行的任何 pod 向与“leia”服务账户关联的所有运行的 pod 发出 TCP 80 端口 80 上的 `HTTP GET /public` 请求。

请参阅[示例 YAML 文件](https://raw.githubusercontent.com/cilium/cilium/1.11.6/examples/policies/kubernetes/serviceaccount/demo-pods.yaml) 以获取完整的功能示例，包括部署和服务账户资源。

```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "k8s-svc-account"
spec:
  endpointSelector:
    matchLabels:
      io.cilium.k8s.policy.serviceaccount: leia
  ingress:
  - fromEndpoints:
    - matchLabels:
        io.cilium.k8s.policy.serviceaccount: luke
    toPorts:
    - ports:
      - port: '80'
        protocol: TCP
      rules:
        http:
        - method: GET
          path: "/public$"
```

## 多集群

当使用集群网格操作多个集群时，集群名称通过标签公开 `io.cilium.k8s.policy.cluster`，可用于将策略限制到特定集群。

```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "allow-cross-cluster"
  description: "Allow x-wing in cluster1 to contact rebel-base in cluster2"
spec:
  endpointSelector:
    matchLabels:
      name: x-wing
      io.cilium.k8s.policy.cluster: cluster1
  egress:
  - toEndpoints:
    - matchLabels:
        name: rebel-base
        io.kubernetes.pod.namespace: default
        io.cilium.k8s.policy.cluster: cluster2
```

注意策略规则中的 `io.kubernetes.pod.namespace: default`。它确保策略适用于 cluster2 默认命名空间中的 `rebel-base`，而不考虑 `x-wing` 部署在 cluster1 中的命名空间。如果政策规则的命名空间标签被省略，它默认为策略本身应用的相同命名空间，这可能不是部署跨集群策略时想要的。

## 集群范围的策略

[CiliumNetworkPolicy](https://docs.cilium.io/en/stable/concepts/kubernetes/policy/#ciliumnetworkpolicy) 只允许绑定限制到特定命名空间的策略。在某些情况下，可以使用 Cilium 的 [CiliumClusterwideNetworkPolicy](https://docs.cilium.io/en/stable/concepts/kubernetes/policy/#ciliumclusterwidenetworkpolicy) Kubernetes 自定义资源来实现集群范围内的策略效果。该策略的规范与[CiliumNetworkPolicy](https://docs.cilium.io/en/stable/concepts/kubernetes/policy/#ciliumnetworkpolicy) 的规范相同，只是它没有命名空间。

在集群中，这个策略将允许从任何命名空间中匹配标签 `name=luke` 的 pod 到任何命名空间中匹配标签 `name=leia` 的 pod 的入站流量。

```yaml
apiVersion: "cilium.io/v2"
kind: CiliumClusterwideNetworkPolicy
metadata:
  name: "clusterwide-policy-example"
spec:
  description: "Policy for selective ingress allow to a pod from only a pod with given label"
  endpointSelector:
    matchLabels:
      name: leia
  ingress:
  - fromEndpoints:
    - matchLabels:
        name: luke
```

### 示例：允许所有流量进入 kube-dns

以下示例允许集群中的所有 Cilium 托管端点与 `kube-system` 命名空间中 53/UDP 端口上的 kube-dns 通信。

```yaml
apiVersion: "cilium.io/v2"
kind: CiliumClusterwideNetworkPolicy
metadata:
  name: "wildcard-from-endpoints"
spec:
  description: "Policy for ingress allow to kube-dns from all Cilium managed endpoints in the cluster"
  endpointSelector:
    matchLabels:
      k8s:io.kubernetes.pod.namespace: kube-system
      k8s-app: kube-dns
  ingress:
  - fromEndpoints:
    - {}
    toPorts:
    - ports:
      - port: "53"
        protocol: UDP
```

### 示例：添加健康端点

以下示例将健康实体添加到所有 Cilium 托管端点，以检查集群连接健康状况。

```yaml
apiVersion: "cilium.io/v2"
kind: CiliumClusterwideNetworkPolicy
metadata:
  name: "cilium-health-checks"
spec:
  endpointSelector:
    matchLabels:
      'reserved:health': ''
  ingress:
    - fromEntities:
      - remote-node
  egress:
    - toEntities:
      - remote-node
```

{{< cta cta_text="下一章" cta_link="../../kubernetes" >}}
