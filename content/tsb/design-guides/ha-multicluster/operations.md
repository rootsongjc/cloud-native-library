---
title: Operating and Testing
---

# Operating and Testing HA and Failover

_This document explains how you might test failover, and operationalize tasks such as draining and restoring clusters_

A platform operator may need to manually:

 * Take a Workload Cluster out-of-rotation, allowing existing requests to complete, before performing maintenance on that cluster
 * Take an Edge Gateway out-of-rotation, allowing cached DNS entries to time-out, before performing maintenance on that Edge Gateway
 * Define a region as ‘active’ or ‘passive’ (the default Tetrate model is all-active)

The worked examples in the [Workload Cluster failover](cluster-failover) and [Edge Gateway failover](edge-failover) guides illustrate various ways to take components out-of-service in a controlled and predictable manner, and the best implementations will be influenced by specific topologies and choice of GSLB solutions.

### To Take a Workload Cluster out-of-rotation

#### Option 1: Edit the Edge Gateway configuration

Editing the Edge Gateway cluster list will have no effect on service availability.  Requests to the removed cluster will be allowed to complete, and new requests will not be routed to the cluster.

You'll need to explicitly list the working clusters in the Edge Gateway's **Gateway** configuration:

<table>
<tr><th width="50%">From this:</th><th width="50%">To this:</th></tr>
<tr><td valign="top">

```yaml
spec:
  workloadSelector:
    namespace: edge
    labels:
      app: edgegw
  http:
    - name: bookinfo
      port: 80
      hostname: bookinfo.tse.tetratelabs.io
      routing:
        rules:
          - route:
              clusterDestination: {}
```

</td><td valign="top">

```yaml
spec:
  workloadSelector:
    namespace: edge
    labels:
      app: edgegw
  http:
    - name: bookinfo
      port: 80
      hostname: bookinfo.tse.tetratelabs.io
      routing:
        rules:
          - route:
              clusterDestination:
                clusters:
                - name: cluster-1
                - name: cluster-2
```

</td></tr>
</table>

#### Option 2: Delete the Gateway resource on the Workload Cluster

Delete the **Gateway** resource on the Workload Cluster.

The Tetrate Platform will immediately update the Edge Gateway configurations to remove that cluster from the load-balancing set for the hostname in the deleted **Gateway** resource.

Downtime is unlikely, and the Envoy Gateway will attempt to load-balance to other clusters if it observes a failure (typically a `404 Not Found` response).


#### Option 2: De-provision the Ingress Gateway on the Workload Cluster

Delete the **IngressGateway** resource on the Workload Cluster.  This will de-provision the Ingress Gateway.

The Tetrate Platform will immediately update the Edge Gateway configurations to remove that cluster from the load-balancing set for the hostname in the deleted **Gateway** resource.

Short-term downtime is possible, and the Envoy Gateway will attempt to load-balance to other clusters if it observes a failure (typically a connection timeout).  This may incur a delay for outstanding requests.

### To take a region out-of-rotation

Traffic distribution to Edge Gateways in various regions is controlled by a GSLB solution.  

#### Option 1: Configure the GSLB solution

Using the GSLB provider's API, and following their best-practice guidelines, remove the desired region (Edge Gateway) out of rotation.

#### Option 2: Trigger a Health Check

This option requires additional configuration, but allows an administrator to take a region out-of-rotation without needing to interact with the third-party GSLB APIs.

The core principle is to use a health check, and to provoke that health check to fail when you wish a region to be taken offline.  Regular requests are unaffected, so clients who have cached DNS entries for the Edge Gateway in that region will not incur any interruption in service or increased latency.

The [Edge Gateway failover](edge-failover) guide explains the principle of the Health Check, where a specially-tagged request (e.g. with an `X-HealthCheck: true` header) receives a custom response that triggers failover or recovery in the GSLB solution.  There are many ways that a Health Check could be implemented, such as editing the Edge Gateway resource to return an error, or using a special URL that routes to a canary service (e.g. httpbin) on the workload clusters.  Refer to Tetrate professional services for specific advice based on your needs and your desired way to interact with the Tetrate platform.