---
title: External Rate Limiting with TLS Verification
description: Secure Traffic To External Rate Limiting Servers
weight: 6
---

Once you have configured [an external rate limit server](./external_rate_limiting), you may want to secure the traffic to the rate limit service. TSB supports specifying [TLS or mTLS](../../refs/tsb/auth/v2/auth#clienttlssettings) parameters for securing communication to external rate limit servers. This document will show you how to configure TLS validation for an external rate limit server by adding CA certificate to the rate limiting configuration. 

Before you get started, make sure you: <br />
✓ Familiarize yourself with [TSB concepts](../../concepts/toc) <br />
✓ Install the TSB environment. You can use [TSB demo](../../setup/self_managed/demo-installation) for quick install<br />
✓ Completed [TSB usage quickstart](../../quickstart). This document assumes you already created Tenant and are familiar with Workspace and Config Groups. Also you need to configure tctl to your TSB environment.<br/>
✓ Competed [Setting Up an External Rate Limiting Server](./external_rate_limiting). This document will continue what you have done in Setting Up an External Rate Limiting Server. You will work in `ext-ratelimit` namespace, and should already have an Ingress Gateway with external rate limit properly configured<br/>

## TLS certificate

To enable TLS for Ingress Gateway to rate limit service traffic, you must have a TLS certificate. This document assumes you already have TLS certificates which usually include server certificate and private key along with the CA as root certificate that will be used by the client.

This document assumes the presence of the following files. If you are using different file names, please change them accordingly:

| File name          | Description |
|--------------------|-------------|
| `ratelimit.crt`    | The server certificate |
| `ratelimit.key`    | The certificate private key |
| `ratelimit-ca.crt` | The CA certificate |

:::note self signed certificate
For the purpose of example, you may opt to use a self-signed certificate.
You may generate a self-signed certificate using [the script show here](../../quickstart/ingress_gateway#certificate-for-gateway), but make sure to adjust the input parameters accordingly.
:::note

Once you have the certificate files, create Kubernetes secret using server certificate and private key. 

```bash{promptUser: alice}
kubectl create secret tls -n ext-ratelimit ratelimit-certs \
  --cert=ratelimit.crt \
  --key=ratelimit.key
```

## Deploy Rate Limit Service with TLS certificate

In this example you will use the Envoy rate limit service. The Envoy proxy sidecar acts as pass through proxy that will validate and terminate TLS before sending the request to the rate limit service. 

Create a configuration file for Envoy with the following content as [`proxy-config-tls.yaml`](../../assets/howto/rate_limiting/proxy-config-tls.yaml)

<CodeBlock className="language-yaml">
  {proxyConfigTlsYAML}
</CodeBlock>

Execute the following to store the configuration in Kubernetes as a `ConfigMap`.

```bash{promptUser: alice}
kubectl create configmap -n ext-ratelimit ratelimit-proxy \
  --from-file=proxy-config-tls.yaml
```

You will need to deploy the rate limit service with an Envoy sidecar to terminate TLS.
Create a file called [`ratelimit-tls.yaml`](../../assets/howto/rate_limiting/ratelimit-tls.yaml) with the following content.

<CodeBlock className="language-yaml">
  {ratelimitTlsYAML}
</CodeBlock>

Then apply this using `kubectl`:

```bash{promptUser: alice}
kubectl apply -f ratelimit-tls.yaml
```

Once you applied the new configuration, make sure that the `ratelimit-tls` service is running properly.
Note that if you have followed the instructions from [Setting Up an External Rate Limiting Server](./external_rate_limiting), you will also see `ratelimit` and `redis` services as well.

```bash{promptUser: alice}
kubectl get pods -n ext-ratelimit

NAME                             READY   STATUS    RESTARTS   AGE
ratelimit-d5c5b64ff-m87dt        1/1     Running   0          2h
ratelimit-tls-568c5cdc69-z82xf   2/2     Running   0          89s
redis-7d757c948f-42sxg           1/1     Running   0          2h
```

## Enable TLS validation for rate limit server in Ingress Gateway

The `ratelimit-tls` service can now terminate TLS, but the Ingress Gateway must also be configured to validate the TLS connections.

First, create a `ConfigMap` named `ratelimit-ca` to store the CA information from `ratelimit-ca.crt`:

```bash{promptUser: alice}
kubectl create configmap -n httpbin ratelimit-ca \
  --from-file=ratelimit-ca.crt
```

Then add the `ratelimit-ca` `ConfigMap` into the Ingress Gateway pod. To do this, you will need to edit [the `httpbin-ingress-gateway.yaml` file](../../reference/samples/httpbin#expose-the-httpbin-service) and add an overlay that reads the `ConfigMap` you have created in the previous steps, then mount the configuration in the ingress gateway deployment.

<CodeBlock className="language-yaml">
  {httpbinIngressGatewayTlsYAML}
</CodeBlock>

Apply with kubectl to update existing ingress gateway

```bash{promptUser: alice}
kubectl apply -f httpbin-ingress-gateway.yaml
```

Finally, update [the Ingress Gateway configuration in `ext-ratelimit-ingress-gateway.yaml`](./external_rate_limiting#configure-ingress-gateway) and enable TLS validation:

<CodeBlock className="language-yaml">
  {extRatelimitIngressGatewayTlsYAML}
</CodeBlock>

And apply with tctl

```bash{promptUser: alice}
tctl apply -f ext-ratelimit-ingress-gateway-tls.yaml
```

## Testing

To verify that the setup is working, you can use the same testing steps as shown in [the Testing steps for "Setting Up an External Rate Limiting Server](./external_rate_limiting#testing)

