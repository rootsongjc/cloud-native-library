---
title: tctl experimental
description: Experimental command
---

Experimental commands that may be modified or deprecated

**Options**

```
  -h, --help   help for experimental
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

## tctl experimental app-ingress

Run a Istio based Ingress Controller for your application

**Synopsis**

Install a dedicated Ingress Controller in your environment to allow
incoming/ingress traffic to be routed to your application.
This controller comprises of 3 components - Istiod, Istio Ingressgateway
and a TSB OpenAPI Translator.
You can configure the Ingress Controller by either specifying Istio
config directly in the application namespace or by specifying the OpenAPI document
for your application - the OpenAPI translator converts the specification into
Istio compatible configuration and applies it on your behalf.

**Options**

```
  -h, --help                             help for app-ingress
      --istio-hub string                 The hub for the Istio images in App Ingress (default "docker.io/istio")
      --istio-tag string                 The tag for the Istio images in App Ingress (default "1.17.2")
  -b, --openapi-backend-service string   Name of the backend service implementing the OpenAPI specification
  -o, --openapi-translator               Enable the OpenAPI translator which generates Istio configs from an OpenAPI specfication and applies them
      --openapi-translator-hub string    The hub for the OpenAPI Translator images in App Ingress (default "docker.io/tetrate")
      --openapi-translator-tag string    The tag for the OpenAPI Translator images in App Ingress (default "a0851637f824f2ae51fe10182c49c3c3fa32ed87")
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

## tctl experimental app-ingress docker-compose

Run App Ingress in Docker using docker-compose.

**Options**

```
  -h, --help                help for docker-compose
      --network string      Docker network (default "app-ingress")
      --output-dir string   Output directory (default "./")
```

**Options inherited from parent commands**

```
  -c, --config string                    Path to the config file to use. Can also be
                                         specified via TCTL_CONFIG env variable. This flag
                                         takes precedence over the env variable.
      --debug                            Print debug messages for all requests and responses
      --disable-tctl-version-warn        If set, disable the outdated tctl version warning. Can also be
                                         specified via TCTL_DISABLE_VERSION_WARN env variable.
      --istio-hub string                 The hub for the Istio images in App Ingress (default "docker.io/istio")
      --istio-tag string                 The tag for the Istio images in App Ingress (default "1.17.2")
  -b, --openapi-backend-service string   Name of the backend service implementing the OpenAPI specification
  -o, --openapi-translator               Enable the OpenAPI translator which generates Istio configs from an OpenAPI specfication and applies them
      --openapi-translator-hub string    The hub for the OpenAPI Translator images in App Ingress (default "docker.io/tetrate")
      --openapi-translator-tag string    The tag for the OpenAPI Translator images in App Ingress (default "a0851637f824f2ae51fe10182c49c3c3fa32ed87")
  -p, --profile string                   Use specific profile (default "default")
```

## tctl experimental app-ingress docker-compose generate

Generate the required docker-compose.yaml and folder structure to bootstrap App Ingress.

```
tctl experimental app-ingress docker-compose generate [OPTIONS] [flags]
```

**Options**

```
  -h, --help   help for generate
```

**Options inherited from parent commands**

```
  -c, --config string                    Path to the config file to use. Can also be
                                         specified via TCTL_CONFIG env variable. This flag
                                         takes precedence over the env variable.
      --debug                            Print debug messages for all requests and responses
      --disable-tctl-version-warn        If set, disable the outdated tctl version warning. Can also be
                                         specified via TCTL_DISABLE_VERSION_WARN env variable.
      --istio-hub string                 The hub for the Istio images in App Ingress (default "docker.io/istio")
      --istio-tag string                 The tag for the Istio images in App Ingress (default "1.17.2")
      --network string                   Docker network (default "app-ingress")
  -b, --openapi-backend-service string   Name of the backend service implementing the OpenAPI specification
  -o, --openapi-translator               Enable the OpenAPI translator which generates Istio configs from an OpenAPI specfication and applies them
      --openapi-translator-hub string    The hub for the OpenAPI Translator images in App Ingress (default "docker.io/tetrate")
      --openapi-translator-tag string    The tag for the OpenAPI Translator images in App Ingress (default "a0851637f824f2ae51fe10182c49c3c3fa32ed87")
      --output-dir string                Output directory (default "./")
  -p, --profile string                   Use specific profile (default "default")
```

