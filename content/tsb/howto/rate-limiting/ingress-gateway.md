---
title: Rate Limiting in Ingress Gateway
description: Configure rate limit in Ingress Gateway based on User-Agent.
weight: 2
---

In this document, we will enable a rate limit in the Ingress Gateway and show how to rate limit based on the HTTP request `user-agent` string.

Before you get started, make sure you: <br />
✓ Familiarize yourself with [TSB concepts](../../concepts/toc) <br />
✓ Install the TSB environment. You can use [TSB demo](../../setup/self_managed/demo-installation) for quick install<br />
✓ Completed [TSB usage quickstart](../../quickstart). This document assumes you already created Tenant and are familiar with Workspace and Config Groups. Also you need to configure tctl to your TSB environment.<br/>

## Enable Rate Limiting Server

Read and follow the instructions on [Enabling the Rate Limiting Server document](./internal_rate_limiting).

:::note Demo Installation
If you are using the [TSB demo](../../setup/self_managed/demo-installation) installation, you already have rate limit service running and ready to use, and can skip this section.
:::note

## Deploy `httpbin` Service

Follow [the instructions in this document](../../reference/samples/httpbin) to create the `httpbin` service. You can skip the sections "Create Certificates" and "Onboard `httpbin` Application".

## Rate limit based on User-agent

Create a file called `rate-limiting-ingress-config.yaml` which edits the existing Ingress Gateway to also rate limit every value for User-agent header at 5 requests/minute. Replace the `organization` and `tenant` with appropriate values

Details for other rate limiting options can be found in [this document](../../refs/tsb/gateway/v2/ingress_gateway)

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
  name: httpbin-gateway # Need not be the same as spec.labels.app
  organization: <organization>
  tenant: <tenant>
  group: httpbin-gateway
  workspace: httpbin
spec:
  workloadSelector:
    namespace: httpbin
    labels:
      app: httpbin-ingress-gateway # name of Ingress Gateway created for httpbin
  http:
    - name: httpbin
      hostname: "httpbin.tetrate.com"
      port: 80
      routing:
        rules:
          - route:
              host: "httpbin/httpbin.httpbin.svc.cluster.local"
              port: 8000
      rateLimiting:
        settings:
          rules:
          - dimensions:
            - header:
                name: user-agent
            limit:
              requestsPerUnit: 5
              unit: MINUTE
```

Configure the Ingress Gateway with `tctl`:

```bash
tctl apply -f rate-limiting-ingress-config.yaml
```

## Testing 

You can test the rate limiting by sending HTTP requests from an external machine or your local environment to the `httpbin` Ingress Gateway, and observe the rate limiting take effect after a certain number of requests.

In the following example, since you do not control `httpbin.tetrate.com`, you will have to trick `curl` into thinking that `httpbin.tetrate.com` resolves to the IP address of the Tier-1 Gateway.

Obtain the IP address of the Tier-1 Gateway that you previously created using the following command.

```bash{promptUser: "alice"}
kubectl -n httpbin get service httpbin-ingress-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Then execute the following command to send HTTP requests to the `httpbin` service through the Ingress Gateway. Replace the `gateway-ip` with the value you obtained in the previous step. 

```bash
curl -k -v "http://httpbin.tetrate.com/get" \
    --resolve "httpbin.tetrate.com:80:<gateway-ip>" \
    -s \
    -o /dev/null \
    -w "%{http_code}\n"
```

For the first 5 requests you should see "200" on your screen. After that,
you should start seeing "429" instead.

You can change the `user-agent` header to another unique value to get a successful response.

```bash
curl -k -v -A "another-agent" \
    "http://httpbin.tetrate.com/get" \
    --resolve "httpbin.tetrate.com:80:<gateway-ip>" \
    -s \
    -o /dev/null \
    -w "%{http_code}\n"
```

After 5 requests, you should start seeing "429" again, until you change the header again.
