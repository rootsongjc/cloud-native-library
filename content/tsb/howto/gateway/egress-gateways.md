---
title: Controlling Access to External Services
description: Using Egress Gateways to Configure Access to External Services
weight: 7
---

Egress Gateways act as a gateway for traffic *exiting* the mesh. Users are able to define services that are allowed to send traffic to external services through the gateway

Currently only HTTPS can be sent externally. However, the original outbound requests should use HTTP. These outbound HTTP requests are converted to HTTPS requests and sent to the external services. For example, a request to `http://tetrate.io` from the service that goes through an Egress Gateway is converted to a request to `https://tetrate.io`, and is proxied on behalf of the originating service. Currently requests that are ultimately need to be HTTP are not supported. For example, you will not be able to use Egress Gateways if your final destination is `http://tetrate.io`

This document will describe how to configure Egress Gateways to allow services to only send outbound requests to specific services.  The following diagram shows the request and response flow when using an Egress Gateway:

[![](../../assets/howto/egress-gateway-flow.png)](../../assets/howto/egress-gateway-flow.png)

Before you get started, make sure you:<br />
✓ Familiarize yourself with [TSB concepts](../../concepts/toc) <br />
✓ Install the TSB environment. You can use [TSB demo](../../setup/self_managed/demo-installation) for quick install<br />
✓ Completed [TSB usage quickstart](../../quickstart). This document assumes you already created Tenant and are familiar with Workspace and Config Groups. Also you need to configure tctl to your TSB environment.

Please note that in the following example you will deploy Egress Gateway in the demo cluster that you have created using the TSB demo install. If you are using another cluster, change the cluster name in the example accordingly.

## Deploy Sleep Services

In this example you will use two `sleep` services, each living in separate namespaces.

Create the namespaces `sleep-one` and `sleep-two`:

```bash
kubectl create namespace sleep-one
kubectl create namespace sleep-two
```

