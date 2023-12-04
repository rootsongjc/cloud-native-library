---
title: 集群之间的连接与故障切换
weight: 6
---

Tetrate 使应用所有者能够轻松地在多个集群中部署应用程序。可以在选择的工作区中部署东西向网关，并将一些或所有服务暴露给其他集群。Tetrate 的中央服务注册表用于在其他集群中为这些暴露的服务创建虚拟端点（**ServiceEntries**），以便客户端可以发现和使用这些服务，就像它们在本地运行一样。

这项功能可用于：
 * 在不同的集群中分发应用程序的组件
 * 从远程集群访问集中式共享服务，如数据库微服务
 * 在不同集群之间为服务实例提供故障切换
 * 通过确保相同的应用程序和寻址方案在一个集群中或分布在多个集群中，简化测试

平台所有者（"Platform"）为故障转移案例准备了平台，应用程序所有者（"Apps"）可以在对其工作流程进行最少修改的情况下利用这些功能。

平台所有者将按以下方式准备平台：

1. 部署东西向网关
    在包含要共享的服务的命名空间中部署东西向网关。

2. 更新工作区以暴露所需的服务
    更新工作区以暴露所需的服务，以便它们可以在其他集群中被发现和使用。

3. 为内部故障切换部署东西向网关
    在其他集群中部署额外的东西向网关以进行服务故障切换。
    然后，应用程序所有者可以：

4. 访问已暴露的服务
    从其他集群中访问已暴露的服务。

5. 在集群之间进行故障切换
    验证服务能否从一个集群故障转移到另一个集群中的备份实例。

## 平台：开始之前

在开始之前，你需要知道：

 * 共享服务所在的工作区
 * 应暴露哪些服务；默认情况下，工作区中的所有服务都会被暴露

你还可以查看 TSE 入门用例：[高可用性](https://docs.tetrate.io/service-express/getting-started/ha-eastwest) 和 [跨集群通信](https://docs.tetrate.io/service-express/getting-started/cross-cluster)。


## 平台：部署东西向网关

在包含要共享服务的命名空间中部署一个东西向网关：

```bash
cat <<EOF > eastwest-gateway.yaml
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: eastwest-gateway
  namespace: bookinfo
spec:
  eastWestOnly: true
EOF

kubectl apply -f eastwest-gateway.yaml
```

列出在本地集群中运行的东西向网关：

```bash
kubectl get pods -A -l app=eastwest-gateway
```

## 平台：更新工作区以暴露所需的服务

更新与工作区相关联的 **WorkspaceSettings**：

```yaml
apiVersion: settings.tetrate.io/v1alpha1
kind: WorkspaceSetting
metadata:
  name: my-workspace-setting
  namespace: bookinfo
spec:
  workspace: my-workspace
  defaultEastWestGatewaySettings:
    workloadSelector:
      app: eastwest-gateway
    exposedServices:
      - "details.bookinfo.svc.cluster.local"
      - "reviews.bookinfo.svc.cluster.local"
```

请注意，**defaultEastWestGatewaySettings** 使用 **workloadSelector** 识别东西向网关，并具有一个可选的 **exposedServices** 部分。

应用程序所有者可以从远程集群中发现和使用这些共享服务。它们作为 **xcp-multicluster** 命名空间中的 **ServiceEntries** 暴露，并且使用与第一个集群中相同的 FQDN：

```bash
kubectl get serviceentry -n xcp-multicluster
```

请注意，如果应用程序所有者在远程集群中部署了相同的服务，那么 Tetrate 控制平台将删除 **ServiceEntries**，以便该集群中的客户端更喜欢在同一集群中的服务实例。

## 应用程序：访问已暴露的服务

一旦在源集群中部署了东西向网关，并使用 **WorkspaceSettings:defaultEastWestGatewaySettings** 选择了要暴露的服务，就可以在源集群中部署服务。匹配的服务将在远程集群中暴露出来。

你可以通过以下方式在远程集群中查看暴露服务的列表如下：

```bash
kubectl get serviceentry -n xcp-multicluster
```

这些服务的完全限定域名（FQDN）在远程集群中是可寻址的，这意味着远程集群中的任何客户端服务都可以访问原始服务，无需进行任何修改。Tetrate 平台会保持**ServiceEntries**与原始服务的存在和状态同步。
## 平台：为内部故障切换部署东西向网关

在这种情况下，我们将准备平台以便在一个集群与另一个集群之间进行内部服务的故障转移。例如，一个应用所有者可以将一个多组件的应用程序（如 **bookinfo**）部署到两个集群中。每个应用程序将使用本地版本的依赖服务，除非本地实例失败，在这种情况下，Tetrate 平台将自动将流量切换到另一个集群。应用所有者不需要进行任何应用程序修改。

#### 先决条件

1. 必须在每个工作负载集群中创建应用程序的命名空间。
2. Tetrate 工作区必须包括这些命名空间，并且必须跨足每个工作负载集群。

例如，如果要在命名空间 **bookinfo** 中部署应用程序，那么这个命名空间必须在每个集群中存在，并且 **Workspace** 配置应引用所有实例，例如，使用以下 **namespaceSelector**：

```yaml
spec:
  namespaceSelector:
    names:
      - "*/bookinfo"
```

#### 部署一个东西向网关

在其他集群中部署额外的东西向网关，与之前完全相同：

```bash
cat <<EOF > eastwest-gateway.yaml
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: eastwest-gateway
  namespace: bookinfo
spec:
  eastWestOnly: true
EOF

kubectl apply -f eastwest-gateway.yaml
```

## 应用程序：在集群之间测试故障转移

通过上述配置，你可以将应用程序部署到多个集群中。如果一个集群中的服务实例因任何原因失败，Tetrate 平台将检测到并将流量透明地切换到远程工作正常的服务实例。

Tetrate 平台为集群中的每个远程服务实例创建了影子 **WorkloadEntries**，这些实例存在于本地实例所在的集群和命名空间中。例如，如果你将 **bookinfo** 应用程序部署到两个配置有高可用性的集群中，然后你可以检查每个集群以查看影子 **WorkloadEntries** 是否存在。

在下面的案例中，我们只暴露了 **details** 和 **reviews** 服务，并且云平台在三个 IP 地址上暴露了 **eastwest-gateway**：

```bash
kubectl get workloadentries -n bookinfo
# NAME                                           AGE   ADDRESS
# k-details-fc556d47e94d1cb435e513fa016c2243     17m   18.135.167.198
# k-details-fc556d47e94d1cb435e513fa016c2243-2   17m   18.168.99.230
# k-details-fc556d47e94d1cb435e513fa016c2243-3   17m   35.179.51.164
# k-reviews-3ab8d1334c8f22513cd591f84c978f88     17m   18.135.167.198
# k-reviews-3ab8d1334c8f22513cd591f84c978f88-2   17m   18.168.99.230
# k-reviews-3ab8d1334c8f22513cd591f84c978f88-3   17m   35.179.51.164

kubectl get svc -n bookinfo eastwest-gateway
# NAME               TYPE           CLUSTER-IP      EXTERNAL-IP                                                                     PORT(S)           AGE
# eastwest-gateway   LoadBalancer   10.100.17.100   k8s-bookinfo-eastwest-00a17af379-bdda7f4eb8c5da5c.elb.eu-west-2.amazonaws.com   15443:30082/TCP   82m
```

要了解更多信息，请查看 TSE 入门练习 [在集群之间进行故障切换](https://docs.tetrate.io/service-express/getting-started/ha-eastwest)。
