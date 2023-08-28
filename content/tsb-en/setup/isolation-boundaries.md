---
title: Istio Isolation Boundaries
description: How to deploy or upgrade multiple isolated control plane clusters using isolation boundaries
---

Istio Isolation Boundaries can run multiple TSB-managed Istio environments within a Kubernetes cluster, or spanning several clusters. These Istio environments are isolated from each other in terms of service discovery and config distribution. Isolation Boundaries bring several benefits:

- Strong network isolation provides strict and easy-to-demonstrate security by default in highly-regulated environments
- The ability to run different Istio versions within a cluster allows you to support legacy and modern applications in the same cluster
- Canary Releases provide flexibility in how TSB upgrades can be tested and deployed

## Installation

:::note Upgrade
For upgrading from non-revisioned to revisioned control plane, follow the steps as mentioned in [Non-revisioned to Revisioned Upgrades](./upgrades/non-revisioned-to-revisioned)
:::

:::note OpenShift
If you use OpenShift, simply replace `kubectl` commands below with `oc`.
:::

For a fresh installation, you can follow the standard steps to onboard a control plane cluster using [tctl](../setup/self_managed/onboarding-clusters) or [helm](../setup/helm/controlplane) along with the following changes:

1. Enable isolation boundary in TSB controlplane operator by setting `ISTIO_ISOLATION_BOUNDARIES` to `true`
2. Add isolation boundaries definition in `ControlPlane` CR or control plane Helm values.

In the following example, you will use Helm to onboard a cluster with isolation boundary enabled. 

### Install with Helm

