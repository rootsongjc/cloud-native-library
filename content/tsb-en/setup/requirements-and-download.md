---
title: Requirements and Download
description: Minimum Requirements and Download Instructions for Tetrate Service Bridge.
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

This page will give you an overview of everything that you need to get started
with both Tetrate Service Bridge (TSB) installation.

Operating a TSB service mesh requires a good understanding of working with
Kubernetes and Docker repositories. For additional guidance, we recommend
reading their supporting documentation.

## Requirements

You can install TSB for production use, or you can install the [demo profile](./self_managed/demo-installation)
for get a quick feel of TSB. Please check the requirements for each in the
following table:

|     | Production TSB | Demo/Quickstart TSB |
| --- | --- | --- |
| **Kubernetes cluster:**<br />EKS 1.21 - 1.24<br />GKE 1.21 - 1.24<br />AKS 1.21 - 1.24 (including Azure Stack HCI)<br />OpenShift 4.7 - 4.11<br />Docker UCP 3.2.5 or above | ✓ | ✓ |
| **Private Docker registry** (HTTPS) | ✓ | ✓ |
| **Tetrate repository Account and API Key** (if you don't have this yet, please contact Tetrate) | ✓ | ✓ |
| **Docker Engine 18.03.01** or above, with push access to your private Docker registry | ✓ | ✓ |
| **PostgreSQL** 11.1 or above | ✓ | packaged (v14.4)|
| **Elasticsearch** 6.x or 7.x | ✓ | packaged (v7.8.1) |
| **Redis** 6.2 or above | ✓ | packaged (v7.0.5) |
| **LDAP server or OIDC Provider** | ✓ | packaged (OpenLDAP v2.6) |
| **Cert-manager:**<br />cert-manager v1.7.2 or above | ✓ | packaged (cert-manager v1.10.0) |

:::note cert-manager usage
[cert-manager](https://cert-manager.io/) is used to issue and manage certificate for TSB webhook, TSB internal communications and integration with external CA for Istio control plane.
:::

:::note cert-manager version
cert-manager 1.4.0 is the minimum version required for use with TSB 1.5. It has the feature flag to sign K8S CSR requests which supports Kubernetes 1.16-1.21. Go to [cert-manager Supported Releases](https://cert-manager.io/docs/installation/supported-releases/) to get more information on supported Kubernetes and OpenShift versions. 
:::

:::note Production installation note
The size of your Kubernetes clusters is dependent on your platform deployment
requirements. A base TSB install does not consume many additional resources.
The sizing of storage is greatly dependent on the size of your application
clusters, amount of workloads (and their request rate), and observability
configuration (sampling rate, data retention period, etc.). For more information
see our [capacity planning](./resource_planning) guide.
:::

When running self-managed, your organization might impose additional (security) restrictions, availability,
and disaster recovery requirements on top of the above mentioned environments
and applications. For detailed information on how to adjust the TSB installation
and configuration please refer to the [operator reference guides](../refs/install)
as well as the [how to section](../howto)
of our documentation where you can find  descriptions of the configuration
options, common deployment scenarios and solutions.

### Identity Provider

TSB requires an Identity Provider (IdP) as the source of users. This identity provider is used for user authentication and to periodically synchronize the information of existing users and groups into the platform. TSB can integrate with LDAP or any OIDC compliant Identity Providers. 

To use LDAP, you have to figure out how to query your LDAP so TSB can use it for authentication and synchronization of users and groups. See [LDAP as Identity Provider](../operations/users/configuring_ldap) for more details on LDAP configuration. 

To use OIDC, create an OIDC client in your IdP. Enable Authorization Code Flow for login with UI and Device Authorization for login with tctl using device code. For more information and examples see how to set up [Azure AD as a TSB Identity Provider](../operations/users/oidc_azure). 

:::note OIDC IdP synchronization
TSB supports Azure AD for synchronization of users and groups. If you use another IdP you have to create a sync job that will get users and teams from your IdP and sync them into TSB using sync API. See [User Synchronization](../operations/users/user_synchronization) for more details.
:::

### Data and Telemetry Storage

TSB requires external data and telemetry storage. TSB uses PostgreSQL as data storage and Elasticsearch as telemetry storage. 

:::danger Demo storage
Demo installation will deploy PostgreSQL, Elasticsearch and LDAP server as Identity Provider populated with mock users and teams. Demo storage is not intended for production usage. Please make sure to provision proper PostgreSQL, Elasticsearch and Identity Provider for your production environment.
:::

### Certificate Provider

TSB 1.5 requires a certificate provider to support certificate provisioning
for internal TSB components for purposes like webhook certificates and others. This certificate provider must be available in the management plane cluster and all control plane clusters. 

TSB supports `cert-manager` as one
of the supported providers. It can manage the lifecycle of `cert-manager` installation for you.
To configure the installation of `cert-manager` in your cluster, add the following section as part of
the `ManagementPlane` or `ControlPlane` CR:

```yaml
  components:
    internalCertProvider:
      certManager:
        managed: INTERNAL
```

You can also use any certificate provider which supports the `kube-CSR` API. To use custom providers,
please refer to the following section [Internal Cert Provider](../refs/install/common/common_config#internalcertprovider)

:::note Existing cert-manager installation
If you are already using cert-manager as part of your cluster, you can set the `managed` field
in `ManagementPlane` or `ControlPlane` CR to `EXTERNAL`. This will let TSB utilize the existing
cert-manager installation. The TSB operator will fail if it finds an already installed cert-manager
when the `managed` field is set to `INTERNAL` to ensure that it does not override
the existing cert-manager installation.
:::

:::note cert-manager Kube-CSR
TSB uses the kubernetes CSR resource to provision certificates for various webhooks. If your configuration
uses an EXTERNAL cert-manager installation, please ensure cert-manager can sign Kubernetes CSR requests. For example,
in cert-manager 1.7.2, this is enabled by setting this feature gate flag `ExperimentalCertificateSigningRequestControllers=true`.
For TSB managed installations using INTERNAL managed cert-manager, this configuration
is already set as part of the installation.
:::

## Download

The first step to get TSB up and running is to install our TSB CLI tool `tctl`.
With `tctl` you can install (or upgrade) TSB. It also allows you to interact
with the TSB API's using yaml objects. If having operated Kubernetes
deployments, this will be familiar to you. It also makes it easy to integrate
TSB with GitOps workflows. 

Follow the instruction in the [CLI reference pages](../reference/cli/guide/index#installation) to download and install `tctl`.

## Sync Tetrate Service Bridge images

Now that you have `tctl` installed, you can download the needed container images
and push them into your private Docker repository. The `tctl` tool makes this
easy by providing the `image-sync` command, which will download the image versions 
matching the current version of `tctl` from Tetrate repository and push it 
into your private Docker repository. The `username` and
`apikey` arguments must hold the Tetrate repository account details provided to you by
Tetrate to enable the download of the container images. The `registry` argument
must point to your private Docker registry.

```bash{promptUser: alice}{outputLines: 2}
tctl install image-sync --username <user-name> \
    --apikey <api-key> --registry <registry-location>
```

The first time you run this command you will be presented with a EULA which
needs to be accepted. If you run the TSB installation from CI/CD or other
environment where you will not have an interactive terminal at your disposal,
you can add the `--accept-eula` flag to the above command.

### Demo installations on a Kind cluster

If you are installing the `demo` profile in a local [kind](https://kind.sigs.k8s.io/) cluster,
you can directly load the images in the kind node as follows:

```bash{promptUser: alice}
# Loging to the Docker repository using our `username` and `apikey`
docker login containers.dl.tetrate.io

# Pull all the docker images
for i in `tctl install image-sync --just-print --raw` ; do docker pull $i ; done

# Load the images to the kind node
for i in `tctl install image-sync --just-print --raw` ; do kind load docker-image $i ; done
```

## Installation

:::note cluster profiles
Operating a multi-cluster TSB environment typically involves communicating with
multiple Kubernetes clusters. In the documentation we do not make explicit use
of `kubectl` config context and `tctl` [config](../reference/cli/reference/config)
profiles as they are specific to your environment. Make sure that you have
selected the right `kubectl` context and `tctl` profile as default or use
explicit arguments to select the correct clusters when executing commands with
these tools.
:::

For installation using Helm chart, please proceed to the
[helm installation](./helm) guide.

For installation using tctl, please proceed to the
[tctl installation](./self_managed) guide.

For the demo installation procedure, please proceed to the
[demo installation](./self_managed/demo-installation) guide.
