---
title: Customizing TSB Kubernetes Components
Description: Explanation on how to configure TSB components in Kubernetes, including overlays.
---

This document describes how to customize the Kubernetes deployments for TSB components, including using overlays to perform advanced configuration of resources that are deployed by the Tetrate Service Bridge (TSB) operators, using examples.

## Background

TSB makes extensive use of the [Operator](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) pattern to deploy and configure the necessary parts in Kubernetes.

Normally customization and fine tuning of the parameters are done through the operator, which is responsible for creating the necessary resources and controlling their lifecycles.

For example, when you create an IngressGateway CR, a TSB operator picks up this information  and deploys and/or updates the relevant resources, such as Kubernetes Service objects, by creating a manifest and applying them. The manifest will use certain parameters that you have provided, along with other default values that are computed by TSB.

However, TSB does not necessarily expose all of the knobs to fine tune the Service objects. If TSB were to provide all hooks to configure the Service object, TSB would have to effectively replicate the entire Kubernetes API, which is realistically not feasible nor desirable.

This is where we use overlays, which allows you to override and apply custom configurations to resources that are being deployed. For more details on how overlays work, please read the [documentation for overlays in the reference](../refs/install/kubernetes/k8s).

:::warning
Overlays are provide as an escape hatch mechanism for TSB features that are not ironed out, and should be used with caution. Configurations that may currently be available over overlays will most likely be removed/changed to be done through TSB operators in the future.
:::

## Notes About the Examples

In these examples that follow, the necessary configurations are applied using `kubectl edit` by directly editing the deployed manifest. If you own the original manifests you may opt to use `kubectl apply` as well, but you will have to provide the entire resource definition, not just the parts that you want to edit.

The sample manifests only show the minimum information required to be specified, along with information to specify the context (location) of where to make these changes.

:::note
Depending on your specific Kubernetes environment, you may need to modify the content of the samples for them to function properly.
:::

:::note Helm installation
All of the examples provided in this document can also be applied to Helm installations by editing management plane or control plane Helm values.

For management plane, the `spec` field in [Helm values](../setup/helm/managementplane) is same with TSB [`ManagementPlane` CR](../refs/install/managementplane/v1alpha1/spec).

For control plane, the `spec` field in [Helm values](../setup/helm/controlplane) is same with TSB [`ControlPlane` CR](../refs/install/controlplane/v1alpha1/spec).
:::

:::note OpenShift
If you use OpenShift, simply replace `kubectl` commands below with `oc`.
:::


Once you have studied these examples, you will most likely be working with far more complex overlays. One caveat that you should be aware of as you write complex overlays is that you can only have one overlay per object. For example, the following specification is syntactically valid, but only the last `patch` against `quux.corge.grault` will be applied:
.

```yaml
kubeSpec:
  overlays:
  - apiVersion: v1
    kind: ....
    name: my-object
    patches:
    - path: foo.bar.baz
      value: 1
  - apiVersion: v1
    kind: ....
    name: my-object
    patches:
    - path: quux.corge.grault
      value: hello
```

This is because the manifest contains multiple entries under `overlays` that point to the same object (`my-object`), and in such cases only the last entry is actually applied. To apply patches to both `foo.bar.baz` and `quux.corge.grault`, you must consolidate all the `patch` specifications under a single object, as follows:

```yaml
kubeSpec:
  overlays:
  - apiVersion: v1
    kind: ....
    name: my-object
    patches:
    - path: foo.bar.baz
      value: 1
    - path: quux.corge.grault
      value: hello
```

## Example Usage for Overlays

### Configure CNI with elevated privileges

Certain environments such as SELinux or OpenShift require special privileges to write files in the host system. To enable this, the `install-cni.securityContext.privileged` property must be set to `true` by editing the `ControlPlane` CR.

Edit the `ControlPlane` CR for the TSB control plane using `kubectl edit`, and use the following snippet as a sample on how to edit the manifest.

```bash
kubectl edit controlplane -n istio-system
```

```yaml
spec:
  components:
    istio:
      kubespec:
        overlays:
        - apiVersion: install.istio.io/v1alpha1
          kind: IstioOperator
          name: tsb-istiocontrolplane
          patches:
          - path: spec.components.cni.k8s
            value:
              overlays:
              - apiVersion: extensions/v1beta1
                kind: DaemonSet
                name: istio-cni-node
                patches:
                - path: spec.template.spec.containers.[name:install-cni].securityContext
                  value:
                    privileged: true
```

### Change XCP service type:

For certain environments, XCP edge can't use a LoadBalancer service type, or annotations need to be added. You can modify them by applying this overlay to the `ControlPlane` CR:

```yaml
spec:
  components:
    xcp:
      kubeSpec:
        overlays:
        - apiVersion: install.xcp.tetrate.io/v1alpha1
          kind: EdgeXcp
          name: edge-xcp
          patches:
          - path: spec.components.edgeServer.kubeSpec.service.annotations
            value:
              traffic.istio.io/nodeSelector: '{"beta.kubernetes.io/os": "linux"}'
          - path: spec.components.edgeServer.kubeSpec.overlays
            value:
            - apiVersion: v1
              kind: Service
              name: xcp-edge
              patches:
              - path: spec.type
                value: NodePort
```

### Preserve endpoint IP address

Kubernetes provides a way to preserve the IP address of the client connecting to an application, which can be used to route traffic to node-local or cluster-wide endpoints.

For this example we assume that you have deployed the following ingress gateway with service type of `LoadBalancer`:

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: tsb-gateway-bookinfo
  namespace: bookinfo
spec:
  kubeSpec:
    service:
      type: LoadBalancer