## tctl experimental app-ingress kubernetes

Run App Ingress in Kubernetes

**Options**

```
  -f, --filename string             Path to file containing IstioOperator custom resource to further customize the istio components in App Ingress
  -h, --help                        help for kubernetes
  -n, --namespace string            The namespace to deploy the App Ingress deployments and services
      --openapi-config-map string   Name of the configmap containing the OpenAPI specification (default "openapi-translator")
```

**Options inherited from parent commands**

```
  -c, --config string                    Path to the config file to use. Can also be
                                         specified via TCTL_CONFIG env variable. This flag
                                         takes precedence over the env variable.
      --debug                            Print debug messages for all requests and responses
      --disable-tctl-version-warn        If set, disable the outdated tctl version warning. Can also be
                                         specified via TCTL_DISABLE_VERSION_WARN env variable.
      --istio-hub string                 The hub for the Istio images in App Ingress (default "docker.io/istio")
      --istio-tag string                 The tag for the Istio images in App Ingress (default "1.17.2")
  -b, --openapi-backend-service string   Name of the backend service implementing the OpenAPI specification
  -o, --openapi-translator               Enable the OpenAPI translator which generates Istio configs from an OpenAPI specfication and applies them
      --openapi-translator-hub string    The hub for the OpenAPI Translator images in App Ingress (default "docker.io/tetrate")
      --openapi-translator-tag string    The tag for the OpenAPI Translator images in App Ingress (default "a0851637f824f2ae51fe10182c49c3c3fa32ed87")
  -p, --profile string                   Use specific profile (default "default")
```

## tctl experimental app-ingress kubernetes generate

Generate the Kuberenetes YAML required to install App Ingress.

```
tctl experimental app-ingress kubernetes generate [OPTIONS] [flags]
```

**Options**

```
  -h, --help   help for generate
```

**Options inherited from parent commands**

```
  -c, --config string                    Path to the config file to use. Can also be
                                         specified via TCTL_CONFIG env variable. This flag
                                         takes precedence over the env variable.
      --debug                            Print debug messages for all requests and responses
      --disable-tctl-version-warn        If set, disable the outdated tctl version warning. Can also be
                                         specified via TCTL_DISABLE_VERSION_WARN env variable.
  -f, --filename string                  Path to file containing IstioOperator custom resource to further customize the istio components in App Ingress
      --istio-hub string                 The hub for the Istio images in App Ingress (default "docker.io/istio")
      --istio-tag string                 The tag for the Istio images in App Ingress (default "1.17.2")
  -n, --namespace string                 The namespace to deploy the App Ingress deployments and services
  -b, --openapi-backend-service string   Name of the backend service implementing the OpenAPI specification
      --openapi-config-map string        Name of the configmap containing the OpenAPI specification (default "openapi-translator")
  -o, --openapi-translator               Enable the OpenAPI translator which generates Istio configs from an OpenAPI specfication and applies them
      --openapi-translator-hub string    The hub for the OpenAPI Translator images in App Ingress (default "docker.io/tetrate")
      --openapi-translator-tag string    The tag for the OpenAPI Translator images in App Ingress (default "a0851637f824f2ae51fe10182c49c3c3fa32ed87")
  -p, --profile string                   Use specific profile (default "default")
```

## tctl experimental app-ingress kubernetes install

Applies a manifest, installing or reconfiguring App Ingress on a cluster.

**Synopsis**

The install command generates an App Ingress installation manifest and applies it to a cluster.

```
tctl experimental app-ingress kubernetes install [flags]
```

**Examples**

```
  # Install a default App Ingress in namespace foo:
  tctl x app-ingress kubernetes install -n foo

```

**Options**

```
      --dry-run                      Console/log output only, make no changes.
  -h, --help                         help for install
      --readiness-timeout duration   Maximum time to wait for Istio resources in each component to be ready. (default 5m0s)
  -y, --skip-confirmation            The skipConfirmation determines whether the user is prompted for confirmation.
                                     If set to true, the user is not prompted and a Yes response is assumed in all cases.
      --verify                       Verify the Istio control plane after installation/in-place upgrade.
```

**Options inherited from parent commands**

