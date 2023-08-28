---
title: Ingress Gateway
description: Configure an Ingress Gateway to allow external traffic for your demo app.
weight: 7
---

In this section, you will configure an Ingress Gateway to allow external traffic to your bookinfo application within the TSB environment.

### Prerequisites

Before proceeding, ensure that you have completed the following tasks:

- Familiarize yourself with TSB concepts.
- Install the TSB demo environment.
- Deploy the Istio Bookinfo sample application.
- Create a Tenant and Workspace.
- Create Config Groups.
- Configure Permissions.

### Create Ingress Gateway Object

You will create an Ingress Gateway object to enable external traffic for your bookinfo application.

#### Create `ingress.yaml`

Create a file named [`ingress.yaml`](../assets/quickstart/ingress.yaml) with the following content:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: tsb-gateway-bookinfo
  namespace: bookinfo
spec:
  selector:
    app: tsb-gateway-bookinfo
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
```

Apply the configuration using `kubectl`:

```bash{promptUser: alice}
kubectl apply -f ingress.yaml
```

Next, obtain the Ingress Gateway IP (or hostname for AWS) and store it in an environment variable:

```bash{promptUser: alice}
export GATEWAY_IP=$(kubectl -n bookinfo get service tsb-gateway-bookinfo -o jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}")
```

You can verify the assigned IP using:

```bash{promptUser: alice}
echo $GATEWAY_IP
```

### Configure TLS Certificate for Gateway

Now, set up a TLS certificate for your Gateway. If you have a TLS certificate ready for your domain, you can use it directly. Alternatively, use the provided script to create a self-signed certificate.

Save the following script as [`gen-cert.sh`](../assets/quickstart/gen-cert.sh), make it executable, and run it:

```bash{promptUser: alice}
chmod +x gen-cert.sh
./gen-cert.sh bookinfo bookinfo.tetrate.com .
```

Create Kubernetes secrets to store the certificates. Replace the paths with the actual paths to your key and certificate files:

```bash{promptUser: alice}{outputLines: 2-3}
kubectl -n bookinfo create secret tls bookinfo-certs \
    --key bookinfo.key \
    --cert bookinfo.crt
```

### Configure Ingress Gateway using UI

1. From the Workspaces list, click on "Gateway Groups."
2. Select the `bookinfo-gw` Gateway Group you created earlier.
3. Navigate to the **Gateway Settings** on the top tab to display the configuration view of the gateway.
4. Click the name of a configuration item to display its configurable fields. If the item has children, expand it by clicking the arrow on the left.
5. Configure the gateway using the following steps, making sure to save changes at the end to avoid validation errors:
   - Add a new Ingress Gateway with the default name `default-ingressgateway` and rename it to `bookinfo-gw-ingress`.
   - Set the Workload Selector to:
     - Namespace: `bookinfo`
     - Label: `app` with the value `tsb-gateway-bookinfo`
   - Under **HTTP Servers**, add a new HTTP Server:
     - Name: `bookinfo`
     - Port: `8443`
     - Hostname: `bookinfo.tetrate.com`
   - Configure **Server TLS Settings**:
     - TLS mode: SIMPLE
     - Secret name: `bookinfo-certs`
   - Under **Routing Settings**, add an HTTP Rule and configure the route:
     - Service host: `<namespace>/productpage.bookinfo.svc.cluster.local`
     - Port: `9080`
6. Save Changes.

### Configure Ingress Gateway using tctl

Create a [`gateway.yaml`](../assets/quickstart/gateway.yaml) file with the necessary configuration, then apply it using `tctl`:

```bash{promptUser: alice}
tctl apply -f gateway.yaml
```

### Test Ingress Traffic

To test if your ingress is working correctly, use the following `curl` command, replacing `$GATEWAY_IP` with the actual Ingress Gateway IP:

```bash{promptUser: alice}{outputLines: 2-3}
curl -k -s --connect-to bookinfo.tetrate.com:443:$GATEWAY_IP \
    "https://bookinfo.tetrate.com/productpage" | \
    grep -o "<title>.*</title>"
```

### Access the Bookinfo UI

To access the bookinfo UI, update your `/etc/hosts` file to make `bookinfo.tetrate.com` resolve to your Ingress Gateway IP:

```bash{promptUser: alice}
echo "$GATEWAY_IP bookinfo.tetrate.com" | sudo tee -a /etc/hosts
```

Now, you can visit https://bookinfo.tetrate.com/productpage in your browser. Note that due to the self-signed certificate, your browser might display a security warning. You can usually bypass this warning through the "Advanced" or "Continue" options in your browser.
