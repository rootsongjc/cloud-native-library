---
title: TSB 升级
description: "使用 TSB Operator 升级 TSB。"
weight: 5
---

本页将指导你如何使用 `tctl` CLI 升级 TSB，呈现不同 Operator 的 Kubernetes 清单，并使用 `kubectl` 将它们应用到集群中以进行升级。

在开始之前，请确保你已完成以下操作：

- 检查新版本的 [要求](../../requirements-and-download)

基于 Operator 的版本之间的升级过程相对简单。一旦 Operator 的 Pod 使用新的发布镜像进行了更新，新生成的 Operator Pod 将升级所有必要的组件以适应新版本。

## 创建备份

为了确保在出现问题时可以恢复一切，请为管理平面和每个集群的本地控制平面创建备份。

### 备份管理平面

#### 备份 `tctl` 二进制文件

由于每个新的 `tctl` 二进制文件可能都附带了新的 Operator 和配置来部署和配置 TSB，因此你应该备份当前正在使用的 `tctl` 二进制文件。请在同步新镜像之前执行此操作。

将带有版本后缀的 `tctl` 二进制文件（例如 `-1.3.0`）复制到一个位置，以便在需要时快速还原旧版本。

```bash
cp ~/.tctl/bin/tctl ~/.tctl/bin/tctl-{version}
```

