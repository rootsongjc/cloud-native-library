---
title: Helm TSB 卸载
description: 卸载 TSB 从你的集群中的步骤。
weight: 6
---

要卸载使用 Helm 安装的 TSB，你可以使用 `helm uninstall` 来卸载一个发布。卸载必须按照以下顺序进行：

1. 数据平面
2. 控制平面
3. 管理平面

## 数据平面卸载

```shell
helm uninstall dp tetrate-tsb-helm/dataplane --namespace istio-gateway
```

一旦 Helm 删除了与数据平面Chart的最后一个发布关联的所有资源，你将需要手动删除一些在卸载过程中创建的资源，这些资源不受 Helm 跟踪。

```shell
kubectl delete serviceaccount tsb-helm-delete-hook --ignore-not-found
kubectl delete clusterrole tsb-helm-delete-hook --ignore-not-found
kubectl delete clusterrolebinding tsb-helm-delete-hook --ignore-not-found
kubectl delete istiooperators.install.istio.io --all -n istio-gateway --ignore-not-found
```

## 控制平面卸载

```shell
helm uninstall cp tetrate-tsb-helm/controlplane --namespace istio-system
```

一旦 Helm 删除了与控制平面Chart的最后一个发布关联的所有资源，你将需要手动删除一些在卸载过程中创建的资源，这些资源不受 Helm 跟踪。

```shell
kubectl delete serviceaccount tsb-helm-delete-hook --ignore-not-found
kubectl delete clusterrole tsb-helm-delete-hook --ignore-not-found
kubectl delete clusterrolebinding tsb-helm-delete-hook --ignore-not-found
kubectl delete apiservices.apiregistration.k8s.io v1beta1.external.metrics.k8s.io
kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io xcp-edge-istio-system
kubectl delete mutatingwebhookconfigurations.admissionregistration.k8s.io xcp-edge-istio-system
```

## 管理平面卸载

```shell
helm uninstall mp tetrate-tsb-helm/managementplane --namespace tsb
```

一旦 Helm 删除了与管理平面Chart的最后一个发布关联的所有资源，你将需要手动删除一些在卸载过程中创建的资源，这些资源不受 Helm 跟踪。

```shell
kubectl delete serviceaccount tsb-helm-delete-hook --ignore-not-found
kubectl delete clusterrole tsb-helm-delete-hook --ignore-not-found
kubectl delete clusterrolebinding tsb-helm-delete-hook --ignore-not-found
kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io xcp-central-tsb
kubectl delete mutatingwebhookconfigurations.admissionregistration.k8s.io xcp-central-tsb
```
