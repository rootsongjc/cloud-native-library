---
title: "Workload Cluster Failover"
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Cluster Load Balancing and Failover

This guide uses the environment described in the [Demonstration Environment](demo-1), namely:

 * One Edge Cluster in **region-1**
 * Two Workload Clusters, in **region-1** and **region-2**
 * The **BookInfo** application running in the Workload Clusters
 * An Edge Gateway load-balancing traffic to the Workload Clusters

| [![Edge and Workload Load Balancing](images/edge-workload.png "Edge and Workload Load Balancing")](images/edge-workload.png) _Edge and Workload Load Balancing_ |
|  :--:  |

A simple HTTP request is routed to the Edge Gateway, and then forwarded to one of the Workload Clusters, and generates a successful response:

```bash
curl http://bookinfo.tse.tetratelabs.io/productpage
```

In this guide, we'll look at the failover behavior of the system when Workload Clusters fail.

## Generate and Observe Test Traffic

It's helpful to generate a steady stream of test traffic to the system.  A benchmarking tool such as **wrk** is suitable:

```bash title="Generate 30-second bursts of traffic, one request at a time"
while sleep 1; do \
   wrk -c 1 -t 1 -d 30 http://bookinfo.tse.tetratelabs.io/productpage ; \
done
```

Observe traffic on the Edge Gateway as follows:

```bash title="Set kubectl context / alias to the cluster-edge Cluster"
kubectl logs -f -n edge -l=app=edgegw | cut -c -60
```

Using two additional terminal windows, observe traffic on each of the Ingress Gateways as follows:

```bash title="Set kubectl context / alias to the cluster-1 Cluster"
kubectl logs -f -n bookinfo -l=app=ingressgw-1 | cut -c -60
```

```bash title="Set kubectl context / alias to the cluster-2 Cluster"
kubectl logs -f -n bookinfo -l=app=ingressgw-2 | cut -c -60
```


| [![Observing Test Traffic](images/loadgen.gif "Observing Test Traffic")](images/loadgen.gif) _Observing Test Traffic_ |
|  :--:  |


## Configuring Edge Gateway

The Edge Gateway is configured using a **Gateway** resource, with the following options:

<Tabs 
  defaultValue="auto"
  values={[
    {label: 'Auto Cluster List', value: 'auto'},
    {label: 'Named Cluster List', value: 'named'},
    {label: 'Weighted Cluster List', value: 'weighted'}
  ]}>
  <TabItem value="auto">

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
# highlight-start
              clusterDestination: {}
# highlight-end





```

  </TabItem>
  <TabItem value="named">

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
# highlight-start
            clusterDestination:
                clusters:
                - name: cluster-1
                - name: cluster-2
# highlight-end


```

  </TabItem>
  <TabItem value="weighted">

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
# highlight-start
              clusterDestination:
                clusters:
                - name: cluster-1
                  weight: 50
                - name: cluster-2
                  weight: 50
# highlight-end
```

  </TabItem>
</Tabs>


### Auto Cluster List

_An Auto Cluster List configuration is a simple and effective configuration that requires minimal management_

```yaml
      routing:
        rules:
          - route:
              clusterDestination: {}
```

With an Auto Cluster list, the Tetrate Platform will identify suitable target clusters. It does so by comparing the hostname in the Edge **Gateway** resources with matching hostnames in workload cluster **Gateway** resources.  If Workload Clusters and Gateway resources are added or removed to the environment, the Edge Gateway will be automatically reconfigured.

The Edge Gateway only direct traffic to Ingress Gateways on Workload Clusters that are in the **same region**.  This locality-based selection is intended to minimise latency and avoid expensive inter-region traffic.

If all of the Ingress Gateways in region-local clusters fail, then the Edge Gateway will share traffic across the remaining Workload Clusters in the remote regions.  Health Checking is based on outlier detection for the Ingress Gateway pods.

### Named Cluster List

_A Named Cluster list functions like an Auto Cluster list, but only considers the Workload Clusters named in the list_

```yaml
      routing:
        rules:
          - route:
              clusterDestination:
                clusters:
                - name: cluster-1
                - name: cluster-2
