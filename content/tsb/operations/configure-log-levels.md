---
title: Configure Log Levels
description: Configure Log Levels for TSB components
weight: 7
---

This document describes how to adjust log levels for the different components in TSB, including platform components, Envoy sidecars and ingress gateways at runtime, as well as the procedure to view the logs.

Before you get started make sure:

- You have installed and configured TSB properly.
- You have installed and configured `kubectl` to access the application cluster.

For the example commands we assume that you have some applications deployed in a `helloworld` namespace.

:::warning TSB Components Produce Lots of Logs
Be careful enabling debug logging across all of TSB's scopes for extended periods of time - TSB components produces a lot of logs! You may be faced with large log ingestion bills due to automatic log ingestion combined with turning up log levels across TSB or Sidecars.
:::

## List the available components

In order to change each components' log level you will need to know which components are available. For that, there is utility command in `tctl` that will leverage the current `kubectl` connection information
(context) and list the available components in that cluster.

```bash
$ tctl experimental debug list-components 
PLANE         COMPONENT                 DEPLOYMENTS                           
management    ldap                      ldap                                     
management    mpc                       mpc                                      
management    xcp                       central, xcp-operator-central            
management    frontenvoy                envoy                                    
management    iamserver                 iam                                      
management    apiserver                 tsb                                      
management    tsb-operator              tsb-operator-management-plane            
management    web-ui                    web                                      
management    zipkin                    zipkin                                   
management    oap                       oap                                      
management    collector                 otel-collector                           
management    postgres                  postgres                                 
control       istio                     istio-operator                           
control       hpaadapter                istio-system-custom-metrics-apiserver    
control       oap                       oap-deployment                           
control       onboarding                onboarding-operator                      
control       collector                 otel-collector                           
control       tsb-operator              tsb-operator-control-plane               
control       zipkin                    zipkin                                   
control       xcp                       edge, xcp-operator-edge                  
data          operator                  istio-operator                           
data          tsb-operator              tsb-operator-data-plane                  
data          bookinfo-gateway          bookinfo/bookinfo-gateway                
data          helloworld-tls-gateway    helloworld-tls/helloworld-tls-gateway    
data          helloworld-gateway        helloworld/helloworld-gateway            
data          httpbin-gateway           httpbin/httpbin-gateway                  
data          tier1                     tier1/tier1
```

As seen in the output above, this command will list all available components in the cluster and sort them by plane (management, control or data plane). It will also show the Kubernetes deployments that build up every
component. The `PLANE` and `COMPONENT` columns in the output is what will need to be used with the command to set the log level below. For instance, to change the `mpc` component log level, you will need to refer to it
with `management/mpc`.

## TSB platform components (management and control planes)

TSB components are able to adjust the log levels for the different existing loggers at runtime without restarting the pod. For that, a new command in `tctl` CLI has been added.

In order to check the available loggers for a component and check the current levels, run the command without any flag.

```bash
tctl experimental debug log-level management/iamserver
Configuring the logging levels:
    POST /logging?level=value	  -> Configures all levels globally
    POST /logging?logger=value	  -> Configures the logging level for 'logger'

Current logging levels:

admin                info    Administration server logs
auth                 info    Authentication messages server
config               info    Messages from the config system
credentials/basic    info    Credentials parsing provider for basic http
credentials/jwt      info    Credentials parsing provider for JWT bearer
default              info    Unscoped logging messages.
dynadsn              info    Messages from dynamic db conn pool
envoy-filter         info    Envoy filter messages
exchange             info    Messages from token exchange
grpc                 info    Messages from the gRPC layer
health               info    Messages from health check service
iam-server           info    Messages from the RunGroup handler
iam/http             info    Messages from http-server
jwt                  info    Messages from the LDAP provider
keyvalue/tx          info    Messages from the transaction system
ldap                 info    LDAP integration messages
local                info    Messages from the local authentication provider
migrations           info    Database migration messages
oauth                info    Messages from the Server Extensions
oauth2               info    OAuth2 messages
oidc                 info    Messages from the OIDC provider
root                 info    Messages from the root credentials package
server               info    Messages from service main
```

In the output above, the leftmost column shows the logger name, the middle column shows the current log level configured for that given logger, and the last column shows a brief description of the kind of messages that logger shows.

