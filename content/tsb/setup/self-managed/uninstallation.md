---
title: TSB 卸载
description: 卸载你的集群中的 TSB 的步骤。
weight: 4
---

本页描述了从集群中卸载 TSB 的步骤。

{{<callout note "注意">}}
此过程对于所有平面（管理、控制和数据平面）都是相似的，因为你需要删除平面的任何自定义资源，然后删除Operator本身。
{{</callout>}}

## 数据平面

由于数据平面负责在你的集群中部署入口网关，因此第一步是从你的集群中删除所有 `IngressGateway` 自定义资源。

```bash
kubectl delete ingressgateways.install.tetrate.io --all --all-namespaces
```

这将删除集群中每个命名空间中部署的所有 `IngressGateway`。运行此命令后，数据平面Operator将删除每个网关的部署和相关资源。这可能需要一些时间来确保它们都成功删除。

为确保你正常删除 `istio-operator` 部署，你必须按以下顺序缩放并删除数据平面Operator命名空间中的剩余对象：

```bash
kubectl -n istio-gateway scale deployment tsb-operator-data-plane --replicas=0
kubectl -n istio-gateway delete istiooperators.install.istio.io --all
kubectl -n istio-gateway delete deployment --all
```

这将删除存储在数据平面Operator命名空间中的 TSB 和 Istio Operator部署。现在你可以清理验证和变异 Web 钩子。

```bash
kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io \
    tsb-operator-data-plane-egress \
    tsb-operator-data-plane-ingress \
    tsb-operator-data-plane-tier1
kubectl delete mutatingwebhookconfigurations.admissionregistration.k8s.io \
    tsb-operator-data-plane-egress \
    tsb-operator-data-plane-ingress \
    tsb-operator-data-plane-tier1
```

删除控制平面将删除所有 TSB 组件以及 TSB 使用的 Istio 控制平面，并使集群中的任何 Sidecar 失去功能。

## 控制平面

要删除 TSB 控制平面，首先删除与其关联的 IstioOperator。

```bash
kubectl delete controlplanes.install.tetrate.io --all --all-namespaces
```

TSB Operator在 istio-system 命名空间中清理 Istio 组件可能需要一些时间，但一旦完成，删除验证和变异 Web 钩子。

```bash
kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io tsb-operator-control-plane
kubectl delete mutatingwebhookconfigurations.admissionregistration.k8s.io tsb-operator-control-plane
kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io xcp-edge-istio-system
```

然后删除 `istio-system` 和 `xcp-multicluster` 命名空间。

```bash
kubectl delete namespace istio-system xcp-multicluster
```

为了清理集群范围的资源，请使用 `tctl install manifest` 命令来呈现 `cluster-operators` 清单并删除生成的清单。

```bash
tctl install manifest cluster-operators --registry=dummy | \
    kubectl delete -f - --ignore-not-found
kubectl delete clusterrole xcp-operator-edge
kubectl delete clusterrolebinding xcp-operator-edge
```

现在清理集群中与控制平面相关的自定义资源定义。

```bash
kubectl delete crd \
    clusters.xcp.tetrate.io \
    controlplanes.install.tetrate.io \
    edgexcps.install.xcp.tetrate.io \
    egressgateways.gateway.xcp.tetrate.io \
    egressgateways.install.tetrate.io \
    gatewaygroups.gateway.xcp.tetrate.io \
    globalsettings.xcp.tetrate.io \
    ingressgateways.gateway.xcp.tetrate.io \
    ingressgateways.install.tetrate.io \
    securitygroups.security.xcp.tetrate.io \
    securitysettings.security.xcp.tetrate.io \
    servicedefinitions.registry.tetrate.io \
    serviceroutes.traffic.xcp.tetrate.io \
    tier1gateways.gateway.xcp.tetrate.io \
    tier1gateways.install.tetrate.io \
    trafficgroups.traffic.xcp.tetrate.io \
    trafficsettings.traffic.xcp.tetrate.io \
    workspaces.xcp.tetrate.io \
    workspacesettings.xcp.tetrate.io \
    --ignore-not-found
```

此时，Kubernetes 集群中的所有 TSB 资源都已删除，但为了从 TSB 配置中删除此集群，你必须运行以下命令：

```bash
tctl delete cluster <cluster>
```

## 管理平面

要卸载管理平面，你需要删除描述管理平面配置的 `ManagementPlane` CR，这将强制管理平面Operator删除与之相关的任何组件。

```bash
kubectl -n tsb delete managementplanes.install.tetrate.io --all
```

然后，删除管理平面Operator。

```bash
kubectl -n tsb delete deployment tsb-operator-management-plane
```

最后，删除验证和变异 Web 钩子。

```bash
kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io tsb-operator-management-plane
kubectl delete  mutatingwebhookconfigurations.admissionregistration.k8s.io tsb-operator-management-plane
kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io xcp-central-tsb
kubectl delete mutatingwebhookconfigurations.admissionregistration.k8s.io xcp-central-tsb
```

为了清理集群范围的资源，请使用 `tctl install manifest` 命令来呈现 `management-plane-operator` 清单并删除它。

```bash
tctl install manifest management-plane-operator --registry=dummy | kubectl delete -f - --ignore-not-found
kubectl delete clusterrole xcp-operator-central
kubectl delete clusterrolebinding xcp-operator-central
```

现在清理集群中与管理平面相关的自定义资源定义。

```bash
kubectl delete crd \
    centralxcps.install.xcp.tetrate.io \
    clusters.xcp.tetrate.io \
    egressgateways.gateway.xcp.tetrate.io \
    egressgateways.install.tetrate.io \
    gatewaygroups.gateway.xcp.tetrate.io \
    globalsettings.xcp.tetrate.io \
    ingressgateways.gateway.xcp.tetrate.io \
    ingressgateways.install.tetrate.io \
    managementplanes.install.tetrate.io \
    securitygroups.security.xcp.tetrate.io \
    securitysettings.security.xcp.tetrate.io \
    servicedefinitions.registry.tetrate.io \
    serviceroutes.traffic.xcp.tetrate.io \
    tier1gateways.gateway.xcp.tetrate.io \
    tier1gateways.install.tetrate.io \
    trafficgroups.traffic.xcp.tetrate.io \
    trafficsettings.traffic.xcp.tetrate.io \
    workspaces.xcp.tetrate.io \
    workspacesettings.xcp.tetrate.io
```