```
  -c, --config string                    Path to the config file to use. Can also be
                                         specified via TCTL_CONFIG env variable. This flag
                                         takes precedence over the env variable.
      --debug                            Print debug messages for all requests and responses
      --disable-tctl-version-warn        If set, disable the outdated tctl version warning. Can also be
                                         specified via TCTL_DISABLE_VERSION_WARN env variable.
  -f, --filename string                  Path to file containing IstioOperator custom resource to further customize the istio components in App Ingress
      --istio-hub string                 The hub for the Istio images in App Ingress (default "docker.io/istio")
      --istio-tag string                 The tag for the Istio images in App Ingress (default "1.17.2")
  -n, --namespace string                 The namespace to deploy the App Ingress deployments and services
  -b, --openapi-backend-service string   Name of the backend service implementing the OpenAPI specification
      --openapi-config-map string        Name of the configmap containing the OpenAPI specification (default "openapi-translator")
  -o, --openapi-translator               Enable the OpenAPI translator which generates Istio configs from an OpenAPI specfication and applies them
      --openapi-translator-hub string    The hub for the OpenAPI Translator images in App Ingress (default "docker.io/tetrate")
      --openapi-translator-tag string    The tag for the OpenAPI Translator images in App Ingress (default "a0851637f824f2ae51fe10182c49c3c3fa32ed87")
  -p, --profile string                   Use specific profile (default "default")
```

## tctl experimental audit

Get the audit logs for a given resource, showing the most recent events first

```
tctl experimental audit <apiVersion/kind | kind | shortform> <name> [flags]
```

**Examples**

```
# Get the audit logs for a tenant using the apiVersion/Kind pattern
tctl experimental audit api.tsb.tetrate.io/v2/Tenant

# Get audit logs for a workspace and all its child resources
tctl experimental audit ws my-workspace --recursive

# Get audit logs for a workspace since a given date
tctl experimental audit ws my-workspace --since "2021/10/21 15:54:44" --user "admin"

# Get audit logs related to security groups in the given workspcae
tctl experimental audit ws my-workspace --recursive --kind "security.tsb.tetrate.io/v2/Group"
tctl experimental audit ws my-workspace --recursive --kind "Group"

# Get the audit logs for a gateway group
tctl experimental audit --workspace my-workspace GatewayGroup my-group

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
  -o, --output-type string          Response output type: table, yaml, json (default "table")
      --max-logs int32              Maximum number of entries to retrieve
      --text string                 Filter events that contain the given text
      --kind apiVersion/kind        Only return entries of this kind. It can be apiVersion/kind or just `kind`
      --severity string             Filter events by severity
      --operation string            Filter events by operation
      --user string                 Filter events generated by the given user
      --since string                Filter events since the given time. Must be in the format: "2006/01/02 15:04:05"
      --recursive                   Get audit logs for child resources as well
  -h, --help                        help for audit
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

## tctl experimental cluster-install-template

Get the install template of a given cluster in yaml format

```
tctl experimental cluster-install-template <name> [flags]
```

**Examples**

```
# Get the install template of the cluster named my-cluster
tctl experimental cluster-install-template my-cluster

```

**Options**

```
  -h, --help         help for cluster-install-template
      --org string   Organization the object belongs to
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

## tctl experimental debug

Commands to interact with the debug endpoint in TSB components

**Options**

```
  -t, --context string      The name of the kubeconfig context to use
  -h, --help                help for debug
  -k, --kubeconfig string   Kubernetes configuration file
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

## tctl experimental debug dashboard

Opens the debug dashboard for a TSB component

```
tctl experimental debug dashboard <component> [flags]
```

**Examples**

```

# Open the debug dashboard for the MPC component
tctl experimental debug dashboard management/mpc

```

**Options**

```
      --admin-server-port int    Port where the admin server is listening in the TSB component (default 5555)
      --browser                  When --browser is supplied as false, the browser will not be opened; the URL of the admin dashboard will just be printed (default true)
  -n, --controlplane string      The namespace where the control plane is deployed (default "istio-system")
  -d, --dataplane string         The namespace where the data plane is deployed (default "istio-gateway")
  -h, --help                     help for dashboard
  -m, --managementplane string   The namespace where the management plane is deployed (default "tsb")