In order to change the log levels, there are multiple ways to accomplish that, with different combinations of the `level` flag.

### Change a single logger

Changing a single logger is possible by providing a logger name followed by a colon (`:`), followed by the desired level. For example:

```bash
tctl experimental debug log-level management/iamserver --level ldap:debug
Configuring the logging levels:
    POST /logging?level=value	  -> Configures all levels globally
    POST /logging?logger=value	  -> Configures the logging level for 'logger'

Current logging levels:

admin                info     Administration server logs
auth                 info     Authentication messages server
config               info     Messages from the config system
credentials/basic    info     Credentials parsing provider for basic http
credentials/jwt      info     Credentials parsing provider for JWT bearer
default              info     Unscoped logging messages.
dynadsn              info     Messages from dynamic db conn pool
envoy-filter         info     Envoy filter messages
exchange             info     Messages from token exchange
grpc                 info     Messages from the gRPC layer
health               info     Messages from health check service
iam-server           info     Messages from the RunGroup handler
iam/http             info     Messages from http-server
jwt                  info     Messages from the LDAP provider
keyvalue/tx          info     Messages from the transaction system
ldap                 debug    LDAP integration messages
local                info     Messages from the local authentication provider
migrations           info     Database migration messages
oauth                info     Messages from the Server Extensions
oauth2               info     OAuth2 messages
oidc                 info     Messages from the OIDC provider
root                 info     Messages from the root credentials package
server               info     Messages from service main
```

You can see by the output received that the `ldap` logger has changed its level to `debug`, raising its verbosity level.

### Change multiple loggers

Changing multiple loggers at once is possible by providing a comma (`,`) separated list of logger name and level pairs. Items within a pair are separated by a colon (`:`). For example:

```bash
tctl experimental debug log-level management/iamserver --level jwt:error,auth:warn,health:error
Configuring the logging levels:
    POST /logging?level=value	  -> Configures all levels globally
    POST /logging?logger=value	  -> Configures the logging level for 'logger'

Current logging levels:

admin                info     Administration server logs
auth                 warn     Authentication messages server
config               info     Messages from the config system
credentials/basic    info     Credentials parsing provider for basic http
credentials/jwt      info     Credentials parsing provider for JWT bearer
default              info     Unscoped logging messages.
dynadsn              info     Messages from dynamic db conn pool
envoy-filter         info     Envoy filter messages
exchange             info     Messages from token exchange
grpc                 info     Messages from the gRPC layer
health               error    Messages from health check service
iam-server           info     Messages from the RunGroup handler
iam/http             info     Messages from http-server
jwt                  error    Messages from the LDAP provider
keyvalue/tx          info     Messages from the transaction system
ldap                 debug    LDAP integration messages
local                info     Messages from the local authentication provider
migrations           info     Database migration messages
oauth                info     Messages from the Server Extensions
oauth2               info     OAuth2 messages
oidc                 info     Messages from the OIDC provider
root                 info     Messages from the root credentials package
server               info     Messages from service main
```

You can see how only the selected loggers have changed to the specified levels.

### Change all loggers at once

You can also change all loggers at once to a given level by just providing the level name, for instance:

```bash
tctl experimental debug log-level management/iamserver --level info
Configuring the logging levels:
    POST /logging?level=value	  -> Configures all levels globally
    POST /logging?logger=value	  -> Configures the logging level for 'logger'

Current logging levels:

admin                info    Administration server logs
auth                 info    Authentication messages server
config               info    Messages from the config system
credentials/basic    info    Credentials parsing provider for basic http
credentials/jwt      info    Credentials parsing provider for JWT bearer
default              info    Unscoped logging messages.
dynadsn              info    Messages from dynamic db conn pool
envoy-filter         info    Envoy filter messages
exchange             info    Messages from token exchange
grpc                 info    Messages from the gRPC layer
health               info    Messages from health check service
iam-server           info    Messages from the RunGroup handler
iam/http             info    Messages from http-server
jwt                  info    Messages from the LDAP provider
keyvalue/tx          info    Messages from the transaction system
ldap                 info    LDAP integration messages
local                info    Messages from the local authentication provider
migrations           info    Database migration messages
oauth                info    Messages from the Server Extensions
oauth2               info    OAuth2 messages
oidc                 info    Messages from the OIDC provider
root                 info    Messages from the root credentials package
server               info    Messages from service main
```

