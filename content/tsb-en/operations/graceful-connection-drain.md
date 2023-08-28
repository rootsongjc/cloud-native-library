---
title: Graceful Connection Drain of istio-proxy
description: How to gracefully shutdown the `istio-proxy` sidecar and reduce inflight connection failure
---

This document explains what happens when a pod which has `istio-proxy` sidecar enabled is deleted, particularly how the connections are treated, and how smooth you can configure the sidecar to drain the inflight connections gracefully.

:::note
This document only applies to TSB version <= `1.4.x`.
:::

Before you get started, make sure you: <br />
✓ Familiarize yourself with [TSB concepts](../concepts/) <br />
✓ Install the TSB environment. You can use [TSB demo](../setup/requirements-and-download) for quick install <br />
✓ Completed [TSB usage quickstart](../quickstart). This document assumes you already created Tenant and are familiar with Workspace and Config Groups. Also you need to configure tctl to your TSB environment <br />
✓ [Install httpbin](../reference/samples/httpbin#deploy-the-httpbin-pod-and-service)

When you issue a delete request against a pod in your Kubernetes cluster, all containers within the pod are sent a SIGTERM. If the pod contains only a single container, it will receive a SIGTERM and go into the terminating state.
However, if the pod contains a sidecar (in our case an `istio-proxy` sidecar), then it is not automatically guaranteed that the main application is terminated before the sidecar.

If the `istio-proxy` sidecar is terminated before the application, the following issues may occur:

1. All TCP connections (both inbound and outbound) are terminated abruptly.
2. Any connections from the application fail 

While there is a [proposed KEP for it](https://github.com/kubernetes/enhancements/tree/master/keps/sig-node/753-sidecar-containers), currently there is no straightforward way to tell Kubernetes to terminate the application before the sidecar.

However, it is possible to workaround this problem by configuring the [`drainDuration`](https://istio.io/latest/docs/reference/config/istio.mesh.v1alpha1/) parameter. This configuration parameter controls the amount of time that the underlying `envoy` proxy drains inflight connections before fully terminating. 

To take advantage of the `drainDuration` parameter, you will need to configure it in both the container sidecars, and the TSB gateways.

## Configuring 	`drainDuration` time for `istio-proxy` containers

You will need to apply an overlay to the `ControlPlane` CR or Helm values to set `drainDuration`. Consider the following example. Note that only applicable parts are shown -- you will most likely need a lot more configuration for your control plane.

```yaml
spec: 
  ...
  components:
    istio:
      kubeSpec:
        overlays:
        - apiVersion: install.istio.io/v1alpha1
          kind: IstioOperator
          name: tsb-istiocontrolplane
          patches:
          - path: spec.meshConfig.defaultConfig.drainDuration
            value: 50s
  ...
```

After adding the overlay to your configuration, use the `kubectl` command to apply it to the `ControlPlane` CR:

```bash{promprUser: alice}
kubectl apply -f controlplane.yaml
```

If you use Helm, you can update `spec` section of the control plane Helm values then do `helm upgrade`.

## Verifying the `drainDuration`

You must restart of the workload with the `istio-proxy` to get the `drainDuration` in effect. Once you have restarted your workload, you can verify it by checking the config dump of the for `envoy`:

```bash{promptUser: alice}
kubectl exec helloworld-v1-59fdd6b476-pjrtr -n helloworld -c istio-proxy -- pilot-agent request GET config_dump |grep -i drainDuration
       "drainDuration": "50s",
```

## Configuring `drainDuration` for TSB gateways

If you are using TSB gateways such as `IngressGateway`, `EgressGateway`, or `Tier1Gateway`, you will need to configure your appropriate gateway type using the `connectionDrainDuration` parameter.

You can query the current value for the `connectionDrainDuration` field on your gateway custom resource by issuing the following command:

```bash{promptUser: alice}
kubectl get ingress helloworld-gateway  -n helloworld -oyaml | grep connectionDrainDuration:
  connectionDrainDuration: 22s
```

The following example shows how `connectionDrainDuration` may be set. Please [read the spec](../refs/install/dataplane/v1alpha1/spec) for further information on the this field.

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: helloworld-gateway
spec:
  connectionDrainDuration: 10s
#  ... <snip> ...
```

## Verifying the `drainDuration` in the TSB Gateway

To check the value for `drainDuration` that is being set on the pod, you can query the environment variable:

```bash{pomptUser: alice}
kubectl describe po helloworld-gateway-7d5d4c8d57-msfd6 -n helloworld | grep -i DRAIN
      TERMINATION_DRAIN_DURATION_SECONDS:  22
```

You can also verify this value by looking at the logs for the gateway pod when you terminate the gateway. If you watch the logs as the gateway pod is terminated, you should see messages resembling the following:

```
2022-03-29T06:02:50.423789Z     info    Graceful termination period is 22s, starting...
2022-03-29T06:03:12.423988Z     info    Graceful termination period complete, terminating remaining proxies.
```
