---
title: 恢复失败的管理平面组件
weight: 1
---

如果 Tetrate 管理平面失败，您需要恢复管理平面以恢复正常操作状态。本指南提供了一个流程概述，您应该在进行此过程时与 [Tetrate 技术支持](https://tetrate.io/contact-us/) 协商。

为了应对管理组件的意外故障，我们建议考虑以下建议：

* 要么在可靠的冗余集群中维护 Postgres 数据库，要么（在 TSE 的情况下）利用[定期的 Postgres 备份](http://docs.tetrate.io/service-express/administration/postgres)。
* 保留 **iam-signing-key** 的备份。
* 如果保留指标很重要，请在可靠的冗余集群中维护 ElasticSearch 数据库，或定期备份，以便在必要时进行恢复。

## 概述

如果[管理平面失败](../scenarios)或[托管管理平面的集群停止运行](../scenarios)，您需要恢复管理平面以恢复正常运行状态。恢复是使用 helm 基础安装完成的。
本方案将演示如何在新的管理集群上从失败的管理集群中恢复配置的任务。

### 先决条件

本指南做出以下假设：

* PostgreSQL 数据库（配置）可用。要么数据库位于失败的集群之外，要么可以从备份中[恢复（仅适用于 TSE）](http://docs.tetrate.io/service-express/administration/postgres)。
* ElasticSearch 数据库（指标）可用。要么数据库位于失败的集群之外，要么可以从备份中恢复，或者可以使用全新的（空的）ElasticSearch 数据库，并容忍指标丢失。
* 新管理平面集群的所有证书都使用与之前失败的集群相同的根证书颁发机构。
* 您可以更新用于发现管理平面的任何 DNS 记录。
* 您有 **iam-signing-key** 的备份。

## 流程

请与[Tetrate 技术支持](https://tetrate.io/contact-us/)合作，按照以下步骤操作：

### 部署新集群

部署新集群，将管理平面恢复到其中。

### 安装依赖项

在集群中安装所需的依赖项。这些依赖项可能包括：

* Cert-Manager（如果您没有使用捆绑的 cert-manager 实例）及相关发行人/证书。确保使用相同的根 CA。
* 保存凭据/证书的任何密钥。
* 来自失败管理平面集群的 **iam-signing-key** - 可选

使用 `kubectl apply` 安装 **iam-signing-key** 密钥。如果无法执行此操作，您需要稍后在此过程中重新配置每个控制平面以使用全新的密钥。

### 准备配置

使用与失败集群相同的 **mp-values.yaml**，更新任何必要的字段，如 hub 或 registry，或者如果需要的话，更新任何其他环境相关字段。

如果使用外部 IP 端点，则无需更新 Elastic/Postgres 配置，但可能需要调整防火墙规则。

### 安装管理平面

使用 **mp-values.yaml** 执行管理平面的 helm 安装，并使用以下命令监视进度：

```bash
kubectl get pod -n tsb
kubectl logs -f -n tse -l name=tsb-operator
```

对于 Tetrate Service Express（TSE），组件安装在 **tse** 命名空间中（而不是 **tsb**）。

### 获取管理平面地址

安装完成后，请获取 **front envoy** 的公共 IP 地址，例如：

```bash
kubectl get svc -n tsb envoy
```

使用 Envoy IP 地址登录 UI：

1. 验证您的 Tetrate 配置是否在 Postgres 数据库中得以保留。
2. 如果可用，检查 Elastic 历史数据。

### 更新 DNS

使用在步骤 5 中获取的新 IP 地址更新用于定位管理平面的 DNS A 记录。远程控制平面集群将使用此 DNS 记录与管理平面进行通信。

传播可能需要一些时间。一旦更改传播完成，请验证您是否可以使用 FQDN 访问管理平面 UI。

### 验证控制平面操作

在管理平面 UI 中，验证工作负载集群控制平面是否连接并与新的管理平面同步。

{{<callout warning "刷新控制平面令牌">}}

**iam-signing-key** 用于生成、验证和旋转令牌，这些令牌提供给控制平面集群，以与管理平面进行通信。

如果无法恢复和恢复原始的 **iam-signing-key**，则需要在每个控制平面上手动刷新令牌：

1. 登录每个控制平面集群。
2. 删除旧令牌以旋转令牌：

    ```bash
    kubectl delete secret otel-token oap-token ngac-token xcp-edge-central-auth-token -n istio-system
    ```

1. 验证控制平面现在是否连接到并与新的管理平面同步。

{{</callout>}}

成功恢复新管理平面后，您将完全恢复故障，您的工作负载集群将由新的管理平面实例控制。

## 故障排除

管理平面和控制平面安装由 Operator 管理。如果进行配置更改，可以监视 Operator 日志以查看进度并识别任何错误。

### 控制平面无法同步

检查 ControlPlane Envoy 的日志，

查找与连接到管理平面或与令牌验证相关的错误：

```bash
kubectl logs deploy/edge -n istio-system -f
```

按照上述描述的方法删除控制平面上的现有令牌，并验证这些令牌是否在控制平面上重新生成。

```bash
kubectl get secrets otel-token oap-token ngac-token xcp-edge-central-auth-token -n istio-system
```

如果令牌未重新生成：

* 检查控制平面实例与新的管理平面实例之间的防火墙规则，并确保允许连接。
* 确保管理平面使用相同的根 CA。

### 无法访问外部组件，如 postgres

1. 验证到 postgres 或任何其他外部组件的防火墙规则。
1. 验证通过 helm 或在 **mp-values.yaml** 中传递的凭据。