```

**Options inherited from parent commands**

```
  -c, --config string               Path to the config file to use. Can also be
                                    specified via TCTL_CONFIG env variable. This flag
                                    takes precedence over the env variable.
  -t, --context string              The name of the kubeconfig context to use
      --debug                       Print debug messages for all requests and responses
      --disable-tctl-version-warn   If set, disable the outdated tctl version warning. Can also be
                                    specified via TCTL_DISABLE_VERSION_WARN env variable.
  -k, --kubeconfig string           Kubernetes configuration file
  -p, --profile string              Use specific profile (default "default")
```

## tctl experimental debug list-components

Lists the TSB components available in the current kubernetes context

```
tctl experimental debug list-components [flags]
```

**Examples**

```

# List all the components and their plane association in the current kubectl context
tctl experimental debug list-components

# List all the components and their plane association in the the cluster for which the
# kubectl configuration is stored in a specific context of a different file
tctl experimental debug list-components --kubeconfig /tmp/some-config.yaml --context clusterA

# List all the components and their plane association in the the cluster for which the
# kubectl configuration is stored the default kubeconfig file, in a context different
# that the active one
tctl experimental debug list-components --context clusterB

# If TSB is installed in non-standard namespaces, you can also provide the namespace names
# to use for each plane:
tctl experimental debug list-components --managementplane my-managementplane-ns
tctl experimental debug list-components --controlplane my-controlplane-ns
tctl experimental debug list-components --dataplane my-dataplane-ns

# You can specify more than one namespace in the same command.
tctl experimental debug list-components \
	--managementplane my-managementplane-ns \
	--controlplane my-controlplane-ns \
	--dataplane my-dataplane-ns

```

**Options**

```
  -n, --controlplane string      The namespace where the control plane is deployed (default "istio-system")
  -d, --dataplane string         The namespace where the data plane is deployed (default "istio-gateway")
  -h, --help                     help for list-components
  -m, --managementplane string   The namespace where the management plane is deployed (default "tsb")
```

**Options inherited from parent commands**

```
  -c, --config string               Path to the config file to use. Can also be
                                    specified via TCTL_CONFIG env variable. This flag
                                    takes precedence over the env variable.
  -t, --context string              The name of the kubeconfig context to use
      --debug                       Print debug messages for all requests and responses
      --disable-tctl-version-warn   If set, disable the outdated tctl version warning. Can also be
                                    specified via TCTL_DISABLE_VERSION_WARN env variable.
  -k, --kubeconfig string           Kubernetes configuration file
  -p, --profile string              Use specific profile (default "default")
```

## tctl experimental debug log-level

Checks or sets the log level for TSB components

```
tctl experimental debug log-level <component> [flags]
```

**Examples**

```

# Check the current log levels for the IAM component
tctl experimental debug log-level managementplane/iamserver
# or
tctl experimental debug log-level management/iamserver
# or
tctl experimental debug log-level mp/iamserver

# Set the log for the IAM component in the management plane to debug
tctl experimental debug log-level management/iamserver --level debug

# Set the logger q from the API server to debug
tctl experimental debug log-level management/apiserver --level q:debug

# Set multiple specific loggers at once
tctl experimental debug log-level management/apiserver --level q:debug,pdp:debug

# Set all loggers to error and then some specific loggers, all at once
tctl experimental debug log-level management/apiserver --level all:error,q:debug,pdp:debug

# Data plane commands work the same for IngressGateway, Tier1Gateway and EgressGateway.

# Check loggers for a given TSB gateway
tctl experimental debug log-level data/bookinfo-gateway

# Set all loggers to trace for a given TSB gateway
tctl experimental debug log-level data/bookinfo-gateway --level trace

# Set the router and http loggers to debug for a given TSB gateway
tctl experimental debug log-level data/bookinfo-gateway --level router:debug,http:debug

```

**Options**

```
      --admin-server-port int     Port where the admin server is listening in the TSB component (default 5555)
  -n, --controlplane string       The namespace where the control plane is deployed (default "istio-system")
  -d, --dataplane string          The namespace where the data plane is deployed (default "istio-gateway")
  -f, --file string               A file containing TSB or Isito resources that will be parsed to infer the workloads that will get the log level adjusted
  -h, --help                      help for log-level
  -l, --level strings             log level to set, might include a logger name.
                                  In the form [logger:]level. If logger is omitted, the specified level
                                  will be set for all loggers of the given component.
                                  
  -m, --managementplane string    The namespace where the management plane is deployed (default "tsb")
  -o, --output-directory string   If wait is provided, the directory where to store the log files. It will be created if it does not exist
  -w, --wait                      Whether or not to wait for logs until Ctrl+C is pressed. Resulting logs will be written to separate files per pod.
  -y, --yes                       With yes, the process will not wait for user confirmation at all
