---
title: Subset based traffic routing using IngressGateway and ServiceRoute
description: Split external traffic between service subsets after matching on URI, header and port at application ingress.
weight: 1
---

In this how-to, you’ll learn how to setup subset based traffic routing by matching traffic on
uri endpoint, header and port and routing it to destination service's host:port.

The example used here demonstrates matching external traffic on hostname `helloworld.tetrate.io`, `end-user: jason` header
and port `443`, and routing it to service versions `v1:v2` in the ratio `80:20`.

### Prerequisites

Before you get started, make sure you: <br />
✓ Familiarize yourself with [TSB concepts](../../concepts/toc) <br />
✓ Install the [TSB demo](../../setup/self_managed/demo-installation) environment <br />
✓ Create a [Tenant](../../quickstart/tenant) <br />

### Create workspace and config groups

<CodeBlock className="language-yaml">
  {helloWorldWsGroupsYAML}
</CodeBlock>

Store the file as [`helloworld-ws-groups.yaml`](../../assets/howto/helloworld-ws-groups.yaml), and apply with `tctl`:

```bash{promptUser: alice}
tctl apply -f helloworld-ws-groups.yaml
```

### Deploy your application

To deploy your application, start by creating the namespace and enable the Istio sidecar injection.

```bash{promptUser: alice}
kubectl create namespace helloworld
kubectl label namespace helloworld istio-injection=enabled
```

<CodeBlock className="language-yaml">
  {helloWorld2SubsetsYAML}
</CodeBlock>

Store as [`helloworld-2-subsets.yaml`](../../assets/howto/helloworld-2-subsets.yaml), and apply with `kubectl`:

```bash{promptUser: alice}
kubectl apply -f helloworld-2-subsets.yaml -n helloworld
```

### Deploy application IngressGateway

<CodeBlock className="language-yaml">
  {helloWorldIngressYAML}
</CodeBlock>

Save as [`helloworld-ingress.yaml`](../../assets/howto/helloworld-ingress.yaml), and apply with `kubectl`:

```bash{promptUser: alice}
kubectl apply -f helloworld-ingress.yaml
```

The TSB data plane operator in the cluster will pick up this configuration and deploy the gateway’s resources
in your application namespace.

Get the Gateway IP. The following command will set the environment variable `GATEWAY_IP` in your current shell.
You will use this environment variable in the next scenarios.

```bash{promptUser: alice}
export GATEWAY_IP=$(kubectl -n helloworld get service tsb-helloworld-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

To confirm that you have a valid Ingress Gateway IP, you can use the following command to display the IP address.

```bash{promptUser: alice}
echo $GATEWAY_IP
```

Finally, configure the gateway so that it routes traffic to your application.

### Certificate for gateway

In this example, you’re going to expose the application using simple TLS at the gateway. You’ll need to provide
it with a TLS certificate stored in a Kubernetes secret.

```bash{promptUser: alice}{outputLines: 2-3}
kubectl create secret tls -n helloworld helloworld-cert \
    --cert /path/to/some/helloworld-cert.pem \
    --key /path/to/some/helloworld-key.pem
```

### Deploy `IngressGateway` and `ServiceRoute`

First, create an **IngressGateway**.

<CodeBlock className="language-yaml">
  {helloWorldGWYAML}
</CodeBlock>

Save as [`helloworld-gw.yaml`](../../assets/howto/helloworld-gw.yaml), and apply with `tctl`:
```bash{promptUser: alice}
tctl apply -f helloworld-gw.yaml
```

You can check that your application is reachable by opening your web browser and directing it to the gateway service IP
or domain name *(depending on your configuration)*.

Next, create a **ServiceRoute**. This service route will match traffic on header `end-user: jason`, and
route traffic in the ratio `80:20` between service versions `v1:v2`. If no header is provided, then it routes entire
traffic to service version `v1`.

:::warning Matching service fqdn
The `spec.service` in `ServiceRoute` should match with some `spec.http[*].routing.rules.route[*].host` of the
`IngressGateway` created above. Otherwise, the routing rules mentioned in the `ServiceRoute` will never take effect.

Both `spec.service` in `ServiceRoute` and `spec.http[*].routing.rules.route[*].host` in `IngressGateway` should be in `namespace/fqdn` format.
:::

<CodeBlock className="language-yaml">
  {helloWorldSVCRouteYAML}
</CodeBlock>

Save as [`helloworld-header-based-routing-service-route.yaml`](../../assets/howto/helloworld-header-based-routing-service-route.yaml),
and apply with `tctl`:
```bash{promptUser: alice}
tctl apply -f helloworld-header-based-routing-service-route.yaml
```

### Verify result

#### Request with header

Send consecutive curl requests **with** header `end-user: jason`. In this case, first route `http-route-match-header-and-port`
should be selected and traffic will get routed in the ratio `80:20` between `v1:v2`.

```bash{promptUser: alice}
for i in {1..20}; do curl -k "https://helloworld.tetrate.com/hello" \
--resolve "helloworld.tetrate.com:443:$GATEWAY_IP" \
-H "end-user: jason" 2>&1; done
Hello version: v2, instance: helloworld-v2-5b46bc9f84-wlsvh
Hello version: v2, instance: helloworld-v2-5b46bc9f84-wlsvh
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v2, instance: helloworld-v2-5b46bc9f84-wlsvh
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
```

You can see that `v1` was returned majority of the times, which means traffic got routed according to first route.

#### Request without header

Send consecutive curl requests **without** any header. In this case, second route `http-route-match-port` will be
selected and entire traffic will be routed to service version `Hello version: v1`.

```bash{promptUser: alice}
for i in {1..20}; do curl -k "https://helloworld.tetrate.com/hello" \
--resolve "helloworld.tetrate.com:443:$GATEWAY_IP" 2>&1; done
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
Hello version: v1, instance: helloworld-v1-fdb8c8c58-b2p2l
```

You can see that all responses were from `Hello version: v1`.
