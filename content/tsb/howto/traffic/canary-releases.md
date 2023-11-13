---
title: Canary Releases
weight: 6
description: Guide on doing canary releases with TSB.
---

This how-to document will show you how to do a canary release of a new sample
service. You'll learn how to deploy and onboard a service in TSB, and how to
adjust its settings to follow the canary deployment process.

✓ You'll create a workspace and the groups you'll need to onboard the application<br />
✓ Expose the application via an application ingress gateway<br />
✓ Perform the canary release.

Before you get started make sure:

✓ You have a TSB management plane up and running.<br />
✓ You have tctl configured to communicate with the TSB management plane.<br />
✓ The cluster where you are deploying the application to is running a TSB
control plane and is correctly onboarded into the TSB management plane.

This guide uses a `hello world` application, if you're using this in production,
please update the relevant fields with the correct information for your
application.

## Get Started

The following YAML file has three objects - a Workspace for the application, a
Gateway group so that you can configure the application ingress, and a Traffic
group that will allow you to configure the canary release process. Store
it as [`ws-groups.yaml`](../../assets/howto/ws-groups.yaml).

<CodeBlock className="language-yaml">
  {wsGroupsYAML}
</CodeBlock>

Apply with tctl:

```bash
tctl apply -f ws-groups.yaml
```

To deploy your application, start by creating the namespace and enable the Istio
sidecar injection.

```bash
kubectl create namespace helloworld
kubectl label namespace helloworld istio-injection=enabled
```

Then deploy your application.

<CodeBlock className="language-yaml">
  {helloWorldYAML}
</CodeBlock>

Store the file as [`helloworld.yaml`](../../assets/howto/helloworld.yaml) and apply with `kubectl`:

```bash
kubectl apply -f helloworld.yaml
```

Before you go further, you should ensure that no traffic is accidentally
directed to any new version of the application. Then, create a `ServiceRoute` in
the traffic group you created earlier, so that all `helloworld` traffic  is sent
solely to version `v1` .

<CodeBlock className="language-yaml">
  {serviceRouteYAML}
</CodeBlock>

Store the file as `serviceroute.yaml` and apply with `tctl`:

```bash
tctl apply -f serviceroute.yaml
```

Great! Now you need to make your application accessible to the world. You need
to deploy an ingress gateway for your application and configure it to route the
incoming traffic to our application service.

In this example, you're going to expose the application using simple TLS at the
gateway. You'll need to provide it with a TLS certificate stored in a Kubernetes
secret.

```bash
kubectl create secret tls -n helloworld helloworld-certs \
    --cert /path/to/some/helloworld-cert.pem \
    --key /path/to/some/helloworld-key.pem
```

Now you can deploy your ingress gateway.

<CodeBlock className="language-yaml">
  {helloIngressYAML}
</CodeBlock>

Store the file as [`hello-ingress.yaml`](../../assets/howto/hello-ingress.yaml) and apply with `kubectl`:

```bash
kubectl apply -f hello-ingress.yaml
```

The TSB data plane operator in the cluster will pick up this configuration and
deploy the gateway's resources in your application namespace. All that is left
to do is configure the gateway so that it routes traffic to your application.

<CodeBlock className="language-yaml">
  {helloGatewayYAML}
</CodeBlock>

Store the file as [`helloworld-gateway.yaml`](../../assets/howto/hello-gateway.yaml) and apply with `tctl`:

```bash
tctl apply -f helloworld-gateway.yaml
```

At this point, you can check that your application is reachable by sending an HTTPS request for `helloworld.tetrate.com` to the gateway service IP.

```bash
curl -k -s --connect-to helloworld.tetrate.com:443:$GATEWAY_IP "https://helloworld.tetrate.com/"
```

Now that your application is running and serving requests, deploy a new version
of the application.

<CodeBlock className="language-yaml">
  {helloWorldV2YAML}
</CodeBlock>

Store the file as [`helloworld-v2.yaml`](../../assets/howto/helloworld-v2.yaml) and apply with `kubectl`:

```bash
kubectl apply -f helloworld-v2.yaml
```

Since you've created a service route that targets all traffic to version `v1`.
Version `v2` won't be getting any requests at this point. Start your canary
release by modifying the service route to send 80% of the traffic to our known
stable version `v1` and 20% to version `v2`.

<CodeBlock className="language-yaml">
  {serviceRoute20YAML}
</CodeBlock>

Store the file as [`serviceroute-20.yaml`](../../assets/howto/serviceroute-20.yaml) and apply with `tctl`:

```bash
tctl apply -f serviceroute-20.yaml
```

If you keep refreshing your application using your web browser, you'll see a
majority of the requests reaching the old `v1` version. The other requests will
show the output of the new `v2` version. To complete the canary release you will
need to repeat this last step until all traffic is sent to the new and improved
version `v2`, (or undo and send all traffic back to version `v1` if you found
some issue with the new version). Simple!
