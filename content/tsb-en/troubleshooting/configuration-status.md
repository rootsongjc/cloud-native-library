---
title: Configuration status troubleshooting
description: Use tctl to understand what's the deployment status of TSB configurations
---

Tetrate Service Bridge's [tctl CLI](../reference/cli/guide/index) lets you
interact with the TSB API to apply objects's configurations. This document
describes how to use tctl to understand what's the deployment status of a
resource configuration within the system.

## Resource Status

TSB tracks the lifecycle of configuration changes as ResourceStatus. You can
fetch them using [tctl x
status](../reference/cli/reference/experimental#tctl-experimental-status). Run
`tctl x status --help` to see all the possible options.

There are different types of resources, depending on how their configuration status is computed.

| Resource Type | Configuration Status | Examples |
| - | - | - |
| Parent | Aggregate the status of their children resources. | `workspace`, `trafficgroup`, `gatewaygroup`, `securitygroup` |
| Child | Does not depend on other resources. | `ingressgateway`, `egressgateway`, `trafficsettings`, etc |
| Non-configurable| Do not get directly materialized as configurations in the target cluster. | `organizations`, `tenants`, `users` |
| With dependencies | High-level resources. | `applications` and `apis` |

A resource status can have several values, depending on on how far its
configuration has been propagated across the [TSB
components](../concepts/architecture).

| Type | Status | Condition |
| - | - | - |
| Child and non-configurable | `ACCEPTED` | Their configuration has been validated and persisted. This is the initial value for valid configurations. |
| | `READY` | Their configuration have been propagated to all the destination clusters. This is also the default state for non-configurable resources. |
| | `PARTIAL` | Some of their configuration are ready in some destination clusters, but not in all of them. |
| | `FAILED` | Their configuration has triggered some internal error in some, or all, destination clusters. |
| | `FAILED` | An offending resource in a destination clusters affects the correct behaviour of the configuration. |
| | | | 
| Parent | `ACCEPTED` | All their children resources either `ACCEPTED` or `READY`. |
| | `READY` | All their children resources `READY`. |
| | `FAILED` | Any of their children has `FAILED`. |
| | | | 
| With dependencies | `ACCEPTED` | All their dependent configurations are `ACCEPTED`. |
| | `READY` | All their dependent configurations are `READY`. |
| | `DIRTY` | All their dependent configurations are `DIRTY`. |
| | `FAILED` | Any of their dependent configurations are `FAILED`. |
| | `PARTIAL` | Their dependent configurations are in a mix of `READY`, `ACCEPTED` and/or `DIRTY`. |

You can read more about the status types in [the Status API spec](../refs/tsb/v2/status#status).

## Using tctl to understand the status of config objects

Let's see some examples in a scenario where the `bookinfo` app is deployed.

:::note
We assume the Bookinfo application has been deployed in its own workspace, as
in our [Quick Start](../quickstart/introduction) tutorials, and has been
configured with the corresponding groups.
:::

You can check the status of the `bookinfo` ingress gateway with `tctl x status`:

```bash{promptUser: alice}
$ tctl x status ig --tenant tetrate --workspace bookinfo --gatewaygroup bookinfo bookinfo
NAME        STATUS      LAST EVENT      MESSAGE
bookinfo    ACCEPTED    XCP_ACCEPTED
```

This shows that its configuration has been validated and persisted.

If you want further information, its yaml version will show you the history of
events of this resource status. This information is very useful for
troubleshooting the lifecycle of a resource configuration.

```bash{promptUser: alice}
$ tctl x status ig --tenant tetrate --workspace bookinfo --gatewaygroup bookinfo bookinfo
apiVersion: api.tsb.tetrate.io/v2
kind: ResourceStatus
metadata:
  group: bookinfo
  name: bookinfo
  organization: tetrate
  tenant: tetrate
  workspace: bookinfo
spec:
  configEvents:
    events:
    - etag: '"sMlEWPbvm6M="'
      timestamp: "2022-02-10T16:54:14.710165091Z"
      type: XCP_ACCEPTED
    - etag: '"sMlEWPbvm6M="'
      timestamp: "2022-02-10T16:54:14.649002805Z"
      type: MPC_ACCEPTED
    - etag: '"sMlEWPbvm6M="'
      timestamp: "2022-02-10T16:54:10.453242255Z"
      type: TSB_ACCEPTED
  status: ACCEPTED
```

Here you can see the historic of events that changed the status of the last
version `sMlEWPbvm6M=` of this `ingressgateway` resource, most recent first.

In this example, the resource was initially accepted by TSB Server, then by MPC
and finally by the XCP component.

Note that just the historic of the latest resource version is persisted. In the
following section your will learn how to use Audit Logs to display the historic
for all the versions.

## Using the TSB audit logs to understand the lifecycle of config objects

TSB has the notion of audit logs that show everything that happens to a TSB
resource. Who did what and when, on each resource, and it also gives insights
on the different stages of its config.

For example, you could use the following command to get a list of all the events
that happened on the bookinfo workspace and all the resources contained in it.

```bash{promptUser: alice}
$ tctl x audit ws bookinfo --recursive --text bookinfo
TIME                   SEVERITY    TYPE                                        OPERATION               USER     MESSAGE
2022/02/10 17:02:53    INFO        api.tsb.tetrate.io/v2/ResourceStatus        XCP_CENTRAL_ACCEPTED    mpc      New ACCEPTED status due to XCP_CENTRAL_ACCEPTED event for trafficgroup "bookinfo" version "oxil15u6bfw="
2022/02/10 17:02:53    INFO        api.tsb.tetrate.io/v2/ResourceStatus        XCP_CENTRAL_ACCEPTED    mpc      New ACCEPTED status due to XCP_CENTRAL_ACCEPTED event for securitygroup "bookinfo" version "gEUA3cK7+YI="
2022/02/10 17:02:52    INFO        api.tsb.tetrate.io/v2/ResourceStatus        MPC_ACCEPTED            mpc      New ACCEPTED status due to MPC_ACCEPTED event for ingressgateway "bookinfo" version "sMlEWPbvm6M="
2022/02/10 17:02:52    INFO        api.tsb.tetrate.io/v2/ResourceStatus        MPC_ACCEPTED            mpc      New ACCEPTED status due to MPC_ACCEPTED event for trafficgroup "bookinfo" version "oxil15u6bfw="
2022/02/10 17:02:52    INFO        api.tsb.tetrate.io/v2/ResourceStatus        XCP_CENTRAL_ACCEPTED    mpc      New ACCEPTED status due to XCP_CENTRAL_ACCEPTED event for workspace "bookinfo" version "GBcgtWe3R80="
2022/02/10 17:02:52    INFO        api.tsb.tetrate.io/v2/ResourceStatus        XCP_CENTRAL_REJECTED    mpc      New ACCEPTED status due to XCP_CENTRAL_ACCEPTED event for gatewaygroup "bookinfo" version "y6q054gFZCQ="
2022/02/10 17:02:52    INFO        api.tsb.tetrate.io/v2/ResourceStatus        MPC_ACCEPTED            mpc      New ACCEPTED status due to MPC_ACCEPTED event for securitygroup "bookinfo" version "gEUA3cK7+YI="
2022/02/10 17:02:52    INFO        api.tsb.tetrate.io/v2/ResourceStatus        MPC_ACCEPTED            mpc      New ACCEPTED status due to MPC_ACCEPTED event for workspace "bookinfo" version "GBcgtWe3R80="
2022/02/10 17:02:52    INFO        api.tsb.tetrate.io/v2/ResourceStatus        MPC_ACCEPTED            mpc      New ACCEPTED status due to MPC_ACCEPTED event for gatewaygroup "bookinfo" version "y6q054gFZCQ="
2022/02/10 17:02:48    INFO        gateway.tsb.tetrate.io/v2/IngressGateway    create                  admin    Create IngressGateway "bookinfo" by "admin"
```

Some errors are identified in the audit logs that you can further inspect by
retrieving the details of the config status for those objects:

```bash{promptUser: alice}
$ tctl x status ig --workspace bookinfo --gatewaygroup bookinfo bookinfo
NAME        STATUS    LAST EVENT              MESSAGE
bookinfo    FAILED    XCP_CENTRAL_REJECTED    admission webhook "central-validation.xcp.tetrate.io" denied the request: configuration is invalid: domain name "tetrate.io---" invalid (label "io---" invalid)
```

As you can see in the command output, the configuration has been rejected by the
XCP component and flagged as invalid, and it will not be propagated to the
target clusters.

You can also get insights by querying the status of the workspace. It will show
any errors in its child resources. This way it is very easy to navigate from
any workspace or top-level element to the specific errors that configuration
objects may present.

```bash{promptUser: alice}
$ tctl x status ws bookinfo
NAME        STATUS    LAST EVENT    MESSAGE
bookinfo    FAILED                  The following children are failing: organizations/tetrate/tenants/tetrate/workspaces/bookinfo/gatewaygroups/bookinfo
```

Or its extended yaml version:

```bash{promptUser: alice}
$ tctl x status ws bookinfo -o yaml
apiVersion: api.tsb.tetrate.io/v2
kind: ResourceStatus
metadata:
  name: bookinfo
  organization: tetrate
  tenant: tetrate
spec:
  aggregatedStatus:
    children:
      organizations/tetrate/tenants/tetrate/workspaces/bookinfo/gatewaygroups/bookinfo:
        message: 'The following children resources have issues: organizations/tetrate/tenants/tetrate/workspaces/bookinfo/gatewaygroups/bookinfo/ingressgateways/bookinfo'
        status: FAILED
      organizations/tetrate/tenants/tetrate/workspaces/bookinfo/securitygroups/bookinfo:
        status: ACCEPTED
      organizations/tetrate/tenants/tetrate/workspaces/bookinfo/trafficgroups/bookinfo:
        status: ACCEPTED
    configEvents:
      events:
      - etag: '"GBcgtWe3R80="'
        timestamp: "2022-02-10T18:32:29.593869622Z"
        type: XCP_ACCEPTED
      - etag: '"GBcgtWe3R80="'
        timestamp: "2022-02-10T18:32:29.576374660Z"
        type: MPC_ACCEPTED
      - etag: '"GBcgtWe3R80="'
        timestamp: "2022-02-10T18:32:24.679197258Z"
        type: TSB_ACCEPTED
  message: 'The following children resources have issues: organizations/tetrate/tenants/tetrate/workspaces/bookinfo/gatewaygroups/bookinfo'
  status: FAILED
```

Finally, audit logs help easily identify when config issues were introduced and
the exact changes that have been applied at any point in time. Here you can
clearly see that an update for admin triggered a change in the config resource
that was rejected, and you can see the exact fields that were changed, causing
the issue:

```bash{promptUser: alice}
$ tctl x audit ig --workspace bookinfo --gatewaygroup bookinfo bookinfo
TIME                   SEVERITY    TYPE                                        OPERATION               USER     MESSAGE
2022/02/10 22:04:14    INFO        api.tsb.tetrate.io/v2/ResourceStatus        XCP_CENTRAL_REJECTED    mpc      New FAILED status due to XCP_CENTRAL_REJECTED event for ingressgateway "bookinfo" version "O0HhTEHkvjA="
2022/02/10 22:04:14    INFO        api.tsb.tetrate.io/v2/ResourceStatus        MPC_ACCEPTED            mpc      New ACCEPTED status due to MPC_ACCEPTED event for ingressgateway "bookinfo" version "O0HhTEHkvjA="
2022/02/10 22:04:12    INFO        gateway.tsb.tetrate.io/v2/IngressGateway    update                  admin    Update IngressGateway "bookinfo" by "admin"
2021/11/25 16:02:53    INFO        api.tsb.tetrate.io/v2/ResourceStatus        XCP_CENTRAL_ACCEPTED    mpc      New ACCEPTED status due to XCP_CENTRAL_ACCEPTED event for ingressgateway "bookinfo" version "sMlEWPbvm6M="
2021/11/25 16:02:52    INFO        api.tsb.tetrate.io/v2/ResourceStatus        MPC_ACCEPTED            mpc      New ACCEPTED status due to MPC_ACCEPTED event for ingressgateway "bookinfo" version "sMlEWPbvm6M="
2021/11/25 16:02:48    INFO        gateway.tsb.tetrate.io/v2/IngressGateway    create                  admin    Create IngressGateway "bookinfo" by "admin"
```

Displaying the yaml with a date filter will output:

```bash{promptUser: alice}
$ tctl x audit ig --workspace bookinfo --gatewaygroup bookinfo bookinfo --operation update --since "2022/02/10 22:04:12" -o yaml
apiVersion: audit.tetrate.io/v1
kind: AuditLog
metadata: {}
spec:
  createTime: "2021-12-13T22:11:32Z"
  fqn: organizations/tetrate/tenants/tetrate/workspaces/bookinfo/gatewaygroups/bookinfo/ingressgateways/bookinfo
  kind: gateway.tsb.tetrate.io/v2/IngressGateway
  message: Update IngressGateway "bookinfo" by "admin"
  operation: update
  properties:
    diff: |2-
       {
        Fqn: "organizations/tetrate/tenants/tetrate/workspaces/bookinfo/gatewaygroups/bookinfo/ingressgateways/bookinfo",
      - Etag: "\"sMlEWPbvm6M=\"",
      + Etag: "\"O0HhTEHkvjA=\"",
        WorkloadSelector: {
         Namespace: "bookinfo",
         Labels: {
          app: "bookinfo-gateway",
         },
        },
        Http: [
         {
      -   Name: "productpage",
      +   Name: "productpage-invalid",
          Port: 80,
      -   Hostname: "bookinfo.tetrate.io",
      +   Hostname: "bookinfo.tetrate.io=--",
          Routing: {
           Rules: [
            {
             RouteOrRedirect: {
              Route: {
               Host: "bookinfo/productpage.bookinfo.svc.cluster.local",
               Port: 9080,
              },
             },
            },
           ],
          },
         },
        ],
       }
    display-name: ""
    etag: '"O0HhTEHkvjA="'
    fqn: organizations/tetrate/tenants/tetrate/workspaces/bookinfo/gatewaygroups/bookinfo/ingressgateways/bookinfo
  severity: INFO
  triggeredBy: admin
```

You can easily see in a `diff` format the exact fields that were changed.

## Summary

- You can use the config status commands to get status details and errors on
  individual resources.
- You can use it as well on top-level resources to quickly identify offending
  resources down the hierarchy.
- You can use the audit logs to have a global view of all events that happened
  on any TSB resource.
- You can correlate those audit logs with the configuration statuses.
- Audit logs give you details on the exact changes that were made to any
  resource.