如果你不小心丢失了二进制文件，你可以从 [此网址](https://binaries.dl.tetrate.io/public/raw/) 找到正确的版本。但强烈建议你备份当前的副本以确保安全。

#### 备份 ManagementPlane CR

通过执行以下命令创建 `ManagementPlane` CR 的备份：

```bash
kubectl get managementplane -n tsb -o yaml > mp-backup.yaml
```

#### 备份 PostgreSQL 数据库

[创建 PostgreSQL 数据库的备份](../../../operations/postgresql)。

连接到数据库的确切过程可能因你的环境而异，请参考你的环境的文档。

### 备份控制平面自定义资源

通过在每个已载入集群上执行以下命令，创建所有 `ControlPlane` CR 的备份：

```
kubectl get controlplane -n istio-system -o yaml > cp-backup.yaml
```

## 升级过程

### 下载 `tctl` 和同步镜像

现在你已经创建了备份，请 [下载新版本的 `tctl` 二进制文件](../../requirements-and-download)，然后获取新的 TSB 容器镜像。

有关如何执行此操作的详细信息在 [要求和下载页面](../../requirements-and-download) 中有描述。

### 创建管理平面 Operator

创建基本清单，它将允许你从私有 Docker 注册表中更新管理平面 Operator：

```bash
tctl install manifest management-plane-operator \
    --registry <your-docker-registry> \
    > managementplaneoperator.yaml
```

{{<callout note 管理命名空间名称>}}
从 TSB 0.9.0 开始，默认的管理平面命名空间名称是 `tsb`，而不是较早版本中使用的 `tcc`。如果你使用早于 0.9.0 的版本安装了 TSB，则你的管理平面可能位于 `tcc` 命名空间中。你需要添加 `--management-namespace tcc` 标志以反映这一点。
{{</callout>}}

{{<callout note "自定义">}}
由 install 命令创建的 managementplaneoperator.yaml 文件现在可以用作管理平面升级的基本模板。如果你的现有 TSB 配置包含在标准配置之上的特定调整，你应该将它们复制到新模板中。
{{</callout>}}

现在，将清单添加到源代码控制或直接使用 kubectl 客户端将其应用到管理平面集群：

```bash
kubectl apply -f managementplaneoperator.yaml
```

应用清单后，你将在 `tsb` 命名空间中看到新的 Operator 运行：

```bash
kubectl get pod -n tsb
名称                                            准备就绪   状态    重启   年龄
tsb-operator-management-plane-d4c86f5c8-b2zb5   1/1     运行中   0          8s
```

有关清单以及如何配置它的更多信息，请查看 [`ManagementPlane` CR 参考](../../../refs/install/managementplane/v1alpha1/spec)。

### 创建控制平面和数据平面 Operator

要在你的应用程序集群中部署新的控制平面和数据平面 Operator，必须运行 [`tctl install manifest cluster-operators`](../../../../reference/cli/reference/install#tctl-install-manifest-cluster-operators) 来检索新版本的控制平面和数据平面 Operator 清单。

```bash
tctl install manifest cluster-operators \
    --registry <your-docker-registry> \
    > clusteroperators.yaml
```
{{<callout note 自定义>}}
clusteroperators.yaml 文件现在可用于你的集群升级。如果你的现有控制平面和数据平面具有标准配置之上的特定调整，你应该将它们复制到模板中。
{{</callout>}}

### 查看 tier1gateways 和 ingressgateways

由于 [Istio 1.14](https://github.com/istio/istio/pull/36928) 中引入的修复，当同时设置 `replicaCount` 和 `autoscaleEnaled` 时，将会忽略 `replicaCount`，只会应用自动缩放配置。这可能导致 `tier1gateways` 和 `ingressgateways` 在升级过程中暂时缩减到 1 个副本，直到应用自动缩放配置

。为了避免此问题，你可以编辑 `tier1gateway` 或 `ingressgateway` 规范，删除 `replicas` 字段，由于当前部署已由 HPA 控制器管理，因此这将允许你使用所需的配置升级 Pod。

你可以通过运行以下命令获取所有 `tier1gateways` 或 `ingressgateways`：

```bash
kubectl get tier1gateway.install -A
kubectl get ingressgateway.install -A
```

### 应用清单

现在，将清单添加到源代码控制或直接使用 kubectl 客户端将其应用到适当的集群中：

```bash
kubectl apply -f clusteroperators.yaml
```

有关每个清单以及如何配置它们的更多信息，请查看以下指南：

- [ControlPlane 资源参考](../../../refs/install/controlplane/v1alpha1/spec)
- [Data Plane 资源参考](../../../refs/install/dataplane/v1alpha1/spec)
- [Kubernetes 资源参考](../../../refs/install/kubernetes/k8s)

## 回滚

如果出现问题并且你想回滚 TSB 到之前的版本，你需要回滚管理平面和控制平面。

### 回滚控制平面

#### 缩减 `istio-operator` 和 `tsb-operator`

```bash
kubectl scale deployment \
   -l "platform.tsb.tetrate.io/component in (tsb-operator,istio)" \
   -n istio-system \
   --replicas=0
```

#### 删除 `IstioOperator` 资源

删除 Operator 将需要删除保护 istio 对象的 finalizer，使用以下命令：

```bash
kubectl patch iop tsb-istiocontrolplane -n istio-system --type='json' -p='[{"op": "remove", "path": "/metadata/finalizers", "value":""}]'


kubectl delete istiooperator -n istio-system --all
```

#### 缩减 `istio-operator` 和 `tsb-operator`，用于数据平面 Operator

```bash
kubectl scale deployment \
   -l "platform.tsb.tetrate.io/component in (tsb-operator,istio)" \
   -n istio-gateway \
   --replicas=0
```

#### 删除数据平面的 `IstioOperator` 资源

从 1.5.11 开始，包含 ingressgateways 的 IOP 被拆分为每个 ingressgateway 都有一个 IOP。为了回滚到旧的 Istio 版本，我们需要删除保护 istio 对象的 finalizer，并使用以下命令删除所有 Operator：

```bash
for iop in $(kubectl get iop -n istio-gateway --no-headers | grep -i "tsb-ingress" | awk '{print $1}'); do kubectl patch iop $iop -n istio-gateway --type='json' -p='[{"op": "remove", "path": "/metadata/finalizers", "value":""}]'; done

kubectl delete istiooperator -n istio-gateway --all
```

### 创建集群 Operator，回滚 ControlPlane CR

使用之前版本的 `tctl` 二进制文件，按照创建集群 Operator 的说明进行操作。

然后应用 `ControlPlane` CR 的备份：

```bash
kubectl apply -f cp-backup.yaml
```

### 回滚管理平面

#### 缩减管理平面中的 Pod

缩减管理平面中的所有 Pod，使其处于非活动状态。

```bash
kubectl scale deployment tsb iam -n tsb --replicas=0
```

#### 恢复 PostgreSQL

从备份中 [恢复 PostgreSQL 数据库](../../../operations/postgresql)。连接到数据库的确切过程可能因你的环境而异，请参考你的环境的文档。

#### 恢复 `tctl` 并创建管理平面 Operator

从你创建的备份副本中恢复 `tctl`，或者 [下载你想要使用的特定版本的二进制文件](https://binaries.dl.tetrate.io/public/raw/)。

```bash
mv ~/.tctl/bin/tctl-{version} ~/.tctl/bin/tctl
```

按照创建管理平面 Operator 的说明创建管理平面 Operator。然后应用 `ManagementPlane` CR 的备份：

```bash
kubectl apply -f mp-backup.yaml
```

#### 恢复部署

最后，恢复部署。

```bash
kubectl scale deployment tsb iam -n tsb --replicas 1
```
