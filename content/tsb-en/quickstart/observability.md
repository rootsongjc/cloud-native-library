---
title: Topology and Metrics
description: Inspect topology and metrics for your demo app.
weight: 8
---

In this section, you will inspect the service topology and metrics for your bookinfo demo application within the TSB environment.

### Prerequisites

Before proceeding, ensure that you have completed the following tasks:

- Familiarize yourself with TSB concepts.
- Install the TSB demo environment.
- Deploy the Istio Bookinfo sample application.
- Create a Tenant and Workspace.
- Create Config Groups.
- Configure Permissions.
- Set up an Ingress Gateway.

### Generate Traffic for Metrics

Before inspecting the topology and metrics, you need to generate traffic for the bookinfo application to have meaningful data. Use the provided script to generate traffic:

Save the following script as [`send-requests.sh`](../../assets/quickstart/send-requests.sh):

```bash
#!/bin/bash
while true; do
    curl -s https://bookinfo.tetrate.com/productpage > /dev/null
    sleep 1
done
```

Make the script executable and run it:

```bash
chmod +x send-requests.sh
./send-requests.sh
```

This script sends a request to the bookinfo product page every 1 second, generating traffic for metrics.

### View Topology and Metrics

Now, you can inspect the service topology and metrics in the TSB UI.

1. In the left panel, under **Tenant**, select **Dashboard**.
2. Click **Select Clusters-Namespaces**.
3. Check the entry corresponding to Tenant `tetrate`, Namespace `bookinfo`, and Cluster `demo`.
4. Click **Select**.

Set the duration of data you wish to view, and enable automatic refresh from the top menu bar in the TSB UI:

- Select a time range, such as _Last 5 minutes_, for the data you want to view.
- Click the _Refresh Metrics_ icon to manually reload metrics or select a refresh _Interval_ for automatic refresh.

### Topology View

Explore the **Topology** page to visualize the topology graph of your services and examine metrics related to traffic volumes, latency, and error rates:

![TSB Dashboard UI: topology view](../../assets/quickstart/topology.png)

### Metrics and Traces

Hover over a service instance to view more detailed metrics or click for a comprehensive breakdown:

![TSB Dashboard UI: service instance metrics](../../assets/quickstart/metrics-1.png)

TSB automatically samples requests and collects trace data for a subset of requests. Select a service and click **Trace** to list recent traces captured through that service. You can explore the full trace to identify traffic flows, timings, and error events:

![TSB Dashboard UI: inspecting a trace](../../assets/quickstart/trace-1.png)

Interpret the trace by understanding:

- `tsb-gateway-bookinfo.bookinfo` calls `productpage.bookinfo.svc.cluster.local:9080`, invoking the `productpage` service in the `bookinfo` namespace.
  - `productpage.bookinfo` first calls `details.bookinfo.svc.cluster.local:9080`, invoking the `details` service in the `bookinfo` namespace.
  - `productpage.bookinfo` later calls `reviews.bookinfo.svc.cluster.local:9080`, invoking the `reviews` service in the `bookinfo` namespace.
    - `reviews.bookinfo` calls `ratings.bookinfo.svc.cluster.local:9080`, invoking the `ratings` service in the `bookinfo` namespace.

You can observe the time intervals between the caller making calls and the target service reading and responding. These intervals correspond to the network call latency and the mesh sidecar proxies' behavior.

For more complex call graphs, you can re-root the display to start from an internal service, excluding the front-end gateway and other front-end services.

### Service Dashboard

Navigate to the **Services** pane in the TSB UI and select one of the services managed by TSB. This opens a comprehensive dashboard with multiple panes, allowing you to drill down into various metrics related to that specific service:

![TSB Service UI: inspecting metrics for a service](../../assets/quickstart/services-1.png)
