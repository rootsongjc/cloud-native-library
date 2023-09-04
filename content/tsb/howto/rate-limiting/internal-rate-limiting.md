---
title: Enabling the Internal Rate Limiting Server
description: How to configure the Control Plane to use a Internal Rate Limiting Server
weight: 1
---

TSB comes with a rate limiting server component for every control plane cluster. By default this is disabled.

This section will only discuss installation procedures for the [internal mode](../rate_limiting#internal-rate-limiting), and not for installation of [external servers](../rate_limiting#external-rate-limiting).

## Configuration

The rate limit server can be enabled by explicitly specifying configuration for the `rateLimitServer` component in the [ControlPlane Operator API](../../refs/install/controlplane/v1alpha1/spec#controlplanecomponentset) or [Helm values](../../setup/helm/controlplane#installation) and applying it to the relevant control plane clusters.

The `rateLimitServer` requires a Redis backend to keep track of the rate limiting attribute counts and its details need to be included in the configuration.

Your Control Plane operator configuration may look like the example below:

```yaml
spec:
  ...
  components:
    rateLimitServer:
      domain: <domain>
      backend:
        redis:
          uri: <redis-uri>
```

Note the introduction of `rateLimitServer` in the `components` object.

The value for `domain` is used to group the storage metadata for rate limits. Specifying the same `domain` for all Control Planes will effectively allow you to configure global rate limiting across all clusters. If you use different values for `domain`, then the rate limiting effects are localized to only those clusters that are looking at the same `domain`. This assumes that the Control Planes are specifying the same Redis server.

We recommend that you specify the same domain only within clusters in the same geographic region, for example `us-east`.

The value for `redis-uri` is the server name and port of the Redis instance to use.
You are responsible in making sure that this URI is reachable from the control plane cluster(s).

## Redis Authentication

If your Redis database requires a password, you can either create the secret yourself:

```bash
kubectl -n istio-system create secret generic \
  redis-credentials \
  --from-literal=REDIS_AUTH=<password>
```

If you are running TSB >= 1.4.0, you can specify it in using the `--redis-password` argument in the [`tctl install manifest control-plane-secrets`](../../reference/cli/reference/install#tctl-install-manifest-control-plane-secrets) command to generate the appropriate secrets.

### TLS

If your Redis database supports in-transit encryption (TLS), you will need to enable TLS in
the Ratelimit Redis client by setting the `REDIS_TLS` key to `true` in the `redis-credentials` secret:

```bash
kubectl -n istio-system create secret generic \
  redis-credentials \
  --from-literal=REDIS_AUTH=<password>
  --from-literal=REDIS_TLS=true
```

If you are running TSB >= 1.5.0, you can specify it in using the `--redis-tls` argument in the [`tctl install manifest control-plane-secrets`](../../reference/cli/reference/install#tctl-install-manifest-control-plane-secrets) command to generate the appropriate secrets. You can also specify a custom CA certificate to validate the TLS connection using the `--redis-tls-ca-cert` argument as well as the Redis Client key and certificate (if client certificate authentication is enabled) using `--redis-tls-client-key` and `redis-tls-client-cert` respectively in the [`tctl install manifest control-plane-secrets`](../../reference/cli/reference/install#tctl-install-manifest-control-plane-secrets) command which will generate the appropriate `redis-credentials` secret. 

## Deploying The Server

Create a manifest using the example shown so far. Make sure to include all of the necessary fields for the Control Plane that has been omitted in the previous example.

If you are updating an existing Control Plane, you can use `kubectl get controlplane -n istio-system -o yaml` to obtain the current values.

Save the manifest into a file, e.g. `control-plane-with-rate-limiting.yaml`, and then apply it using `kubectl`:

```bash{promptUser: "alice"}
kubectl apply -f control-plane-with-rate-limiting.yaml
```

To check if the rate limit server is properly running in the cluster, execute the following command:

```bash{promptUser: "alice"}
kubectl get pods -n istio-system | grep ratelimit
ratelimit-server-864654b5b5-d77bq                       1/1     Running   2          2d1h
```
