---
title: Helm TSB Uninstallation
description: Steps to follow to uninstall TSB from your cluster.
---

To uninstall TSB, installed using helm, you can use `helm uninstall` to uninstall a release. Uninstallation must be done
in the following order:

1. [Data Plane](#data-plane-uninstallation).
2. [Control Plane](#control-plane-uninstallation).
3. [Management Plane](#management-plane-uninstallation).

## Data Plane Uninstallation
```shell
helm uninstall dp tetrate-tsb-helm/dataplane --namespace istio-gateway
```

Once Helm has removed all the resources associated with the last release of the data plane chart, you will need to
manually remove some resources created during the uninstallation process that are untracked by Helm.

```shell
kubectl delete serviceaccount tsb-helm-delete-hook --ignore-not-found
kubectl delete clusterrole tsb-helm-delete-hook --ignore-not-found
kubectl delete clusterrolebinding tsb-helm-delete-hook --ignore-not-found
kubectl delete istiooperators.install.istio.io --all -n istio-gateway --ignore-not-found
```

## Control Plane Uninstallation
```shell
helm uninstall cp tetrate-tsb-helm/controlplane --namespace istio-system
```

Once Helm has removed all the resources associated with the last release of the data plane chart, you will need to
manually remove some resources created during the uninstallation process that are untracked by Helm.

```shell
kubectl delete serviceaccount tsb-helm-delete-hook --ignore-not-found
kubectl delete clusterrole tsb-helm-delete-hook --ignore-not-found
kubectl delete clusterrolebinding tsb-helm-delete-hook --ignore-not-found
kubectl delete apiservices.apiregistration.k8s.io v1beta1.external.metrics.k8s.io
kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io xcp-edge-istio-system
kubectl delete mutatingwebhookconfigurations.admissionregistration.k8s.io xcp-edge-istio-system
```

## Management Plane Uninstallation
```shell
helm uninstall mp tetrate-tsb-helm/managementplane --namespace tsb
```

Once Helm has removed all the resources associated with the last release of the data plane chart, you will need to
manually remove some resources created during the uninstallation process that are untracked by Helm.

```shell
kubectl delete serviceaccount tsb-helm-delete-hook --ignore-not-found
kubectl delete clusterrole tsb-helm-delete-hook --ignore-not-found
kubectl delete clusterrolebinding tsb-helm-delete-hook --ignore-not-found
kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io xcp-central-tsb
kubectl delete mutatingwebhookconfigurations.admissionregistration.k8s.io xcp-central-tsb
```