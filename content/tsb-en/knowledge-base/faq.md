---
title: TSB FAQ
description: Frequently Asked Questions
---

## How can I tell if Envoy is healthy?


The best way to tell if Envoy is healthy is to check its health and readiness endpoint (`healthz`). To check Envoy's `healthz` endpoint for an application in an onboarded cluster, you need to connect directly to the application's sidecar Envoy.

Suppose you have a pod called `details-v1-57f8794694-hc7gd` in the `bookinfo` namespace of your cluster which hosts your application.

Use `kubectl port-forward` to establish port forwarding directly to your Envoy sidecar on port `15021` from your local machine:

```bash{promptUser: alice}
kubectl port-forward -n bookinfo details-v1-57f8794694-hc7gd 15021:15021
```

Once the above command is successful, you should now be able to point your favorite tool to the URL `http://localhost:15021/healthz/ready` and access the `healthz` endpoint for Envoy directly. You should avoid using the browser for this, as the Envoy proxy will return a `200 OK` response with an empty body if it is properly configured and running.

For example, you can use `curl` in verbose mode as follows:

```bash{promptUser: alice}
curl -v http://localhost:15021/healthz/ready
```

This should produce an output similar to the following. Envoy is properly working if the response status is `200 OK`.

```bash{promptUser: alice}
curl -v http://localhost:15021/healthz/ready
*   Trying 127.0.0.1:15021...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 15021 (#0)
> GET /healthz/ready HTTP/1.1
> Host: localhost:15021
> User-Agent: curl/7.68.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< date: Fri, 02 Jul 2021 13:32:05 GMT
< content-length: 0
< x-envoy-upstream-service-time: 0
< server: envoy
<
* Connection #0 to host localhost left intact
```

## `tctl` failed to connect to cluster

Check if you have the correct organization and tenant information associated with the cluster in your `tctl` profile.

First, get the current active profile by issuing the following command:

```bash{promptUser: alice}
tctl config profiles list
```

You should see an output similar to the following. 

```
  CURRENT  NAME     CLUSTER  ACCOUNT
           default  default  admin-user
  *        gke-tsb  gke-tsb  gke-user
```

The entry with the asterisk (`*`) is the current active profile. To configure the current profile `gke-tsb`, such that the `gke-user` connects to the cluster using the organization name `organization-name` and the tenant name `tenant-name`, execute the following command:

```bash{promptUser: alice}
tctl config users set "gke-user" \
  --org <organization-name> \
  --tenant <tenant-name> \
  --username <username> \
  --password <password>
```

The organization name and the tenant name can obtained via the Web UI.

After  this, when you execute `tctl` commands will operate against the specified organization and tenant. The same thing can be done for each `tctl` subcommand that needs authentication by explicitly specifying the `--org` and `--tenant` arguments.

## Is it possible to share a single TSB instance across multiple clusters?

