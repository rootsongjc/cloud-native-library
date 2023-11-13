---
title: Setting Up Workload Onboarding
description: How to Setup Workload Onboarding
---

This document describes how to set up your environment so that your VMs are ready to be
[onboarded using the Workload Onboarding Agent](./onboarding).

The setup for Workload Onboarding consists of the following steps:

1. Enable Workload Onboarding
1. Create the WorkloadGroup
1. Allow the workloads to join WorkloadGroup
1. Create the Sidecar configuration
1. Install the Workload Onboarding Agent on a VM

## Enable Workload Onboarding

To enable Workload Onboarding in a given Kubernetes Cluster, you need to edit
TSB [ControlPlane](../../../refs/install/controlplane/v1alpha1/spec) resource or Helm
configuration as follows:

```yaml
spec:
  ...
  meshExpansion:
    onboarding:                                           # (1) REQUIRED
      endpoint:
        hosts:
        - <onboarding-endpoint-dns-name>                  # (2) REQUIRED
        secretName: <onboarding-endpoint-tls-cert>        # (3) REQUIRED
      tokenIssuer:
        jwt:
          expiration: <onboarding-token-expiration-time>  # (4) OPTIONAL
      localRepository: {}                                 # (5) OPTIONAL
```

And then:

1. To enable Workload Onboarding in a given Kubernetes Cluster, you need to edit
   the `spec.meshExpansion.onboarding` section and provide the values for all mandatory
   fields
1. You must provide a DNS name for the Workload Onboarding Endpoint, e.g.
   `onboarding-endpoint.your-company.corp`
1. You must provide the name of the Kubernetes Secret that holds the TLS certificate
   for the Workload Onboarding Endpoint
1. You can choose a custom expiration time for the onboarding tokens, which defaults to
   `1 hour`
1. You can choose to deploy a local copy of the repository with DEB/RPM
   packages of the Workload Onboarding Agent and Istio sidecar

## Workload Onboarding Endpoint

The Workload Onboarding Endpoint is the component that the individual Workload
Onboarding Agent(s) connect to join the mesh.

In production scenarios, the Workload Onboarding Endpoint must be highly
available, have a stable address, and enforce TLS on incoming connections.

For that reason, the DNS name and TLS certificate are mandatory parameters for
enabling Workload Onboarding.

### DNS name

You can choose any DNS name for the Workload Onboarding Endpoint.

That name must be associated with the address of the Kubernetes Service `vmgateway`
from the `istio-system` namespace.