```

**Options inherited from parent commands**

```
  -c, --config string               Path to the config file to use. Can also be
                                    specified via TCTL_CONFIG env variable. This flag
                                    takes precedence over the env variable.
  -t, --context string              The name of the kubeconfig context to use
      --debug                       Print debug messages for all requests and responses
      --disable-tctl-version-warn   If set, disable the outdated tctl version warning. Can also be
                                    specified via TCTL_DISABLE_VERSION_WARN env variable.
  -k, --kubeconfig string           Kubernetes configuration file
  -p, --profile string              Use specific profile (default "default")
```

## tctl experimental es-validate

(experimental) validates Elasticsearch setting in the current Kubernetes context

**Synopsis**

(experimental) the command is using the current Kubernetes context 
		to query TSB ControlPlane CRD in "istio-system" namespace

To run the command - login to the Kubernetes cluster that has TSB Control Plane deployed 
  tctl x es-validate 
 
The command is using the users current Kubernetes context to query TSB Custom Resources
and obtains:
- Elasticsearch credentials that are stored in "elastic-credentials" secret
- Elasticsearch CA certificate that is stored in "es-certs" secret
- TSB Tokens "oap-token", "xcp-edge-central-auth-token" and "otel-token"
- "telemetryStore" and "managementPlane" (only for ControlPlane) sections of TSB Custom Resources
The command analyzes the received data and tries to make an educated call to the Elasticsearch 
- if Data from Elasticsearch is returned then the correct config is displayed for the user to apply

Additional checks that are performed:

- Encoded credentials might have a carriage return - it can cause unpredictable behavior - the package 
  informs the user on any found carriage returns in the Kubernetes secret.
- CA certificate if presented by Elasticsearch gets placed in /tmp directory, and can be easily applied (only if 
trusted)
- curl command with the complete list of parameters is displayed to help with additional testing
- Tokens expiration date is validated and user is informed of any expired tokens
- Checks can be done when TSB ControlPlane is pointing to standalone Elasticsearch or via MP FrontEnvoy

NOTE:if -m `<management plane namespace>` is used than checks can fail for within cluster services as the source of 
the call (shell with tctl) can be outside of the cluster network

```
tctl experimental es-validate [flags]
```

**Examples**

```
# Check Elasticsearch setting of TSB Control Plane located in 'istio-system' namespace
tctl experimental es-validate

#  Check Elasticsearch setting of TSB Control Plane located in 'cpns' namespace
tctl experimental es-validate -n cpns

#  Check Elasticsearch setting of TSB Management plane located in 'tsb' namespace
tctl experimental es-validate -m tsb
```

**Options**

```
  -n, --controlplane string      The namespace in the cluster that the control plane is installed in. (default "istio-system")
  -h, --help                     help for es-validate
  -m, --managementplane string   The namespace in the cluster that the management plane is installed in (MP is checked only when the namespace is present - MP is usually installed in 'tsb' namespace).
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

## tctl experimental gitops

Configures clusters to use GitOps flows

**Options**

```
  -h, --help   help for gitops
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

## tctl experimental gitops grant

Grant permissions to use GitOps features in the given cluster

```
tctl experimental gitops grant [flags]
```

**Examples**

```

# Grant permissions to use GitOps features in the given cluster.
# By default the cluster service account will have permissions to manage configuration in the
# configured organization.
tctl experimental gitops grant <cluster-name>

# Only give GitOps permissions on a specific tenant.
tctl experimental gitops grant <cluster-name> --tenant <tenant-name>

# Only give GitOps permissions on a specific workspace.
tctl experimental gitops grant <cluster-name> --tenant <tenant-name> --workspace <workspace-name>

```

**Options**

```
  -h, --help               help for grant
  -t, --tenant string      The name of the tenant to enable GitOps for.
  -w, --workspace string   The name of the workspace to enable GitOps for.
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

## tctl experimental service-account

Commands to manage TSB service accounts

**Options**