All of the loggers have been changed to the `info` level with a single command.

### Change loggers using the operator

All the management and control planes components can be also configured by using the MP/CP CRs. For example, to modify the `xcp-operator-edge`, you can modify the CP CR to use the following configuration:

```yaml
spec:
  components:
    xcp:
      kubeSpec:
        overlays:
        - apiVersion: apps/v1
        kind: Deployment
        name: xcp-operator-edge
        patches:
        - path: spec.template.spec.containers.[name:xcp-operator].args[-1]
          value: --log_output_level
        - path: spec.template.spec.containers.[name:xcp-operator].args[-1]
          value: all:error
```

Bear in mind that there are components which are deployed by another operator, like `edge` in the control plane. In order to modify these components, you will need to do an overlay of the operator like the following:

```yaml
spec:
  components:
    xcp:
      kubeSpec:
        overlays:
        - apiVersion: apps/v1
          kind: Deployment
          name: xcp-operator-edge
          patches:
          - path: spec.template.spec.containers.[name:xcp-operator].args[-1]
            value: --log_output_level
          - path: spec.template.spec.containers.[name:xcp-operator].args[-1]
            value: all:error
        # Add the overlay for edge
        - apiVersion: install.xcp.tetrate.io/v1alpha1
          kind: EdgeXcp
          name: edge-xcp
          patches:
          - path: spec.components.edgeServer.kubeSpec.overlays
            value:
            - apiVersion: v1
              kind: Deployment
              name: edge
              patches:
              - path: spec.template.spec.containers.[name:edge].args[all:info]
                value: all:error
```

The same happens if you want to modify `istiod` or all the gateways from the istio operator, you will need to do an overlay from the `istio-operator` which is the component that deploys `istiod`:

```yaml
spec:
  components:
    istio:
      kubeSpec:
        overlays:
        - apiVersion: install.istio.io/v1alpha1
          kind: IstioOperator
          name: tsb-istiocontrolplane
          patches:
          - path: spec.values.global.proxy.logLevel
            value: warn
          - path: spec.values.global.logging.level
            value: default:warn
```

Above examples will work for all the components deployed by the management or control plane operators, but if you want to modify the loggers for the operators itself, you will need to manually edit the operator deployment. For example, let's change the loggers for the control plane operator deployment:

```bash
kubectl edit deployment tsb-operator-control-plane -n istio-system
```
```yaml
spec:
  template:
    spec:
      containers:
      - args:
        - control-plane
        - --deployment-name
        - tsb-operator-control-plane
        # Add below the changes
        - --log-output-level
        - default:info,tsboperator/kubernetes:error
```

### Configure loggers using Install APIs

Most of the components are provided with knobs to choose the log level for a particular component. This can be done using Install APIs CRs like MP or CP. Following are the examples:
For example in CP CR:

```bash
kubectl edit deployment tsb-operator-control-plane -n istio-system
```

```yaml
spec:
  components:
    xcp:
      logLevels:
        all: error
    oap:
      logLevel: debug
    istio:
      logLevels:
        all: trace
```

Moreover default log level can also be set for all the components. Since there could be different log levels for different components, the default log level will only be rendered for components that uses the particular log level.
For example in CP CR:

```yaml
spec:
  defaultLogLevel: info
```

Similarly, this could be done for MP as well.

Take a look at different components and log levels supported by the components in the MP and CP CRs:

[Control Plane Install API Reference Docs](../refs/install/controlplane/v1alpha1/spec).<br/>
[ManagementPlane Plane Install API Reference Docs](../refs/install/managementplane/v1alpha1/spec).

## Configure log levels for ingress gateways

In order to change the gateways log levels, the same procedure described above can be used. Note that the `list-components` command output also includes the gateways deployed in the current cluster under the `data` plane.

```bash
$ tctl experimental debug list-components  | egrep ^data
data          tsb-operator              tsb-operator-data-plane                  
data          operator                  istio-operator                           
data          bookinfo-gateway          bookinfo/bookinfo-gateway                
data          helloworld-tls-gateway    helloworld-tls/helloworld-tls-gateway    
data          helloworld-gateway        helloworld/helloworld-gateway            
data          httpbin-gateway           httpbin/httpbin-gateway                  
data          tier1                     tier1/tier1
```

