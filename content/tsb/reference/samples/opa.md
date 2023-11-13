---
title: Installing Open Policy Agent
description: How to Install Open Policy Agent
---

[Open Policy Agent](https://www.openpolicyagent.org/) (OPA) is an open source, general-purpose policy engine that provides a high-level declarative language that lets you specify policy as code. OPA also offers simple APIs to offload policy decision-making from your software. 

This document describes a simplified version of the configuring OPA in TSB, to accompany sections where it is used as the external authorization (`ext-authz`) service. In your actual application there may be differences that require tweaking.

:::note OPA support
Tetrate does not offer support for OPA. Please look elsewhere if you need support for your use case.
:::

For more detailed explanation of the configurations described below, please refer to [the official documentation](https://www.openpolicyagent.org/docs/latest).

## Preparing a Policy

OPA requires a policy file written using [OPA's policy language](https://www.openpolicyagent.org/docs/latest/policy-language/) to decide if requests should be authorized. Since the actual policy will differ significantly from example to example, details on how to write this file will not be covered in this document. Please refer to [the documents in OPA website](https://www.openpolicyagent.org/docs/latest) for details.

One thing to note is the package name specified in the policy file. If you have a policy file that has the following package declaration, you will be using the value `helloworld.authz` in the container configuration later.

```
package helloworld.authz
```

### Example: Policy with Basic Authentication

This example shows a policy that only allows users `alice` and `bob` to be authenticated via Basic Authentication. If the user is authorized, the user name will be stored in the HTTP header named `x-user`.

```
package example.basicauth

default allow = false

# username and password database
user_passwords = {
    "alice": "password",
    "bob": "password"
}

allow = response {
    # check if password from header is same as in database for the specific user
    basic_auth.password == user_passwords[basic_auth.user_name]
    response := {
      "allowed": true,
      "headers": {"x-user": basic_auth.user_name}
    }
}

basic_auth := {"user_name": user_name, "password": password} {
    v := input.attributes.request.http.headers.authorization
    startswith(v, "Basic ")
    s := substring(v, count("Basic "), -1)
    [user_name, password] := split(base64url.decode(s), ":")
}
```

### Storing the Policy in Kubernetes

Assuming your policy is stored in a file named `policy.rego`, you will need to store the file in a Kubernetes Secret or a ConfigMap.

To create a Secret, execute the following command, replacing `namespace` with the appropriate value:

```bash
kubectl create secret generic opa-policy -n <namespace> \
  --from-file policy.rego
```

If you are using a ConfigMap, execute the following command in the same manner:

```bash
kubectl create configmap opa-policy -n <namespace> \
  --from-file policy.rego
```

The name of the resource (`opa-policy`) may be changed if necessary.

## Basic Deployment

The following manifest shows an example that can be used to deploy an OPA service, and an OPA agent with mostly default settings. Remember to replace the `package` and `namespace` in the configuration with the proper values.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: opa
  namespace: <namespace>
spec:
  selector:
    app: opa
  ports:
    - name: grpc
      protocol: TCP
      port: 9191
      targetPort: 9191
---
kind: Deployment
apiVersion: apps/v1
metadata:
  name: opa
  namespace: <namespace>
spec:
  replicas: 1
  selector:
    matchLabels:
      app: opa
  template:
    metadata:
      labels:
        app: opa
      name: opa
    spec:
      volumes:
        - name: opa-policy
          secrets:
            secretName: opa-policy
      containers:
        image: openpolicyagent/opa:latest-envoy
        name: opa
        securityContext:
          runAsUser: 1111
        args:
          - "run"
          - "--server"
          - "--addr=localhost:8181"
          - "--diagnostic-addr=0.0.0.0:8282"
          - "--set=plugins.envoy_ext_authz_grpc.addr=:9191"
          - "--set=plugins.envoy_ext_authz_grpc.query=data.<package>.allow"
          - "--set=decision_logs.console=true"
          - "--ignore=.*"
          - "/policy/policy.rego"
        livenessProbe:
          httpGet:
            path: /health?plugins
            scheme: HTTP
            port: 8282
          initialDelaySeconds: 5
          periodSeconds: 5
        readinessProbe:
          httpGet:
            path: /health?plugins
            scheme: HTTP
            port: 8282
          initialDelaySeconds: 5
          periodSeconds: 5
        volumeMounts:
        - readOnly: true
          mountPath: /policy
          name: opa-policy
```

Assuming you have saved the above manifest in a file named `opa.yaml`, execute the following command to deploy:

```bash
kubectl apply -f opa.yaml
```

## Terminating TLS

In order to secure communications between the ext-authz services (where we use OPA as example) and its clients (gateways and sidecars), you can enable TLS verification. As example, here we will use the Envoy sidecar proxy to terminate TLS also verify TLS certificate coming from the client.

:::note
The settings in the following samples are for testing purposes only. Please consult your security requirements and craft a different configuration for your production use case
:::

### Prepare Certificate

Either use a certificate that was provided by your administrators, or use a self-signed certificate for testing. You may be able to leverage [the instructions in the quickstart](../../quickstart/ingress_gateway#certificate-for-gateway) to create a self-signed certificate.

If you have not already done so, create the Secret to contain the certificates. The secret will be named `opa-certs`, and will be used later. Assuming you have generated the files `opa.key` and `opa.crt`, execute the command below to create the Secret.  Replace the value for `namespace` with an appropriate value.

```bash
kubectl -n <namespace> create secret tls opa-certs \
  --key opa.key \
  --cert opa.crt
```

### Create Envoy Configuration File

Create a file named `config.yaml` with the following contents.  Replace the value for `namespace` with an appropriate value. This configuration assumes that the admin port is at port `10250`, an "insecure" `grpc` at port `18080`, and a `grpc` port with TLS termination at port `18443`.

```yaml
admin:
  address:
    socket_address:
      address: 127.0.0.1
      port_value: 10250

static_resources:
  listeners:
    # Insecure GRPC listener
    - name: grpc-insecure
      address:
        socket_address:
          address: 0.0.0.0
          port_value: 18080
      access_log:
        - name: envoy.access_loggers.file
          typed_config:
            "@type": type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog
            path: /dev/stdout
      filter_chains:
        - filters:
            - name: envoy.filters.network.tcp_proxy
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
                cluster: grpc_rlserver
                stat_prefix: grpc_insecure

    # Secured by TLS
    - name: grpc-simple-tls
      address:
        socket_address:
          address: 0.0.0.0
          port_value: 18443
      access_log:
        - name: envoy.access_loggers.file
          typed_config:
            "@type": type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog
            path: /dev/stdout
      filter_chains:
        - filters:
            - name: envoy.filters.network.tcp_proxy
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
                cluster: grpc_rlserver
                stat_prefix: grpc_simple_tls
          transport_socket:
            name: envoy.transport_sockets.tls
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.DownstreamTlsContext
              common_tls_context:
                tls_certificates:
                  - certificate_chain: { filename: /certs/tls.crt }
                    private_key: { filename: /certs/tls.key }
```

Create a `ConfigMap` to store the configuration in Kubernetes. Replace the value for `namespace` with an appropriate value.

```bash
kubectl create configmap -n <namespace> opa-proxy \
  --from-file=config.yaml
```

### Deploy Service

Create a file named `opa-tls.yaml` with the following contents. Replace the value for `namespace` with an appropriate value.

```yaml
apiVersion: v1
kind: Service
metadata:
 name: opa-tls
 namespace: <namespace>
spec:
 selector:
   app: opa-tls
 ports:
   - name: http
     port: 8080
     targetPort: 8080 # Doesn't go through Envoy
   - name: grpc-insecure
     port: 18080
     targetPort: 18080
   - name: grpc-tls
     port: 18443
     targetPort: 18443
---
apiVersion: apps/v1
kind: Deployment
metadata:
 name: opa-tls
 namespace: <namespace>
spec:
 replicas: 1
 selector:
   matchLabels:
     app: opa-tls
 template:
   metadata:
     labels:
       app: opa-tls
     name: opa-tls
   spec:
     containers:
     - name: envoy-proxy
       image: envoyproxy/envoy-alpine:v1.18.4
       imagePullPolicy: Always
       command:
         - "/usr/local/bin/envoy"
       args:
         - "--config-path /etc/envoy/config.yaml"
         - "--mode serve"
       ports:
       - name: grpc-plaintext
         containerPort: 18080
       - name: grpc-tls
         containerPort: 18443
       volumeMounts:
         - name: proxy-config
           mountPath: /etc/envoy
         - name: proxy-certs
           mountPath: /certs
     - name: opa
       image: openpolicyagent/opa:latest-envoy
       securityContext:
         runAsUser: 1111
       ports:
       - containerPort: 8181
       args:
       - "run"
       - "--server"
       - "--addr=localhost:8181"
       - "--diagnostic-addr=0.0.0.0:8282"
       - "--set=plugins.envoy_ext_authz_grpc.addr=:9191"
       - "--set=plugins.envoy_ext_authz_grpc.path=demo/authz/allow"
       - "--set=decision_logs.console=true"
       - "--ignore=.*"
       - "/policy/policy.rego"
       livenessProbe:
         httpGet:
           path: /health?plugins
           scheme: HTTP
           port: 8282
         initialDelaySeconds: 5
         periodSeconds: 5
       readinessProbe:
         httpGet:
           path: /health?plugins
           scheme: HTTP
           port: 8282
         initialDelaySeconds: 5
         periodSeconds: 5
       volumeMounts:
         - readOnly: true
           mountPath: /policy
           name: opa-policy
     volumes:
     - name: opa-policy
       configMap:
         name: opa-policy
     - name: proxy-certs
       secret:
         secretName: opa-certs
     - name: proxy-config
       configMap:
        name: opa-proxy
```

Apply `opa-tls.yaml` using kubectl:

```bash
kubectl apply -f opa-tls.yaml
```

Once the above deployment is ready, you should set up the client side appropriately to use `grpcs://opa-tls.<namespace>.svc.cluster.local:18443`. 