```
  -h, --help   help for service-account
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

## tctl experimental service-account create

Creates a new service account

**Synopsis**

Creates a new service account

This command creates a new service account with a new key pair and prints the
generated private key to the standard output.

The private key should be stored securely, as it cannot be retrieved again and
it is required if you want to generate authentication tokens for the service account.

```
tctl experimental service-account create <name> [flags]
```

**Options**

```
  -h, --help   help for create
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

## tctl experimental service-account delete

Deletes a service account

**Synopsis**

Deletes a service account and all its keys

```
tctl experimental service-account delete <name> [flags]
```

**Options**

```
  -h, --help   help for delete
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

## tctl experimental service-account gen-key

Generate a new key pair for the given service account

**Synopsis**

Generate a new key pair for the given service account

This command generates a new key pair for the service account and prints the
generated private key to the standard output.

The key private key should be stored securely, as it cannot be retrieved again and
it is required if you want to generate authentication tokens for the service account.

```
tctl experimental service-account gen-key <name> [flags]
```

**Options**

```
  -h, --help   help for gen-key
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

## tctl experimental service-account get

Get one or multiple service accounts

```
tctl experimental service-account get [<name>] [flags]
```

**Options**

```
  -h, --help                 help for get
  -o, --output-type string   Response output type: table, yaml, json (default "table")
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

## tctl experimental service-account revoke-key

Revoke a given key pair for the given service account

```
tctl experimental service-account revoke-key <name> --id <key id> [flags]
```

**Options**

```
  -h, --help        help for revoke-key
      --id string   ID of the key to revoke
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

## tctl experimental service-account token

Generate a new token that can be used to authenticate to TSB

**Synopsis**

Generate a new token that can be used to authenticate to TSB

This command generates a new token to authenticate to TSB as the service account.
The command reads the private key from the specified file and uses it to sign the token.
You can generate a new private key using the gen-key command.

```
tctl experimental service-account token <name> --key-path <key file> [--expiration <expiration>] [flags]
```

**Options**

```
      --expiration duration   Expiration for the token (default 30m0s)
  -h, --help                  help for token
      --key-path string       Path to the file that contains the private key to use to generate the token
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

## tctl experimental sidecar-bootstrap

(experimental) Bootstrap Istio Sidecar for a workload that runs on VM or Baremetal (mesh expansion scenarios)

**Synopsis**

(experimental) Takes in one or more WorkloadEntry(s), generates identity(s) for them,
and optionally copies generated files to the remote node(s) over SSH protocol and starts Istio Sidecar(s) there.

Alternatively, if SSH is not enabled on the remote node(s), generated files can be saved locally instead.
In that case you will be able to transfer files to the remote node(s) using a mechanism that suits best your particular environment.

If you choose to copy generated files to the remote node(s) over SSH, you will be required to provide SSH credentials,
i.e. either SSH Key or SSH Password.
If you want to use an SSH Password or a passphrase-protected SSH Key, you must run this command on an interactive terminal to type the password in.
We do not accept passwords through command line options to avoid leaking secrets into shell history.

File copying is performed over SCP protocol, and as such SCP binary must be installed on the remote node.
If SCP is installed in a location other than `/usr/bin/scp`, you have to provide absolute path to the SCP binary
by adding `sidecar-bootstrap.istio.io/scp-path` annotation to the respective WorkloadEntry resource.

To start Istio Sidecar on the remote node you must have Docker installed there.
Istio Sidecar will be started on the host network as a docker container in capture mode.

While this command can work without any explicit configuration, it is also possible to fine tune its behavior
by adding various annotations on a WorkloadEntry resource. E.g., consider the following real life example:

  ```yaml
  apiVersion: networking.istio.io/v1beta1
  kind: WorkloadEntry
  metadata:
    annotations:
      sidecar-bootstrap.istio.io/proxy-config-dir: /etc/istio-proxy # Directory on the remote node to copy generated files into
      sidecar-bootstrap.istio.io/ssh-user: istio-proxy              # User to SSH as; must have permissions to run Docker commands
                                                                    # and to write copied files into the target directory
      sidecar.istio.io/statsInclusionRegexps: ".*"                  # Configure Envoy proxy to export all available stats
      proxy.istio.io/config: |
        concurrency: 3                                              # ProxyConfig overrides to apply
    name: my-vm
    namespace: my-namespace
  spec:
    address: 1.2.3.4                                                # At runtime, Istio Sidecar will bind incoming listeners to that address.
                                                                    # At bootstrap time, this command will SSH to that address
    labels:
      app: ratings
      version: v1
      class: vm                                                     # It's very handy to have extra labels on a WorkloadEntry
                                                                    # to be able to narrow down label selectors to VM workloads only
    network: on-premise                                             # If your VM doesn't have L3 connectivity to k8s Pods,
                                                                    # make sure to fill in network field
    serviceAccount: ratings-sa
  ```

For a complete list of supported annotations run `tctl x sidecar-bootstrap --docs`.

```
tctl experimental sidecar-bootstrap [<workload-entry-name>[.<namespace>]] [flags]
```

**Examples**

```
  # Show under-the-hood actions to copy workload identity of a VM represented by a given WorkloadEntry:
  tctl x sidecar-bootstrap my-vm.my-namespace --dry-run

  # Show under-the-hood actions to copy workload identity and start Istio Sidecar on a VM represented by a given WorkloadEntry:
  tctl x sidecar-bootstrap my-vm.my-namespace --start-istio-proxy --dry-run

  # Copy workload identity into a VM represented by a given WorkloadEntry:
  tctl x sidecar-bootstrap my-vm.my-namespace

  # Copy workload identity and start Istio Sidecar on a VM represented by a given WorkloadEntry:
  tctl x sidecar-bootstrap my-vm.my-namespace --start-istio-proxy

  # Generate workload identity for a VM represented by a given WorkloadEntry and save generated files into an archive file (*.tgz) at a given path
  tctl x sidecar-bootstrap my-vm.my-namespace --output-file path/to/output/file.tgz

  # Generate workload identity for a VM represented by a given WorkloadEntry and save generated files into a directory
  tctl x sidecar-bootstrap my-vm.my-namespace --output-dir path/to/output/dir

  # Print a list of supported annotations on the WorkloadEntry resource:
  tctl x sidecar-bootstrap --docs
