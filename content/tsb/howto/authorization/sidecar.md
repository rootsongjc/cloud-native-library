---
title: Service to service authorization using external authorization
description: Shows how to use OPA to authorize service to service traffic
weight: 1
---

[Tetrate Service Bridge (TSB)](../../concepts/terminology##tetrate-service-bridge-tsb) provides authorization capabilities to authorize every HTTP request coming to a service from another service ("service-to-service" requests).

TSB supports *local* authorization by using JWT claims and *external* authorization which uses a service running externally to determine if a request should be allowed or denied. External authorization can be used on both gateways and workloads (through their sidecars).

You may decide to use an external authorization system if you have a separate in-house system or if you want to integrate with a third party authorization solution such as [Open Policy Agent (OPA)](https://www.openpolicyagent.org/) or [PlainID](https://www.plainid.com/).

This document describes how to configure service-to-service authorization using OPA as an example. OPA is an open source, general-purpose policy engine that provides a high-level declarative language that lets you specify policy as code. 

:::note OPA support
Tetrate does not offer support for OPA. Please look elsewhere if you need support for your use case. 
:::

Before you get started, make sure you: <br />
✓ Familiarize yourself with [TSB concepts](../../concepts/toc) <br />
✓ Install the TSB environment. You can use [TSB demo](../../setup/self_managed/demo-installation) for quick install <br />
✓ Completed TSB usage quickstart. This document assumes you already created a Tenant and are familiar with [Workspaces](../../concepts/terminology#workspace) and Config Groups. Also you need to configure `tctl` to your TSB environment.

## Overview

The following diagram shows the request and response flow when using an external authorization system to authorize service-to-service requests. 

![](../../assets/howto/service-to-service-authorization.png)

The desired result is to be able to send requests from the "Sleep workload" to "`httpbin` with OPA workload", and have these requests go through proper authorization checks by OPA. If a request from the "Sleep workload" is deemed to be unauthorized, a `403` Forbidden should be returned.

Note that while in this example you deploy OPA as sidecar within a pod, it is also possible to deploy OPA in a separate pod. If you do deploy OPA in a separate pod, you will need to investigate yourself what value you use when you specify the URL of the external system later.

## Setting up the services

### Setting up the `httpbin` service

You will first setup the "server side", which is the "httpbin with OPA workload" component in the diagram.

#### OPA policy

Before starting a service, you need to create the Kubernetes Secret which will contain OPA policy.

Below is an example of OPA policy that you will use to authorize requests. It will allow requests when:
* JWT token is present
* JWT token is not expired
* URL path that you want to access is specified in the JWT token

Create a file named [s2s-policy.rego](../../assets/howto/s2s-policy.rego) with the following content:

<CodeBlock>
  {policyRego}
</CodeBlock>
```

Then store the policy in Kubernetes as a Secret.

```
kubectl create namespace httpbin
kubectl create secret generic opa-policy -n httpbin --from-file s2s-policy.rego
```

#### Create httpbin deployment with OPA and Envoy sidecars

Once you have the policy, deploy the `httpbin` service that references the policy.
Create a file named [`s2s-httpbin-with-opa.yaml`](../../assets/howto/s2s-httpbin-with-opa.yaml) with the following content:

<CodeBlock className="language-yaml">
  {httpbinWithOpaYAML}
</CodeBlock>

Then apply it with kubectl:

```
kubectl label namespace httpbin istio-injection=enabled --overwrite=true
kubectl apply -n httpbin -f s2s-httpbin-with-opa.yaml
```

### Setting up the `sleep` service

Since you will be configuring service-to-service authorization, you need a service to act as a client to your `httpbin` service.

In this example you will deploy a service that does nothing but sleep, which maps to the "sleep workload" in the previous diagram. You will use `kubectl exec` later to issue HTTP requests to the `httpbin` service.

Create a file called [`s2s-sleep.yaml`](../../assets/howto/s2s-sleep.yaml) with the following content:

<CodeBlock className="language-yaml">
  {sleepYAML}
</CodeBlock>

Deploy this sleep service with kubectl:

```
kubectl create namespace sleep
kubectl label namespace httpbin istio-injection=enabled --overwrite=true
kubectl apply -n sleep -f s2s-sleep.yaml
```

## Testing

### Test with external authorization disabled

So far you have deployed the services but have not enabled external authorization. Thus requests from the `sleep` service to the `httpbin` service are not checked for authorization.

This can be seen by checking if sending HTTP requests from the `sleep` service results in a `200` OK.

To send a request from sleep service, identify the pod within your `sleep` service:

```
export SLEEP_POD=$(kubectl get pod -n sleep -l app=sleep -o jsonpath={.items..metadata.name})
```

Then send a request from this pod to the `httpbin` service, which should be reachable at `http://httpbin-with-opa.httpbin:8000`:

```
kubectl exec ${SLEEP_POD} -n sleep -c sleep  -- curl http://httpbin-with-opa.httpbin:8000/headers -s -o /dev/null -w "%{http_code}\n"
```

With external authorization disabled, the above command should display `200`.

### Test with external authorization enabled

To see how the external authorization works, you will have to create a workspace and security group.

#### Create the workspace

Create a file called [`s2s-workspace.yaml`](../../assets/howto/s2s-workspace.yaml) with the following content.

Please note that in the following example we assume that you have deployed your `httpbin` service in the `demo` cluster that you have created using the TSB demo install. If you are using another cluster, change the cluster name in the example accordingly.

<CodeBlock className="language-yaml">
  {workspaceYAML}
</CodeBlock>

Then apply it using tctl:

```
tctl apply -f s2s-workspace.yaml
```

#### Create the SecuritySettings

Once you have a workspace, you need to create a SecuritySettings for that workspace to enable external authorization.

Create a file called [`s2s-security-settings.yaml`](../../assets/howto/s2s-workspace.yaml) with the following content.

Please note that the `uri` points to a local address (`grpc://127.0.0.1:9191`) because in this example the OPA service is deployed in the same pod as a sidecar. If you have deployed OPA in a separate pod, you will need to change the value for `uri` accordingly.

<CodeBlock className="language-yaml">
  {securitySettingsYAML}
</CodeBlock>

Then apply it using tctl:

```
tctl apply -f s2s-security-settings.yaml
```

### Testing the authorization

Send a request to `httpbin` service again.

With the SecuritySettings applied, plain requests from the `sleep` service to `httpbin` service should fail with `403` Forbidden. 

```
kubectl exec ${SLEEP_POD} -n sleep -c sleep  -- curl http://httpbin-with-opa.httpbin:8000/headers -s -o /dev/null -w "%{http_code}\n"
```

The above command should display `403`.

In order to authorize the requests, you need to add a JWT in the requests. For this example, the raw JWT that we would like to attach to the requests looks like the following:

```
{
  "path": "L2hlYWRlcnM=",
  "nbf": 1500000000,
  "exp": 1900000000
}
```

The path claim has value `L2hlYWRlcnM=`, which is the base64 encoded form of the string `/headers`.

JWTs need to be passed via the `Authorization` header, which requires the entire JWT to be base64 encoded as show below. Save this into an environment variable:

```
export JWT_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwYXRoIjoiTDJobFlXUmxjbk09IiwibmJmIjoxNTAwMDAwMDAwLCJleHAiOjE5MDAwMDAwMDB9.9yl8LcZdq-5UpNLm0Hn0nnoBHXXAnK4e8RSl9vn6l98"
```

Finally, send a request with the above JWT token to the `httpbin` service, making sure that the request is pointing to the path `/headers`, which matches the claim in the JWT. This time around you should get a `200` OK.

```
kubectl exec ${SLEEP_POD} -n sleep -c sleep  -- curl http://httpbin-with-opa.httpbin:8000/headers -H "Authorization: Bearer $JWT_TOKEN" -s -o /dev/null -w "%{http_code}\n"
```

To check that requests to other paths are not authorized, try sending the following request, which is pointing to the path `/get`. The following command should result in a `403` Forbidden.

```
kubectl exec ${SLEEP_POD} -n sleep -c sleep  -- curl http://httpbin-with-opa.httpbin:8000/get -H "Authorization: Bearer $JWT_TOKEN" -s -o /dev/null -w "%{http_code}\n"
```
