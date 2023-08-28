---
title: Create Config Groups
description: Create Gateway, Traffic, and Security Groups.
weight: 5
---

In order to configure the bookinfo application, you will need to create a Gateway Group, a Traffic Group, and a Security Group. Each group provides specific APIs to configure various aspects of the services.

### Prerequisites

Before you proceed with this guide, ensure you have completed the following steps:

- Familiarize yourself with [TSB concepts](../concepts/)
- Install the [TSB demo](../setup/self_managed/demo-installation) environment
- Deploy the [Istio Bookinfo](./deploy_sample_app) sample app
- Create a [Tenant](./tenant)
- Create a [Workspace](./workspace)

### Using the UI

1. On the left panel, under **Tenant**, select **Workspaces**.
2. Click on the `bookinfo-ws` Workspace card.
3. Click on the **Gateway Groups** button.
4. Click on the card with the + icon to add a new **Gateway Group**.
5. Enter the Group ID as `bookinfo-gw`.
6. Provide your Gateway Group with a display name and description.
7. Enter `*/bookinfo` as the Initial namespace selector.
8. Set the Config Mode to `BRIDGED`.
9. Click **Add**.
10. Return to the Workspace by selecting **Workspaces** from the left panel.

Repeat the same steps for the Traffic Group using Group ID `bookinfo-traffic`, and for the Security Group using Group ID `bookinfo-security`.

### Using tctl

Create the `groups.yaml` file:

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
  organization: tetrate
  tenant: tetrate
  workspace: bookinfo-ws
  name: bookinfo-gw
spec:
  namespaceSelector:
    names:
      - "*/bookinfo"
  configMode: BRIDGED
---
apiVersion: traffic.tsb.tetrate.io/v2
kind: Group
metadata:
  organization: tetrate
  tenant: tetrate
  workspace: bookinfo-ws
  name: bookinfo-traffic
spec:
  namespaceSelector:
    names:
      - "*/bookinfo"
  configMode: BRIDGED
---
apiVersion: security.tsb.tetrate.io/v2
kind: Group
metadata:
  organization: tetrate
  tenant: tetrate
  workspace: bookinfo-ws
  name: bookinfo-security
spec:
  namespaceSelector:
    names:
      - "*/bookinfo"
  configMode: BRIDGED
```

Apply the configuration using `tctl`:

```bash{promptUser: alice}
tctl apply -f groups.yaml
```

These steps will create the necessary Gateway, Traffic, and Security Groups for configuring various aspects of the services in the bookinfo application.
