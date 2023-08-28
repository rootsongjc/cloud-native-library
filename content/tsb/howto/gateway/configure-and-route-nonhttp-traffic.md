---
title: Configure and route HTTP, non-HTTP (multi-protocol) and multi-port service traffic in TSB
description: Guide to configure HTTP and non-HTTP (multi-port, multi-protocol) servers at the gateway.
weight: 9
---

This how-to document will show you how to configure non-HTTP servers with TSB. After
reading this document you should be familiar with the usage of the TCP section in
`IngressGateway` and `Tier1Gateway` API.

## Summary
Workflow is exactly the same as configuring HTTP servers in `IngressGateway` and
`Tier1Gateway`. However, multi-port services are supported for non-HTTP. 

Before you get started, make sure you: <br />
✓ Familiarize yourself with [TSB concepts](../../concepts/toc) <br />
✓ Familiarize yourself with [onboarding clusters](../../setup/self_managed/onboarding-clusters) <br />
✓ Create a [Tenant](../../quickstart/tenant) <br />

## Setup
* Four clusters with TSB installed - Management plane, Tier-1 and Tier-2 edge clusters.
* In Tier-2 clusters, deploy Tier-2 gateways in `echo` namespace
* In Tier-1 cluster, deploy Tier-1 gateway in `tier1` namespace
* In both the gateways, the ports `8080` and `9999` should be available (for simplicity, we consider the service
  and the target ports to be the same). For installing gateways, see [here](../../quickstart/ingress_gateway)
