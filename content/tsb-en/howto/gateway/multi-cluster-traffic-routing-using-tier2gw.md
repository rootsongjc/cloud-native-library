---
title: Multi-cluster traffic routing using Tier-2 gateway
description: Shift traffic between clusters using a Tier-2 gateway
weight: 4
---

Tier-2 gateway or IngressGateway configures a workload to act as a gateway for traffic entering the mesh. The ingress gateway also provides basic API gateway functionalities such as JWT token validation and request authorization.

In this guide, you'll: <br />
✓ Deploy [bookinfo application](https://istio.io/latest/docs/examples/bookinfo/) split in two different clusters configured as Tier-2, having `productpage` in one and reviews, details and rating in the other.<br />

Before you get started, make sure that you: <br />
✓ You have already deployed `productpage` in `cluster 1` and details, ratings and reviews in `cluster 2`. For this demo we are assuming you have bookinfo deployed and configured in TSB. <br />
✓ The control planes in all components need to be sharing the same [root of trust](https://istio.io/latest/docs/tasks/security/cert-management/plugin-ca-cert/). <br />

## Scenario

In this scenario we will have two control plane clusters configured as Tier-2 (`tsb-tier2gcp1` and `tsb-tier2gcp2`). We are going to deploy bookinfo in both Tier-2 clusters, `tsb-tier2gcp1` will have `productpage` installed and `tsb-tier2gcp2` will have reviews, details and ratings installed.

So the scenario for Tier-2 clusters (once configured) should look like the following:

![](../../assets/howto/bookinfo-tier2-tier2-diagram.png)

Make sure that both clusters are sharing the same root of trust. You must populate the `cacerts` with the correct certificates before deploying the Control Planes in both clusters. Please refer to the Istio docs on [Plugin CA Certificates](https://istio.io/latest/docs/tasks/security/cert-management/plugin-ca-cert/) for more detail.

## Configuration
### Configure TSB objects
For this example, it is assumed that you already have an Organization called `tetrate`, a tenant called `test`, and two control plane clusters configured with Tier-2 gateways.

First, create the workspace and the gateway group:
```yaml
apiversion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: tetrate
  tenant: test
  name: bookinfo
spec:
  displayName: bookinfo app
  description: Workspace for the bookinfo app
  namespaceSelector:
    names:
      - "*/bookinfo-front"
      - "*/bookinfo-back"
---
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
  organization: tetrate
  tenant: test
  workspace: bookinfo
  name: bookinfo-gw
spec:
  configMode: BRIDGED
  namespaceSelector:
    names:
      - "*/bookinfo-front"
      - "*/bookinfo-back"
```

And apply it:
```bash
tctl apply -f mgmt-bookinfo.yaml
```

In the example above, a wild-card ("*") notation is used to select the namespaces `bookinfo-front` and `bookinfo-back` across all onboarded clusters. If you would like to target a specific cluster, you can do so by replacing the "*" with the cluster name that you would like to use.

### Deploy the ingress gateways
Now, if the namespaces are not created, we will create them and enable sidecar injection in both. In `tsb-tier2gcp1` we will create `bookinfo-front` namespace and deploy `productpage`, and in `tsb-tier2gcp2` we will create `bookinfo-back` namespace and deploy reviews, ratings and details.

Create a certificate in the `bookinfo-front` so that services in the namespace can be exposed using HTTPS.

```bash
kubectl create secret tls bookinfo-cert -n bookinfo-front --cert cert.pem --key key.pem
```

Once this is done,  create a `IngressGateway`  deployment in each cluster:
```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: bookinfo-front-gw
  namespace: bookinfo-front
spec:
  kubeSpec:
    service:
      ports:
      - name: mtls
        port: 15443
        targetPort: 15443
      - name: https
        port: 443
        targetPort: 8443
      - name: http2
        port: 80
        targetPort: 8080
      type: LoadBalancer
---
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: bookinfo-back-gw
  namespace: bookinfo-back
spec:
  kubeSpec:
    service:
      ports:
      - name: mtls
        port: 15443
        targetPort: 15443
      - name: https
        port: 443
        targetPort: 8443
      - name: http2
        port: 80
        targetPort: 8080
      type: LoadBalancer
```

And apply them:
```bash
kubectl apply -f bookinfo-<front|back>-ingress.yaml
```

Obtain the IP address for both services:
```bash
FRONT=$(kubectl get svc -n bookinfo-front bookinfo-front-gw -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
BACK=$(kubectl get svc -n bookinfo-back bookinfo-back-gw -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

And configure the DNS to reach using the following configuration:
```text
FRONT → bookinfo.tetrate.com
BACK → bookinfo-back.tetrate.com (could be the name you prefer).
```

At this point it is important to add the following lines inside `productpage` deployment spec for the deployment to be able to know where details and reviews are hosted:
```yaml
        env:
        - name: DETAILS_HOSTNAME
          value: bookinfo-back.tetrate.com:80
        - name: REVIEWS_HOSTNAME
          value: bookinfo-back.tetrate.com:80
```
:::note
With the default `productpage` image this won't work because the default port is hard coded to 9080, this is just an example, but you can modify it to get also the port and not only the hostname.
:::

### Configure Ingress Gateway Routing
Now we can configure the deployed ingress gateways by creating the Tier-2 gateway configuration. This can be done by creating an `IngressGateway` gateway resource.

:::note
Notice that the `apiVersion` is different from the previous one, because the first is to install the ingress gateway, and the second is to configure the gateway and virtual service using BRIDGED API.
:::

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
  organization: tetrate
  tenant: test
  workspace: bookinfo
  group: bookinfo-gw
  name: bookinfo-front-gw
spec:
  workloadSelector:
    namespace: bookinfo-front
    labels:
      app: bookinfo-front-gw
  http:
  - name: bookinfo
    port: 443
    hostname: bookinfo.tetrate.com
    tls:
      mode: SIMPLE
      secretName: bookinfo-cert
    routing:
      rules:
      - route:
          host: bookinfo-front/productpage.bookinfo-front.svc.cluster.local
          port: 9080
---
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
  organization: tetrate
  tenant: test
  workspace: bookinfo
  group: bookinfo-gw
  name: bookinfo-back-gw
spec:
  workloadSelector:
    namespace: bookinfo-back
    labels:
      app: bookinfo-back-gw
  http:
  - name: bookinfo-back
    port: 80
    hostname: bookinfo-back.tetrate.com
    routing:
      rules:
      - match:
        - uri:
            prefix: /details
        route:
          host: bookinfo-back/details.bookinfo-back.svc.cluster.local
          port: 9080
      - match:
        - uri:
            prefix: /reviews
        route:
          host: bookinfo-back/reviews.bookinfo-back.svc.cluster.local
          port: 9080
```

### Verification
With this configuration, `bookinfo.tetrate.com` using HTTPS is exposed using HTTPS, and `bookinfo-back.tetrate.com` using HTTP.

At this point you can test if it works by executing the following:
```bash
$ curl -I https://bookinfo.tetrate.com/productpage
```

:::note
The `productpage` service is configured to send traffic to the details and reviews services through port 80. However, after we have configured the TSB objects, there's a service entry created that will redirect this port 80 to 15443 (which is configured for mTLS), and also a destination rule to use mTLS.
:::

You can see both by running the command below, and looking at both bookinfo related service entries and destination rules:
```bash
kubectl get dr,se -n xcp-multicluster
```
