---
title: Configuring Authz for proxy-protocol
description: How to configure generation of authorization policies at service port instead of workload port by default
draft: true
---

By default, the authorization policies are created using workload port of the server to match the traffic. However in some cases like when using curl with `--haproxy-protocol`, envoy proxy tries to match the incoming traffic at service port instead of the workload port. This document provides a way for users to allow that.

Before you get started, make sure you: <br />
✓ Familiarize yourself with [TSB concepts](../../concepts/toc) <br />
✓ Install the [TSB demo](../../setup/self_managed/demo-installation) environment <br />
✓ Deploy the [Istio Bookinfo](../../quickstart/deploy_sample_app) sample app <br />
✓ Create a [Tenant](../../quickstart/tenant) <br />
✓ Create a [Workspace](../../quickstart/workspace) <br />
✓ Create [Config Groups](../../quickstart/config_groups) <br />
✓ Configure [Permissions](../../quickstart/permissions) <br />
✓ Configure [Ingress Gateway](../../quickstart/ingress_gateway)

## Apply haproxy-protocol EnvoyFilter

Enable haproxy-protocol on listener. Create the following `haproxy-filter.yaml`
```
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: proxy-protocol
  namespace: bookinfo
spec:
  workloadSelector:
    labels:
      istio: ingressgateway
  configPatches:
  - applyTo: LISTENER
    patch:
      operation: MERGE
      value:
        listener_filters:
        - name: proxy_protocol
          typed_config:
            "@type": "type.googleapis.com/envoy.extensions.filters.listener.proxy_protocol.v3.ProxyProtocol"
            allow_requests_without_proxy_protocol: true
        - name: tls_inspector
          typed_config:
            "@type": "type.googleapis.com/envoy.extensions.filters.listener.tls_inspector.v3.TlsInspector"
```
Apply with `kubectl`
```bash
kubectl apply -f haproxy-filter.yaml
```

## Configure TSB Gateway

Update the `gateway.yaml` file to the following:

```
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
Metadata:
  organization: tetrate
  name: bookinfo-gw-ingress
  group: bookinfo-gw
  workspace: bookinfo-ws
  tenant: tetrate
spec:
  workloadSelector:
    namespace: bookinfo
    labels:
      app: tsb-gateway-bookinfo
  http:
    - name: bookinfo
      port: 443
      hostname: "bookinfo.tetrate.com"
      tls:
        mode: SIMPLE
        secretName: bookinfo-certs
      routing:
        rules:
          - route:
              host: "bookinfo/productpage.bookinfo.svc.cluster.local"
```

Apply with `tctl`
```bash
tctl apply -f gateway.yaml
```

## Configure Ingress Gateway object

To enable authorization on the service port instead of workload port update your `ingress.yaml`:

```
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: tsb-gateway-bookinfo
  namespace: bookinfo
spec:
  kubeSpec:
    service:
      type: LoadBalancer
      annotations:
        xcp.tetrate.io/authz-ports: "443" # This annotation prevents TSB translation for this port to workload port when creating istio authorization policies
```

Apply with `kubectl`
```bash
kubectl apply -f ingress.yaml
```

## Testing

To test if your ingress is working correctly with haproxy-protocol try the following curl curl request:

```bash
curl -k -s --connect-to bookinfo.tetrate.com:443:$GATEWAY_IP \
    "https://bookinfo.tetrate.com/productpage" | \
    grep -o "<title>.*</title>"
```
