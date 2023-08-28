---
id: get
title: tctl get
description: Get command
---
## tctl get

Get one or multiple objects

```
tctl get <apiVersion/kind | kind | shortform> [<name>] [flags]
```

**Examples**

```
# List tenants using the apiVersion/Kind pattern
tctl get api.tsb.tetrate.io/v2/Tenant

# List workspaces using the kind
tctl get workspace

# Get a single workspace using the short form
tctl get ws my-workspace

# List gateway groups of a workspace
tctl get --workspace my-workspace GatewayGroup

# Get the access bindings of an ingress gateway
tctl get accessbindings organizations/foo/tenants/foo/workspaces/foo/gatewaygroups/foo/ingressgateways/foo

# Get all resources within a tenant
tctl get all --tenant foo

# Get all resources within a workspace
tctl get all --tenant foo --workspace bar

# Get all resources within a given group
tctl get all --tenant foo --workspace bar --gatewaygroup baz

# Get all resources within a tenant, referrencing a given FQDN
tctl get all --tenant foo --fqdn some.fqdn.local

# Get all IngressGateway within a given tenant
tctl get all --tenant foo --kind IngressGateway

# Get all access bindings within a given tenant
tctl get all --tenant foo --api-version rbac.tsb.tetrate.io/v2

NOTE. Filters supplied to "tctl get all" are ANDed.

# Get all IngressGateway within a given tenant AND that include the FQDN foo.local
tctl get all --tenant foo --kind IngressGateway --fqdn foo.local

Group kind is available for different APIs, so these helpers are available to easily retrieve them:
- TrafficGroup
- SecurityGroup
- GatewayGroup
- IstioInternalGroup

These are the available short forms:
 aab	ApplicationAccessBindings
 ab	AccessBindings
 ap	AuthorizationPolicy
 apiab	APIAccessBindings
 app	Application
 cs	Cluster
 dr	DestinationRule
 ef	EnvoyFilter
 eg	EgressGateway
 gab	GatewayAccessBindings
 gg	GatewayGroup
 gw	networking.istio.io/v1beta1/Gateway
 gwt	gateway.tsb.tetrate.io/v2/Gateway
 iab	IstioInternalAccessBindings
 ig	IngressGateway
 iig	IstioInternalGroup
 oab	OrganizationAccessBindings
 org	Organization
 os	OrganizationSetting
 otm	Metric
 ots	Source
 pa	PeerAuthentication
 ra	RequestAuthentication
 sa	ServiceAccount
 sab	SecurityAccessBindings
 sd	Sidecar
 se	ServiceEntry
 sg	SecurityGroup
 sr	ServiceRoute
 ss	SecuritySetting
 sss	ServiceSecuritySetting
 svc	Service
 t1	Tier1Gateway
 tab	TrafficAccessBindings
 tg	TrafficGroup
 tnab	TenantAccessBindings
 tns	TenantSetting
 ts	TrafficSetting
 vs	VirtualService
 wab	WorkspaceAccessBindings
 wext	WasmExtension
 wp	WasmPlugin
 ws	Workspace
 wss	WorkspaceSetting

For API version and kind, please refer to: https://docs.tetrate.io/service-bridge/latest/en-us/reference

```

**Options**

```
      --org string                    Organization the object belongs to
      --tenant string                 Tenant the object belongs to
  -w, --workspace string              Workspace the object belongs to
  -g, --group string                  Group the object belongs to
  -t, --trafficgroup string           Traffic group the object belongs to
  -s, --securitygroup string          Security group the object belongs to
  -l, --gatewaygroup string           Gateway group the object belongs to
  -i, --istiointernalgroup string     Istio internal group the object belongs to
  -a, --application string            Application the object belongs to
      --api string                    API the object belongs to
  -o, --output-type string            Response output type: table, yaml, json (default "table")
      --fqdn string                   FQDN to filter results of get all
      --kind string                   Kind to filter results of get all
      --api-version string            apiVersion to filter results of get all
      --service string                Service the object belongs to
      --telemetry-source string       Telemetry source the object belongs to
      --max-concurrent-requests int   Maximum of concurrent requests sent to TSB
  -h, --help                          help for get
```

**Options inherited from parent commands**

```
  -c, --config string               Path to the config file to use. Can also be
                                    specified via TCTL_CONFIG env variable. This flag
                                    takes precedence over the env variable.
      --debug                       Print debug messages for all requests and responses
      --disable-tctl-version-warn   If set, disable the outdated tctl version warning. Can also be
                                    specified via TCTL_DISABLE_VERSION_WARN env variable.
  -p, --profile string              Use specific profile (default "default")
```

