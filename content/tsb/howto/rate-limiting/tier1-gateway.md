---
title: Rate limiting in Tier-1 Gateway
description: Configure rate limit in Tier-1 Gateway based on attributes in the request such as headers, URL path/prefixes and client remote address.
weight: 4
---

In this document, we will enable a rate limit in the Tier-1 Gateway and show how to rate limit based on the client IP address.

Before you get started, make sure you: <br />
✓ Familiarize yourself with [TSB concepts](../../concepts/toc) <br/>
✓ Install the TSB environment. You can use [TSB demo](../../setup/self_managed/demo-installation) for quick install<br />
✓ Completed [TSB usage quickstart](../../quickstart). This document assumes you already created Tenant and are familiar with Workspace and Config Groups. Also you need to configure tctl to your TSB environment.<br/>

## Deploy Tier-1 Gateway and Ingress Gateway

Before applying any rate limits, please read [Multi-cluster traffic shifting with Tier-1 Gateway](../gateway/multi-cluster-traffic-shifting) and familiarize yourself with setting up multi-cluster setup using Tier-1 Gateways.

The rest of the documentation assumes that you have completed the above.

## Enable Rate Limiting Server

Read and follow the instructions on [Enabling the Rate Limiting Server document](./internal_rate_limiting).

:::note Demo Installation
If you are using the [TSB demo](../../setup/self_managed/demo-installation) installation, you already have rate limit service running and ready to use, and can skip this section.
:::note

## Deploy `httpbin` Service

Follow [the instructions in this document](../../reference/samples/httpbin) to create the `httpbin` service, and make sure the service is exposed at `httpbin.tetrate.com`.

## Create Tier-1 Gateway

Create a file called `rate-limiting-tier1-config.yaml` which edits the existing Tier-1 Gateway to also rate limit every unique client(source) IP Address at 10 requests/minute. Replace the cluster name with the cluster where the `httpbin` service is deployed to.

Details for other rate limiting options can be found in [this document](../../refs/tsb/gateway/v2/ingress_gateway#ratelimitdimension-1)

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Tier1Gateway
metadata:
  name: tier1-gateway
  group: tier1-gateway-group
  workspace: tier1-workspace
  tenant: tetrate
  organization: tetrate
spec:
  workloadSelector:
    namespace: tier1
    labels:
      app: tier1-gateway
  externalServers:
  - hostname: httpbin.tetrate.com
    name: httpbin
    port: 443
    rateLimiting:
      settings:
        rules:
        - dimensions:
          - remoteAddress:
              value: '*'
          limit:
            requestsPerUnit: 10
            unit: MINUTE
    tls:
      mode: SIMPLE
      # make sure to use correct secret name that you created previously
      secretName: httpbin-certs
    clusters:
    - name: <cluster>
      weight: 100
```

Configure the Tier-1 gateway using tctl:

```bash{promptUser: "alice"}
tctl apply -f rate-limiting-tier1-config.yaml
```

## Testing

You can test the rate limiting by sending HTTP requests from an external machine or your local environment to the `httpbin` service, and observe the rate limiting take effect after a certain number of requests.

In the following example, since you do not control `httpbin.tetrate.com`, you will have to trick `curl` into thinking that `httpbin.tetrate.com` resolves to the IP address of the Tier-1 Gateway.

Obtain the IP address of the Tier-1 Gateway that you previously created using the following command.

```bash{promptUser: "alice"}
kubectl -n tier1 get service tier1-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Then execute the following command to send HTTP requests to the `httpbin` service through the Tier-1 Gateway. Replace the `gateway-ip` with the value you obtained in the previous step. You also need to pass the CA cert, which you should have created in the step to deploy the `httpbin` service. 
 
```bash{promptUser: "alice"}
curl -I "https://httpbin.tetrate.com/get" \
  --resolve "httpbin.tetrate.com:443:<gateway-ip>" \
  --cacert httpbin.crt \
  -s \
  -o /dev/null \
  -w "%{http_code}\n"
```

Repeat executing the above command more than 10 times in a minute. After 10 requests, the response code that you see should change from 200 to 429.
