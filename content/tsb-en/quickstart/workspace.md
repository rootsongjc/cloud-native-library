---
title: Create a Workspace
description: Create a TSB Workspace using the UI or tctl.
weight: 4
---

In this section, you will learn how to create a TSB Workspace called `bookinfo-ws` bound to the `bookinfo` namespace.

### Prerequisites

Before proceeding, make sure you have completed the following tasks:

- Familiarize yourself with TSB concepts.
- Install the TSB demo environment.
- Deploy the Istio Bookinfo sample application.
- Create a Tenant.

### Using the UI

1. Under **Tenant** on the left panel, select **Workspaces**.
2. Click the card to add a new Workspace.
3. Enter the Workspace ID as `bookinfo-ws`.
4. Provide your Workspace with a display name and description.
5. Enter `demo/bookinfo` as the Initial namespace selector.
6. Click **Add**.

If you have previously onboarded the demo app successfully, you should see something similar to:

- 1 Cluster
- 1 Namespace
- 4 Services
- 1 Workspace

### Using tctl

Create the following `workspace.yaml` file:

```yaml
apiversion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: tetrate
  tenant: tetrate
  name: bookinfo-ws
spec:
  namespaceSelector:
    names:
      - "*/bookinfo"
```

Apply the configuration using `tctl`:

```bash
tctl apply -f workspace.yaml
```

If you have previously onboarded the demo app successfully and go to the UI to display Tenants, you should see something similar to the following:

![TSB Tenant UI: objects created](../../assets/quickstart/tenant-stats.png)

- 1 Cluster
- 1 Namespace
- 4 Services
- 1 Workspace

By following these steps, you have successfully created a TSB Workspace called `bookinfo-ws` bound to the `bookinfo` namespace.