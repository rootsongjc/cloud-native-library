---
title: Traffic Shifting
description: Shifting traffic between different versions of your demo app's review service.
weight: 9
---

In this scenario, you will learn how to use a Service Route to shift traffic between different versions of the review service in your demo app.

### Prerequisites

Before proceeding, ensure that you have completed the following tasks:

- Familiarize yourself with TSB concepts.
- Install the TSB demo environment.
- Deploy the Istio Bookinfo sample application.
- Create a Tenant, Workspace, Config Groups, Permissions, Ingress Gateway, and check service topology and metrics.

### Serve v1 only

#### Using the UI

1. Under **Tenant** on the left panel, select **Workspaces**.
2. On the `bookinfo-ws` Workspace card, click on **Traffic Groups**.
3. Click on the `bookinfo-traffic` Traffic Group you created previously.
4. Select the **Traffic Settings** tab.
5. Under Traffic Settings, click on **Service Routes**.
6. Click **Add new...** to create a new Service Route with the default name `default-serviceroute`.
7. Rename it to `bookinfo-traffic-reviews`.
8. Set Service to `bookinfo/reviews.bookinfo.svc.cluster.local`.
9. Expand **bookinfo-traffic-reviews**.
10. Expand **Subsets**.
11. Click **Add new Subset...** to create a new Subset called `subset-0`.
12. Click on `subset-0`:
   - Set name to `v1`.
   - Set the weight to `100`.
   - Click on **Add Label**, and set Label to `version` and Value to `v1`.
13. Click **Save Changes**.

#### Using tctl

Create the following `reviews.yaml` file:

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: ServiceRoute
Metadata:
  organization: tetrate
  name: bookinfo-traffic-reviews
  group: bookinfo-traffic
  workspace: bookinfo-ws
  tenant: tetrate
spec:
  service: bookinfo/reviews.bookinfo.svc.cluster.local
  subsets:
    - name: v1
      labels:
        version: v1
```

Apply the configuration using `tctl`:

```bash
tctl apply -f reviews.yaml
```

#### Verify result

Open https://bookinfo.tetrate.com/productpage and refresh the page several times. You will see that only reviews v1 (no star ratings) are displayed.

### Split traffic between v1 and v2

#### Using the UI

1. Select the `v1` subset of your Service Route.
2. Enter `50` as the weight.
3. Click **Add new Subset...** below the `v1` subset to create a new Subset called `subset-1`.
4. Click on `subset-1`:
   - Set name to `v2`.
   - Enter `50` as the weight.
   - Click on **Add Label**, and set Label to `version` and Value to `v2`.
5. Click **Save Changes**.

#### Using tctl

Update the `reviews.yaml` file to split traffic evenly between `v1` and `v2`:

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: ServiceRoute
Metadata:
  organization: tetrate
  name: bookinfo-traffic-reviews
  group: bookinfo-traffic
  workspace: bookinfo-ws
  tenant: tetrate
spec:
  service: bookinfo/reviews.bookinfo.svc.cluster.local
  subsets:
    - name: v1
      labels:
        version: v1
      weight: 50
    - name: v2
      labels:
        version: v2
      weight: 50
```

Apply the updated configuration using `tctl`:

```bash
tctl apply -f reviews.yaml
```

#### Verify result

Go to https://bookinfo.tetrate.com/productpage again and refresh the page several times. You will see reviews switching between v1 (no star ratings) and v2 (black star ratings) versions.

### Serve v2 only

#### Using the UI

1. Select the `v1` subset of your Service Route.
2. Click **Delete v1** to remove it.
3. Select the `v2` subset of your Service Route.
4. Set the weight to `100`.
5. Click **Save Changes**.

#### Using tctl

Update the `reviews.yaml` file to route 100% traffic to the `v2` version:

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: ServiceRoute
Metadata:
  organization: tetrate
  name: bookinfo-traffic-reviews
  group: bookinfo-traffic
  workspace: bookinfo-ws
  tenant: tetrate
spec:
  service: bookinfo/reviews.bookinfo.svc.cluster.local
  subsets:
    - name: v2
      labels:
        version: v2
```

Apply the updated configuration using `tctl`:

```bash
tctl apply -f reviews.yaml
```

#### Verify result

Go to https://bookinfo.tetrate.com/productpage again and refresh the page several times. You will see reviews only showing the v2 version (black star ratings).

By following these steps, you have successfully managed traffic shifting between different versions of the review service in your demo app using TSB's Service Route feature.