Yes. A single TSB [management plane](../concepts/terminology/#management-plane) is able to manage a large number of clusters. You will need to onboard each cluster that you want to associated into the same management plane. Please also see the document [TSB Resource Consumption and Capacity Planning](../setup/resource_planning) for more details on the amount of resources you may need as you increase the number of participating clusters.

If you need to configure each cluster with different permissions or teams, logically partition them as necessary using [workspaces](../concepts/terminology/#workspace) and [groups](../concepts/terminology/#group).

See our Installation guide for instructions to onboard a cluster into [TSB](../setup/self_managed/onboarding-clusters).

## I get an "OPENSSL_VERIFY failure" when using custom certificates.

When you use an [intermediate CA](../operations/vault/istiod-ca), or when you use your own certificates, you may get an "OPENSSL_VERIFY failure" error in the client Envoy.

The "OPENSSL_VERIFY failure" error can be caused by various reasons. The general approach you should take is to fetch the certificates and verify their contents. Please be aware that diagnosing the certificates themselves is not in the scope of this document, and you will have to be prepared to do this yourself.

`istioctl` has a built-in command for comparing CA bundles across workloads: `istioctl proxy-config rootca-compare pod/<pod-1>.<namespace-1> pod/<pod-2>.<namespace-2>`. This command automates the manual process below and should be your first choice when diagnosing OPENSSL_VERIFY errors.

### Checking certificates manually

To obtain the certificates that the destination Envoy instance is using, use `istioctl` like the example below. Replace `<server-pod-ID>` with the appropriate value for the Envoy instance that you are debugging:

```bash{promptUser: "alice"}
istioctl proxy-config secret <server-pod-ID> -ojson > server-tls.json
```

The file `server-tls.json` will contain the Istio mutual TLS certificate, from which we can extract the individual certificates.

```bash{promptUser: "alice"}
cat server-tls.json | \
  jq -r `.dynamicActiveSecrets[0].secret.tlsCertificate.certificateChain.inlineBytes' | \
  base64 --decode > server.crt
```

In the following example we are going to separate out the server certificate with the rest of the chain for demonstration purposes, and use `openssl verify` to check the certificates. Copy the bash script to a file named `check-chain.sh`:

```bash{promptUser: "alice"}
#!/bin/bash

# filename provided by the user.
usercert=$1

# temporary files and cleanup
tmpfirst=$(mktemp)
tmpchain=$(mktemp)
function cleanup_tmpfiles {
        [ -f "$tmpfirst" ] && rm -f "$tmpfirst";
        [ -f "$tmpchain" ] && rm -f "$tmpchain";
}

trap cleanup_tmpfiles EXIT
trap 'trap - EXIT; cleanup_tmpfiles; exit -1' INT PIPE TERM

outfile="$tmpfirst"
count=0
while IFS= read -r line
do
        if [[ "$line" == *-"BEGIN CERTIFICATE"-* ]]; then
                ((count = $count + 1))
                if [[ $count == 2 ]]; then
                        outfile="$tmpchain"
                fi
        fi
        echo $line >> "$outfile"
done < "$usercert"

openssl verify -CAfile "$tmpchain" "$tmpfirst" > /dev/null
if [[ $? == 0 ]]; then
        echo "OK"
fi
```

Then run it against the file you obtained in the previous step:

```bash{promptUser: "alice"}
$ bash check-chain.sh server.crt
```

If the verification fails during the execution of the above script, the certificates are not chained correctly. For example, the CA certificate subject may not match the workload certificate's issuer.

## How does Istio CNI work with a Kubernetes CNI like Cilium or Calico? Does it replace them?

Istio's CNI does _not_ replace a CNI plugin like Cilium or Calico, but Istio CNI _does_ work with any other Kubernetes CNI as an add-on to that plugin (a "[chained plugin](https://github.com/containernetworking/cni/blob/master/SPEC#section-2-execution-protocol)" in the language of the CNI spec).

Your primary CNI plugin will run and build the Kubernetes network for your pod, then Istio's CNI will run rewriting the network rules to trap traffic through Envoy. Istio's CNI executes literally the same code as the `istio-init` container to rewrite those network rules (see this blog on [the Istio website](https://istio.io/latest/blog/2019/data-plane-setup/#traffic-flow-from-application-container-to-sidecar-proxy) for an in-depth look at how that traffic interception works). 

The explanation from [the official site](https://istio.io/latest/docs/setup/additional-setup/cni/) describes it well:

> By default Istio injects an init container, `istio-init`, in pods deployed in the mesh. The `istio-init` container sets up the pod network traffic redirection to/from the Istio sidecar proxy. This requires the user or service-account deploying pods to the mesh to have sufficient Kubernetes RBAC permissions to deploy [containers with the `NET_ADMIN` and `NET_RAW` capabilities](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container). Requiring Istio users to have elevated Kubernetes RBAC permissions is problematic for some organizations' security compliance. The Istio CNI plugin is a replacement for the `istio-init` container that performs the same networking functionality but without requiring Istio users to enable elevated Kubernetes RBAC permissions.

## How do I enable Istio CNI in TSB?

See our [Istio CNI Administration Guide](../operations/features/istio_cni#enable-istio-cni-in-control-plane) for how to configure Istio CNI in TSB.

## What do I need to do in TSB or Istio when if I change my CNI plugin?

Nothing: Istio's CNI plugin configures itself to run after the main plugin. Changing your CNI provider and rebuilding your cluster ensures Istio's CNI will still run chained after your main plugin.

## Configure AWS internal ELBs

In some cases you will want the AWS load balancers that result from deploying services in the EKS cluster to be internal and not exposed to the Internet. The TSB operator API provides you with a path to set annotations in the Kubernetes service for each specific component so you can add the `service.beta.kubernetes.io/aws-load-balancer-scheme` or `service.beta.kubernetes.io/aws-load-balancer-internal` annotations.

For instance, the following snippet:

```
spec:
  components:
    frontEnvoy:
      kubeSpec:
        service:
          annotations:
            service.beta.kubernetes.io/aws-load-balancer-scheme: internal
```

Will configure the Kubernetes service for the front envoy (the main entry point to TSB API and UI) as an internal LB. Similarly, you can do that for the gateways deployed in your cluster.

```
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: bookinfo
  namespace: bookinfo
spec:
  kubeSpec:
    service:
      annotations:
            service.beta.kubernetes.io/aws-load-balancer-scheme: internal    
```