```

With a Named Cluster list, the Tetrate Platform will direct traffic to the Ingress Gateways on the named Workload Clusters.  The platform verifies that the clusters have Ingress Gateways, with a **Gateway** resource containing a matching hostname.

The Edge Gateway will direct traffic to Ingress Gateways on Workload Clusters that are in the **same region**.  This locality-based selection is intended to minimise latency and avoid expensive inter-region traffic.

If all of the Ingress Gateways in region-local clusters fail, then the Edge Gateway will share traffic across the remaining Workload Clusters in the remote regions.  Health Checking is based on outlier detection for the Ingress Gateway pods.

### Weighted Clusters List

_Use weights to orchestrate the gradual transfer of traffic from one cluster to another_

```yaml
      routing:
        rules:
          - route:
              clusterDestination:
                clusters:
                - name: cluster-1
                  weight: 50
                - name: cluster-2
                  weight: 50
```

With a Weighted list of clusters, the Tetrate platform will strictly distribute traffic across the clusters in accordance to the configured weights.  No health checking is performed, so if a cluster does not have a functioning Ingress Gateway, requests directed to that cluster will respond with a '**503 no healthy upstream**' error response.

Weights are intended to be used in a controlled situation where you wish to canary-test a new cluster.


## Test Failure Handling

You can test failure handling as follows:

 * Run the load generator and tail the Gateway logs as described above
 * Apply your desired Edge Gateway configuration: `tctl apply -f bookinfo-edge.yaml`

You're now ready to provoke a failure and:

 1. Observe traffic distribution on each Ingress Gateway
 2. Observe successful requests (200 status code) and errors (503 or other status codes)

Note that failover does not take place when using weights with the clusters.

### Remove Gateway resources

The easiest way to provoke a failure is to remove the **Gateway** resources on the Workload Clusters.  The Tetrate platform will identify which Ingress Gateways are managing traffic for the desired hostname, and configure the Edge Gateway accordingly:

 * To remove a **Gateway** resource: `tctl delete -f bookinfo-ingress-1.yaml`
 * To restore a **Gateway** resource: `tctl apply -f bookinfo-ingress-1.yaml`

This method simulates an operational failure where the **Gateway** resource is not applied on a working cluster, or where the service and its associated **Gateway** resource is deleted.

### Scale Ingress Gateways

Another way to test failure handling is to scale the Ingress Gateway service to 0 replicas:

 * Provoke a failure by scaling a Workload Cluster Ingress Gateway to 0 replicas: `kubectl scale deployment -n bookinfo ingressgw-2 --replicas=0`
 * Restore the Ingress Gateway by scaling to 1 replica

The speed of failover depends on the speed of outlier detection and the responsiveness of the Tetrate control plane.  It can take up to 60 seconds to identify a failure and re-configure the Edge Gateway.

This method simulates an infrastructure failure where the **Ingress Gateway** fails on the Workload Cluster.

### Scale Upstream Services

On each Workload Cluster, the **Gateway** resource forwards traffic to the named upstream service, such as `bookinfo/productpage.bookinfo.svc.cluster.local`. The Tetrate Platform does not explicitly check that the upstream service is present and functioning, so if the service fails, the platform will continue to route traffic to the Workload Cluster.

However, the Envoy proxy that operates as the Edge Gateway does verify response codes and will retry requests where possible if a failure is received.  In this scenario, you will observe requests to the failed Workload Cluster generate a **503 UH no_healthy_upstream** or similar error, and Envoy then retries the request against the other cluster(s).  Envoy will back-off sending requests to the failed cluster, but speculatively try it infrequently in order to detect its recovery.

You can investigate the failure behaviour by scaling the upstream service on the Workload Cluster as follows:

 * Provoke a service failure by scaling to 0 replicas: `k1 scale deployment -n bookinfo productpage-v1 --replicas=0`
 * Restore the service by scaling to 1 replica

This method simulates an operational failure where the upstream service fails on the Workload Cluster.

:::tip Internal Service Failover

In addition, you can also use an **East-West Gateway** to manage internal failover of services within the cluster.

:::


## What have we achieved?

We have observed the failure detection and recovery behavior of the Tetrate platform in a range of scenarios where the **Workload Cluster** or its hosted services were to fail.  

Next, we'll consider how to scale the **Edge Gateways** and handle the failure of one or more **Edge Clusters / Edge Gateways**.