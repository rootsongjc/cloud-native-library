---
title: Create a Tenant
description: Create a TSB Tenant using the UI or tctl.
weight: 3
---

Here's the content for the "Create a Tenant" section:

## Create a Tenant

In this section, you will learn how to create a TSB Tenant using either the TSB UI or `tctl`.

### Prerequisites

Before proceeding, ensure that you have completed the following tasks:

- Familiarize yourself with TSB concepts.
- Install the TSB demo environment.
- Deploy the Istio Bookinfo sample application.

### Using the UI

1. Under **Organization** on the left panel, select **Tenants**.
2. Click the card to add a **new Tenant**.
3. Enter the Tenant ID as `tetrate`.
4. Provide your Tenant with a display name and description.
5. Click **Add**.

### Using tctl

Create the following [`tenant.yaml`](../../assets/quickstart/tenant.yaml) file:

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Tenant
metadata:
  organization: tetrate
  name: tetrate
spec:
  displayName: Tetrate
```

Apply the configuration using `tctl`:

```bash{promptUser: alice}
tctl apply -f tenant.yaml
```

By following these steps, you will have successfully created a TSB Tenant named `tetrate`. This Tenant can be used to organize and manage your TSB environment.
