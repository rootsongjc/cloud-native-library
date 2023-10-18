---
title: 集群准备
weight: 1
---

平台所有者（"平台"）将通过以下步骤准备一个集群：

1. 部署 TSE/TSB

   首先部署 TSE 或 TSB，并启动预期的工作负载集群。

2. 启用严格（零信任）安全

   配置平台以遵循 'require-mTLS' 和 'deny-all' 的零信任安全策略。

3. 创建 Kubernetes 命名空间

   在每个将由应用所有者用于托管服务和应用程序的集群中创建并标记命名空间。

4. 创建 Tetrate 工作区

   创建将用于管理命名空间内服务行为的 Tetrate 工作区和相关配置。

5. 部署入口网关

   如有需要，在将托管应该提供给外部访问的服务的工作区中部署入口网关。

6. 启用 GitOps 集成

   启用 GitOps 集成，以便应用所有者用户可以在不需要 Tetrate 特权访问的情况下与平台交互。

7. 启用其他集成

   启用其他集成，以便应用所有者用户可以在不需要 Tetrate 特权访问的情况下与平台交互。

## 平台：部署 TSE/TSB

按照产品说明部署 TSE 或 TSB 管理平面，然后启动预期的工作负载集群。

请确保安装所需的附加组件并满足必要的先决条件。

## 平台：启用严格安全

你应该使用 TSE/TSB 配置平台以零信任方式运行。具体来说：

 * 组件与应用所有者服务之间的所有通信都使用 mTLS 进行安全保护。这意味着外部的第三方，例如集群中的其他服务或具有数据路径访问权限的服务，不能读取事务、修改事务或冒充客户或服务。
 * 默认情况下拒绝所有通信。平台所有者必须明确打开所需的通信路径。这意味着只允许明确允许的通信。

### 严格安全

**TSE**

导航到 **设置** > **基本设置**。确保 **Enforce mTLS** 和 **Deny-All** 都已启用：

![TSE 安全设置](../images/tse-security.png)

你也可以使用 Tetrate API 配置严格安全，方法是遵循 Tetrate Service Bridge 的说明。

在 Tetrate 产品中，默认设置与顶级组织关联，顶级组织在 TSB 中是可定义的，而在 TSE 中设置为值 `tse`。

你将在名为 **default** 的 **OrganizationSetting** 中的 **OrganizationSetting.spec.defaultSecuritySetting** 部分中找到安全设置：

```bash
tctl get os -o yaml
```

可以在租户或工作区的基础上进一步覆盖这些设置（请注意，TSE 有一个名为 **tse** 的单一租户，而 TSB 支持多个用户定义的租户）。

 * 要默认要求使用 mTLS，请将 **authenticationSettings.trafficMode** 设置为 **REQUIRED**
 * 要默认声明拒绝所有通信，请将 **authorization.rules.denyAll** 设置为 **true**
 * 要防止子资源覆盖这些设置，请将 **propagationStrategy** 设置为 **STRICTER**（此步骤是非必需的）

