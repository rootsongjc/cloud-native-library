---
title: Configuring Permissions
description: Configure access policies using AccessBindings.
weight: 6
---

In this section, you will learn how to configure access policies using `AccessBindings` in TSB to manage permissions for different teams and users.

### Prerequisites

Before proceeding, ensure that you have completed the following tasks:

- Familiarize yourself with TSB concepts.
- Install the TSB demo environment.
- Deploy the Istio Bookinfo sample application.
- Create a Tenant and Workspace.
- Create Config Groups.

### Grant Full Access to a Team for a Workspace

You will configure an access policy that grants a team full access to a Workspace. The members of the team will be able to create and fully manage the resources within the Workspace, but won't be able to modify the Workspace object itself. This will be achieved by assigning the `Creator` role.

1. In the left panel, under **Tenant**, select **Workspaces**.
2. Click the desired Workspace to access its details page.
3. Click the **Permissions** tab.
4. Select the **By Teams** option to view the list of teams.
5. Locate and click the **Edit** icon on the right of the desired team.
6. Choose the `Creator` [role](../../refs/tsb/rbac/v2/role).
7. Click the **Save Changes** button at the bottom right.

### Grant Write Permissions to a User for a Group

To grant write permissions to a specific user for a Group, follow a similar process:

1. Navigate to the Group's **Permissions** tab.
2. Choose the **By Users** option to view the list of users.
3. Find and click the **Edit** icon next to the desired user.
4. Select the `Writer` [role](../../refs/tsb/rbac/v2/role).
5. Click the **Save Changes** button at the bottom right.

### Using tctl

You can also achieve the same configuration using `tctl` by applying `AccessBindings` defined in a YAML file:

Create the following [`access-policy.yaml`](../../assets/quickstart/access-policy.yaml) file with the necessary `AccessBindings` for both Workspace and Traffic Group objects.

Apply the policy using `tctl`:

```bash
tctl apply -f access-policy.yaml
```

By following these steps, you can effectively configure access policies using `AccessBindings` to manage permissions for different teams and users within your TSB environment.
