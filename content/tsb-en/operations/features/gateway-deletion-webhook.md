---
title: Gateway Deletion Hold Webhook
description: How to enable gateway delete webhook to hold delete operation and allow configuration change to propagate across all clusters
---

If a gateway is deleted (e.g. during a downscaling event), remote clusters would continue to attempt to send traffic to the gateway IP address until they received an update that the gateway’s IP address was removed. This may cause `503` errors for HTTP traffic or `000` errors for passthrough cross cluster traffic.

Since TSB 1.6, you can delay gateway deletions by a configurable period to provide sufficient time for the gateway’s IP address removal to propagate across other clusters to avoid `503` or `000` errors. Currently this feature is disabled by default.

## Enable Gateway Deletion Hold Webhook

In order to enable a gateway deletion hold webhook in your control plane, you will need to
edit `xcp` component in `ControlPlane` CR or Helm values and add the following environment variables:

1. `ENABLE_GATEWAY_DELETE_HOLD` with value set to `true`
2. `GATEWAY_DELETE_HOLD_SECONDS`. This is optional with default is 10 seconds

```yaml
spec:
  components:
    xcp:
      ...
      kubeSpec:
        deployment:
          env:
            - name: ENABLE_GATEWAY_DELETE_HOLD
              value: "true"
            - name: GATEWAY_DELETE_HOLD_SECONDS
              value: "20"
  ...
```

This will delay gateway deletions for 20 seconds while the deleted gateway IP is removed from remote clusters.
