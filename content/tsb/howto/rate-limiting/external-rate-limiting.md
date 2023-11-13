---
title: Setting Up an External Rate Limiting Server
description: How to configure TSB Ingress Gateway to use external rate limiting server
weight: 5
---

TSB supports using external rate limiting servers. This document will describe how to configure [Envoy rate limit service](https://github.com/envoyproxy/ratelimit) and use it as external rate limiting server in TSB's Ingress Gateway through an example.

Before you get started, make sure you: <br />
✓ Familiarize yourself with [TSB concepts](../../concepts/toc) <br />
✓ Install the TSB environment. You can use [TSB demo](../../setup/self_managed/demo-installation) for quick install<br />
✓ Completed [TSB usage quickstart](../../quickstart). This document assumes you already created Tenant and are familiar with Workspace and Config Groups. Also you need to configure tctl to your TSB environment.<br/>

:::note
While this document will only describe how to apply rate limiting using an external server for Ingress Gateway, you can do the same for Tier-1 Gateways and service-to-service (through TSB Traffic Settings) using a similar configuration.
:::

## Create the Namespace

In this example we will install the external rate limit service in `ext-ratelimit` namespace.
Create the namespace if not already present in the target cluster by running the following command:

```bash
kubectl create namespace ext-ratelimit
```

### Configure Rate Limit Service

:::note
Please read the [Envoy rate limit documentation](https://github.com/envoyproxy/ratelimit#configuration) to learn the details about the concept of domains and descriptors.
:::

Create a file name [`ext-ratelimit-config.yaml`](../../assets/howto/rate_limiting/ext-ratelimit-config.yaml) with the following content. This configuration specifies that requests to every unique request path should be limited to 4 requests/minute.

<CodeBlock className="language-yaml">
  {extRateLimitConfigYAML}
</CodeBlock>

Then create a `ConfigMap` using the file you created:

```bash
kubectl -n ext-ratelimit apply -f ext-ratelimit-config.yaml
```

### Deploy Rate Limit Server and Redis

Deploy Redis and `envoyproxy/ratelimit`. Create a file called [`redis-ratelimit.yaml`](../../assets/howto/rate_limiting/redis-ratelimit.yaml) with the following contents:

<CodeBlock className="language-yaml">
  {redisRateLimitYAML}
</CodeBlock>

```bash
kubectl -f redis-ratelimit.yaml
```

If everything is successful, you should have a working rate limit server. 
Make sure that Redis and the rate limit server are running by executing the following command:

```bash
kubectl get pods -n ext-ratelimit
```

You should see an output resembling the following:

```
NAME                        READY   STATUS    RESTARTS   AGE
ratelimit-d5c5b64ff-m87dt   1/1     Running   0          14s
redis-7d757c948f-42sxg      1/1     Running   0          14s
```

## Configure Ingress Gateway

This example assumes that you are applying rate limit to the [`httpbin`](../../reference/samples/httpbin) workload. If you have not already done so, deploy the `httpbin` service, create `httpbin` Workspace and Config Groups and expose the service through an Ingress Gateway.

The following sample sets rate limiting on requests in the `httpbin-ratelimit` domain. The request path is stored in `descriptorKey` named `request-path`, which is then used by the rate limit server.

<CodeBlock className="language-yaml">
  {extRateLimitIngressGatewayYAML}
</CodeBlock>

Save this to a file named [`ext-ratelimit-ingress-gateway.yaml`](../../assets/howto/rate_limiting/ext-ratelimit-ingress-gateway.yaml), and apply it using `tctl`:

```bash
tctl apply -f ext-ratelimit-ingress-gateway.yaml
```

### Testing

You can test the rate limiting by sending HTTP requests from an external machine or your local environment to the httpbin Ingress Gateway, and observe the rate limiting take effect after a certain number of requests.

In the following example, since you do not control httpbin.tetrate.com, you will have to trick curl into thinking that httpbin.tetrate.com resolves to the IP address of the Ingress Gateway.

Obtain the IP address of the Ingress Gateway that you previously created using the following command.

```bash
kubectl -n httpbin get service httpbin-ingress-gateway \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Then execute the following command to send HTTP requests to the httpbin service through the Ingress Gateway. Replace the gateway-ip with the value you obtained in the previous step.

```bash
curl -k "http://httpbin.tetrate.com/get" \
    --resolve "httpbin.tetrate.com:80:<gateway-ip>" \
    -s \
    -o /dev/null \
    -w "%{http_code}\n"
```

For the first 4 requests you should see "200" on your screen. After that, you should start seeing "429" instead.

You can change the request path to another unique value to get a successful response.

```bash
curl -k "http://httpbin.tetrate.com/headers" \
    --resolve "httpbin.tetrate.com:80:<gateway-ip>" \
    -s \
    -o /dev/null \
    -w "%{http_code}\n"
```

After 4 requests, you should start seeing "429" again, until you change the request path.

## Considerations for Using Rate Limiting Server over Multiple Clusters

In case you would like to share the same rate limiting rules against multiple cluster, there are two possible choices:

* Deploy a single rate limit service in one cluster, and make it reachable from all other clusters that share the rules, or
* Deploy rate limit services in each cluster, but make them all use the same Redis backend.

In the second scenario, you will have to make Redis accessible from all clusters. Each rate limit server should also use the same domain value.
