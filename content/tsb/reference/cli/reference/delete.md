---
id: delete
title: tctl delete
description: Delete command
---
## tctl delete

Delete an object

```
tctl delete [<apiVersion/kind> <name>] [flags]
```

**Examples**

```
# Delete a cluster using the apiVersion/Kind pattern
tctl delete api.tsb.tetrate.io/v2/Cluster my-cluster

# Delete a single workspace using the short form
tctl delete ws my-workspace

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
  -f, --file string                 File containing configuration to apply
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
      --force                       Force object deletion even if deletion protection is enabled
  -h, --help                        help for delete
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

