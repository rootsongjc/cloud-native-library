---
title: External Authorization in Tier-1 Gateways
description: How To Use OPA to Authorize Requests From Public Facing Network
weight: 4
---

TSB provides authorization capability to authorize every request coming to your service from a public network. This document will describe how to configure Tier-1 Gateway authorization using Open Policy Agent (OPA) as an example.

Before you get started, make sure you: <br />
✓ Familiarize yourself with [TSB concepts](../../concepts/toc). <br />
✓ Completed Tier-1 Gateway routing to Tier-2 Gateway with [httpbin already configured](../../reference/samples/httpbin) in TSB.<br />
✓ Created a Tenant, and understand Workspaces and Config Groups.<br />
✓ Configured `tctl` for your TSB environment.

The following diagram shows the request/response flow using OPA with Tier-1 Gateways. Requests that come to Tier-1 Gateway will be checked by OPA. If the request is deemed unauthorized, then the request will be denied with a 403 (Forbidden) response, otherwise they are sent to the Tier-2 Gateways.

## Deploy `httpbin` Service

Follow [the instructions in this document](../../reference/samples/httpbin) to create the `httpbin` service, and make sure the service is exposed at `httpbin.tetrate.com`.

## Configuring OPA

For this example you will be deploying OPA as its own standalone service. Create a namespace for the OPA service, if you have not already done so:

```bash{promptUser: "alice"}
kubectl create namespace opa
```

Follow the instructions in [the OPA document](../../reference/samples/opa) to create [an OPA policy using Basic Authentication](../../reference/samples/opa#example--policy-with-basic-authentication), and deploy the OPA service and agent in the `opa` namespace.

```
kubectl apply -f opa.yaml
```

Then update your Tier-1 Gateway configuration 
your OpenAPI spec by adding the following section to the Tier-1 Gateway and use tctl to apply them 

```
apiVersion: gateway.tsb.tetrate.io/v2
kind: Tier1Gateway
metadata:
 organization: tetrate
 tenant: tetrate
 workspace: tier1
 group: tier1
 name: tier1gw
spec:
 workloadSelector:
   namespace: tier1
   labels:
     app: tier1gw
     istio: ingressgateway
 externalServers:
 - name: httpbin
   hostname: httpbin.tetrate.com
   port: 443
   tls:
     mode: SIMPLE
     secretName: tier1-cert
   clusters:
   - labels:
       network: tier2
   authorization:
     external:
       uri: grpc://opa.opa.svc.cluster.local:9191
```

## Testing

You can test the external authorization by following the instructions in the ["Configuring External Authorization in Ingress Gateways"](./ingress_gateway#testing), except you need to obtain the Tier-1 Gateway IP address instead of the Ingress Gateway address.

To obtain the Tier-1 Gateway address, execute the following command:

```bash{promptUser: "alice"}
kubectl -n tier1 get service tier1-gateway \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Then follow [the instructions](./ingress_gateway#testing) but replace the value for `gateway-ip` with the address of the Tier-1 Gateway.
