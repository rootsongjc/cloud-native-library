---
title: Migrating VM Monoliths to your cluster
description: How-to migrate a portion of a VM workload to a cluster, and split traffic between VM and cluster.
weight: 2
---

In this how-to you'll learn how to migrate a portion of a VM "monolith" workload
to a cluster and split traffic between your VM and cluster.

In this example, the server running on the VM will be treated as a "monolithic"
application. The same steps can be followed if the VM was calling out to other
VMs. You'd just have to make sure the VMs being called out to were resolvable
and or reachable from your cluster.

Before you start: <br />
✓ [Install the TSB management plane](../../setup/self_managed/management-plane-installation) <br />
✓ Onboarded a [cluster](../../setup/self_managed/onboarding-clusters)<br />
✓ [Install the data plane operator](../../concepts/operators/data_plane) <br />
✓ Provision a VM to run in a TSB workload *(this guide assumes Ubuntu 20.04)*.


The first step, is to install Docker

```bash
sudo apt-get update
sudo apt-get -y install docker.io
```

Then, run the httpbin server and test that it works.

```bash{outputLines: 2-4,6-9,10-12}
sudo docker run -d \
    --name httpbin \
    -p 127.0.0.1:80:80 \
    kennethreitz/httpbin
curl localhost/headers
{
    "headers": {
        "Accept": "*/*", 
        "Host": "localhost", 
        "User-Agent": "curl/7.68.0"
    }
}
```
Next onboard the VM into your cluster following the [VM onboarding docs](../../setup/workload_onboarding/onboarding-vms). 
Create the following service account in your cluster for use by your VM.

```bash{outputLines: 4-9,10-11}
kubectl create namespace httpbin
kubectl label namespace httpbin istio-injection=enabled
cat <<EOF | kubectl apply -f-
apiVersion: v1
kind: ServiceAccount
metadata:
  name: httpbin
  labels:
    account: httpbin
  namespace: httpbin
EOF
```

Adjust the WorkloadEntry you installed as part of the VM onboarding for your
workload. Here is an example for httpbin.

```yaml
apiVersion: networking.istio.io/v1beta1
kind: WorkloadEntry
metadata:
  name: httpbin-vm
  namespace: httpbin
  annotations:
    sidecar-bootstrap.istio.io/ssh-host: <ssh-host>
    sidecar-bootstrap.istio.io/ssh-user: istio-proxy
    sidecar-bootstrap.istio.io/proxy-config-dir: /etc/istio-proxy
    sidecar-bootstrap.istio.io/proxy-image-hub: docker.io/tetrate
    sidecar-bootstrap.istio.io/proxy-instance-ip: <proxy-instance-ip>
spec:
  address: <vm-address>
  labels:
    class: vm
    app: httpbin
    version: v1
  serviceAccount: httpbin
  network: <vm-network-name>
```

Modify the Sidecar resource, and make sure that you have any necessary firewall
rules set up to allow traffic to your VM.

```yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: httpbin-no-iptables
  namespace: httpbin
spec:
  egress:
  - bind: 127.0.0.2
    hosts:
    - ./*
  ingress:
  - defaultEndpoint: 127.0.0.1:80
    port:
      name: http
      number: 80
      protocol: HTTP
  workloadSelector:
    labels:
      app: httpbin
      class: vm
```

In your cluster, add the following to configure traffic flow from your cluster
to the VM.

```bash{outputLines: 2-9,10-16}
cat <<EOF | kubectl apply -f-
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  labels:
    app: httpbin
  namespace: httpbin
spec:
  ports:
  - port: 80
    targetPort: 80
    name: http
  selector:
    app: httpbin
EOF
```

Apply the ingress gateway config using tctl to configure a gateway to accept
traffic and forward it to the VM. 

:::note 
When used in production, this configuration should be updated to match your
setup where necessary. For example, if you have a workspace or gateway group
you can use.
:::

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  name: foo-ws
  tenant: <tenant>
spec:
  namespaceSelector:
    names:
      - "*/httpbin"
---
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
  name: httpbin
  workspace: foo-ws
  tenant: <tenant>
spec:
  namespaceSelector:
    names:
      - "*/httpbin"
  configMode: BRIDGED
---
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
  name: httpbin
  group: httpbin
  workspace: foo-ws
  tenant: <tenant>
spec:
  workloadSelector: # adjust this to match the gateway you are configuring
    namespace: httpbin
    labels:
        app: httpbin-gateway
  http:
    - name: httpbin
      port: 8080
      hostname: "httpbin.tetrate.io"
      routing:
        rules:
          - route:
              host: "httpbin/httpbin.httpbin.svc.cluster.local"
              port: 80
```

At this point, you should be able to send traffic to your gateway for host
`httpbin.tetrate.io`, and it should be forwarded to your VM. 

You can verify this with curl by manually setting the host header and accessing
the IP of your gateway e.g. `curl -v -H "Host: httpbin.tetrate.io" 34.122.114.216/headers` 
where `34.122.114.216` is the address of your gateway.

You could now direct whatever points to your VM (DNS or L4 LB, for example) to
point to your cluster gateway. Traffic will flow to your cluster, and then to
your VM.

Now, add the httpbin workload running on your VM to your cluster and send a
portion of traffic to the cluster version. Start by applying the following
config with tctl (adjusting the config where necessary).

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: Group
metadata:
  name: httpbin
  workspace: foo-ws
  tenant: <tenant>
spec:
  namespaceSelector:
    names:
      - "<cluster>/httpbin"
  configMode: BRIDGED
---
apiVersion: traffic.tsb.tetrate.io/v2
kind: ServiceRoute
metadata:
  name: httpbin
  group: httpbin
  workspace: foo-ws
  tenant: <tenant>
spec:
  service: httpbin/httpbin
  subsets:
  - name: v1
    labels:
      version: v1
    weight: 100
```

This will send 100% of traffic to the VM because you set this up before
deploying your app to your cluster. To start traffic splitting, run the
following command in your cluster.

```bash{outputLines: 2-9,10-29}
cat <<EOF | kubectl apply -f-
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
  labels:
    app: httpbin
    version: v2
  namespace: httpbin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin
      version: v2
  template:
    metadata:
      labels:
        app: httpbin
        version: v2
    spec:
      serviceAccountName: httpbin
      containers:
      - name: httpbin
        image: kennethreitz/httpbin
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
EOF
```

Verify that the app is running in your cluster. 

Now edit the TSB ServiceRoute config to include the newly deployed v2 version in
the cluster and apply it with `tctl` *(adjusting where necessary)*.

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: ServiceRoute
metadata:
  name: httpbin
  group: httpbin
  workspace: foo-ws
  tenant: <tenant>
spec:
  service: httpbin/httpbin
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

Now send a few requests to your application through your gateway.

You can verify through logs, or the TSB UI that traffic is being split between
your VM and cluster applications.

Once you're satisfied that the newer version is performing as expected, you can
slowly increase the  traffic percentages until all traffic is being sent to your
cluster and shifted away from the VM.



