---
title: TSB Uninstallation
description: Steps to follow to uninstall TSB from your cluster.
---

This page describes the procedure to follow to uninstall TSB from a cluster.

:::note
The process will be similar for all of the planes (management, control, and data
planes), because you'll need to delete any custom resource for the plane, then
delete the operator itself.
:::

## Data plane

As the data plane takes care of deploying ingress gateways in your cluster, the
first step is to delete all of the `IngressGateway` custom resources from your
cluster.

```bash{promtUser: Alice}{outputLines: 2}
kubectl delete ingressgateways.install.tetrate.io \
    --all --all-namespaces
```

This will delete all the `IngressGateway`'s deployed in every namespace in the
cluster. Once you've run this command, the data plane operator will delete the
deployments and associated resources for every gateway. This may take some time
to ensure that they're all successfully removed.

To make sure that you gracefully remove the `istio-operator` deployment, you
must scale and delete the remaining objects in the data plane operator namespace
in the following order:

```bash{promtUser: Alice}{outputLines: 2, 4}
kubectl -n istio-gateway scale deployment \
    tsb-operator-data-plane --replicas=0
kubectl -n istio-gateway delete \
    istiooperators.install.istio.io --all
kubectl -n istio-gateway delete deployment --all
```

This will delete both the TSB and Istio operator deployments stored in the data
plane operator namespace. Now you can clean up the validation and mutation web
hooks.

```bash{promtUser: Alice}{outputLines: 2-6, 7-9,10}
kubectl delete \
    validatingwebhookconfigurations.admissionregistration.k8s.io \
    tsb-operator-data-plane-egress \
    tsb-operator-data-plane-ingress \
    tsb-operator-data-plane-tier1
kubectl delete \
    mutatingwebhookconfigurations.admissionregistration.k8s.io \
    tsb-operator-data-plane-egress \
    tsb-operator-data-plane-ingress \
    tsb-operator-data-plane-tier1
```

Removing the control plane will remove all TSB components as well as the Istio
control plane used by TSB and render any sidecars in the cluster non-functional.

## Control Plane

To delete the TSB control plane, first delete the IstioOperator associated with
it.

```bash{promtUser: Alice}
kubectl delete controlplanes.install.tetrate.io --all --all-namespaces
```

It may take some time for the TSB operator in the istio-system namespace to
clean up the Istio components, but once it's complete, delete the validation
and mutation web hooks.

```bash{promtUser: Alice}{outputLines: 2-3, 5-6, 8-9}
kubectl delete \
    validatingwebhookconfigurations.admissionregistration.k8s.io \
    tsb-operator-control-plane
kubectl delete \
    mutatingwebhookconfigurations.admissionregistration.k8s.io \
    tsb-operator-control-plane
kubectl delete \
    validatingwebhookconfigurations.admissionregistration.k8s.io \
    xcp-edge-istio-system
```

Then delete the `istio-system` and `xcp-multicluster` namespaces.

```bash{promtUser: Alice}
kubectl delete namespace istio-system xcp-multicluster
```

In order to clean up the cluster-scoped resources, use the `tctl install manifest`
command to render the `cluster-operators` manifest and delete the resulting
manifest.

```bash{promtUser: Alice}{outputLines: 2}
tctl install manifest cluster-operators --registry=dummy | \
    kubectl delete -f - --ignore-not-found
kubectl delete clusterrole xcp-operator-edge
kubectl delete clusterrolebinding xcp-operator-edge
```

Now clean up all the control plane related custom resource definitions in your
cluster.

```bash{promtUser: Alice}{outputLines: 2-9,10-21}
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

At this point, all the TSB resources in the Kubernetes cluster are removed,
but in order to remove this cluster from TSB configuration, you have to run
the following command:

```bash{promtUser: Alice}
tctl delete cluster <cluster>
```

## Management plane

To uninstall the management plane, you need to remove the `ManagementPlane` CR
that describes your management plane configuration, which will force the
management plane operator to delete any components related to it.

```bash{promtUser: Alice}
kubectl -n tsb delete managementplanes.install.tetrate.io --all
```

Then, delete the management plane operator.

```bash{promtUser: Alice}
kubectl -n tsb delete deployment tsb-operator-management-plane
```

Finally, delete the validation and mutation web hooks.

```bash{promtUser: Alice}{outputLines: 2-3, 5-6, 8-9, 11-12}
kubectl delete \
    validatingwebhookconfigurations.admissionregistration.k8s.io \
    tsb-operator-management-plane
kubectl delete \
    mutatingwebhookconfigurations.admissionregistration.k8s.io \
    tsb-operator-management-plane
kubectl delete \
    validatingwebhookconfigurations.admissionregistration.k8s.io \
    xcp-central-tsb
kubectl delete \
    mutatingwebhookconfigurations.admissionregistration.k8s.io \
    xcp-central-tsb
```

To clean up the cluster-scoped resources, use the `tctl install manifest`
command to render the `management-plane-operator` manifest and delete it.

```bash{promtUser: Alice}{outputLines: 2-3}
tctl install manifest management-plane-operator \
    --registry=dummy | \
    kubectl delete -f - --ignore-not-found
kubectl delete clusterrole xcp-operator-central
kubectl delete clusterrolebinding xcp-operator-central
```

Now clean up all the management plane related custom resource definitions in
your cluster.

```bash{promtUser: Alice}{outputLines: 2-9,10-20}
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
