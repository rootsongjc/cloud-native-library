---
title: 已修订版本间的升级
description: 如何从已修订升级控制平面集群到已修订。
weight: 2
---

在继续之前，请确保你熟悉[Istio 隔离边界](../../isolation-boundaries)功能。

{{<callout note 注意>}}

可以在单个隔离边界内执行已修订到已修订的控制平面升级。
{{</callout>}}

## 升级之前

一旦启用了 Istio 隔离边界功能，边界可以用于保持服务发现隔离，并在隔离边界内升级 Istio 控制平面。对于包含单个隔离边界的`ControlPlane` CR 或 Helm 值：

```yaml
spec:
  ...
  components:
    xcp:
      isolationBoundaries:
      - name: global
        revisions:
        - name: stable
          istio:
            tsbVersion: 1.6.0
```

你将升级`stable`修订版本中的所有工作负载以使用`tsbVersion: 1.6.1`。

{{<callout note "控制平面升级策略">}}
TSB 支持修订到修订升级的原地和金丝雀控制平面升级。
{{</callout>}}

## 控制平面原地升级

对于原地升级，你可以直接更新`tsbVersion`字段 - 保留修订`name`不变。

```yaml
spec:
  ...
  components:
    xcp:
      isolationBoundaries:
      - name: global
        revisions:
        - name: stable
          istio:
            tsbVersion: 1.6.1
```

这将重新部署 Istio 控制平面组件，与`tsbVersion: 1.6.1`对应的 TSB Istio 版本。这个状态将由 istio-system 命名空间中的 xcp-operator-edge Operator 协调。

### 网关升级

默认情况下，网关将自动升级以使用最新的`tsbVersion`。有关网关升级行为的更多详细信息，请参阅[网关升级](../gateway-upgrade)。

### 应用程序升级

由于修订名称未更改，因此在工作负载命名空间（本示例中的`workload-ns`）中不需要进行任何更新。但是，你仍然需要重新启动应用程序工作负载。为避免流量中断，推荐使用滚动更新。

```bash
kubectl rollout restart deployment -n workload-ns
```

### VM 工作负载升级

要升级 VM 工作负载，请使用[修订链接](../../workload-onboarding/guides/setup)从你的上机平面下载最新的 Istio sidecar，然后在 VM 上重新安装 Istio sidecar。

然后重新启动在 VM 上运行的`onboarding-agent`。

## 控制平面金丝雀升级

对于金丝雀升级，你可以添加另一个修订版本，其名称为`1-6-1`，其具有升级的`tsbVersion`值。

```yaml
spec:
  ...
  components:
    xcp:
      isolationBoundaries:
      - name: global
        revisions:
        - name: stable
          istio:
            tsbVersion: 1.6.0
        - name: 1-6-1
          istio:
            tsbVersion: 1.6.1
```

这将部署另一个 Istio 控制平面（修订`1-6-1`）与`tsbVersion: 1.6.1`对应的 TSB Istio 版本。这个状态将由 istio-system 命名空间中的 xcp-operator-edge 操作符协调。你可以检查`istio-operator`和`istiod`部署以进行验证。

```bash
kubectl get deployment -n istio-system | grep istio-operator
```
```bash
# 输出
istio-operator-stable         1/1     1            1           15小时
istio-operator-1-6-1          1/1     1            1            2分钟
```

```bash
kubectl get deployment -n istio-system | grep istiod
```
```bash
# 输出
istiod-stable          1/1     1            1           15小时
istiod-1-6-1           1/1     1            1            2分钟
```

请注意，仍然部署了一个旧的修订控制平面（`stable`），它管理着现有的 sidecars 和网关。

### 网关升级

要升级网关，请[更新`spec.revision`](../../isolation-boundaries)在`Ingress/Egress/Tier1Gateway`资源中。这将协调现有的网关 Pod 以连接到新的修订 Istio 控制平面。TSB 默认配置了带有`RollingUpdate`策略的网关安装资源，以确保零停机时间。

你还可以通过修补网关 CR 来更新`spec.revision`。

```bash
kubectl patch ingressgateway.install <name> -n <namespace> --type=json --patch '[{"op": "replace","path": "/spec/revision","value": "1-6-1"}]'; \
```

### 应用程序升级

要升级 sidecars，请替换工作负载命名空间标签`istio.io/rev=stable`并应用新的修订。

```bash
kubectl label namespace workload-ns istio.io/rev=1-6-1 --overwrite=true
```

然后重新启动应用程序工作负载。为避免流量中断，推荐使用滚动更新。
```bash
kubectl rollout restart deployment -n workload-ns
```

### VM 工作负载升级

要升级 VM 工作负载，请使用[修订链接](../../workload-onboarding/guides/setup)从你的上机平面下载最新的 Istio sidecar，然后在 VM 上重新安装 Istio sidecar。

在`onboarding-agent`配置中[更新`revision`值](../../isolation-boundaries)，然后重新启动`onboarding-agent`。

## 升级后清理

不再使用的修订版本可以从`ControlPlane` CR 中删除或标记为“禁用”。将其标记为禁用有助于随时启用修订版本。

选择 1：禁用修订版本

```yaml
spec:
  ...
  components:
    xcp:
      isolationBoundaries:
      - name: global
        revisions:
        - name: stable
          istio:
            tsbVersion: 1.6.0
          disable: true
        - name: 1-6-1
          istio:
            tsbVersion: 1.6.1
```

选择 2：删除修订版本

```yaml
spec:
  ...
  components:
    xcp:
      isolationBoundaries:
      - name: global
        revisions:
        - name: 1-6-1
          istio:
            tsbVersion: 1.6.1
```

{{<callout note "旧的 Istio 控制平面组件">}}
在禁用/删除隔离边界下的修订版本后，可能会保留一些旧的组件。例如，`IstioOperator`资源、istio-operator（修订版）部署或 istiod（修订版）部署。这是由于删除`IstioOperator`资源和 istio-operator 部署的竞争条件造成的。
在这种情况下，可以像普通的 Kubernetes 对象一样删除这些 Istio 组件。

```bash
kubectl delete iop xcp-iop-stable -n istio-system
kubectl delete deployment istio-operator-stable -n istio-system
kubectl delete configmap istio-sidecar-injector-stable -n istio-system
kubectl delete deployment istiod-stable -n istio-system
```
{{</callout>}}

## 从已修订到已修订的回滚

这个工作流程与从已修订到已修订的控制平面升级类似。你需要更新你的工作负载以使用旧的修订版本。
