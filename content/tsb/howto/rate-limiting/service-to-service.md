---
title: Service to service rate limiting
description: An example of rate limiting in TrafficSetting context
weight: 3
---

TSB is capable of applying rate limits for both gateways and sidecars. In this document, we will enable rate limiting for sidecars to control quota for service to service traffic.

Before you get started, make sure you: <br />
✓ Familiarize yourself with [TSB concepts](../../concepts/toc) <br />
✓ Install the TSB environment. You can use [TSB demo](../../setup/self_managed/demo-installation) for quick install<br />
✓ Completed [TSB usage quickstart](../../quickstart). This document assumes you already created Tenant and are familiar with Workspace and Config Groups. Also you need to configure tctl to your TSB environment.<br/>

## Enable Rate Limiting Server

Read and follow the instructions on [Enabling the Rate Limiting Server document](./internal_rate_limiting).

:::note Demo Installation
If you are using the [TSB demo](../../setup/self_managed/demo-installation) installation, you already have rate limit service running and ready to use, and can skip this section.
:::note

If you intend to use the same rate limiting server in a multi-cluster setup, all clusters must point to the same [Redis backend and domain](../../refs/install/controlplane/v1alpha1/spec#ratelimitserver )

## Deploy `httpbin` Service

Follow [the instructions in this document](../../reference/samples/httpbin) to create the `httpbin` service. You can skip the sections "Expose the `httpbin` Service", "Create Certificates", and "Onboard `httpbin` Application".

## Create TrafficSetting

Create a TrafficSetting object in a file named `service-to-service-rate-limiting-traffic-setting.yaml`. In this example the rate limit is set to maximum of 4 requests per minute per path. Replace the `organization` and `tenant` with appropriate values

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: TrafficSetting
metadata:
  organization: <organization>
  tenant: <tenant>
  workspace: httpbin
  group: httpbin-traffic
  name: httpbin-traffic-settings-ratelimit
spec:
  rateLimiting:
    settings:
      rules:
      - dimensions:
        - header:
            name: ":path"
            value: 
              prefix: "/"
        limit:
          requestsPerUnit: 4
          unit: MINUTE
```

Apply the manifest using `tctl`:

```bash
tctl apply -f service-to-service-rate-limiting-traffic-setting.yaml
```

## Deploy `sleep` Service

Since you will be configuring service-to-service rate limiting, another service to act as a client to your `httpbin` service is necessary.

Follow [the instructions in this document](../../reference/samples/sleep_service) to create the `sleep` service. You can skip the section on "Create a `sleep` Workspace".

## Testing

You can test the rate limiting by sending HTTP requests from the `sleep` service to `httpbin` service, and observe the rate limiting take effect after a certain number of requests.

To send a request from sleep service, you need to identify the pod within your sleep service.
Execute the following command to find out the pod name:

```bash
kubectl get pod -n sleep -l app=sleep -o jsonpath={.items..metadata.name}
```

Then send a request from this pod to the `httpbin` service, which should be reachable at `http://httpbin.httpbin:8000`. Make sure to replace the value for `sleep-pod` with an appropriate value:

```bash
kubectl exec <sleep-pod> -n sleep -c sleep -- \
  curl http://httpbin.httpbin:8000/get \
    -s \
    -o /dev/null \
    -w "%{http_code}\n"
```

Repeat executing the above command more than 4 times. After 4 requests, the response code that you see should change from 200 to 429.

Since the rate limiting rule was based on the request path, accessing another path on the `httpbin`, you should see a 200 response again:

```bash
kubectl exec <sleep-pod> -n sleep -c sleep -- \
  curl http://httpbin.httpbin:8000/headers \
    -s \
    -o /dev/null \
    -w "%{http_code}\n"
```

Similar to the previous example, repeating the above command more than 4 times should result in the rate limiting activating, and you should start getting a 429 instead of 200.