The procedure to change the log level for a gateway will be the same as for the rest of the components. For instance, to verify the `bookinfo-gateway` log levels, the following command can be run:

```bash
$ tctl experimental debug log-level data/bookinfo-gateway
active loggers:
  admin: trace
  aws: trace
  assert: trace
  backtrace: trace
  cache_filter: trace
  client: trace
  config: trace
  connection: trace
  conn_handler: trace
  decompression: trace
  dubbo: trace
  envoy_bug: trace
  ext_authz: trace
  rocketmq: trace
  file: trace
  filter: trace
  forward_proxy: trace
  grpc: trace
  hc: trace
  health_checker: trace
  http: trace
  http2: trace
  hystrix: trace
  init: trace
  io: trace
  jwt: trace
  kafka: trace
  lua: trace
  main: trace
  matcher: trace
  misc: trace
  mongo: trace
  quic: trace
  quic_stream: trace
  pool: trace
  rbac: trace
  redis: trace
  router: trace
  runtime: trace
  stats: trace
  secret: trace
  tap: trace
  testing: trace
  thrift: trace
  tracing: trace
  upstream: trace
  udp: trace
  wasm: trace
```

And the log levels can be adjusted using the same procedure, for instance to turn all logger to `info` level, the following command can be used:

```bash
$ tctl experimental debug log-level data/bookinfo-gateway --level info
active loggers:
  admin: info
  aws: info
  assert: info
  backtrace: info
  cache_filter: info
  client: info
  config: info
  connection: info
  conn_handler: info
  decompression: info
  dubbo: info
  envoy_bug: info
  ext_authz: info
  rocketmq: info
  file: info
  filter: info
  forward_proxy: info
  grpc: info
  hc: info
  health_checker: info
  http: info
  http2: info
  hystrix: info
  init: info
  io: info
  jwt: info
  kafka: info
  lua: info
  main: info
  matcher: info
  misc: info
  mongo: info
  quic: info
  quic_stream: info
  pool: info
  rbac: info
  redis: info
  router: info
  runtime: info
  stats: info
  secret: info
  tap: info
  testing: info
  thrift: info
  tracing: info
  upstream: info
  udp: info
  wasm: info
```

This will adjust the log levels to all replica pods of the gateway deployment.

## Using `istioctl` to configure log levels of the data plane

