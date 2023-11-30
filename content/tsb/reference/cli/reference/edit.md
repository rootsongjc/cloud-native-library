---
title: tctl edit
description: Edit command
---

Edit one or multiple objects

```
tctl edit <apiVersion/kind | kind | shortform> [<name>] [flags]
```

**Examples**

```
Edit will perform a get on the given object
and launch $EDITOR (environment variable needs to be set) for editing it
then apply the changes back.

# Edit a workspace.
tctl edit workspace foo

# Edit a tenant
tctl edit tenant my-department

# Edit an IngressGateway
tctl edit ingressgateway myIng --workspace foo --gatewaygroup bar

# You can also edit lists of objects

# Edit multiple gateway groups at once
tctl edit gatewaygroup --workspace foo --gatewaygroup bar baz

# Or even all workspaces at once
tctl edit workspace --tenant foo

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
      --org string                  Organization the object belongs to
      --tenant string               Tenant the object belongs to
  -w, --workspace string            Workspace the object belongs to
  -g, --group string                Group the object belongs to
  -t, --trafficgroup string         Traffic group the object belongs to
  -s, --securitygroup string        Security group the object belongs to
  -l, --gatewaygroup string         Gateway group the object belongs to
  -i, --istiointernalgroup string   Istio internal group the object belongs to
  -a, --application string          Application the object belongs to
      --api string                  API the object belongs to
  -o, --output-directory string     Response output type: table, yaml, json
  -h, --help                        help for edit
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

