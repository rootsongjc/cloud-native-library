---
title: Move Data To A New Organization
description: Moving all the configurations, users, and groups from an organization to a newly created one.
weight: 10
---

This document describes how to move all configurations, users, and groups from an
[organization](../concepts/terminology/#organization) to a newly created one.

## Get Data

Start by extracting all of the configurations per tenant. For each tenant, execute the following command:

```bash
tctl get all --tenant <tenant> > config.yaml
```

Once you have all the configurations in `config.yaml`, make sure to manually copy the
[various bindings](../refs/tsb/rbac/v2/yaml) (e.g. ApplicationAccessBindings, APIAccessBindings, etc) in it to a file called
`bindings.yaml`, and remove them from `config.yaml`.

This is due to the fact that when you use the contents of `config.yaml` later, the fully qualified names for the
bindings will not exist, which would have resulted in an error when applying the configuration. The bindings will have
to be applied *after* the objects have been moved to the new organization.

You will also have to edit `config.yaml` and replace the value in each `metadata.organization` field in the file to
point to the new organization you will create.

If you are creating a new tenant, you should also change the tenant section.

Below is a sample YAML file showing what an entry in your `config.yaml` should look like. Please also note that the YAML
file below does not have the fully qualified names, `etag`, and `resourceVersion`. These should also be removed from
your `config.yaml`.

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  displayName: Bookinfo app
  name: bookinfo
  organization: ${myorg}
  tenant: ${mytenant}
spec:
  displayName: Bookinfo app
  namespaceSelector:
    names:
    - '*/bookinfo'
```

## Apply the configuration

Once `config.yaml` has been edited, you need to create the new organization. Create a file called `myorg.yaml` with the
following content, replacing the name with your new organization name:

```
apiVersion: api.tsb.tetrate.io/v2
kind: Organization
metadata:
  name: <myorg>
```

Then apply the new configuration to create the organization.

```bash
tctl apply -f myorg.yaml
```

For each tenant in your old organization, you will have to create an equivalent tenant in the new organization. Create a
file containing the necessary tenants. The content should look like the sample below, with the organization and tenant
name replaced to valid values in your environment.

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Tenant
metadata:
  organization: <myorg>
  name: <mytenant>
```

Then apply the new configuration to create the new tenant(s). The example assumes you have listed all of the necessary
tenants in the file `mytenants.yaml`

```bash
tctl apply -f mytenants.yaml
```

Finally, apply the configuration stored in the file `config.yaml` you edited earlier:

```bash
tctl apply -f config.yaml
```

At this point, both the old and the new organizations will exist, but only the old one will be working, as you have not
yet updated the configuration in the management plane to point to the new organization.

## Onboard the clusters

Create a file `clusters.yaml` with content resembling below sample, with the name of the cluster and organization
replaced to valid values in your environment. Add more entries for all of the clusters that should belong to the new
organization.

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Cluster
metadata:
  name: <cluster>
  organization: <myorg>
  labels:
    env: qa
    tier: one
spec:
  displayName: "Cluster T1"
  network: tier1
  tier1Cluster: true
```

Then apply the configuration.  This will associate the clusters with the new organization.

```bash
tctl apply -f clusters.yaml
```

Create a file `controlplane.yaml` resembling below sample, with the name of the cluster replaced to a valid value in
your environment.

<!-- is there a tcl get controlplane type of command, so the user can just copy the necessary values ? -->

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  name: controlplane
  namespace: istio-system
spec:
  hub: ...
  telemetryStore:
    ...
  managementPlane:
    host: ...
    port: ...
    clusterName: <mycluster>
```

## Sync the users/groups

At this point you should have all of the clusters and the control plane migrated to the new organization. You now need
to synchronize the users and groups to the new organization. To do this, create a Job as follows

```bash
kubectl create job --from=cronjob/teamsync teamsync -n tsb
```

After some time, when the job is finished, you will be able to see the users and groups in the new organization from the
TSB UI.

Make sure to remove `tetrate-agents` from the bindings. Remove the section shown below from every binding in
`bindings.yaml`

```yaml
- role: rbac/envreader
  subjects:
  - team: organizations/<myorg>/teams/tetrate-agents
```

Then, after this is done, apply the bindings:

```bash
tctl apply -f bindings.yaml
```

## Migrate the organization

At this point you have moved everything to the new organization, but the management plane is still configured to use the
old one.

Create a file called `managementplane.yaml` and point it to use the new organization:

```
apiVersion: install.tetrate.io/v1alpha1
kind: ManagementPlane
metadata:
  name: managementplane
  namespace: tsb
spec:
  hub: ...
  organization: <myorg>
  dataStore:
    ...
  telemetryStore:
    ...
  tokenIssuer:
    ...
```

Now is a good time to make sure you have not misconfigured anything, as applying this configuration may result in your
applications being disconnected and taken down.

Make sure that you have no missing configuration from the old organization which has not yet been applied to the newly
created organization. For example, when/if you have tier1-tier2 configured, you need to explicitly allow the network to
communicate from tier1 to tier2.

Once you are satisfied, apply the new configurations:

```bash
kubectl apply -f managementplane.yaml
```

And finally, login to TSB using the new organization:

```bash
tctl login
```

Once you have verified everything is working appropriately, you can proceed to delete the old workspaces, tenants, and
organization.

{{<callout note "User validation against old organization">}}
In case you have an external LDAP configured to work with TSB, and users are still being validated against the old
organization, you will need to manually fix data stored in Postgres. If you have followed the steps in the exact
sequence as provided in this document, this should however not occur.

**If you do need to fix Postgres, please make sure to backup the database first**. When ready, issue the following
command from the Postgres command line, replacing `<your_old_org>` with the name of your old organization:

```
delete from node where name like '%<your_old_org>%';
```

This will delete the required table, and also delete other related data from other tables via foreign keys.
{{</callout>}}
