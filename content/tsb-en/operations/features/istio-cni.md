---
title: Istio CNI
description: How to configure the Istio control plane to use the Istio CNI plugin.
---

By default, Istio injects sidecar proxies into application's pods in order to
handle the traffic for the pod. These sidecars need to be privileged containers
as they need to manipulate `iptables` rules in the pod network namespace to be
able to intercept the traffic coming in and out the pod.

This default behavior is not desirable from a security standpoint as it
effectively grants the application pods to run with these elevated privileges.
The alternative Istio provides to this is the use of a
[CNI plugin](https://istio.io/docs/setup/additional-setup/cni/) that handles the
pod network namespace modifications at pod creation time.

## Enable Istio CNI in control plane

In order to enable the Istio CNI plugin in your control plane, you will need to
edit the `ControlPlane` CR or Helm values to include the CNI configuration.

```yaml
spec:
  components:
    istio:
      kubeSpec:
        CNI:
          chained: true
          binaryDirectory: /opt/cni/bin
          configurationDirectory: /etc/cni/net.d
      traceSamplingRate: 100
  hub: <registry-location>
  managementPlane:
    host: <tsb-address>
    port: <tsb-port>
    clusterName: <cluster-name>
  telemetryStore:
    elastic:
      host: <elastic-hostname-or-ip>
      port: <elastic-port>
      version: <elastic-version>
```

The snippet above shows the default `ControlPlane` CR with the addition of
`spec.components.istio.kubeSpec.CNI`. This will configure the Istio control
plane to deploy the CNI plugin following the provided configuration. 

:::note 
Configuration values might change depending on the Kubernetes distribution you
use, please refer to the 
[Istio documentation](https://istio.io/docs/setup/additional-setup/cni/) for
more information.
:::

:::note
Istio CNI can also be bound to a specific Istio revision, and then can be upgraded
from one Istio revision to another. Please refer [Istio CNI Upgrades](../../setup/upgrades/cni-upgrade)
for more information.
:::
