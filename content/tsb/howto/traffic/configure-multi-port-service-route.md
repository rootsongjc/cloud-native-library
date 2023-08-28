---
title: Configure ServiceRoute for (multi-port, multi-protocol) services
description: Guide to configure HTTP and non-HTTP (multi-port, multi-protocol) routes to services.
weight: 5
---

This how-to document will show you how to configure routes to services exposing multiple
ports through a single `ServiceRoute` config.

## Scenario

Consider a backend service named `tcp-echo` which exposes two ports, `9000` and `9001` over TCP. The service
has two versions `v1` and `v2` and traffic splitting needs to be achieved between these two versions for both 
ports. In order to achieve this, a `ServiceRoute` with port level settings needs to be configured.

## Deploy the `tcp-echo` Service

Deploy the `tcp-echo` application from the Istio's samples directory into the `echo` namespace by
installing [these manifests](https://github.com/istio/istio/blob/master/samples/tcp-echo/tcp-echo-services.yaml).

## TSB configuration

### Deploy a Workspace and Traffic Group

Apply the following configuration to create a Workspace and a Traffic Group.

:::note
The examples assume that you have already created an organization named `tetrateio`
and a tenant named `tetrate`.
:::

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
 name: tcp-multiport-ws
 organization: tetrateio
 tenant: tetrate
spec:
 namespaceSelector:
   names:
     - "*/echo"
---
apiVersion: traffic.tsb.tetrate.io/v2
kind: Group
metadata:
 name: tcp-multiport-tg
 organization: tetrateio
 tenant: tetrate
 workspace: tcp-multiport-ws
spec:
 configMode: BRIDGED
 namespaceSelector:
   names:
   - "*/echo"
```

### Deploy the `ServiceRoute`

Apply the following configuration to create the `ServiceRoute` that configures both ports.

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: ServiceRoute
metadata:
  name: tcp-multiport-service-route
  organization: tetrateio
  tenant: tetrate
  workspace: tcp-multiport-ws
  group: tcp-multiport-tg
spec:
  service: "echo/tcp-echo.svc.cluster.local"
  portLevelSettings:
    - port: 9000
      trafficType: TCP
    - port: 9001
      trafficType: TCP
  subsets:
    - name: v1
      labels:
        version: v1
      weight: 80
    - name: v2
      labels:
        version: v2
      weight: 20
```

## Testing

To verify that the routes have been set successfully, try curling several times to the `echo` pod. The request will
be forwarded to the `v1` pod most of the times because of the `80:20` weight ratio set between `v1:v2`.

For testing TCP traffic, use `nc` instead.
```bash
kubectl -n echo exec -it <pod-name> -c <container-name> -- curl -sv tcp-echo.svc.cluster.local:9000
kubectl -n echo exec -it <pod-name> -c <container-name> -- sh -c "echo hello | nc -v tcp-echo.svc.cluster.local:9001"
```