* Deploy apps in Tier-2 cluster which work with HTTP and non-HTTP traffic. In this demo, you will deploy
  applications from the Istio's samples directory into the echo namespace.
    * `helloworld` is used for HTTP traffic. [Manifests here](https://github.com/istio/istio/blob/master/samples/helloworld/helloworld.yaml)
    * `tcp-echo` is used for non-HTTP traffic. [Manifests here](https://github.com/istio/istio/blob/master/samples/tcp-echo/tcp-echo.yaml)
* Make sure you have the required privileges to deploy the gateway configurations.

## TSB configuration

### Configuring workspace and groups
First create the workspace. Here, we assume that the clusters were onboarded as `cluster-0`, `cluster-1`,
`cluster-2` and `cluster-3`. It is also assumed that `cluster-3` is Tier-1, `cluster-0` has TSB management
plane installed. 
```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
 name: tcp-http-demo
 organization: tetrateio
 tenant: tetrate
spec:
 namespaceSelector:
   names:
     - "cluster-1/echo"
     - "cluster-2/echo"
     - "cluster-3/tier1"
```

Separate groups are configured for Tier-1 and Tier-2 gateways
```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
 name: tcp-http-test-t2-group
 organization: tetrateio
 tenant: tetrate
 workspace: tcp-http-demo
spec:
 namespaceSelector:
   names:
   - "cluster-1/echo"
   - "cluster-2/echo"
---
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
 name: tcp-http-test-t1-group
 organization: tetrateio
 tenant: tetrate
 workspace: tcp-http-demo
spec:
 configMode: BRIDGED
 namespaceSelector:
   names:
   - "cluster-3/tier1"
```
### Provisioning certificates and keys for the gateways
You have to create two secrets in the namespaces where gateway workloads are deployed
* `hello-tlscred` for the Helloworld application
* `echo-tlscred` for the TCP-echo application

You can provision certificates with tools like `openssl` and create secrets as follows.
```bash
# Create secrets for the helloworld application. Here the certificate and
# the keys are provisioned in helloworld.crt and helloworld.key
kubectl --context=<kube-cluster-context> -n <gateway-ns> create secret tls hello-tlscred \
          --cert=helloworld.crt --key=helloworld.key

# Create secrets for the tcp-echo application
kubectl --context=<kube-cluster-context> -n <gateway-ns> create secret tls echo-tlscred \
          --cert=echo.crt --key=echo.key
```

### Configuring Ingress Gateway at Tier-2 clusters
A few notes
* For the configuration of port 8080, TLS is required and the hostnames must be different. Otherwise, it is an error.
* The credentials are stored as secret in the namespace where gateway workloads are running. In Tier-2, it is the `echo` namespace and in Tier-1 it is the `tier1` namespace.

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
 name: tcp-http-t2-gateway
 organization: tetrateio
 tenant: tetrate
 workspace: tcp-http-demo
 group: tcp-http-test-t2-group
spec:
 workloadSelector:
   namespace: echo
   labels:
     app: tsb-gateway-echo
 http:
 - name: http-hello
   port: 8080
   hostname: hello.tetrate.io
   tls:
     mode: SIMPLE
     secretName: hello-tlscred
   routing:
     rules:
     - route:
         host: echo/helloworld.echo.svc.cluster.local
         port: 5000
 tcp:
 # echo.tetrate.io:8080 receives non-HTTP traffic. There
 # is also hello.tetrate.io:8080 receiving HTTP traffic on
 # this port. To distinguish between the two services, you
 # need to have different hostnames with TLS so that the
 # clients can use different SNI to distinguish between them.
 # This is the "multi-protocol"/"multiple traffic type" part.
 - name: tcp-echo
   port: 8080 # Same port as the previous HTTP server,
              # but different hostname.
   hostname: echo.tetrate.io
   tls:
     mode: SIMPLE
     secretName: echo-tlscred
   route:
     host: echo/tcp-echo.echo.svc.cluster.local
     port: 9000

 # There is already a service called echo.tetrate.io defined
 # port 8080. There can be another TCP service with the same
 # hostname on a different port. This is the "multi-port" part.
 - name: tcp-echo-2
   port: 9999
   hostname: echo.tetrate.io
   route:
     host: echo/tcp-echo.echo.svc.cluster.local
     port: 9001
```

### Configuring Tier-1 gateway
The host:port defined here should match exactly with the host:port and the traffic type should
match exactly with the ones defined in `IngressGateway` before
```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Tier1Gateway
metadata:
 name: tcp-http-t1-gateway
 organization: tetrateio
 tenant: tetrate
 workspace: tcp-http-demo
 group: tcp-http-test-t1-group
spec:
 workloadSelector:
   namespace: tier1
   labels:
     app: tsb-gateway-tier1
 externalServers:
 # This matches with the HTTP server hello.tetrate.io:8080
 # defined in the Tier-2 gateway configuration 
 - name: http-hello
   hostname: hello.tetrate.io
   port: 8080
   tls:
     mode: SIMPLE
     secretName: hello-tlscred
 tcpExternalServers:
 # This matches with echo.tetrate.io:8080. The names need not
 # be the same between the configs, but hostname must match.
 - name: tcp-echo
   hostname: echo.tetrate.io
   port: 8080
   tls:
     mode: SIMPLE
     secretName: echo-tlscred

 # This matches with echo.tetrate.io:9999 in Tier-2 configs.
 - name: tcp-echo-2
   hostname: echo.tetrate.io
   port: 9999
```

## Routing traffic between clusters

### North-south (From Tier-1 to Tier-2 clusters)
First, find out the external IP address of the Tier-1 gateway and save it in `TIER1_IP` variable
```bash
$ export TIER1_IP=<tier1-gateway-ip>
```
#### Routing HTTPS traffic
```bash
$ curl -svk --resolve hello.tetrate.io:8080:$TIER1_IP https://hello.tetrate.io:8080/hello
```
**NOTE**: Don't use `-k` flag unless it is for testing purposes. It skips server certificate verification and is insecure

#### Routing non-HTTP traffic
1. TLS traffic - There could be some warnings related to the server certificates. As this is a demo, they
can be ignored.
```bash
$ openssl s_client -connect $TIER1_IP:8080 -servername echo.tetrate.io
```

2. Plain TCP traffic
```bash
$ echo hello | nc -v $TIER1_IP 9999
```

### East-west (Between Tier-2 clusters)
DNS names defined in the `hostname` field is used for routing east-west traffic. Exec into an Istio sidecar-injected pod from where you would like to send the traffic and run `nc` for non-HTTP (but TCP) traffic. No need to initiate TLS here as TLS origination is done by the sidecar. 

```bash
kubectl -n echo exec -it <pod-name> -c app -- sh -c "echo hello | nc -v echo.tetrate.io 8080"
kubectl -n echo exec -it <pod-name> -c app -- sh -c "echo hello | nc -v echo.tetrate.io 9999"
kubectl -n echo exec -it <pod-name> -c app -- curl -sv hello.tetrate.io:8080
```