Services that have been deployed in the service mesh can have their logging controlled dynamically. There are a few ways to change these levels, but the easiest is using the [`istioctl proxy-config log`](https://istio.io/latest/docs/reference/commands/istioctl/#istioctl-proxy-config-log) command.

```bash
istioctl proxy-config log <pod-name[.namespace]> --level <arguments>
```

The `arguments` can be in either of the following forms: `level=<name>` or `<logger>=<name>`.

When using the `level=<name>` form, all applicable components are set to the log level specified by `name`. When using the `<logger>=<name>` form, the log level on the particular logger specified by the `logger` is changed. Finally, you can list many loggers in a single command, like `<logger1>=<name1>,<logger2>=<name2>,<logger3>=<name3>`.

The following names are allowed: `none`, `default`, `debug`, `info`, `warn`, or `error`

For details on the different log levels and loggers available, please refer to the documentation of [`istioctl proxy-config log`](https://istio.io/latest/docs/reference/commands/istioctl/#istioctl-proxy-config-log)

:::note You can view log levels directly with kubectl too!

Services that have been deployed in the service mesh will contain the `pilot-agent` command in the sidecar container. It's primary responsibility is to bootstrap the Envoy proxy, but it can also be used to configure logging levels at runtime among other things.

The `pilot-agent` command may be invoked to update the logging level through `kubectl` in the following way:

```bash
kubectl exec <pod-name> -c istio-proxy -- \
  pilot-agent request POST 'logging?<arguments>'
```

`pod-name` refers to the target Kubernetes pod. Notice we are using `-c istio-proxy` option to explicitly specify that we are executing the `pilot-agent` command in the sidecar of the service that is deployed in `pod-name`
:::

## Configure log levels for application sidecars

### Verify the deployed application pods

Verify that `istio-proxy` sidecars are properly deployed:

```bash
kubectl get pods -n helloworld -o jsonpath="{.items[*].spec.containers[*].name}" | \
  tr -s '[[:space:]]' '\n' | \
  sort | \
  uniq -c | \
  grep istio-proxy
```

This should print a text resembling the following output:

```
  2 istio-proxy
```

### Adjust the log level

For this example we assume that the following applications have already been deployed and onboarded into TSB:

```
NAME                             READY   STATUS    RESTARTS   AGE
helloworld-v1-776f57d5f6-2h8dq   2/2     Running   0          5h49m
helloworld-v2-54df5f84b-v2wv6    2/2     Running   0          5h49m
```

```bash
istioctl proxy-config log helloworld-v1-776f57d5f6-2h8d --level debug
```

:::warning
It is recommended that you do NOT turn on `debug` log level for production workloads or workloads for high volume traffic systems. They may print excessive information that could overwhelm your application(s), or at the very least cost you a lot of money in log ingestion fees!
:::

Once the above command takes effect, you will be able to view the debug logs from the sidecars using `kubectl`:

```bash
kubectl logs -f helloworld-v1-776f57d5f6-2h8dq -c istio-proxy
```

If you would like to apply the same change to the log level to other sidecars on your application, you will have to repeat the process for each pod that you are interested in.

:::note Changing Log Levels with Kubectl
The `istio-proxy` sidecar in the application pod contains the `pilot-agent` command.

Run the following command via `kubectl` on the sidecar to configure the log level:
```bash
kubectl -n helloworld exec helloworld-v1-776f57d5f6-2h8dq -c istio-proxy -- \
  pilot-agent request POST 'logging?level=debug'
```
:::

### Resetting the log levels

Once you are done inspecting the logs, always make sure to adjust the log level back again. This will also have to be done for each of the sidecars whose log levels you have adjusted.

`istioctl` has a shortcut for this:

```bash
istioctl proxy-config log helloworld-v1-776f57d5f6-2h8dq --reset
```

:::note Reset shortcut not available for `kubectl`
Unfortunately there's not a shortcut for resetting the log levels via `kubectl`. You need to `kubectl exec` a command that restores all of the logs you changed using a list of log scopes and levels, like:
```bash
kubectl -n helloworld exec helloworld-v1-776f57d5f6-2h8dq -c istio-proxy -- \
  pilot-agent request POST 'logging?h2=debug,http=info,grpc=error'
```
:::

## Using configuration to change log levels

The `tctl` command line utility includes another way to configure the log levels, which is using a file containing the actual configuration objects used to configure traffic flows. For instance, for
a given `IngressGateway`:

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
  name: ingress-bookinfo
  group: g1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  workloadSelector:
    namespace: ns1
    labels:
      app: gateway
  http:
  - name: bookinfo
    port: 9443
    hostname: bookinfo.com
    tls:
      mode: SIMPLE
      secretName: bookinfo-certs
    routing:
      rules:
      - route:
          host: ns1/productpage.ns1.svc.cluster.local
```

The `tctl` command would adjust log levels for the pods matching the `workloadSelector`, plus those pods that service the destination service `productpage.ns1.svc.cluster.local`. This also works when using
direct mode inspecting the equivalent objects (`Gateway`, `VirtualService`, etc.). This is useful to troubleshoot data path for ingress or east/west traffic, where you can leverage the `tctl get all` command output
to configure the appropriate pods that are in the data path for a request to a given hostname.

```bash
tctl get all --fqdn bookinfo.com > /tmp/bookinfo-config.yaml
tctl experimental debug log-levels -f /tmp/bookinfo-config.yaml --level=trace
```

The above commands for instance, would query TSB and get all the config objects that refer the hostname `bookinfo.com`, saving them to the file `/tmp/bookinfo-config.yaml`. The second command would then
configure the log level to `trace` for all pods in the data path for the `bookinfo.com` host name. Once troubleshooting has finished, you can revert back the log level to more reasonable values.

```bash
tctl experimental debug log-levels -f /tmp/bookinfo-config.yaml --level=info
```

:::note Multi-cluster
The commands to adjust log levels use the currently configured `kubectl` config file and context, while your configuration might expand multiple clusters. For instance, you could have in the same file the Tier1 and
Tier2 configuration. `tctl` will display which pods matched and ask for confirmation before proceeding. If you need to use multiple clusters, you will need to run the command once while targeting each cluster with
`kubectl`.
:::
