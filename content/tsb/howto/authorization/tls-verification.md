---
title: External Authz with TLS verification
description: Securing traffic between TSB and external authorization service.
weight: 3
---

TSB supports specifying [TLS or mTLS](../../refs/tsb/auth/v2/auth#clienttlssettings) parameters for securing communication to external auth servers. This document will show you how to configure TLS validation for an external authorization server by adding a CA certificate to the authorization configuration. 

Before you get started, make sure you: <br />
✓ Familiarize yourself with [TSB concepts](../../concepts/toc) <br />
✓ Install the TSB environment. You can use [TSB demo](../../setup/self_managed/demo-installation) for quick install<br />
✓ Completed [TSB usage quickstart](../../quickstart). This document assumes you already created Tenant and are familiar with Workspace and Config Groups. Also you need to configure tctl to your TSB environment.<br/>

The examples in this document will build on top of ["Configuring External Authorization in Ingress Gateways"](./ingress_gateway). Make sure to have completed that document before proceeding, and note that you will be working on the namespace `httpbin`

## Create TLS certificate

To enable TLS for Ingress Gateway to authorization service traffic, you must have a TLS certificate. This document assumes you already have TLS certificates which usually include server certificate and private key along with the CA as root certificate that will be used by the client. This document use following files

1. `authz.crt` as  server certificate
2. `authz.key` as certificate private key
3. `authz-ca.crt` as CA certificate

If you decide to use other file names, please replace them accordingly throughout the examples below.

:::note self signed certificate
For the purpose of example, you can create self signed certificates using this [scripts](../../quickstart/ingress_gateway#certificate-for-gateway).
:::note

Once you have the files, create Kubernetes secret using server certificate and private key.

```bash
kubectl create secret tls -n httpbin opa-certs \
  --cert=authz.crt \
  --key=authz.key
```

You will also need the CA certificate in to validate the TLS connection.
Create a `ConfigMap` named `authz-ca` that will contain the CA certificate:

```bash
kubectl create configmap -n httpbin authz-ca \
  --from-file=authz-ca.crt
```

## Deploy Authorization Service with TLS certificate

Follow the instructions in ["Installing Open Policy Agent in TSB"](../../reference/samples/opa#terminating-tls) to setup an instance OPA with a sidecar proxy that terminates TLS. 


## Modify Ingress Gateway

You will need to add CA certificate to the Ingress Gateway to validate the TLS connection.
Create a file named `httpbing-ingress-gateway.yaml` with the following contents. This manifest adds overlays to read the `ConfigMap` named `authz-ca` that contains the CA certificates to the Ingress Gateway deployment.

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: httpbin-ingress-gateway
  namespace: httpbin
spec:
  kubeSpec:
    service:
      type: LoadBalancer
    overlays:
    - apiVersion: apps/v1
      kind: Deployment
      name: httpbin-ingress-gateway
      patches:
      - path: spec.template.spec.volumes[-1]
        value:
          name: authz-ca
          configMap:
            name: authz-ca
      - path: spec.template.spec.containers.[name:istio-proxy].volumeMounts[-1]
        value:
          name: authz-ca
          mountPath: /etc/certs
          readOnly: true
```

Apply with kubectl:

```bash
kubectl apply -f httpbin-ingress-gateway.yaml
```

Then update the Ingress Gateway configuration to enable TLS validation:

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
Metadata:
 organization: tetrate
 name: httpbin-ingress-gateway
 group: httpbin
 workspace: httpbin
 tenant: tetrate
spec:
 workloadSelector:
   namespace: httpbin
   labels:
     app: httpbin-ingress-gateway
 http:
   - name: httpbin
     port: 443
     hostname: "httpbin.tetrate.com"
     tls:
      mode: SIMPLE
      secretName: httpbin-certs
     routing:
       rules:
         - route:
             host: "httpbin/httpbin.httpbin.svc.cluster.local"
             port: 8080
     authorization:
       external:
         tls:
           mode: SIMPLE
           files:
             caCertificates: /etc/certs/authz-ca.crt
         uri: grpcs://opa.opa.svc.cluster.local:18443
```

Apply with tctl

```bash
tctl apply -f ext-authz-ingress-gateway-tls.yaml
```

## Testing

You can use the same testing steps as shown in ["Configuring External Authorization in Ingress Gateways"](./ingress_gateway#testing)


