---
title: 非版本到版本的升级
description: 如何将控制平面集群从非版本升级到版本。
weight: 1
---

在继续之前，请确保你熟悉 [Istio 隔离边界](../../isolation-boundaries) 功能。

## 升级前

从非版本升级到版本控制平面设置涉及启用 Istio 隔离边界功能。
启用后，可以在隔离边界内配置版本，控制平面必须升级到该版本。
按照 [隔离边界安装](../../isolation-boundaries#installation) 中提到的步骤部署具有启用隔离边界功能的控制平面。

启用 Istio 隔离边界功能后，你需要在添加隔离边界到 `ControlPlane` CR 之前，将 TSB 数据平面 Operator 的规模缩小。这是为了避免 TSB 数据平面 Operator 和 TSB 控制平面 Operator 在协调相同的 TSB Ingress/Egress/Tier1Gateway 资源时发生竞争条件。

```bash
kubectl scale --replicas=0 deployment tsb-operator-data-plane -n istio-gateway
```

出于同样的原因，我们还必须将 istio-operator 在 istio-gateway 命名空间中的规模缩小。
```bash
kubectl scale --replicas=0 deployment istio-operator -n istio-gateway
```

随着这一步，还删除了由 tsb-operator-data-plane 创建和管理的 webhooks。

```bash
kubectl delete validatingwebhookconfiguration tsb-operator-data-plane-egress tsb-operator-data-plane-ingress tsb-operator-data-plane-tier1; \
kubectl delete mutatingwebhookconfiguration tsb-operator-data-plane-egress tsb-operator-data-plane-ingress tsb-operator-data-plane-tier1;
```

{{<callout note "控制平面升级策略">}}
TSB 仅支持从非版本到版本的控制平面升级的金丝雀升级。这意味着在任何给定时间点，将部署两个 Istio 控制平面 - 非版本和版本控制平面。
{{</callout>}}

## 控制平面

在你的 `ControlPlane` CR 中配置一个隔离边界。如果使用 Helm，你可以在 Helm 值文件中添加隔离边界配置。

```yaml
spec:
  hub: <registry-location>
  telemetryStore:
    elastic:
      host: <tsb-address>
      port: <tsb-port>
      version: <elastic-version>
      selfSigned: <is-elastic-use-self-signed-certificate>
  managementPlane:
    host: <tsb-address>
    port: <tsb-port>
    clusterName: <cluster-name-in-tsb>
    selfSigned: <is-mp-use-self-signed-certificate>
  components:
    xcp:
      isolationBoundaries:
      - name: global
        revisions:
        - name: revisioned
      centralAuthMode: 'JWT'
```

{{<callout note "global 隔离边界">}}
尽管我们可以在启用隔离边界支持后部署多个版本控制平面，使用任何 "name" 的边界，但建议创建一个名为 "global" 的隔离边界，以便现有的 Workspace 可以被视为 "global" 隔离边界的一部分。已经在集群中部署的现有工作区将不会绑定到特定的隔离边界，因此 "global" 命名的隔离边界为所有这些未指定其隔离边界的工作区提供了一个后备。
{{</callout>}}

在 `ControlPlane` CR 中配置隔离边界将在 `istio-system` 命名空间中设置版本化的控制平面，如下所示

```bash
kubectl get deployment -n istio-system | grep istio-operator
```

```bash
# 输出
istio-operator                1/1     1            1            15h
istio-operator-revisioned     1/1     1            1            2m
```

```bash
kubectl get deployment -n istio-system | grep istiod
```

```bash
# 输出
istiod                 1/1     1            1            15h
istiod-revisioned      1/1     1            1            2m
```

请注意，仍然部署了一个非版本的控制平面，负责管理现有的 sidecar 和网关。

### 网关升级

要升级网关，请在 `Ingress/Egress/Tier1Gateway` 资源中 [添加 `spec.revision`](../../isolation-boundaries#gateway-deployment)。这将使现有的网关 pod 被调整为连接到版本化的 Istio 控制平面。TSB 默认配置了 Gateway 安装资源，使用 `RollingUpdate` 策略，确保零停机时间。

你还可以通过对网关 CR 进行打补丁来添加 `spec.revision`。
```bash
kubectl patch ingressgateway.install <name> -n <namespace> --type=json --patch '[{"op": "replace","path": "/spec/revision","value": "revisioned"}]'; \
```

### 应用升级

要升级 sidecar，请移除工作负载命名空间标签中的 `istio-injection=enabled`，并将 `istio.io/rev` 标签应用于 Istio 版本的工作负载命名空间。

```bash
kubectl label namespace workload-ns istio-injection- istio.io/rev=revisioned
```

然后重新启动应用工作负载。首选滚动更新以避免流量中断。
```bash
kubectl rollout restart deployment -n workload-ns
```

### VM 工作负载升级

要升级 VM 工作负载，请

使用 [版本化链接](../../workload_onboarding/guides/setup#installing-istio-sidecar-for-revisioned-istio) 从你的入驻平面下载最新的 Istio sidecar，然后在 VM 上重新安装 Istio sidecar。

使用 [`revision` 值](../../isolation-boundaries#vm-workload-onboarding) 更新 `onboarding-agent` 配置，然后重新启动 `onboarding-agent`。Istio sidecar 将连接到版本化的 Istio 控制平面。

## 升级后清理

一旦所有 sidecar 都已移动到版本化代理，所有应用网关都已具备版本化网关，并确保升级正常运行，我们可以继续清理现在已经过时的旧非版本化资源。

请记住，我们已经将 TSB 数据平面 Operator 和非版本 istio-operator 从 istio-gateway 命名空间的规模缩小。现在，可以安全地删除 `istio-gateway` 命名空间，因为不再需要它。

```bash
kubectl delete ns istio-gateway
```

使用 `kubectl` 删除位于命名空间 `istio-system` 中的名为 `tsb-istiocontrolplane` 的 `IstioOperator` 资源。

```bash
kubectl delete iop tsb-istiocontrolplane -n istio-system
```

确保 `istio-system` 命名空间中的 `istiod` 部署由 istio-operator 部署删除。然后删除 Istio operator 部署和 Kubernetes RBAC（`clusterrole` 和 `clusterrolebinding`）。

```bash
kubectl delete clusterrole,clusterrolebinding istio-operator
kubectl delete deployment,sa istio-operator -n istio-system
```

## 从版本化回滚到非版本化

### 在升级后清理之前

- 将 istio-gateway 命名空间中的 tsb 数据平面 Operator 的规模增加。
  ```bash
  kubectl scale --replicas=1 deployment tsb-operator-data-plane -n istio-gateway
  ```
  随着此操作，删除由 tsb-operator-control-plane 创建和管理的 webhooks。
  ```bash
  kubectl delete validatingwebhookconfiguration tsb-operator-control-plane-egress tsb-operator-control-plane-ingress tsb-operator-control-plane-tier1; \
  kubectl delete mutatingwebhookconfiguration tsb-operator-control-plane-egress tsb-operator-control-plane-ingress tsb-operator-control-plane-tier1;
  ```

- 要回滚网关，从 TSB 网关安装资源的 `Ingress/Egress/Tier1Gateway` 中移除 `spec.revision`。

  对于网关部署，最好配置滚动更新以避免流量中断。这可以在 `ingress/Egress/Tier1Gateway` 资源中配置。
  这将导致网关 pod 启动并连接到仍在运行的较旧的非版本 Istio 控制平面。

- 通过将工作负载命名空间标签中的 `istio.io/rev` 值更改为 `default` 来回滚 sidecars。
  ```bash
  kubectl label namespace workload-ns istio.io/rev=default
  ```

  然后重新启动应用工作负载。
  ```bash
  kubectl rollout restart deployment -n workload-ns
  ```

- 一旦所有数据平面组件都回滚到非版本化的控制平面，我们可以继续从 `ControlPlane` CR 中删除隔离边界。这将删除在 `istio-system` 命名空间中部署的版本化控制平面组件。

### 在升级后清理之后

{{<callout warning "网关回滚">}}
在进行升级后的清理之后，将网关从版本化回滚到非版本化控制平面不能保证零停机时间。
{{</callout>}}

- 首先，我们需要恢复非版本化的控制平面。要获取较旧的非版本化控制平面，请使用禁用了 `ISTIO_ISOLATION_BOUNDARIES` 的 TSB 集群 Operator 重新安装。
  ```
  tctl install manifest cluster-operators --registry $HUB > clusteroperators.yaml
  kubectl apply -f clusteroperators.yaml
  ```

  再次部署 Operator 将在 istio-gateway 命名空间中带回 TSB 数据平面 Operator。然后，非版本化的 TSB 控制平面 Operator 将协调更新的 `ControlPlane` 资源以重新部署非版本化的 Istio 控制平面。
  由于已删除隔离边界支持，这还将清理所有版本化的控制平面组件。

- 编辑现有的 `ControlPlane` CR，以删除 `spec.components.xcp.isolationBoundaries`。

- 要回滚网关，请从 TSB 网关安装资源的 `Ingress/Egress/Tier1Gateway` 中移除 `spec.revision`。
  对于网关部署，最好配置滚动更新以避免流量中断。这可以在 `ingress/Egress/Tier1Gateway` 资源中配置。
  这将导致网关 pod 启动并连接到仍在运行的较旧的非版本 Istio 控制平面。

- 通过将工作负载命名空间标签中的 `istio.io/rev` 值更改为 `default` 来回滚 sidecars。
  ```bash
  kubectl label namespace workload-ns istio.io/rev=default
  ```

  然后重新启动应用工作负载。
  ```bash
  kubectl rollout restart deployment -n workload-ns
  ```
