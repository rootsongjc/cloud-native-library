---
title: Distributed Ingress Gateways
description: Resilient Mesh with Distributed Ingress Gateways.
weight: 8
---

For this scenario, you will need two clusters onboarded to configure round 
robin - failover between them.

### Prerequisites

Before you get started, make sure you: <br />
✓ Familiarize yourself with [TSB concepts](../../concepts/toc) <br />
✓ Install the [TSB demo](../../setup/self_managed/demo-installation) environment <br />
✓ Create a [Tenant](../../quickstart/tenant) <br />

### Create workspace and gateway group

The following YAML file has two objects; a `Workspace` for the application, and
a `Gateway` group so that you can configure the application ingress.

<CodeBlock className="language-yaml">
  {httpBinMgmtYAML}
</CodeBlock>

Store as [`httpbin-mgmt.yaml`](../../assets/howto/httpbin-mgmt.yaml), and apply with tctl:

```bash
tctl apply -f httpbin-mgmt.yaml
```

### Deploy httpbin

The following configurations should be applied to both clusters; to deploy your
application, start by creating the namespace and enable the Istio sidecar
injection.

```bash
kubectl create namespace httpbin
kubectl label namespace httpbin istio-injection=enabled
```

Then deploy your application.

```bash
kubectl apply -f \
    https://raw.githubusercontent.com/istio/istio/master/samples/httpbin/httpbin.yaml \
    -n httpbin
```

### Configure ingress gateway

In this example, you're going to expose the application using simple TLS at the
gateway. You'll need to provide it with a TLS certificate stored in a Kubernetes
secret.

```bash
kubectl create secret tls -n httpbin httpbin-cert \
    --cert /path/to/some/cert.pem \
    --key /path/to/some/key.pem
```

Now you can deploy the ingress gateway.

<CodeBlock className="language-yaml">
  {httpBinIngressYAML}
</CodeBlock>

Save as [`httpbin-ingress.yaml`](../../assets/howto/httpbin-ingress.yaml), and apply with `kubectl`:

```bash
kubectl apply -f httpbin-ingress.yaml
```

Applying above configurations to both clusters, will create the same environment
for both of them, now we will deploy the gateway and virtual services.

The TSB data plane operator in the cluster will pick up this configuration and
deploy the gateway's resources in your application namespace. All that is left
to do is configure the gateway so that it routes traffic to your application.

<CodeBlock className="language-yaml">
  {httpBinGWYAML}
</CodeBlock>

Save as [`httpbin-gw.yaml`](../../assets/howto/httpbin-gw.yaml), and apply with `tctl`:

```bash
tctl apply -f httpbin-gw.yaml
```

Now, you can configure both ingress gateway service IP to your DNS entry and
configure ROUND ROBIN between them, or just configure one IP and use the other
cluster as failover.

You can test that both ingress gateway are working by running:

```bash
curl -s -o /dev/null --insecure -w "%{http_code}" \
    "https://httpbin.tetrate.com" \
    --resolve "httpbin.tetrate.com:443:$CLUSTER1_IP"
```

```bash
curl -s -o /dev/null --insecure -w "%{http_code}" \
    "https://httpbin.tetrate.com" \
    --resolve "httpbin.tetrate.com:443:$CLUSTER2_IP"
```