In production scenarios, you can achieve that by using [`external-dns`](https://github.com/kubernetes-sigs/external-dns).

### TLS certificate

To provide a certificate for the Workload Onboarding Endpoint, you need to
create a Kubernetes secret of type TLS in the `istio-system` namespace.

You have several options:

* Either create a Kubernetes secret from an X509 cert and a private key
  procured out-of-band
* Or you can use [cert-manager](https://cert-manager.io/docs/) to automate provisioning of the TLS cert

#### TLS certificate procured out-of-band

To provide a TLS certificate procured out-of-band, use:

```shell
kubectl create secret tls <onboarding-endpoint-tls-cert> \
  -n istio-system \
  --cert=<path/to/cert/file> \
  --key=<path/to/key/file>
```

#### TLS certificate procured by `cert-manager`

To automate the provisioning of the TLS certificate, you can use [cert-manager](https://cert-manager.io/docs/).

For example, you can procure a free TLS certificate signed by a
trusted CA, such as [Let's Encrypt](https://letsencrypt.org/).

In this case, your configuration will look similar to:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: <onboarding-endpoint-tls-cert>
  namespace: istio-system
spec:
  secretName: <onboarding-endpoint-tls-cert>
  duration: 2160h   # 90d
  renewBefore: 360h # 15d
  usages:
  - server auth
  dnsNames:
  - <onboarding-endpoint-dns-name>
  issuerRef:
    name: <your-issuer>
    kind: ClusterIssuer
```

Refer to the [cert-manager](https://cert-manager.io/docs/) documentation for further details.

## Workload Onboarding Tokens

The Workload Onboarding Token represents a temporary grant to onboard a workload
into the service mesh.

The Workload Onboarding Endpoint issues the Workload Onboarding Token
after verifying the platform-specific credentials presented by the
Workload Onboarding Agent, e.g. credentials of the VM the workload is running
on.

The Workload Onboarding Token is used as a session token in subsequent requests
from the Workload Onboarding Agent to the Workload Onboarding Endpoint
to improve the efficiency of authentication and authorization.

By default, the Workload Onboarding Token is valid for `1 hour`.

Users might choose a custom expiration time for the Workload Onboarding Token
for several reasons, e.g.:

* shorten the expiration time to meet stricter security policies
  established within their organization
* extend expiration time to lower the load caused by frequent
  token renewals

## Local Repository

For convenience, the DEB/RPM packages of the Workload Onboarding Agent and
Istio sidecar can be hosted locally within their network.

Once users enable a local repository, they will be able to download the DEB/RPM packages
from an HTTP server at `https://<onboarding-endpoint-dns-name>`.

The local repository allows downloading the following artifacts:

| URI                                              | Description                                    |
|--------------------------------------------------|------------------------------------------------|
| `/install/deb/amd64/onboarding-agent.deb`        | DEB package of the Workload Onboarding Agent |
| `/install/deb/amd64/onboarding-agent.deb.sha256` | SHA-256 checksum of the DEB package             |
| `/install/deb/amd64/istio-sidecar.deb`           | DEB package of the Istio sidecar             |
| `/install/deb/amd64/istio-sidecar.deb.sha256`    | SHA-256 checksum of the DEB package             |
| `/install/rpm/amd64/onboarding-agent.rpm`        | RPM package of the Workload Onboarding Agent |
| `/install/rpm/amd64/onboarding-agent.rpm.sha256` | SHA-256 checksum of the RPM package             |
| `/install/rpm/amd64/istio-sidecar.rpm`           | RPM package of the Istio sidecar             |
| `/install/rpm/amd64/istio-sidecar.rpm.sha256`    | SHA-256 checksum of the RPM package             |

## Create the WorkloadGroup

When a workload running outside of a Kubernetes cluster is onboarded into the mesh,
it is considered to join a certain [WorkloadGroup](https://istio.io/latest/docs/reference/config/networking/workload-group/).

The Istio WorkloadGroup resource holds the configuration shared by all the workloads
that join it.

In a way, an Istio WorkloadGroup resource is to individual workloads what
a Kubernetes Deployment resource is to individual Pods.

To be able to onboard individual workloads into a given Kubernetes cluster, you must
first create a respective Istio WorkloadGroup in it.

E.g.,

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadGroup
metadata:
  name: ratings
  namespace: bookinfo
  labels:
    app: ratings
spec:
  template:                           # (1)
    labels:
      app: ratings
      class: vm
    serviceAccount: ratings-vm        # (2)
    network:        virtual-machines  # (3)
```

where

1. All the workloads joining that group inherit the configuration specified in
  `spec.template`
1. Inside the mesh, the onboarded workloads will have the identity of the
   Kubernetes service account specified in `spec.template.serviceAccount`.
   If `spec.template.serviceAccount` is not set, the service account `"default"`
   is assumed (this account is guaranteed to exist in every Kubernetes namespace).
1. If the workloads in that group have no direct connectivity to Kubernetes `Pods`
   you must set the `spec.template.network` field to a non-empty value.

## Allow workloads to join a WorkloadGroup

The workloads running outside of a Kubernetes cluster are not allowed to join the mesh
unless it is explicitly authorized.

For the purposes of onboarding, a workload is considered to have the identity of
the host it is running on. For example, if a workload is running on an AWS EC2
instance, it is considered to have the identity of that AWS EC2 instance.

To allow a workload to onboard into a given cluster, a user must create an
[onboarding policy](../../../refs/onboarding/config/authorization/v1alpha1/policy)
in that cluster.

An OnboardingPolicy is a Kubernetes resource that authorizes workloads with certain
identities to join certain WorkloadGroup(s). An OnboardingPolicy must be
created in the same namespace as the WorkloadGroup(s) it applies to.

### Examples

The example below allows the workloads running on any AWS EC2 instance
associated with the given AWS account to join any of the
available WorkloadGroups in the given Kubernetes namespace:

```yaml
apiVersion: authorization.onboarding.tetrate.io/v1alpha1
kind: OnboardingPolicy
metadata:
  name: allow-any-aws-ec2-instance-from-given-accounts
  namespace: bookinfo
spec:
  allow:
  - workloads:
    - aws:
        accounts:
        - '123456789012'
        - '234567890123'
        ec2: {} # any AWS EC2 instance from the above account(s)
    onboardTo:
    - workloadGroupSelector: {} # any WorkloadGroup from that namespace
```

For security reasons, the AWS accounts must always be listed explicitly.
You will not be able to specify that workloads associated with any
account to freely join the mesh since that's never a good practice.

While the previous example may have been a rather "permissive" policy,
a more restrictive onboarding policy might only allow onboarding workloads
from AWS EC2 instances in a particular AWS region and/or zone, with a
particular AWS IAM Role, etc. It might also only allow workloads to
join a specific subset of WorkloadGroups.

The following shows an example of a more restrictive policy:

```yaml
apiVersion: authorization.onboarding.tetrate.io/v1alpha1
kind: OnboardingPolicy
metadata:
  name: allow-narrow-subset-of-aws-ec2-instances
  namespace: bookinfo
spec:
  allow:
  - workloads:
    - aws:
        partitions:
        - aws
        accounts:
        - '123456789012'
        regions:
        - us-east-2
        zones:
        - us-east-2b
        ec2:
          iamRoleNames:
          - ratings-role        # any AWS EC2 instance from the above partitions/accounts/regions/zones
                                # that is associated with one of IAM Roles on that list
    onboardTo:
    - workloadGroupSelector:
        matchLabels:
          app: ratings          # (1)
```

The above policy authorizes workloads that have the label `app=ratings` (1)
to join those WorkloadGroup(s). For example, the following group would
match the policy, but if you omit or specify different values in the
`label` field, it would not match.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadGroup
metadata:
  name: ratings
  namespace: bookinfo
  labels:
    app: ratings 
spec:
  ...
```

## Create the Sidecar configuration

Workload Onboarding does not currently support the use of `Iptables` for traffic redirection.
Therefore you will need to configure an Istio Sidecar resource, and
reconfigure the application and/or the host environment as necessary.

### Workload Configuration (Ingress)

Make sure your workload (i.e., user application) listens on `127.0.0.1`
instead of `0.0.0.0`.

For example, if your application listens on `0.0.0.0:8080`, change its
configuration so that it listens on `127.0.0.1:8080` instead.

This has two effects: first, both the Istio proxy and the workload will
be able to listen on the same port — and thus, the proxy will be able to
listen on `<host IP>:8080`. And second, other nodes in the mesh will not
be able to connect directly to your application. They would be forced
to go through the proxy, which will proxy the traffic to `127.0.0.1:8080`.

### Workload Configuration (Egress)

Configure your application to refer to dependent services by their DNS names.
Otherwise, the application will not be able to take full advantage of the mesh.

Specifically, the application should refer to other Kubernetes services by
their cluster-local DNS names, such as `details.bookinfo`, `details.bookinfo.svc`,
or `details.bookinfo.svc.cluster.local`.

Other mesh-external services should be referred to using their DNS names (e.g. `example.org`)

You will also need to alias the DNS names of your dependent services to
the IP addresses of the egress listeners that you will be using by editing
the `/etc/hosts` file in your VM.

Assuming that you are referring to `details.bookinfo.svc` and `example.org` in
your application, edit the `/etc/hosts` file to contain the following lines, replacing
the `egress listener IP address` with appropriate values:

```
<egress listner IP address>	details.bookinfo.svc
<egress listner IP address>	example.org
```

As a result, when your application attempts to make a request to
`ratings.bookinfo.svc:8080` or `example.org:8080`, your application would
be connecting to the egress listener, which will proxy the requests to
their respective destinations.

:::note
Alternatively, you might consider specifying the Istio proxy in the
`http_proxy` environment variable.
:::

### Sidecar Resource Configuration

You will need to create an Istio Sidecar resource on your Kubernetes
cluster. The YAML definition will look like the following:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: bookinfo-ratings-no-iptables
  namespace: bookinfo
spec:
  workloadSelector:                  # (1)
    labels:
      app: ratings
      class: vm
  ingress:                           # (2)
  - defaultEndpoint: 127.0.0.1:8080
    port:
      name: http
      number: 8080
      protocol: HTTP
  egress:                            # (3)
  - bind: 127.0.0.2
    port:
      name: http                   # REQUIRED   
      number: 8080
      protocol: HTTP               # REQUIRED
    hosts:
    - ./*
```

Section (1) defines the WorkloadGroups that this sidecar applies to.
In this example, this configuration applies to workloads whose labels match
`app: ratings`. This example also specifies that we only apply this to
those with the `class: vm` label, which is intended to be used to
distinguish workloads deployed on VMs and those deployed on Kubernetes pods.

Section (2) defines the Ingress listener. This configuration specifies that
the Istio proxy will be listening on `<host IP>:8080`, and will forward
the traffic received on `<host IP>:8080` to `127.0.0.1:8080`, which should be
where your application will be listening.

Section (3) defines the Egress listener. This configuration specifies that
the Egress listener will be listening on `127.0.0.2:8080`. It also specifies
that the Egress listener will proxy outgoing requests to any service that
matches the `hosts` list and has port `8080`.

## Install Workload Onboarding Agent on a VM

You will need to install the following components on the VM that you want to onboard:

1. the Workload Onboarding Agent
1. an Istio Sidecar

Use either the DEB or RPM package, depending on your preference. 
You can download these packages from your local repository at
`https://<onboarding-endpoint-dns-name>` (for more details, refer to "Enabling Workload Onboarding").

If you use an ARM-based VM, change `amd64` to `arm64` in the following examples.

### Installing the Workload Onboarding Agent DEB Package

Run the following commands. Replace the `onboarding-endpoint-dns-name` with the appropriate value.

```bash
curl -fLO "https://<onboarding-endpoint-dns-name>/install/deb/amd64/onboarding-agent.deb"

curl -fLO "https://<onboarding-endpoint-dns-name>/install/deb/amd64/onboarding-agent.deb.sha256"

sha256sum --check onboarding-agent.deb.sha256

sudo apt-get install -y ./onboarding-agent.deb

rm onboarding-agent.deb onboarding-agent.deb.sha256
```

### Installing the Workload Onboarding Agent RPM Package

Run the following commands. Replace the `onboarding-endpoint-dns-name` with the appropriate value.

```bash
curl -fLO "https://<onboarding-endpoint-dns-name>/install/rpm/amd64/onboarding-agent.rpm"

curl -fLO "https://<onboarding-endpoint-dns-name>/install/rpm/amd64/onboarding-agent.rpm.sha256"

sha256sum --check onboarding-agent.rpm.sha256

sudo yum install -y ./onboarding-agent.rpm

rm onboarding-agent.rpm onboarding-agent.rpm.sha256
```

### Installing the Istio Sidecar DEB package

Run the following commands. Replace the `onboarding-endpoint-dns-name` with the appropriate value.

```bash
curl -fLO "https://<onboarding-endpoint-dns-name>/install/deb/amd64/istio-sidecar.deb"

curl -fLO "https://<onboarding-endpoint-dns-name>/install/deb/amd64/istio-sidecar.deb.sha256"

sha256sum --check istio-sidecar.deb.sha256

sudo apt-get install -y ./istio-sidecar.deb

rm istio-sidecar.deb istio-sidecar.deb.sha256
```

### Installing the Istio Sidecar RPM Package

Run the following commands. Replace the `onboarding-endpoint-dns-name` with the appropriate value.

```bash
curl -fLO "https://<onboarding-endpoint-dns-name>/install/rpm/amd64/istio-sidecar.rpm"

curl -fLO "https://<onboarding-endpoint-dns-name>/install/rpm/amd64/istio-sidecar.rpm.sha256"

sha256sum --check istio-sidecar.rpm.sha256

sudo yum install -y ./istio-sidecar.rpm

rm istio-sidecar.rpm istio-sidecar.rpm.sha256
```

### Installing the Istio Sidecar for Revisioned Istio

If you enable [Istio Isolation Boundary](../../isolation-boundaries), you need to use
revisioned package download path to download the DEB or RPM packages. 
Replace `<istio-revision>` with the Istio revision name you want to use.

Revisioned link for DEB package. 
```
https://<onboarding-endpoint-dns-name>/install/istio-sidecar/<istio-revision>/deb/amd64/istio-sidecar.deb
```

Revisioned link for RPM package.  
```
https://<onboarding-endpoint-dns-name>/install/istio-sidecar/<istio-revision>/rpm/amd64/istio-sidecar.rpm
```