```

Edit the IngressGateway CR for the application using `kubectl edit`, and use the following snippet as a sample on how to edit the manifest.

```bash
kubectl edit tsb-gateway-bookinfo -n bookinfo
```

```yaml
spec:
  connectionDrainDuration: 10s
  kubeSpec:
    overlays:
    - apiVersion: v1
      kind: Service
      name: tsb-gateway-bookinfo
      patches:
      - path: spec.externalTrafficPolicy
        value: Local
```

### Add a host alias to `istiod`

In some scenarios, `istiod` may need to communicate with services that have no DNS records. A typical example would be when there is a need to fetch a custom Istio CA from Vault or other secret managers. The `hostAlias` patch will directly map hostnames to ip addresses in a way similar to statically adding an entry to a VM host file.

Edit the `ControlPlane` CR for the TSB control plane using `kubectl edit`, and use the following snippet as a sample on how to edit the manifest. Replace `<hostname-FQDN>` and `<ip address>` with the appropriate values.

```bash
kubectl edit controlplane -n istio-system
```

```yaml
spec:
  components:
    istio:
      kubeSpec:
        overlays:
        - apiVersion: install.istio.io/v1alpha1
          kind: IstioOperator
          name: tsb-istiocontrolplane
          patches:
          - path: spec.components.pilot.k8s.overlays
            value:
            - apiVersion: apps/v1
              kind: Deployment
              name: istiod
              patches:
              - path: spec.template.spec.hostAliases
                value:
                - hostnames:
                  - <hostname-FQDN>
                  ip: <ip address>
```

### Configure sidecar resource limits

The Sidecar API resource does not allow you to specify resource usage limit or definitions for the sidecar, but this is possible by adding an overlay to the `ControlPlane` CR. In this example, we will overwrite resource limits under the `resources` field.

Edit the `ControlPlane` CR for the TSB control plane using `kubectl edit`, and use the following snippet as a sample on how to edit the manifest. Update the actual resource limit values as necessary.

```bash
kubectl edit controlplane -n istio-system
```

```yaml
spec:
  components:
    istio:
      kubeSpec:
        overlays:
        - apiVersion: install.istio.io/v1alpha1
          kind: IstioOperator
          name: tsb-istiocontrolplane
          patches:
          - path: spec.values.global.proxy
            value:
              resources:
                limits:
                  cpu: 2000m
                  memory: 1024Mi
                requests:
                  cpu: 100m
                  memory: 128Mi
```

#### Forwarding client information

Some applications require knowing the certificate information of the connecting client. TSB uses the `x-forwarded-client-cert` header to pass this information along to the backend servers. In order to enable this feature you need to configure the Envoy proxies for ControlPlane and IngressGateway(s) as such.

For the ControlPlane, edit the `ControlPlane` CR for the TSB control plane using `kubectl edit`, and use the following snippet as a sample on how to edit the manifest

```bash
kubectl edit controlplane -n istio-system
```

```yaml
spec:
  components:
    istio:
      kubeSpec:
        overlays:
        - apiVersion: install.istio.io/v1alpha1
          kind: IstioOperator
          name: tsb-istiocontrolplane
          patches:
          - path: spec.meshConfig.defaultConfig.gatewayTopology
            value:
              forwardClientCertDetails: APPEND_FORWARD
```

For the IngressGateway, edit the IngressGateway CR for the application using `kubectl edit`, and use the following snippet as a sample on how to edit the manifest. Replace the `<ingress-name>` and `<namespace>` values as appropriate.

```bash
kubectl edit <ingress-name> -n <namespace>
```

```yaml
spec:
  kubeSpec:
    overlays:
    - apiVersion: apps/v1
      kind: Deployment
      name: <ingress-name>
      patches:
      - path: spec.template.metadata.annotations.proxy\.istio\.io/config
          gatewayTopology:
            forwardClientCertDetails: APPEND_FORWARD
```

### Controlling user session inactivity time for TSB UI

By default the user session for TSB UI expires after 15 minutes of inactivity. You may override this value by setting the `SESSION_AGE_IN_MINUTES` environment variable through the overlay mechanism.

Suppose you would like to allow the user to be logged into the Web UI for 60 minutes. Edit the `ControlPlane` CR for the TSB control plane using `kubectl edit`, and use the following snippet as a sample on how to edit the manifest.

```bash
kubectl edit managementplane -n tsb
```

```yaml
spec:
  webUI:
    kubeSpec:
      overlays:
      - apiVersion: apps/v1
        kind: Deployment
        name: web
        patches:
        - path: spec.template.spec.containers.[name:web].env[-1]
          value:
            name: SESSION_AGE_IN_MINUTES
            value: "60"
```

It is highly recommended that `SESSION_AGE_MINUTES` be set to the minimum for security best practices with regards to accessing the UI.

### Setting Environment Variables in TSB Components

Sometimes you need to go in and set arbitrary environment variables for TSB components - for example, one mitigation to the Log4j-related security vulnerabilities is to set the `LOG4J_FORMAT_MSG_NO_LOOKUPS` environment variable to `true` in Java binaries that include Log4j (versions 2.10 or above). To do this, you can use the `env` section of the Kubernetes component spec in the TSB operator configurations.

To set a value for the Management Plane (TSB) cluster, you'll update the `ManagementPlane` CR:

```yaml
spec:
  components:
    oap:
      kubeSpec:
        deployment:
          env:
          - name: LOG4J_FORMAT_MSG_NO_LOOKUPS
            value: "true"
```

And to set a value for the Control Plane (application) clusters, you'll update the ControlPlane resource:

```yaml
spec:
  components:
    oap:
      kubeSpec:
        deployment:
          env:
          - name: LOG4J_FORMAT_MSG_NO_LOOKUPS
            value: "true"
```

## References
TSB reference Doc
