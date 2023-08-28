---
title: Client Side Load Balancing
description: How to setup multiple replicas and load balance between them.
weight: 3
---

import helloWorld1YAML from '!!raw-loader!../../assets/howto/helloworld-1.yaml';
import helloWorldWsGroupsYAML from '!!raw-loader!../../assets/howto/helloworld-ws-groups.yaml';
import helloWorldIngressYAML from '!!raw-loader!../../assets/howto/helloworld-ingress.yaml';
import helloWorldGWYAML from '!!raw-loader!../../assets/howto/helloworld-gw.yaml';
import helloWorldClientLBYAML from '!!raw-loader!../../assets/howto/helloworld-client-lb.yaml';
import CodeBlock from '@theme/CodeBlock';

The following YAML file has three objects -  a `Workspace` for the application,
a `Gateway group` so that you can configure the application ingress, and a
`Traffic group` that will allow you  to configure the canary release process.

<CodeBlock className="language-yaml">
  {helloWorldWsGroupsYAML}
</CodeBlock>

Store the file as [`helloworld-ws-groups.yaml`](../../assets/howto/helloworld-ws-groups.yaml), and apply with `tctl`:

```bash{promptUser: alice}
tctl apply -f helloworld-ws-groups.yaml
```

To deploy your application, start by creating the namespace and enable the Istio
sidecar injection.

```bash{promptUser: alice}
kubectl create namespace helloworld
kubectl label namespace helloworld istio-injection=enabled
```

Then deploy your application.

<CodeBlock className="language-yaml">
  {helloWorld1YAML}
</CodeBlock>

Store as [`helloworld-1.yaml`](../../assets/howto/helloworld-1.yaml), and apply with `kubectl`:

```bash{promptUser: alice}
kubectl apply -f helloworld-1.yaml
```

Note that you're deploying 3 replicas for this deployment.

In this example, you're going to expose the application using simple TLS at the
gateway. You'll need to provide it with a TLS certificate stored in a Kubernetes
secret.

```bash{promptUser: alice}{outputLines: 2-3}
kubectl create secret tls -n helloworld helloworld-cert \
    --cert /path/to/some/helloworld-cert.pem \
    --key /path/to/some/helloworld-key.pem
```

Now you can deploy your ingress gateway.

<CodeBlock className="language-yaml">
  {helloWorldIngressYAML}
</CodeBlock>

Save as [`helloworld-ingress.yaml`](../../assets/howto/helloworld-ingress.yaml), and apply with `kubectl`:

```bash{promptUser: alice}
kubectl apply -f helloworld-ingress.yaml
```

The TSB data plane operator in the cluster will pick up this configuration and
deploy the gateway's resources in your application namespace. Finally, configure
the gateway so that it routes traffic to your application.

<CodeBlock className="language-yaml">
  {helloWorldGWYAML}
</CodeBlock>

Save as [`helloworld-gw.yaml`](../../assets/howto/helloworld-gw.yaml), and apply with `tctl`:
```bash{promptUser: alice}
tctl apply -f helloworld-gw.yaml
```

You can check that your application is reachable by opening your web browser and
directing it to the gateway service IP or domain name *(depending on your
configuration)*.

At this point, your application will load balance using Round Robin by default.
Now, configure client-side load balancing and use the source IP.

<CodeBlock className="language-yaml">
  {helloWorldClientLBYAML}
</CodeBlock>

Save as [`helloworld-client-lb.yaml`](../../assets/howto/helloworld-client-lb.yaml), and apply with `tctl`:

```bash{promptUser: alice}
tctl apply -f helloworld-client-lb.yaml
```

Now, the same pod is being used as a backend for all our requests coming from
the same IP.

In this example you have used the source IP, but there are other methods allowed
too; using the header of an HTTP request, or configuring an HTTP cookie.
