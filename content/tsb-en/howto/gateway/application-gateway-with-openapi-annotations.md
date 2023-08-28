---
title: Configuring Application Gateways Using OpenAPI Annotations
description: How to configure Application Gateways using OpenAPI annotations
weight: 10
---

An [Application](../../refs/tsb/application/v2/application) in TSB represents a set of logical groupings of [Services](../../refs/tsb/registry/v2/service) that are related to each other and expose a set of [APIs](../../refs/tsb/application/v2/api) that implement a complete set of business logic.

![](../../assets/howto/applications-services-api.png)

TSB can leverage OpenAPI annotations when configuring API runtime policies. In this document you will enable authorization via Open Policy Agent (OPA), as well as rate limiting through an external service. Each request will need to go through basic authorization, and for each valid user a rate limit policy will be enforced.

![](../../assets/howto/openapi-opa-rate-limit.png)

Before you get started, make sure you: <br />
✓ Familiarize yourself with [TSB concepts](../../concepts/toc) <br />
✓ Familiarize yourself with [Open Policy Agent (OPA)](https://www.openpolicyagent.org/docs/latest/) <br />
✓ Familiarize yourself with Envoy external authorization and rate limit <br />
✓ Install the [TSB demo](../../setup/self_managed/demo-installation) environment <br />
✓ Familiarize yourself with [Istio Bookinfo](../../quickstart/deploy_sample_app) sample app <br />
✓ Create a [Tenant](../../quickstart/tenant)

## Deploy `httpbin` Service

Follow [the instructions in this document](../../reference/samples/httpbin) to create the `httpbin` service. Complete all steps in that document.

## TSB Specific Annotations

The following extra TSB-specific annotations can be added to the OpenAPI specification in order to configure the API.

| Annotation                   | Description                                                                                                                                                                                    |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| x-tsb-service                | The upstream service name in TSB that provides the API, as seen in the TSB service registry (you can check with `tctl get services`).                                                          |
| x-tsb-cors                   | The [CORS policy](https://en.wikipedia.org/wiki/Cross-origin_resource_sharing) for the server.                                                                                                 |
| x-tsb-tls                    | The TLS settings for the server. If omitted, the server will be configured to serve plain text connections. The `secretName` field must point to an existing Kubernetes secret in the cluster. |
| x-tsb-external-authorization | The OPA settings for the server.                                                                                                                                                               |
| x-tsb-ratelimiting           | The external rate limit server (e.g. [envoyproxy/ratelimit](https://github.com/envoyproxy/ratelimit)) settings.                                                                                 |

## Configure the API

Create the following API definition in a file called `httpbin-api.yaml`.

In this scenario you will only use one of the APIs (`/get`) that the `httpbin` service [provides](https://httpbin.org/). If you want to use all of the `httpbin` API you can get their OpenAPI specifications from [this link](../../assets/howto/httpbin-openapi.yaml).

```yaml
apiversion: application.tsb.tetrate.io/v2
kind: API
metadata:
  organization: <organization>
  tenant: <tenant>
  application: httpbin
  name: httpbin-ingress-gateway
spec:
  description: Httpbin OpenAPI
  workloadSelector:
    namespace: httpbin
    labels:
      app: httpbin-gateway
  openapi: |
    openapi: 3.0.1
    info:
      version: '1.0-oas3'
      title: httpbin
      description: An unofficial OpenAPI definition for httpbin
      x-tsb-service: httpbin.httpbin

    servers:
      - url: https://httpbin.tetrate.com
        x-tsb-cors:
          allowOrigin:
            - "*"
        x-tsb-tls:
          mode: SIMPLE
          secretName: httpbin-certs
    paths:
      /get:
        get:
          tags:
            - HTTP methods
          summary: |
            Returns the GET request's data.
          responses:
            '200': 
              description: OK
              content:
                application/json:
                  schema:
                    type: object
```

Apply using `tctl`:

```bash{promptUser: "alice"}
tctl apply -f httpbin-api.yaml
```

At this point, you should be able to send requests to the `httpbin` Ingress Gateway.

Since you do not control `httpbin.tetrate.com`, you will have to trick `curl` into thinking that `httpbin.tetrate.com` resolves to the IP address of the Ingress Gateway.

Obtain the IP address of the Ingress Gateway that you previously created using the following command.

```bash{promptUser: "alice"}
kubectl -n httpbin get service httpbin-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Execute the following command to send HTTP requests to the `httpbin` service through the Tier-1 Gateway. Replace the `gateway-ip` with the value you obtained in the previous step. You also need to pass the CA cert, which you should have created in the step to deploy the `httpbin` service.

```bash{promptUser: "alice"}
curl -I "https://httpbin.tetrate.com/get" \
  --resolve "httpbin.tetrate.com:443:<gateway-ip>" \
  --cacert httpbin.crt
```

You should see a successful HTTP response.

## Authorization with OPA

Once the API is properly exposed via OpenAPI annotations, OPA can be configured against the API Gateway.

In this example you will create a policy that checks for basic authentication in the request header. If the user is authenticated, the user name should be added to the `x-user` header so that it can be used by the rate limit service to enforce quota for each user later.

### Configure OPA

Create the `opa` namespace, where the OPA and its configuration will be deployed to:

```bash{promptUser: "alice"}
kubectl create namespace opa
```

Create a file name [`openapi-policy.rego`](../../assets/howto/openapi-policy.rego):

<CodeBlock>{openapiPolicyRego}</CodeBlock>

Then create a `ConfigMap` using the file you created:

```bash{promptUser: "alice"}
kubectl -n opa create configmap opa-policy \
  --from-file=openapi-policy.rego
```

Create the `Deployment` and the `Service` objects that use the above policy configuration in a file named [`opa.yaml`](../../assets/howto/openapi-opa.yaml).

<CodeBlock className="language-yaml">{openapiOpaYAML}</CodeBlock>

Then apply the manifest:

```
kubectl apply -f opa.yaml
```

Finally, open the `httpbin-api.yaml` file that you created in a previous section, and add the `x-tsb-external-authorization` annotation in the `server` component:

```yaml
    ...
    servers:
      - url: https://httpbin.tetrate.com
        ...
        x-tsb-external-authorization:
          uri: grpc://opa.opa.svc.cluster.local:9191
```

And apply the changes again:

```bash{promptUser: "alice"}
tctl apply -f httpbin-api.yaml
```

### Testing

To test, execute the following command, replacing the values for username, password, and gateway-ip accordingly.

```bash{promptUser: "alice"}
curl -u <username>:<password> \
  "https://httpbin.tetrate.com/get" \
  --resolve "httpbin.tetrate.com:443:<gateway-ip>" \
  --cacert httpbin.crt
  -s \
  -o /dev/null \
  -w "%{http_code}\n"
```

| Username          | Password          | Status Code |
| ----------------- | ----------------- | ----------- |
| `alice`           | `password`        | 200         |
| `bob`             | `password`        | 200         |
| `<anything else>` | `<anything else>` | 403 (\*1)   |

(\*1) [See documentation for more details](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/security/ext_authz_filter#external-authorization)

## Rate limiting with external service

[TSB supports internal and external mode for rate limiting](../rate_limiting). In this example you will deploy a separate Envoy rate limit service.

### Configure Rate Limit

Create the `ext-ratelimit` namespace, where the rate limit server and its configuration will be deployed to:

```bash{promptUser: "alice"}
kubectl create namespace ext-ratelimit
```

Create a file name [`ext-ratelimit-config.yaml`](../../assets/howto/ext-ratelimit-config.yaml). This configuration specifies that the user `alice` should be rate limited to 10 requests/minute and user `bob` should be limited to 2 requests/minute.

<CodeBlock className="language-yaml">{extRateLimitConfigYAML}</CodeBlock>

Then create a `ConfigMap` using the file you created:

```bash{promptUser: "alice"}
kubectl -n ext-ratelimit create configmap ext-ratelimit \
  --from-file=config.yaml=ext-ratelimit-config.yaml
```

You now need to deploy Redis and `envoyproxy/ratelimit`. Create a file called [`redis-ratelimit.yaml`](../../assets/howto/redis-ratelimit.yaml) with the following contents:

<CodeBlock className="language-yaml">{redisRateLimitYAML}</CodeBlock>

If everything is successful, you should have a working rate limit server. The next step is to add an annotation for `x-tsb-ratelimiting` to the OpenAPI object:

Next, update your OpenAPI spec by adding the following `x-tsb-ratelimiting` annotation in OpenAPI server object

```yaml
...
    servers:
      - url: https://httpbin.tetrate.com
        ...
       x-tsb-external-ratelimiting:
          domain: "httpbin-ratelimit"
          rateLimitServerUri: "grpc://ratelimit.ext-ratelimit.svc.cluster.local:8081"
          rules:
            - dimensions:
              - requestHeaders:
                  headerName: x-user
                  descriptorKey: x-user-descriptor

...
```

### Testing

To test, execute the following command, replacing the values for username, password, and gateway-ip accordingly.

```bash{promptUser: "alice"}
curl -u <username>:<password> \
  "https://httpbin.tetrate.com/get" \
  --resolve "httpbin.tetrate.com:443:<gateway-ip>" \
  --cacert httpbin.crt
  -s \
  -o /dev/null \
  -w "%{http_code}\n"
```

First, try sending multiple requests using the username `alice` and password `password`. You should receive the status code `200` until the 10th request. After that you should receive `429` responses, until 10 minutes have passed.

Try the same with username `bob` and password `password`. The behavior should be identical, except that this time you should only be able to send 2 requests before starting to receive `429` responses.

## Policy ordering

TSB does not currently support specifying explicit policy order.

Instead, the creation timestamp for the configurations will implicitly be used. Therefore, the execution order cannot be guaranteed if you specify the external authorization and rate limiting services in one go.

This is why in this document the external authorization and rate limiting configurations were applied in two separate steps, in this specific order. This way the authorization processing is performed before the rate limiting.
