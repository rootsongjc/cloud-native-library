---
title: Onboarding Clusters
description: Deploy Istio Control Plane on Kubernetes and connect it to TSB.
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

This page explains how to onboard a Kubernetes cluster to an existing Tetrate
Service Bridge management plane.

Before you start, make sure that you've:

✓ Checked the [requirements](../requirements-and-download)<br />
✓ [Installed TSB management plane](./management-plane-installation) or [demo installation](./demo-installation)<br />
✓ [Login to the management plane with tctl](../tctl_connect)<br />
✓ Checked [TSB control plane components](../components#control-plane)

:::note isolation boundaries
TSB 1.6 introduces isolation boundaries that allows you to have multiple TSB-managed Istio environments within a Kubernetes cluster, or spanning several clusters. One of the benefits of isolation boundaries is that you can perform canary upgrades of the control plane. 

To enable isolation boundaries, you must update operator deployment with environment variable `ISTIO_ISOLATION_BOUNDARIES=true` and control plane CR to include `isolationBoundaries` field.
For more information, see [Isolation Boundaries](../isolation-boundaries).
:::

## Creating Cluster Object

To create the correct credentials for the cluster to communicate with the
management plane, you need to create a cluster object using the management plane
API.

Adjust the below `yaml` object according to your needs and save to a file called `new-cluster.yaml`.

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Cluster
metadata:
  name: <cluster-name-in-tsb>
  organization: <organization-name>
spec: {}
```

:::note Cluster name in TSB
&lt;cluster-name-in-tsb&gt; is the designated name for your cluster in TSB. You
use this name in TSB APIs, such as namespace selector in workspaces and config
groups. You will also use this name when creating a `ControlPlane` CR
below. This name must be unique.
:::

Please refer to the reference docs for details on the configurable fields of a
[Cluster](../../refs/tsb/v2/cluster) object.

To create the cluster object at the management plane, use `tctl` to apply the
`yaml` file containing the cluster details.

```bash{promptUser:alice}
tctl apply -f new-cluster.yaml
```

## Deploy Operators

Next, you need to install the necessary components in the cluster to onboard and
connect it to the management plane.

There are two operators you must deploy. First, the control plane operator,
which is responsible for managing Istio, SkyWalking, and various other
components. Second, the data plane operator, which is responsible for managing
gateways.

```bash{promptUser:alice}{outputLines:2}
tctl install manifest cluster-operators \
    --registry <registry-location> > clusteroperators.yaml
```

<Tabs
  defaultValue="Default"
  values={[
    {label: 'Standard', value: 'Default'},
    {label: 'OpenShift', value: 'OC'},
  ]}>
  <TabItem value="Default">

The install manifest cluster-operators command outputs the Kubernetes manifests
of the required operators. We can then add this to our source control or apply
it to the cluster:

```bash{promptUser:alice}
kubectl apply -f clusteroperators.yaml
```

  </TabItem>
  <TabItem value="OC">

The install manifest cluster-operators command outputs the Kubernetes manifests
of the required operators. We can then add this to our source control or apply
it to the cluster:

```bash{promptUser:alice}
oc apply -f clusteroperators.yaml
```

  </TabItem>
</Tabs>

:::note
For [configuring secrets](#configuring-secrets) and [control plane installation](#control-plane-installation) below, you must
create secrets and custom resource yamls for each cluster individually.
In other words, repeat the steps for each cluster and make sure to pass `<cluster-name-in-tsb>`
value that you set above then apply both yamls to the correct cluster.
:::

## Configuring Secrets

The control plane needs secrets in order to authenticate with the management plane.
These include a service account key, Elasticsearch credentials, and CA bundles if using
self-signed certificates for the management plane, XCP or Elasticsearch.
Following are a list of secrets that you need to create.

| Secret name | Description |
|----------------|-------------|
| `elastic-credentials` | Elasticsearch username and password. |
| `es-certs` | The CA certificate to validate Elasticsearch connections when Elasticsearch is configured to present a self-signed certificate. |
| `redis-credentials` | Contains:<br />&ensp;1. Redis password. <br />&ensp;2. Flag to use TLS. <br />&&ensp;3. The CA certificate to verify Redis connections when Postgres is configured to present a self-signed certificate. <br />&ensp;4. Client certificate and private key if Redis is configured with mutual TLS. |
| `xcp-central-ca-bundle` | The CA bundle to validate the certificates presented by XCP Central. |
| `mp-certs` | The CA certificate to validate TSB management plane APIs if the management plane is configured to present a self-signed certificate. This is CA that created to sign front-envoy TLS certificate. |
| `cluster-service-account` | The CA bundle to validate the certificates presented by XCP Central. |


:::note front-envoy as Elasticsearch proxy
TSB front-envoy can act as proxy to Elasticsearch that is configured in `ManagementPlane` CR.
If you use this, make sure to set `es-certs` with `front-envoy` TLS certificate.
:::


### Using tctl to Generate Secrets

These secrets can be generated in the correct format by passing them as command-line flags
to the `tctl` control-plane-secrets command.

First, create service account for the cluster using `tctl`, which returns a private key
encoded as a JWK that the cluster will use to authenticate with the management
plane. The private key is needed when rendering the secrets for the cluster.

Run the following command to generate a service account private key for the cluster:

```bash{promptUser:alice}
tctl install cluster-service-account \
    --cluster <cluster-name-in-tsb> \
    > cluster-<cluster-name-in-tsb>-service-account.jwk
```

The TSB management plane does not store the private key, so it is recommended to
run the command once and store the the private key in
`cluster-<cluster-name>-service-account.jwk` securely. Each time it is run
a new private key will be created and associated with the service account in
addition to the older keys. The older keys will continue to work so it is safe
to run this command multiple times.

Now use `tctl` to render the Kubernetes secrets for the cluster, providing the
cluster name, service account key and Elasticsearch credentials. If using self-signed
certificates for the management plane, XCP or Elasticsearch, the CA bundle must also be
provided here.

:::note Self signed certificate
If you use self signed certificate, you can use Demo install as reference how to set necessary CA bundle. You should have CA bundle from management plane installation step where you create your self-signed certificates. If you use front-envoy as Elasticsearch proxy, you must use front-envoy CA certificate for `--elastic-ca-certificate`
:::note

<Tabs
  defaultValue="Standard"
  values={[
    {label: 'Standard', value: 'Standard'},
    {label: 'Demo install', value: 'Demo'},
]}>

  <TabItem value="Standard">

The following command will generate `controlplane-secrets.yaml` that contains Elasticsearch credentials and service account key.

```bash{promptUser: alice}
tctl install manifest control-plane-secrets \
    --cluster <cluster-name-in-tsb> \
    --cluster-service-account="$(cat cluster-<cluster-name-in-tsb>-service-account.jwk)" \
    > controlplane-secrets.yaml
```

  </TabItem>
  <TabItem value="Demo">

To onboard your cluster to existing demo installation, you need to get necessary CA
from existing control and management planes already running in the demo cluster. Before you continue, make sure to use demo cluster kubeconfig.

Get management plane CA using following command.
```bash{promptUser: alice}
kubectl get -n tsb secret tsb-certs -o jsonpath='{.data.ca\.crt}' | base64 --decode > mp-certs
```

Since Elasticsearch is proxied behind front-envoy,
Elasticsearch CA is same as management plane CA and can also get obtained here:
```bash{promptUser: alice}
kubectl get -n istio-system secret es-certs -o jsonpath='{.data.ca\.crt}' | base64 --decode > es-certs
```

Get XCP central CA using following command
```bash{promptUser: alice}
kubectl get -n tsb secret xcp-central-cert -o jsonpath='{.data.ca\.crt}' | base64 --decode > xcp-central-ca-certs
```

Create control plane secrets using following command.

```bash{promptUser: alice}
tctl install manifest control-plane-secrets \
    --cluster <cluster-name-in-tsb> \
    --cluster-service-account="$(cat cluster-<cluster-name-in-tsb>-service-account.jwk)" \
    --elastic-ca-certificate="$(cat es-certs)" \
    --management-plane-ca-certificate="$(cat mp-certs)" \
    --xcp-central-ca-bundle="$(cat xcp-central-ca-certs)" \
    > controlplane-secrets.yaml
```

Before you apply the secrets yaml, make sure switch kubeconfig from demo cluster to the cluster that you want to onboard.

  </TabItem>
</Tabs>

<br />

For more information, see the CLI reference for the `tctl`
[install control plane secrets](../../reference/cli/reference/install#tctl-install-manifest-control-plane-secrets)
command. You can also check the bundled explanation from `tctl` by running this help command:

```bash{promptUser: alice}
tctl install manifest control-plane-secrets --help
```

### Applying secrets

Once you've created your secrets manifest, you can add to source control or apply it to your cluster.

<Tabs
  defaultValue="Default"
  values={[
    {label: 'Standard', value: 'Default'},
    {label: 'OpenShift', value: 'OC'},
  ]}>
  <TabItem value="Default">

```bash{promptUser:alice}
kubectl apply -f controlplane-secrets.yaml
```

  </TabItem>
  <TabItem value="OC">

```bash{promptUser:alice}
oc apply -f controlplane-secrets.yaml
```

  </TabItem>
</Tabs>

### Intermediate Istio CA Certificates

By default the Istio CA will generate a self-signed root certificate and key and use them to sign the workload certificates. If you want to deploy a TSB control plane in multi-cluster environment, Istio in all clusters must use the same root certificate. See [Intermediate Istio CA Certificates](../certificate/certificate-setup#intermediate-istio-ca-certificates) for more details on how to setup Istio CA in the control plane.

:::note Automated Certificate Management
Since 1.7, TSB supports automated certificate management intermediate Istio CA certificates. Go to [Automated Certificate Management](../certificate/automated-certificate-management) for more details. If you want to use automated certificate management, you can skip this section. 

Make sure that you have enabled this in your [management plane](./management-plane-installation#management-plane-installation) installation by setting `certIssuer.clusterIntermediateCAs` in the management plane custom resource.

You also need to enable this in the control plane custom resource by setting `components.xcp.centralProvidedCaCert` as shown below.
:::

:::note Demo installation
Istio control plane that installed in the demo cluster is using generated self-signed root CA.
If you want to include demo control plane in multi-cluster environment you must update Istio `cacerts`
in the Demo cluster `istio-system` namespace with new one issued using same root CA that is used for other clusters.

Then restart `istiod` and all your workloads in the demo cluster so it will have new root CA. You also need
to restart `oap-deployment` in `istio-system` namespace so workloads can send access log to OAP.
:::

## Control Plane Installation

Finally, you will need to create a [ControlPlane](../../refs/install/controlplane/v1alpha1/spec#controleplanespec)
custom resource in Kubernetes that describes the control plane you wish to deploy.

For this step, you will be creating a manifest file that must include several variables:

| Field Name | Variable Name | Description |
|------------|---------------|-------------|
| `hub` | `registry-location` | URL of your Docker registry. |
| `managementPlane.clusterName` | `cluster-name-in-tsb` | Name used when the cluster was [registered](#creating-cluster-object) to TSB management plane. |
| `managementPlane.host` | `tsb-address` | Address where your TSB management plane is running. This is external IP of `front-envoy` service or domain name that you use in your DNS entry. For AWS, use ELB DNS name. |
| `managementPlane.port` | `tsb-port` | Port number where your TSB  management plane is listening. Default is 8443. |
| `managementPlane.selfSigned` | `<is-mp-use-self-signed-certificate>` | Set to `true` is you use self signed certificate for the management plane. If you are not using self-signed certificates, you can either omit these fields or specify an explicit `false` value. |
| `telemetryStore.elastic.host` | `elastic-address` | Address where your Elasticsearch instance is running. |
| `telemetryStore.elastic.port` | `elastic-port` | Port number where your Elasticsearch instance is listening. |
| `telemetryStore.elastic.selfSigned` | `<is-elastic-use-self-signed-certificate>` | Set to `true` is you use self signed certificate for the Elasticsearch. If you are not using self-signed certificates, you can either omit these fields or specify an explicit `false` value. |
| `telemetryStore.elastic.protocol` | `elastic-protocol` | Either `http` or `https` with default to `https`. Note that default value will not stored in CRD. |
| `telemetryStore.elastic.version` | `elastic-version` | The major version number of your Elasticsearch instance (e.g. if version is `7.13.0`, the value should be `7` |

:::note Self signed certificate
If you are using self signed certificate, check example in `Demo install` below to set custom SNI.
:::

<Tabs
  defaultValue="Default"
  values={[
    {label: 'Standard', value: 'Default'},
    {label: 'Mirantis', value: 'MKE'},
    {label: 'Demo install', value: 'Demo'},
  ]}>
  <TabItem value="Default">

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  name: controlplane
  namespace: istio-system
spec:
  hub: <registry-location>
  managementPlane:
    host: <tsb-address>
    port: <tsb-port>
    clusterName: <cluster-name-in-tsb>
    selfSigned: <is-mp-use-self-signed-certificate>
  telemetryStore:
    elastic:
      host: <elastic-hostname-or-ip>
      port: <elastic-port>
      version: <elastic-version>
      selfSigned: <is-elastic-use-self-signed-certificate>
  components:
    xcp:
      centralProvidedCaCert: true
    internalCertProvider:
      certManager:
        managed: INTERNAL
```

For more details on what each of these sections describes and how to configure
them, please check out the following links:
- [Telemetry Store](../../refs/install/controlplane/v1alpha1/spec#telemetrystore)
- [Management Plane](../../refs/install/controlplane/v1alpha1/spec#managementplanesettings)
- [Internal Cert Provider](../../refs/install/common/common_config#internalcertprovider)

This can then be applied to your Kubernetes cluster:

```bash{promptUser:alice}
kubectl apply -f controlplane.yaml
```

  </TabItem>
  <TabItem value="MKE">
Istio requires the use of the CNI plugin in order to inject the sidecar
in the pods. You will also need an overlay to the Istio CNI DaemonSet
to run them with privileged permissions.

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  name: controlplane
  namespace: istio-system
spec:
  components:
    xcp:
      centralProvidedCaCert: true
    internalCertProvider:
      certManager:
        managed: INTERNAL
    istio:
      kubeSpec:
        CNI:
          chained: true
          binaryDirectory: /opt/cni/bin
          configurationDirectory: /etc/cni/net.d
# Depending in the underlaying machine OS, you will need to uncomment the following
# lines if istio CNI pods need privileged permissions to run.
#       overlays:
#       - apiVersion: install.istio.io/v1alpha1
#         kind: IstioOperator
#         name: tsb-istiocontrolplane
#         patches:
#         - path: spec.components.cni.k8s
#             overlays:
#             - apiVersion: extensions/v1beta1
#               kind: DaemonSet
#               name: istio-cni-node
#               patches:
#               - path: spec.template.spec.containers.[name:install-cni].securityContext
#                 value:
#                   privileged: true
  hub: <registry-location>
  managementPlane:
    host: <tsb-address>
    port: <tsb-port>
    clusterName: <cluster-name-in-tsb>
    selfSigned: <is-mp-use-self-signed-certificate>
  telemetryStore:
    elastic:
      host: <elastic-hostname-or-ip>
      port: <elastic-port>
      version: <elastic-version>
      selfSigned: <is-elastic-use-self-signed-certificate>
  meshExpansion: {}
```

For more details on what each of these sections describes and how to configure
them, please check out the following links:
- [Telemetry Store](../../refs/install/controlplane/v1alpha1/spec#telemetrystore)
- [Management Plane](../../refs/install/controlplane/v1alpha1/spec#managementplanesettings)
- [Internal Cert Provider](../../refs/install/common/common_config#internalcertprovider)

Before applying it, bear in mind that you will have to grant `cluster-admin`
role to `istio-system:istio-operator` service account.

This can then be applied to your Kubernetes cluster:

```bash{promptUser:alice}
kubectl apply -f controlplane.yaml
```

  </TabItem>
  <TabItem value="Demo">

Since demo installation is using auto generated self signed certificate, you have to specify XCP custom SNI to pass TLS validation check. You will use overlay to set XCP central SNI value as shown below.

Demo installation also use management plane `front-envoy` as proxy to the deployed Elasticsearch in the demo cluster. So you will use same `<tsb-address>` and `<tsb-port>` to configure `telemetryStore.elastic`.


```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  name: controlplane
  namespace: istio-system
spec:
  hub: <registry-location>
  managementPlane:
    host: <tsb-address>
    port: <tsb-port>
    clusterName: <cluster-name-in-tsb>
    selfSigned: true
  telemetryStore:
    elastic:
      host: <tsb-address>
      port:  <tsb-port>
      version: 7
      selfSigned: true
  components:
    internalCertProvider:
      certManager:
        managed: INTERNAL
    xcp:
      centralAuthMode: JWT
      centralProvidedCaCert: true
      kubeSpec:
        overlays:
        - apiVersion: install.xcp.tetrate.io/v1alpha1
          kind: EdgeXcp
          name: edge-xcp
          patches:
          - path: spec.centralAuthJwt.centralSni
            value: "central.xcp.tetrate.io"
```

For more details on what each of these sections describes and how to configure
them, please check out the following links:
- [Telemetry Store](../../refs/install/controlplane/v1alpha1/spec#telemetrystore)
- [Management Plane](../../refs/install/controlplane/v1alpha1/spec#managementplanesettings)
- [Internal Cert Provider](../../refs/install/common/common_config#internalcertprovider)

This can then be applied to your Kubernetes cluster:

```bash{promptUser:alice}
kubectl apply -f controlplane.yaml
```

  </TabItem>

</Tabs>

:::note
To onboard a cluster, you do not need to create any data plane descriptions at
this stage. Data plane descriptions are only needed when adding Gateways. For
more information, see the section on [Gateways](../../quickstart/ingress_gateway)
in the [usage quickstart](../../quickstart/introduction) guide.
:::

### Verify Onboarded Cluster

To verify a cluster has been successfully onboarded check that the pods have all
started correctly.

<Tabs
  defaultValue="Default"
  values={[
    {label: 'Standard', value: 'Default'},
    {label: 'OpenShift', value: 'OC'},
  ]}>
  <TabItem value="Default">

```bash{promptUser:alice}{outputLines:2-9,10-11}
kubectl get pod -n istio-system
NAME                                          READY   STATUS    RESTARTS   AGE
edge-66cbf867c6-rshqh                                    1/1     Running   0      1m25s
istio-operator-78446c59c5-dg28c                          1/1     Running   3      1m25s
istio-system-custom-metrics-apiserver-557ffcfbc8-lpw2f   1/1     Running   0      1m25s
istiod-6d474df64f-2w8s8                                  1/1     Running   0      1m25s
oap-deployment-894544dd6-v2w77                           3/3     Running   0      1m25s
onboarding-operator-f68684bf4-txwxn                      1/1     Running   1      1m25s
otel-collector-765d5c6475-6zfnf                          3/3     Running   0      1m25s
tsb-operator-control-plane-554c56d4f4-cnzjg              1/1     Running   3      1m25s
xcp-operator-edge-787fc64b8d-rhlth                       1/1     Running   5      1m25s
```

  </TabItem>
  <TabItem value="OC">

```bash{promptUser:alice}{outputLines:2-9,10-11}
oc get pod -n istio-system
NAME                                          READY   STATUS    RESTARTS   AGE
edge-66cbf867c6-rshqh                                    1/1     Running   0      1m25s
istio-operator-78446c59c5-dg28c                          1/1     Running   3      1m25s
istio-system-custom-metrics-apiserver-557ffcfbc8-lpw2f   1/1     Running   0      1m25s
istiod-6d474df64f-2w8s8                                  1/1     Running   0      1m25s
oap-deployment-894544dd6-v2w77                           3/3     Running   0      1m25s
onboarding-operator-f68684bf4-txwxn                      1/1     Running   1      1m25s
otel-collector-765d5c6475-6zfnf                          3/3     Running   0      1m25s
tsb-operator-control-plane-554c56d4f4-cnzjg              1/1     Running   3      1m25s
xcp-operator-edge-787fc64b8d-rhlth                       1/1     Running   5      1m25s
```

#### Istio setup for onboarded applications

Besides the CNI configuration required in the `ControlPlane`, you need to be
aware that any namespace that is going to have workloads with Istio sidecars,
will need a to account for the need of creating a `NetworkAttachmentDefinition`
object created so that the pods can be attached to the `istio-cni` network.

```bash{promptUser: alice}{outputLines: 2-6}
cat <<EOF | oc -n <target-namespace> create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: istio-cni
EOF
```

Also note that the envoy sidecars injected into the workloads run as user ID
1337, and that is disallowed by default in OpenShift. Hence, we will need to add
the `anyuid` SCC (or any other SCC that allows the aforementioned user ID) to
the service accounts used in the application namespace.

```bash{promptUser:alice}{outputLines: 2}
oc adm policy add-scc-to-group anyuid \
    system:serviceaccounts:<target-namespace>
```

  </TabItem>
</Tabs>

### Verify Cluster Status

Then check if cluster status is sent to the management plane. You can do this by using TSB UI. Login to TSB UI, then go to Clusters page and see if your newly onboarded cluster has the following information available: Provider, XCP Version, Istio Version and Last Sync.

You can also use tctl by executing the following
```bash
tctl get clusters <cluster-name-in-tsb> -o yaml | grep state: -A 5
```

```bash
  state:
    istioVersions:
    - 1.12.4-34a16db007
    lastSyncTime: "2022-07-01T06:24:34.562924571Z"
    provider: gke
    xcpVersion: v1.3.0-rc31
```

If you see Cluster state, it means XCP edge in the control plane has connected to XCP central in the management plane.