Follow the instructions in [control plane installation with Helm](../setup/helm/controlplane#installation) using following Helm values to enable Istio Isolation Boundaries.

```yaml
operator:
  deployment:
    env:
      - name: ISTIO_ISOLATION_BOUNDARIES
        value: "true"

spec:
  managementPlane:
    clusterName: <cluster-name-in-tsb>
    host: <tsb-address>
    port: <tsb-port>
  telemetryStore:
    elastic:
      host: <tsb-address>
      port: <tsb-port>
      version: <elastic-version>
      selfSigned: <is-elastic-use-self-signed-certificate>
  components:
    xcp:
      isolationBoundaries:
      - name: dev
        revisions:
        - name: dev-stable
      - name: qa
        revisions:
        - name: qa-stable

secrets:
  clusterServiceAccount:
    clusterFQN: organizations/jupiter/clusters/<cluster-name-in-tsb>
    JWK: '$JWK'
```

After the installation steps are done, look at `deployments`, `configmaps` and `webhooks` in the `istio-system` namespace. All resources which are part of the revisioned Istio control plane will be having `revisions.name` as a suffix in the name. These resources are going to be present for every revision that is configured under `isolationBoundaries`.

The control plane operator validates whether the revision name across isolation boundaries is unique. This revision name value will be used to configure revisioned namespaces and bring up revisioned data-plane gateways.

```bash{promptUser:alice}
kubectl get deployment -n istio-system | grep stable
```
```bash{promptUser:alice}
# Output
istio-operator-dev-stable             1/1     1            1           2d1h
istio-operator-qa-stable              1/1     1            1           45h
istiod-dev-stable                     1/1     1            1           2d1h
istiod-qa-stable                      1/1     1            1           45h
```

```bash{promptUser:alice}
kubectl get configmap -n istio-system | grep stable
```
```bash{promptUser:alice}
# Output
istio-dev-stable                      2      2d1h
istio-qa-stable                       2      45h
istio-sidecar-injector-dev-stable     2      2d1h
istio-sidecar-injector-qa-stable      2      45h
```

### Install with tctl

If you prefer to use [tctl installation](./self_managed/onboarding-clusters), you can use following command to generate cluster operator with Istio Isolation Boundaries enabled

```bash{promptUser:alice}
tctl install manifest cluster-operators \
  --registry <registry-location> \
  --set "operator.deployment.env[0].name=ISTIO_ISOLATION_BOUNDARIES" \
  --set "operator.deployment.env[0].value=true" > clusteroperators.yaml
```

Then update `xcp` component in your `ControlPlane` CR or Helm values with `isolationBoundaries`:
```yaml
spec:
  ...
  components:
    xcp:
      isolationBoundaries:
      - name: dev
        revisions:
        - name: dev-stable
      - name: qa
        revisions:
        - name: qa-stable
```

Following examples to use Isolation Boundaries are same regardless of your installation preference.

### Specifying TSB version in revisions

Istio Isolation Boundaries also provide a way to control the Istio version to be used for deploying control plane components and data-plane proxies. This can be specified in the isolation boundary configurations as follows:

```yaml
spec:
  ...
  components:
    xcp:
      isolationBoundaries:
      - name: dev
        revisions:
        - name: dev-stable
          istio:
            tsbVersion: 1.6.1
      - name: qa
        revisions:
        - name: qa-stable
          istio:
            tsbVersion: 1.6.0
```

With these configurations, two revisioned control planes are deployed - with corresponding TSB released Istio images.
Having multiple revisions in a single isolation boundary helps upgrade workloads in a particular isolation boundary, from one `tsbVersion` to another. See [Revisioned to Revisioned Upgrades](./upgrades/revisioned-to-revisioned) for more details.

If the `tsbVersion` field is left empty, the ControlPlane resource defaults to the current TSB released version.

## Using isolation boundary and revisions

### Application deployment

Workloads can now be deployed in appropriate namespaces with a revision label. The revision label `istio.io/rev` determines the revisioned control plane for the proxies to connect to, for service discovery and xDS updates.
Make sure to configure the workload Namespaces as follows:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  labels:
    istio.io/rev: dev-stable
  name: dev-bookinfo
---
apiVersion: v1
kind: Namespace
metadata:
  labels:
    istio.io/rev: qa-stable
  name: qa-bookinfo
```

Application Pods in these namespaces will be injected with the istio-proxy configurations that enable them to connect to their respective revisioned Istio control planes.

### VM workload onboarding

:::note Single Isolation boundary
[Workload Onboarding](./workload_onboarding/guides) only support single isolation boundary. Support for multiple isolation boundary will be available in next releases.
:::

By default, workload onboarding will use non-revisioned Istio control plane. To use revisioned control plane, You need to use [revisioned link](./workload_onboarding/guides/setup#installing-istio-sidecar-for-revisioned-istio) to download Istio sidecar from TSB workload onboarding repository.

You also need to update [agent configuration](../refs/onboarding/config/agent/v1alpha1/agent_configuration) in `/etc/onboarding-agent/agent.config.yaml` in your VM to add revision value.

```yaml
apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
kind: AgentConfiguration
sidecar:
  istio:
    revision: dev-stable
```

Then restart onboarding agent. 
```
systemctl restart onboarding-agent
```

If you use cloud-init to provision your VM, then you need to add above `AgentConfiguration` in your cloud-init file. Since file `/etc/onboarding-agent/agent.config.yaml` might be created in advance, for Debian based OS, you need to pass `-o Dpkg::Options::="--force-confold"` when installing onboarding agent for non-interactive installation.

```
sudo apt-get install -y -o Dpkg::Options::="--force-confold" ./onboarding-agent.deb
```

### Workspace configurations

Every workspace can be configured to be part of an isolation boundary by specifying the isolation boundary name as shown below:

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: tetrate
  tenant: tetrate
  name: qa-ws
spec:
  isolationBoundary: qa
  namespaceSelector:
    names:
      - "*/qa-bookinfo"
```

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: tetrate
  tenant: tetrate
  name: dev-ws
spec:
  isolationBoundary: dev
  namespaceSelector:
    names:
      - "*/dev-bookinfo"
```

:::note Brownfield Setup
In a brownfield setup, existing Workspaces would not be configured with any particular isolation boundary. In that case, if Istio Isolation Boundaries are enabled and configured, the Workspace will look to be part of an isolation boundary - named "global". If this "global" isolation boundary is not configured in the `ControlPlane` CR, the Workspace will not be a part of any isolation boundary.
Therefore, it is recommended to create a fallback isolation boundary named "global", for Workspaces that do not specify any isolation boundary in their spec.

```yaml
spec:
  ...
  components:
    xcp:
      isolationBoundaries:
      - name: global
        revisions:
          - name: default
```
:::


### Gateway deployment

For each gateway (Ingress/Egress/Tier1) resource, you must set a `revision` that belongs to the desired isolation boundary.

For example in your Ingress gateway deployment:

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: tsb-gateway-dev-bookinfo
  namespace: dev-bookinfo
spec:
  revision: dev-stable         # Revision value
```

Once applied, this will result in **revisioned** gateway deployment. 

### Istio isolation

Having multiple isolation boundaries set up in a single/multiple clusters allow users to run multiple mesh environments that are segregated in terms of service discovery. This means that a Service in one isolation boundary will only be discoverable to clients in the same isolation boundary, and therefore will allow traffic to Services in the same isolation boundary. Services that are separated via isolation boundaries are not be able to discover each other, leading to no inter-boundary traffic.

As a simple example consider the following isolation boundary configuration

```yaml
...
spec:
  ...
  components:
    xcp:
      isolationBoundaries:
      - name: dev
        revisions:
        - name: dev-stable
        revisions:
        - name: dev-testing
      - name: qa
        revisions:
        - name: qa-stable
```

This could correspond to three separate namespaces `dev-bookinfo`, `dev-bookinfo-testing` and `qa-bookinfo` with the revision labels attached appropriately.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  labels:
    istio.io/rev: dev-testing
  name: dev-bookinfo-testing
---
apiVersion: v1
kind: Namespace
metadata:
  labels:
    istio.io/rev: dev-stable
  name: dev-bookinfo
---
apiVersion: v1
kind: Namespace
metadata:
  labels:
    istio.io/rev: qa-stable
  name: qa-bookinfo
```

Note that the namespaces `dev-bookinfo` and `dev-bookinfo-testing` are part of the same isolation boundary `dev`, whereas the namespace `qa-bookinfo` is part of the isolation boundary `qa`.

This configuration will have the following affects in the cluster:

1. Services in namespace `dev-bookinfo` will be discovered by proxies running in namespaces `dev-bookinfo` and `dev-bookinfo-testing`. This is because both namespaces `dev-bookinfo` and `dev-bookinfo-testing` are a part of the same isolation boundary.

2. Services in namespace `dev-bookinfo` will NOT be discovered by proxies running in namespace `qa-bookinfo`. This is because namespaces `dev-bookinfo` and `qa-bookinfo` are part of different isolation boundaries.

And similarly for other namespaces.

### Strict isolation

If a Service from one boundary tries to communicate to a Service in a different boundary, the "client" side proxy treats the outbound traffic to be destined outside the mesh. By default, this traffic is allowed, but can be restricted by using `outboundTrafficPolicy` in the `IstioOperator` resource mesh config.
By default, the value for this `outboundTrafficPolicy` is set as

```yaml
outboundTrafficPolicy:
  mode: ALLOW_ANY
```

In order to restrict cross-isolation-boundary traffic you can set the `.outboundTrafficPolicy.mode` to `REGISTRY_ONLY`.

- First list down the `IstioOperator` resources in the `istio-system` namespace.
```bash{promptUser:alice}
kubectl get iop -n istio-system | grep xcp-iop
```

```bash{promptUser:alice}
# Output
xcp-iop-dev-stable               stable   HEALTHY     25h
xcp-iop-dev-testing              stable   HEALTHY     25h
xcp-iop-qa-stable                stable   HEALTHY     25h
```

- Choose the `IstioOperator` resource name for which the outboundTrafficPolicy config needs to be set. We will patch the `xcp-iop-dev-stable` IstioOperator resource with the policy configuration. Edit the Helm values for the TSB control plane above, and following overlay for `istio` component:

```yaml
spec:
  ...
  components:
    istio:
      kubeSpec:
        overlays:
        - apiVersion: install.istio.io/v1alpha1
          kind: IstioOperator
          name: xcp-iop-dev-stable
          patches:
          - path: spec.meshConfig.outboundTrafficPolicy
            value:
              mode: REGISTRY_ONLY
```

This can be done for other `IstioOperator`s in a similar fashion, by appending the overlays.

## Troubleshooting

1. Look for `ingressdeployment`, `egressdeployment`, `tier1deployment` resources in the `istio-system` namespace corresponding to TSB `IngressGateway`, `EgressGateway`, `Tier1Gateway` resources respectively.

```bash{promptUser:alice}
kubectl get ingressdeployment -n istio-system
```
```bash{promptUser:alice}
# Output
NAME                       AGE
tsb-gateway-dev-bookinfo   3h10
```

If missing, the TSB control plane operator did not reconcile TSB gateway resource to corresponding XCP resource. First, re-verify the revision match between the TSB control plane operator and Gateway resource.
Next, the operator logs should give some hints.

2. Look for corresponding `IstioOperator` resource in the `istio-system` namespace. Example:

```bash{promptUser:alice}
kubectl get iop -n istio-system | grep dev-stable
```
```bash{promptUser:alice}
# Output
xcp-iop-dev-stable               dev-stable   HEALTHY     25h
xcpgw-tsb-dev-gateway-bookinfo   dev-stable   HEALTHY     3h14m
```
If missing, the `xcp-operator-edge` logs should give some hints.

3. If the above two points are OK and the gateway deployment/services are still not getting deployed, or the deployment configurations not as configured in the `IstioOperator` resource, the Istio operator deployment logs should give some hints.

4. To troubleshoot service discovery between revisioned namespace workloads, look at the control plane `IstioOperator` resource in the `istio-system` namespace. For multiple revisions there will be multiple resources.

```bash{promptUser:alice}
kubectl get iop -n istio-system | grep xcp-iop
```
```bash{promptUser:alice}
# Output
xcp-iop-dev-stable               stable   HEALTHY     25h
xcp-iop-dev-testing              stable   HEALTHY     25h
xcp-iop-qa-stable                stable   HEALTHY     25h
```

Service discovery in namespace workloads is determined by the `.spec.meshConfig.discoverySelectors` field in the control plane `IstioOperator` resources. Considering `dev-stable` and `dev-testing` revisions share an isolation boundary, the `discoverySelectors` in both the `IstioOperator` resources (`xcp-iop-dev-stable` and `xcp-iop-dev-staging`) must look like

```yaml
  discoverySelectors:
  - matchLabels:
      istio.io/rev: dev-stable
  - matchLabels:
      istio.io/rev: dev-testing
```

but since the revision `qa-stable` is part of a separate isolation boundary the `discoverySelectors` in `xcp-iop-qa-stable` would look simply like

```yaml
  discoverySelectors:
    - matchLabels:
        istio.io/rev: qa-stable
```

5. To further debug service discovery by istio proxies and traffic between services, the following `istioctl` commands come in handy

```bash{promptUser:alice}
istioctl pc endpoints -n <namespace> deploy/<deployment-name>
```
```bash{promptUser:alice}
# Output
ENDPOINT                                                STATUS      OUTLIER CHECK     CLUSTER
10.20.0.36:8090                                         HEALTHY     OK                outbound|80||echo.echo.svc.cluster.local
10.255.20.128:15443                                     HEALTHY     OK                outbound|80||echo.tetrate.io
...
127.0.0.1:15000                                         HEALTHY     OK                prometheus_stats
127.0.0.1:15020                                         HEALTHY     OK                agent
unix://./etc/istio/proxy/XDS                            HEALTHY     OK                xds-grpc
unix://./var/run/secrets/workload-spiffe-uds/socket     HEALTHY     OK                sds-grpc
```

and
```bash{promptUser:alice}
istioctl pc routes -n <namespace> deploy/<deployment-name>
```
```bash{promptUser:alice}
# Output
NAME                                                        DOMAINS                                                         MATCH                  VIRTUAL SERVICE
80                                                          echo, echo.echo + 1 more...                                     /*
80                                                          echo.tetrate.io, 240.240.0.1                                    /*
echo-gateway.echo.svc.cluster.local:15021                   *                                                               /*
...
                                                            *                                                               /stats/prometheus*
                                                            *                                                               /healthz/ready*
inbound|7070||                                              *                                                               /*
InboundPassthroughClusterIpv4                               *                                                               /*
inbound|8090||                                              *                                                               /*
```
