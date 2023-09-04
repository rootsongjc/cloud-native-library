---
title: TSB Helm 升级
description: 使用 Helm 升级 TSB。
weight: 5
---

本文档解释了如何利用 [Helm](https://helm.sh) Chart来升级 TSB 的不同元素。本文假定 [Helm 已经安装](https://helm.sh/docs/intro/install/) 在系统中。

本文档仅适用于使用 Helm 创建的 TSB 实例，不适用于从基于 TCTL 的安装升级。

在开始之前，请确保你已经：

- 检查新版本的 [要求](../../requirements-and-download#requirements)

## 先决条件

1. 已经 [安装](https://helm.sh/docs/intro/install/) `Helm`
1. 已经 [安装](../../../reference/cli/guide/index#installation) TSB cli `tctl`
1. 已经 [安装](https://kubernetes.io/docs/tasks/tools/#kubectl) `kubectl`
1. Tetrate 的镜像仓库的凭据


### 配置 Helm 仓库

- 添加仓库：
  ```shell
  helm repo add tetrate-tsb-helm 'https://charts.dl.tetrate.io/public/helm/charts/'
  helm repo update
  ```

- 列出可用版本：
  ```shell
  helm search repo tetrate-tsb-helm -l
  ```

### 备份 PostgreSQL 数据库

[创建 PostgreSQL 数据库的备份](../../../operations/postgresql#create-a-backup-of-tsb-configuration)。

根据你的环境，连接到数据库的确切过程可能会有所不同，请参考你环境的文档。

## 升级过程

### 管理平面

升级管理平面Chart：

```bash
helm upgrade mp tetrate-tsb-helm/managementplane --namespace tsb -f values-mp.yaml
```

### 控制平面

升级控制平面Chart：

```bash
helm upgrade cp tetrate-tsb-helm/controlplane --namespace istio-system -f values-cp.yaml --set-file secrets.clusterServiceAccount.JWK=/tmp/<cluster>.jwk
```

### 数据平面

升级数据平面Chart：

```bash
helm upgrade dp tetrate-tsb-helm/dataplane --namespace istio-gateway -f values-dp.yaml
```

## 回滚

如果发生问题，你希望将 TSB 回滚到以前的版本，你需要回滚管理平面、控制平面和数据平面Chart。

### 回滚控制平面

你可以使用 `helm rollback` 回滚到当前版本。要查看当前版本，可以运行：
```bash
helm history cp -n istio-system
```

然后，你可以回滚到以前的版本：
```bash
helm rollback cp <REVISION> -n istio-system
```

### 回滚管理平面

#### 缩减管理平面中的 Pod 数量

缩减管理平面中连接到 Postgres 的所有 Pod，以使其处于非活动状态。

```bash
kubectl scale deployment tsb iam -n tsb --replicas=0
```

#### 恢复 PostgreSQL

[从备份中恢复你的 PostgreSQL 数据库](../../../operations/postgresql#restore-a-backup)。
根据你的环境，连接到数据库的确切过程可能会有所不同，请参考你环境的文档。

#### 恢复管理平面

```bash
helm rollback mp <REVISION> -n tsb
```