可以在 [TSB API 参考](https://docs.tetrate.io/service-bridge/latest/refs/tsb/v2/organization_setting) 中找到这些设置的描述。

稍后，你将有选择地覆盖这些设置以允许允许的流量。

## 平台：创建 Kubernetes 命名空间

Kubernetes 的核心隔离单元是[命名空间](https://kubernetes.io/docs/concepts/security/multi-tenancy/)。许多部署使用非常细粒度的命名空间以强制执行高级别的控制并为每个服务提供重复配置的自由。

一旦将工作负载集群接入到 TSE/TSB 中，然后可以创建每个应用所有者团队将需要的命名空间，并为 Istio 注入进行标记。这就是命名空间中的资源将由 TSE/TSB 管理所需的全部内容：

```bash
kubectl create namespace bookinfo
kubectl label namespace bookinfo istio-injection=enabled
```

## 平台：创建 Tetrate 工作区

在实践中，细粒度的命名空间并不准确地模拟许多企业遵循的应用程序和团队结构。应用程序由多个命名空间组成，通常跨越多个不同的集群、区域、地区甚至云。

出于这个原因，Tetrate 引入了一个称为 **工作区** 的更高级别的结构。工作区是 Tetrate 产品中的主要隔离单元，它只是一个或多个集群中的一组命名空间。

![命名空间和工作区](../images/namespace-workspace.png)

工作区提供了一个便捷的更高级别抽象，与组织的应用程序保持一致，这些应用程序通常跨越多个命名空间和/或集群。

<details>
<summary><b>TSB 租户</b></summary>

Tetrate Service Express（TSE）提供一个单一的组织（用于全局设置）和多个工作区（用于个别设置）。TSE 旨在由单个团队使用。

Tetrate Service Bridge 添加了一个中间层的 **租户** 概念，允许在顶级组织内拥有多个独立的团队。**租户** 可以在团队层面上应用额外的隔离，并可以覆盖全局设置。

在本文档中，我们假设组织内只有一个团队，因此所有设置将应用于工作区级别。示例将使用名为 `tse` 的组织和名为 `tse` 的租户；当使用 TSB 时，你应该将这些更改为反映你选择的层次结构。
</details>

为每个应用程序创建 Tetrate 工作区，覆盖分配给该应用程序的命名空间：

 * 通过工作区的 **namespaceSelector** 定义命名空间列表。条目可以限制在单个集群中 ```cluster-1/bookinfo```，也可以跨足所有集群 ```*/bookinfo```
 * 注意我们如何使用 **WorkspaceSetting** 覆盖了每个工作区的 **defaultSecuritySetting**。

```bash
cat <<EOF > bookinfo-ws.yaml
apiversion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: tse
  tenant: tse
  name: bookinfo-ws
spec:
  namespaceSelector:
    names:
      - "*/bookinfo"
---
apiVersion: api.tsb.tetrate.io/v2
kind: WorkspaceSetting
metadata:
  organization: tse
  tenant: tse
  workspace: bookinfo-ws
  name: bookinfo-ws-settings
spec:
  defaultSecuritySetting:
    authenticationSettings:
      trafficMode: REQUIRED
    authorization:
      mode: WORKSPACE
EOF

tctl apply -f bookinfo-ws.yaml
```

在打开一个工作区（**authorization.mode: WORKSPACE**）时，你在零信任环境中创建了一个“泡泡”。该工作区内的所有服务可以相互通信，但必须使用 mTLS。

## 平台：部署入口网关

通常，你会希望安排外部流量到达工作区内的特定服务。为此，你首先应在每个集群中的每个工作区部署一个**入口网关**。应用程序所有者随后可以定义通过此入口网关公开其服务的网关规则。

### 创建 Tetrate 网关组

首先，创建一个 Tetrate 网关组，其范围限定在将托管入口网关的每个工作区和集群内。例如，如果 **Bookinfo** 工作区跨足了 **cluster-1** 和 **cluster-2**，你可以为此工作区创建两个网关组，每个集群一个：

```bash
cat <<EOF > bookinfo-gwgroup-cluster-1.yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
  name: bookinfo-gwgroup-cluster-1
  organization: tse
  tenant: tse
  workspace: bookinfo-ws
spec:
  namespaceSelector:
    names:
      - "cluster-1/bookinfo"
EOF

tctl apply -f bookinfo-gw-group-1.yaml
```

### 部署入口网关

接下来，在要接收外部流量的每个工作区和集群中部署一个入口网关：

```bash
cat <<EOF > bookinfo-ingress-gw.yaml
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: bookinfo-ingress-gw
  namespace: bookinfo
spec:
  kubeSpec:
    service:
      type: LoadBalancer
EOF

kubectl apply -f bookinfo-ingress-gw.yaml
```

这一步将在相应的命名空间中创建一个 **envoy 代理** pod，它将作为入口网关运行（```kubectl get pod -n bookinfo -l app=bookinfo-ingress-gw```）。请注意，你使用 IngressGateway 在特定集群中创建资源，因此使用 ```kubectl``` 部署资源。

稍后，应用程序所有者将想要创建 **Gateway** 资源以公开其选择的服务。他们需要知道：

 * Tetrate 工作区的名称，例如 **bookinfo-ws**
 * 每个集群上 Tetrate 网关组的名称，例如 **bookinfo-gwgroup-cluster-1**
 * 每个集群上入口网关的名称，例如 **bookinfo-ingress-gw**。可以在所有集群上使用相同的名称

入口网关非常轻量级，并且为了安全和容错目的，为每个工作区运行一个单独的入口网关提供了隔离。对于非常大型的部署，你可能希望在多个工作区之间[共享入口网关](../../howto/gateway/shared-ingress)。

## 平台：启用 GitOps 集成

提供 Tetrate 管理的平台配置有两种方式：

 * 使用 `tctl` 提供平台范围的配置，调用用户需要对 Tetrate API 服务器进行身份验证
 * 使用 `kubectl` 提供每个集群的配置，调用用户需要对 Kubernetes API 服务器进行身份验证

对于某些用例，用户（平台所有者或应用程序所有者）需要提供平台范围和每个集群的配置。

Tetrate 的 GitOps 集成允许用户使用 Kubernetes API 提供平台范围的配置。GitOps 应该在一个或多个集群上启用；该过程会安装 Tetrate 平台范围配置的 CRD，任何资源都会自动从集群推送到 Tetrate API 服务器：

 * **Tetrate Service Express：** 在 Tetrate Service Express 上默认启用 GitOps 集成。有关集成的概述，请参阅 [TSE 中的 GitOps](https://docs.tetrate.io/service-express/gitops/gitops-tse) 指南。
 * **Tetrate Service Bridge：** 你需要在 Tetrate Service Bridge 上明确启用 GitOps。有关详细信息，请参阅 TSB 文档中的 [配置 GitOps](../../../operations/features/configure-gitops)。

总的来说，GitOps 不仅适用于 GitOps 的用例。即使在组织采用 GitOps 姿态来管理配置之前，它也是有用的；GitOps 也可以用于允许选定的 K8s 用户管理 Tetrate 配置。这意味着用户不必拥有 Tetrate 用户/角色，他们可以使用他们已经习惯的 K8s 工具。

## 平台：启用额外的集成

你可能希望为你的平台启用其他集成。例如，在使用 AWS 时：

 * 安装 [AWS 负载均衡控制器](http://docs.tetrate.io/service-express/installation/eks-cluster#install-aws-load-balancer-controller) 以实现更好的负载均衡器集成
 * 启用 [AWS Route 53 控制器](https://docs.tetrate.io/service-express/integrations/route53#enabling-the-integration) 以管理由应用程序所有者公开的服务的 DNS 记录条目