```

**Options**

```
  -a, --all                            bootstrap all WorkloadEntry(s) in a given namespace
  -o, --archive                        (experimental) save generated files into a local archive file (*.tgz) instead of copying them to a remote machine (file name will be picked automatically)
      --context string                 The name of the kubeconfig context to use
      --docs                           (experimental) print a list of supported annotations on the WorkloadEntry resource
      --dry-run                        print generated configuration and respective SSH commands but don't connect to, copy files or execute commands remotely
      --duration duration              (experimental) amount of time that generated ServiceAccount tokens should be valid for (default 24h0m0s)
  -h, --help                           help for sidecar-bootstrap
      --ignore-host-keys               (experimental) do not verify remote host key when establishing SSH connection
  -i, --istioNamespace string          Istio system namespace (default "istio-system")
      --kubeconfig string              Kubernetes configuration file
  -n, --namespace string               Config namespace
  -d, --output-dir string              save generated files into a local directory instead of copying them to a remote machine
      --output-file string             (experimental) save generated files into a local archive file (*.tgz) instead of copying them to a remote machine (file name is picked by the user)
      --ssh-connect-timeout duration   (experimental) timeout on establishing SSH connection (default 10s)
  -k, --ssh-key string                 (experimental) authenticate with SSH key at a given location
      --ssh-password                   (experimental) force SSH password-based authentication
      --ssh-port int                   (experimental) default port to SSH to (is only effective unless the 'sidecar-bootstrap.istio.io/ssh-port' annotation is present on a WorkloadEntry) (default 22)
  -u, --ssh-user string                (experimental) default user to SSH as, defaults to the current user (is only effective unless the 'sidecar-bootstrap.istio.io/ssh-user' annotation is present on a WorkloadEntry)
      --start-istio-proxy              start Istio Sidecar on a remote host after copying configuration files
      --timeout duration               (experimental) timeout on copying a single file to a remote host (default 1m0s)
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

## tctl experimental status

Get the status of an object

```
tctl experimental status <apiVersion/kind | kind | shortform> <name> [flags]
```

**Examples**

