---
title: YAML API Guide
menu-title: Guide
description: Guide describing how to use our YAML API for communication with TSB.
---

In this guide you'll learn how to use the TSB CLI (`tctl`) to perform common
operations on the platform. You will learn how to configure the CLI to access
your TSB installation and how to manage TSB resources from the command line.

## Getting started

To use the YAML API you need the TSB CLI
[installed and configured](../cli/guide/index).

Once you have the CLI installed and configured to talk to your TSB installation,
you'll need to configure access to the TSB platform with the `tctl login`
command:

```bash
tctl login
```

You will be prompted for the TSB organization, which was set in the TSB install
process or made available to you, the tenant, and the credentials.

The platform administrator should have already assigned a tenant to you. If not,
or you are an administrator performing an initial setup, it is OK to leave it
blank. You can always edit the configured user later and set the tenant when
needed.

```text
Organization: tetrate
Tenant:
Username: admin
Password:
Login Successful!
  Configured user: demo-admin
  User "demo-admin" enabled in profile: demo
```

:::note Important
The Organization and Tenant pre-configured in the user settings are used only in
the `tctl get` and `tctl delete` commands. When creating or modifying resources
with `tctl apply`, the organization and tenant will be taken from each resource
**metadata** section, as you'll see below.
:::

## YAML API fundamentals

The TSB YAML API has declarative semantics. All TSB objects share a common set
of properties that are used to uniquely identify the object in the resource
hierarchy, and a specific model that holds the values that belong to that
particular resource. For example, the following TSB resource configures the
traffic settings for a given traffic group:

```yaml
# block 1 - resource type
apiVersion: traffic.tsb.tetrate.io/v2
kind: TrafficSetting
# block 2 - resource metadata
metadata:
  name: defaults
  group: helloworld
  workspace: helloworld
  tenant: tetrate
  organization: tetrate
# block 3 - resource contents
spec:
  reachability:
    mode: GROUP
  resilience:
    circuitBreakerSensitivity: MEDIUM
```

- The first block (`apiVersion` and `kind`) identifies the type of the resource.
- The second block defines the `metadata` for the resource. All resources have a
  `name` and a set of metadata properties that configure where in the resource
  hierarchy the resource belongs. 
- The third block (`spec`) contains the actual contents of the resource object.

### Applying resources

Resources are applied with the `tctl apply` command. If an applied resource does
not yet exist, this will create it. If the resource already exists, the command
will replace the contents with the information it contains.

:::note
Update operations are full object updates. The entire object must be sent on
every apply operation as partial updates are not supported.
:::

When applying resources, the parent resources must exist as well. If the `apply`
request contains several resources, they must be provided in the right order to
make sure the operation will not fail because a resource is missing its parent.
The following example shows how to create a tenant and a workspace in an
existing organization:

```bash
tctl apply -f - <<EOF
apiVersion: api.tsb.tetrate.io/v2
kind: Tenant
metadata:
  organization: tetrate    # This organization must exist
  name: example-tenant     # Name of the tenant to be created
spec:
  displayName: Example Tenant
  description: An example tenant for the YAML guide
---
apiversion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: tetrate
  tenant: example-tenant   # Name of the tenant above
  name: first-workspace    # Name of the workspace to be created
spec:
  displayName: First Workspace
  description: An example workspace
  namespaceSelector:
    names:
      - "*/default"
---
EOF
```

### Listing and getting resources

The `tctl get` command retrieves resources. If no name is specified, all
resources of the requested kind will be returned. If a specific name is given,
then only the requested resource is returned.

The syntax for the get command is: `tctl get <resource type> <parameters>`

Where the parameters include the optional resource name, and the necessary flags
to configure the location in the resource hierarchy where the resource belongs.

The command also accepts several output parameters, to retrieve the objects in a
table form (default), YAML or JSON:

#### Get all workspaces in the configured tenant

```bash
tctl get workspace
```

Example output:

```text
NAME        DISPLAY NAME  DESCRIPTION
helloworld  Helloworld    Helloworld application
bookinfo    Bookinfo      Bookinfo application
```

#### Get the details of a workspace

```bash
tctl get workspace helloworld -o yaml
```

Example output:

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  description: Helloworld application
  displayName: Helloworld
  name: helloworld
  organization: tetrate
  resourceVersion: '"BePMGaj00FM="'
  tenant: tetrate
spec:
  description: Helloworld application
  displayName: Helloworld
  etag: '"BePMGaj00FM="'
  fqn: organizations/tetrate/tenants/tetrate/workspaces/helloworld
  namespaceSelector:
    names:
    - '*/helloworld'
```

#### Get all service routes in a given traffic group

Note that we need to provide the flags to specify which is the workspace and
group we want to get the service routes for:

```bash
tctl get serviceroute \
    --workspace helloworld \
    --trafficgroup helloworld -o yaml
```

Example output:

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: ServiceRoute
metadata:
  group: helloworld
  name: hello
  organization: tetrate
  resourceVersion: '"NWEYABT/fjM="'
  tenant: tetrate
  workspace: helloworld
spec:
  etag: '"NWEYABT/fjM="'
  fqn: organizations/tetrate/tenants/tetrate/workspaces/helloworld/trafficgroups/helloworld/serviceroutes/hello
  service: helloworld/helloworld.helloworld.svc.cluster.local
  subsets:
  - labels:
      version: v1
    name: v1
    weight: 80
  - labels:
      version: v2
    name: v2
    weight: 20
```

### Deleting resources

The `tctl delete` command deletes resources. It follows the same semantics as
the tctl get command, except that the name parameter is required.

:::warning
Note that deleting a resource will delete the resource and all its child
objects, so use this with caution, especially when deleting resources that are
at higher levels of the resource hierarchy.
:::

Assume you have an existing `trafficgroup` you can query with the command below:

```bash
tctl get trafficgroup --workspace test
```

Example output:

```text
NAME     DISPLAY NAME  DESCRIPTION
test-tg  test-tg       et-tg
```

To delete the `trafficgroup`:

```bash
tctl delete trafficgroup test-tg --workspace test
```

Query it again:

```bash
tctl get trafficgroup -w test
No resources found
```
