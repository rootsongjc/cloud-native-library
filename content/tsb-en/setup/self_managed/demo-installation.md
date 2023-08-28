---
title: Demo Installation
description: How To Install The Demo Profile
---

If you just want to take a quick look at what TSB can do, you can opt to
install TSB's demo profile. The demo profile is a simplified "batteries included"
install experience that includes PostgreSQL, Elasticsearch, and LDAP running
on the Kubernetes cluster.

You should be able to comfortably test TSB on a cluster with 3-6 nodes with 4
vCPU and 16gb each. Since the demo install runs PostgreSQL and Elasticsearch on
Kubernetes, the cluster must have a default storage class set, and the ability
for these resources to create Persistent Volume Claims with a minimum size of
100gb for Elasticsearch as well as for PostgreSQL.

Check the [TSB Support Policy](../../release_notes_announcements/support_policy#kubernetes-versions) for compatibility with Kubernetes.

## Demo Profile Installation

### Obtain `tctl` and Sync Images

To install the demo profile, first follow the steps to
[download `tctl`](../requirements-and-download#download) and
[sync the container images](../requirements-and-download#sync-tetrate-service-bridge-images).

### Create a Kubernetes Cluster

Setup a Kubernetes cluster where you will be installing the demo profile into.
The exact step to create a cluster differs depending on your environment.
Please consult the manual for your environment for details
on how to create a Kubernetes cluster.

#### Using kind

If you are using a [kind](https://kind.sigs.k8s.io/) cluster to install the
demo profile, you will have to install [MetalLB](https://metallb.universe.tf/) after
having created the cluster to let TSB uses services of type `LoadBalancer`.

Once it is installed, you need to create a [Layer 2 configuration](https://metallb.universe.tf/configuration/#layer-2-configuration)
that configures the range of IP addresses that will be used for `LoadBalancer` services.
The range must be within the range of IPs of the `kind` Docker network (the default one used by kind).
You can view the current range of IPs with the following command:

```bash{promptUser: alice}
docker inspect kind | jq '.[0].IPAM.Config[0]'
{
  "Subnet": "172.18.0.0/16",
  "Gateway": "172.18.0.1"
}
```

Make sure to configure a range of IP addresses that is in the returned subnet. Once the layer 2 configuration
has been applied, you can proceed to install the demo profile.


### Execute `tctl install demo`

Once you have a cluster, make sure that the Kubernetes context is pointed
to the cluster that you want to install the demo profile into.

The `tctl install demo` command will use the `current-context` from your `kubectl`
configuration. Make sure it is pointing to the correct Kubernetes cluster before
proceeding.

Run the following command to start the installation. You may provide your own
admin password via the `--admin-password` option (available since 1.4.0), or
one will be generated for you.

```bash{promptUser: alice}
tctl install demo \
  --registry <registry-location> \
  --admin-password <password>
```

:::note
In certain environments (often with limited resources or under heavy load
already), the installation might take longer than expected and the `tctl` tool
could exit. The install demo command above is idempotent, making it safe to run again
until the entire installation is completed.
:::


When this installation is complete, you will have a management plane and control
plane running inside your Kubernetes cluster.

On top of this, an [Organization](../../concepts/terminology#organization) named `tetrate`
will have been created.

After the demo installation is done, you may want to go through the [Quickstart](../../quickstart)
guides to get your feet wet.

Even if you are not going to go through the Quickstart, this may be a good time to
[create a tenant](../../quickstart/tenant), as it will likely be required when you follow the examples in this website.

## Login to the Web UI

You will need to know the URL for the TSB Web UI and the credentials to login to the UI.

This information can be found at the end of the demo install command output.
You should have seen an output resembling the following text. Use this information
to navigate and log into the Web UI.

```bash{promptUser: "alice"}
Controlplane installed successfully!
Management Plane UI accessible at: https://31.224.214.68:8443
Admin credentials: username: admin, password: yGWx1s!Y@&-KBe0V
```

It is possible to further configure the demo installation. For example, you can
easily onboard clusters by following the [onboarding clusters guide](./onboarding-clusters).