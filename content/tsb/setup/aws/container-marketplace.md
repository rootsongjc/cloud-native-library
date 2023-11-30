---
title: 从 AWS 容器市场安装 TSB
weight: 2
---

本文档介绍了如何通过 AWS 容器市场在你的 Amazon Kubernetes (EKS) 集群中安装 Tetrate Service Bridge (TSB)。

{{<callout note 注意>}}
本文档适用于已经购买了 Tetrate 的 AWS 容器市场提供的用户。
如果你没有订阅 Tetrate 容器市场提供的服务，本文档将不起作用。
如果你对 AWS 市场的私有报价感兴趣，请联系 Tetrate。
{{</callout>}}

## Tetrate Operator 概述

Tetrate Operator 是 Tetrate 提供的 Kubernetes Operator，它使安装、部署和升级 TSB 更加简单。Tetrate Service Bridge 的 AWS 容器市场提供安装了 Tetrate Operator 的一个版本到 EKS 集群中。之后，TSB 可以安装在你 EKS 集群中的任何命名空间中。
在本文档中，假定 TSB 将安装在 `tsb` 命名空间中。

使用 Tetrate Operator 的先决条件
要使用市场上的 Tetrate 提供，确保满足以下要求：
* 你可以访问配置了服务帐户的 EKS 集群（Kubernetes 版本 1.16 或更高）。
* 你在 EKS 集群上具有集群管理员访问权限。
* 你已经设置了 EKS 集群，并且已经设置了 `kubectl`。
* 你已经[下载了 `tctl`](../../../../reference/cli/guide/index#installation)。

## 安装步骤

### 创建和配置 Kubernetes 集群的 AWS IAM 角色

AWS IAM 权限是通过 AWS 的 Kubernetes 服务帐户 IAM 角色授予 Tetrate 的。此功能必须在集群级别启用。
创建一个名为 `eks-tsb-operator` 的 IAM 角色，用于 Tetrate Operator pod，并根据 AWS 指南[为 EC2 配置它](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-service.html)。稍后将替换信任关系。
然后授予 AWS 管理策略 `AWSMarketplaceMeteringRegisterUsage` 给 `eks-tsb-operator`。

创建 IAM 角色的信任关系。使用以下模板，并将 `AWS_ACCOUNT_ID` 和 `OIDC_PROVIDER` 替换为适当的值。

`AWS_ACCOUNT_ID` 应替换为你的 AWS 帐户 ID。

`OIDC_PROVIDER` 应替换为你的 Kubernetes 集群的 OpenID Connect 提供程序 URL。在替换之前，你必须删除 URL 中的 `https://` 前缀。

有关 EKS 集群的 IAM OIDC 提供程序的详细信息，请参阅[官方文档](https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html)。

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::AWS_ACCOUNT_ID:oidc-provider/OIDC_PROVIDER"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "OIDC_PROVIDER:sub": "system:serviceaccount::tsb:tsb-operator-management-plane"
        }
      }
    }
  ]
}
```

### 安装 Tetrate Operator 和 TSB 管理平面

使用 Tetrate CLI (`tctl`)，生成 Tetrate Operator 的 Kubernetes 清单，并将其安装到你的 Kubernetes 集群中。

使用以下命令生成 TSB 管理平面的 CRDs：

```bash
tctl install manifest management-plane-operator \
   --registry 709825985650.dkr.ecr.us-east-1.amazonaws.com/tetrate-io > managementplaneoperator.yaml
```

打开上面创建的 `managementplaneoperator.yaml` 文件，找到 `tsb-operator-management-plane` 的 `ServiceAccount` 定义。在 `ServiceAccount` 的 YAML 定义内部，添加 `annotation` 部分，包含 IAM 角色信息，以便 ServiceAccount 可以访问它。将注释中的 `AWS_ACCOUNT_ID` 替换为你的 AWS 帐户 ID：

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    platform.tsb.tetrate.io/application: tsb-operator-managementplane
    platform.tsb.tetrate.io/component: tsb-operator
    platform.tsb.tetrate.io/plane: management
  name: tsb-operator-management-plane
  namespace: 'tsb'
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::AWS_ACCOUNT_ID:role/eks-tsb-operator 
```

使用 `kubectl` 部署 Operator，确保你的 Kubernetes 上下文指向正确的集群：

```bash
kubectl apply -f managementplaneoperator.yaml
```

部署 Tetrate Operator 可能需要一些时间。你可以通过运行以下命令来监视其状态：

```bash
kubectl -n tsb get pod -owide
```

你应该会看到类似以下示例的文本。当 READY 和 STATUS 列的值分别为 `1/1` 和 `Running` 时，Operator 已准备就绪。

```bash
kubectl -n tsb get pod -owide
NAME                                             READY   STATUS    RESTARTS   AGE   IP               NODE                                              NOMINATED NODE   READINESS GATES
tsb-operator-management-plane-68c98756d5-n44d7   1/1     Running   0          71s   192.168.17.234   ip-192-168-24-207.ca-central-1.compute.internal   <none>          <none>
```

请按照 [管理平面安装](../../../self-managed/management-plane-installation) 中的说明完成安装管理平面的步骤。

## 访问 TSB 用户界面

执行以下命令获取分配给管理平面的 ELB 地址：

```bash
kubectl -n tsb get svc -l=app=envoy
```

为你的 EL

B 分配一个 DNS 记录。有关详细信息，请参阅[官方文档](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-creating.html)。

设置 DNS 记录后，你可以使用 URL `https://<DNS Name>:8443` 访问 Web 用户界面。

## 下一步

如果你有进一步的问题，请[联系我们](https://tetrate.io)。