```
# Get the status of a tenant using the apiVersion/Kind pattern
tctl experimental status api.tsb.tetrate.io/v2/Tenant my-tenant

# Get the status of a workspace using the short form
tctl experimental status ws my-workspace

# Get the status of a gateway group
tctl experimental status --workspace my-workspace GatewayGroup my-group

Group kind is available for different APIs, so this helpers are available to easly retrieve them:
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
      --telemetry-source string     Telemetry source the object belongs to
  -o, --output-type string          Response output type: table, yaml, json (default "table")
  -h, --help                        help for status
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

## tctl experimental troubleshoot

Commands for troubleshooting your clusters

**Options**

```
  -h, --help   help for troubleshoot
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

## tctl experimental troubleshoot log-explorer

Explore Envoy access logs from your cluster

**Options**

```
  -h, --help   help for log-explorer
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

## tctl experimental troubleshoot log-explorer cluster

Lists details of a cluster from a `tctl collect` tar file

```
tctl experimental troubleshoot log-explorer cluster [flags]
```

**Examples**

```
tctl experimental log-explorer cluster [tar file]
```

**Options**

```
  -h, --help               help for cluster
  -n, --namespace string   List details of only specified namespace
      --workspace string   List details of only specified workspace
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

## tctl experimental troubleshoot log-explorer request

Analyze an individual request

```
tctl experimental troubleshoot log-explorer request [flags]
```

**Examples**

```
tctl experimental log-explorer request [tar file] [requestID]
```

**Options**

```
  -h, --help                 help for request
  -o, --output-type string   Select the output type, available formats json and yaml, default format is yaml (default "yaml")
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

## tctl experimental troubleshoot log-explorer service

Analyze access logs to a service contained in a `tctl collect` tar file

```
tctl experimental troubleshoot log-explorer service [flags]
```

**Examples**

```
tctl experimental log-explorer service [tar file] [service]
```

**Options**

```
      --all                Show all requests instead of just the longest ones and those with errors.
      --full-log           Print the full Envoy access log instead of a summary.
  -h, --help               help for service
      --limit int          Number of requests to show (defaults to 10). (default 10)
  -n, --namespace string   The namespace containing the service.
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

## tctl experimental verify

Verify environment is ready for install or installed successfully

```
tctl experimental verify [flags]
```

**Options**

```
      --failure-threshold Level   The severity level of analysis at which to set a non-zero exit code. Valid values: [   Info Warn Error] (default Warn)
  -h, --help                      help for verify
  -L, --list-verifiers            List the verifiers that will be run based on the execution context and passed flags
      --output-threshold Level    The severity level of analysis at which to display messages. Valid values: [   Info Warn Error] (default Info)
  -s, --suppress stringArray      Names of verifiers to suppress
      --timeout duration          The duration to wait before giving up (default 1m0s)
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

## tctl experimental wait

Wait until a resource reaches the desired status

```
tctl experimental wait <apiVersion/kind | kind | shortform> <name> [flags]
```

**Examples**

```
Wait command assumes the default desired status is READY for any resource.
Also, --status and --event optional parameters can be provided to specificy another status to wait for.
Keep in mind that the desired status could never be reached if something fails, it would reach
a failed status instead. In this case, the wait command would finish even though the resource didn't reach the desired status.

# Wait for a tenant using the apiVersion/Kind pattern
tctl experimental wait api.tsb.tetrate.io/v2/Tenant
		
# Wait for a workspace to be ready using the short form
tctl experimental wait ws my-workspace --status READY

# Wait for a workspace to be ready in no more than 1 minute
tctl experimental wait workspace my-workspace --status READY --timeout 1m
		
# Wait for a a gateway group to be accepted by XCP
tctl experimental wait --workspace my-workspace GatewayGroup my-group --status ACCEPTED --event XCP_ACCEPTED

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
  -o, --output-type string          Response output type: table, yaml, json (default "table")
      --status string               The status to wait for. One of [ACCEPTED READY FAILED DIRTY PARTIAL] (default "READY")
      --event string                The type of the last event to wait for. One of [TSB_ACCEPTED MPC_ACCEPTED XCP_ACCEPTED XCP_REJECTED MPC_FAILED XCP_UNKNOWN XCP_PARTIALLY_APPLIED XCP_APPLIED XCP_ERRORED XCP_IGNORED MPC_DIRTY]
      --timeout duration            The timeout to fail the command if the condition is not reached (default 2m0s)
  -h, --help                        help for wait
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