Then follow the instructions in the ["Installing `sleep` Workload in TSB"](../../reference/samples/sleep_service#create-a-sleep-workspace) document to install sleep service two sleep services in the `demo` cluster. Install the service `sleep-one` in namespace `sleep-one`, and the service `sleep-two` in namespace `sleep-two`, respectively

You do **NOT** need to create a Workspace, as you will do this later in this example.

## Create Workspace and Traffic Group for Sleep Services

You will need a Traffic Group to associate with the Egress Gateway that you will be creating later. Since a Traffic Group belongs to a Workspace, you will need to create a Workspace as well.

Create a file name `sleep-workspace.yaml` with the following contents. Replace the values for `cluster`, `organization`, and `tenant` accordingly. For demo installations, you can use the value `demo` for the `cluster`, and `tetrate` for both `organization` and `tenant`.

```yaml
apiversion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: <organization>
  tenant: <tenant>
  name: sleep
spec:
  displayName: Sleep Workspace
  namespaceSelector:
    names:
      - "<cluster>/sleep-one"
      - "<clluser>/sleep-two"
---
apiVersion: traffic.tsb.tetrate.io/v2
kind: Group
metadata:
  organization: <organization>
  tenant: <tenant>
  workspace: sleep
  name: sleep-tg
spec:
  displayName: Sleep Traffic
  namespaceSelector:
    names:
      - "<cluster>/sleep-one"
      - "<cluster>/sleep-two"
  configMode: BRIDGED
```

Apply with `tctl`:

```bash
tctl -f sleep-workspace.yaml
```

## Deploy Egress Gateway

### Create the Egress Gateway Namespace

Egress gateways are typically managed by a separate team than the one developing the app (in this case, the `sleep` services) to avoid the ownerships being mixed up.

In this example we create a separate namespace `egress` to manage the Egress Gateway. Execute the following command to create a new namespace:

```bash
kubectl create namespace egress
```

### Deploy the Egress Gateway

Create a file called `egress-deploy.yaml` with the following contents:

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: EgressGateway
metadata:
  name: cluster-egress
  namespace: egress
spec:
  kubeSpec:
    service:
      type: NodePort  
```

Apply with kubectl:

```bash
kubectl apply -f egress-deploy.yaml
```

### Create a Workspace and a Gateway Group for Egress Gateway

You will also need to create a Workspace and a Gateway Group for the Egress Gateway that you just created.

Create a file named `egress-workspace.yaml` with the following contents. Replace the values for `cluster`, `organization`, and `tenant` accordingly. For demo installations, you can use the value `demo` for the `cluster`, and `tetrate` for both `organization` and `tenant`.

```yaml
apiversion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: <organization>
  tenant: <tenant>
  name: egress
spec:
  displayName: Egress Workspace
  namespaceSelector:
    names:
      - "<cluster>/egress"
---
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
  organization: <organization>
  tenant: <tenant>
  workspace: egress
  name: egress-gw
spec:
  displayName: Egress Gateway
  namespaceSelector:
    names:
      - "<cluster>/egress"
  configMode: BRIDGED
```

Apply with tctl

```bash
tctl apply -f egress-workspace.yaml
```

## Configure Egress Gateway

In this example, you will be applying different configurations to the two `sleep` services.

`sleep-one` will be configured so that it can access all external URLs, but `sleep-two` will only be allowed to access a single destination (in this sample, "edition.cnn.com").

Create a file named `egress-config.yaml` with the following contents. Replace the values for `organization` and `tenant` accordingly. For demo installations, you can use the value `tetrate` for both `organization` and `tenant`.

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: EgressGateway
metadata:
  organization: <organization>
  tenant: <tenant>
  workspace: egress
  group: egress-gw
  name: cluster-egress 
spec:
  workloadSelector:
    namespace: egress 
    labels:
      app: cluster-egress
  authorization:
    - from:
        mode: CUSTOM
        serviceAccounts: ["sleep-one/sleep"]
      to: ["*"]
    - from:
        mode: CUSTOM
        serviceAccounts: ["sleep-two/sleep"]
      to: ["edition.cnn.com"]
```

Apply with tctl

```bash
tctl apply -f egress-config.yaml
```

## Create TrafficSettings to use Egress Gateway

Finally, create traffic settings to tie the Traffic Group that the services are associated to with the Egress Gateway.

Create a file named `sleep-traffic-setting-egress.yaml` with the following contents. Replace the values for `organization` and `tenant` accordingly. For demo installations, you can use the value `tetrate` for both `organization` and `tenant`.

The `host` value is in `<namespace>/<fqdn>` format. The `fqdn` value is derived from the `namespace` and `metadata.name` values specified in the previous step:

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: TrafficSetting
metadata:
  organization: <organization>
  tenant: <tenant>
  workspace: sleep
  group: sleep-tg
  name: sleep-traffic-settings
spec:
  egress:
    host: egress/cluster-egress.egress.svc.cluster.local
```

Apply this with tctl:

```bash
tctl apply -f sleep-traffic-setting-egress.yaml
```

## Testing

To test whether Egress Gateway is working correctly, you will be sending requests from the `sleep` services to external services.

For this you will need to figure out the Pod names for `sleep-one` and `sleep-two`. Execute the following commands to lookup the Pod names:

```bash
export SLEEP_ONE_POD=$(kubectl get pod -n sleep-one -l app=sleep -o jsonpath='{.items[*].metadata.name}')
export SLEEP_TWO_POD=$(kubectl get pod -n sleep-two -l app=sleep -o jsonpath='{.items[*].metadata.name}')
```

Execute the following commands against `sleep-one`. Since you have configured the Egress Gateway such that `sleep-one` is allowed to access all external services, the following commands should all display "200":

```bash
kubectl exec ${SLEEP_ONE_POD} -n sleep-one -c sleep -- \
  curl http://twitter.com \
    -s \
    -o /dev/null \
    -L \
    -w "%{http_code}\n"

kubectl exec ${SLEEP_ONE_POD} -n sleep-one -c sleep -- \
  curl http://github.com \
    -s \
    -o /dev/null \
    -L \
    -w "%{http_code}\n"

kubectl exec ${SLEEP_ONE_POD} -n sleep-one -c sleep -- \
  curl http://edition.cnn.com \
    -s \
    -o /dev/null \
    -L \
    -w "%{http_code}\n"

kubectl exec ${SLEEP_ONE_POD} -n sleep-one -c sleep -- \
  curl http://httpbin.org \
    -s \
    -o /dev/null \
    -L \
    -w "%{http_code}\n"
```

Do the same for service `sleep-two` by replacing `SLEEP_ONE_POD` to `SLEEP_TWO_POD`, and `sleep-one` to `sleep-two`, respectively.

This time, only requests to edition.cnn.com should display "200". All other requests should display "403".
