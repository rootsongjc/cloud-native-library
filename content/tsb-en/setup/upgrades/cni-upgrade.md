---
title: Revisioned Istio CNI and Upgrades
description: How to manage revisioned Istio CNI and upgrade Istio CNI from one revision to another.
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

Before you continue, make sure you are familiar with [Istio Isolation Boundaries](../isolation-boundaries) feature.

## Revisioned Istio CNI

The Istio CNI can be bound to a specific Istio revision, in a revisioned Istio environment. Consider the following Isolation Boundary configuration that allows for managing revisioned Istio environments

```yaml
spec:
  ...
  components:
    xcp:
      isolationBoundaries:
      - name: global
        revisions:
        - name: stable
          istio:
            tsbVersion: 1.6.1
```

Once a revision is in place, Istio CNI can be enabled with the revision specified under Isolation Boundary configuration as shown below

<Tabs
  defaultValue="Non-Openshift"
  values={[
    {label: 'Non-Openshift', value: 'Non-Openshift'},
    {label: 'Openshift', value: 'Openshift'},
  ]}>
  <TabItem value="Non-Openshift">

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  name: <cluster-name>
  namespace: istio-system
spec:
  components:
    istio:
      kubeSpec:
        CNI:
          chained: true
          binaryDirectory: /opt/cni/bin
          configurationDirectory: /etc/cni/net.d
          revision: stable
    ...
    xcp:
      isolationBoundaries:
      - name: global
        revisions:
        - name: stable
          istio:
            tsbVersion: 1.6.1
    ...
  hub: <registry-location>
  managementPlane:
    host: <tsb-address>
    port: <tsb-port>
    clusterName: <cluster-name>
  telemetryStore:
    elastic:
      host: <elastic-hostname-or-ip>
      port: <elastic-port>
      version: <elastic-version>
```

  </TabItem>
  <TabItem value="Openshift">

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  name: <cluster-name>
  namespace: istio-system
spec:
  components:
    istio:
      kubeSpec:
        CNI:
          revision: stable
    ...
    xcp:
      isolationBoundaries:
      - name: global
        revisions:
        - name: stable
          istio:
            tsbVersion: 1.6.1
    ...
  hub: <registry-location>
  managementPlane:
    host: <tsb-address>
    port: <tsb-port>
    clusterName: <cluster-name>
  telemetryStore:
    elastic:
      host: <elastic-hostname-or-ip>
      port: <elastic-port>
      version: <elastic-version>
```

  </TabItem>
</Tabs>

:::note Brownfield Setup
In a brownfield setup, with Isolation Boundaries and Istio CNI already enabled - the `revision` value defaults to the revision with the latest `revisions[].istio.tsbVersion`.
If multiple such `tsbVersion`s are present, alphabetical preference is given based on `revisions[].name`.
:::


## Istio CNI Upgrade

Once Istio CNI is bound to a revision, upgrading to a different revision is fairly straightforward.

First add a `canary` Istio control plane under the Isolation Boundaries configuration.

```yaml
spec:
  ...
  components:
    xcp:
      isolationBoundaries:
      - name: global
        revisions:
        - name: stable
          istio:
            tsbVersion: 1.6.1
        - name: canary
          istio:
            tsbVersion: 1.6.1-rc1
```

Then, update the `revision` value under Istio CNI settings, to point to the `canary` revision as shown below.

:::note Openshift
For Openshift environments, Istio CNI is enabled by default and no specific configuration is required. Therefore, to manage revisioned Istio CNI in Openshift, on the `revision` field is supported.
:::

<Tabs
  defaultValue="Non-Openshift"
  values={[
    {label: 'Non-Openshift', value: 'Non-Openshift'},
    {label: 'Openshift', value: 'Openshift'},
  ]}>
  <TabItem value="Non-Openshift">

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  name: <cluster-name>
  namespace: istio-system
spec:
  components:
    istio:
      kubeSpec:
        CNI:
          chained: true
          binaryDirectory: /opt/cni/bin
          configurationDirectory: /etc/cni/net.d
          revision: canary
    ...
    xcp:
      isolationBoundaries:
      - name: global
        revisions:
        - name: stable
          istio:
            tsbVersion: 1.6.1
        - name: canary
          istio:
            tsbVersion: 1.6.1-rc1
  ...
```

  </TabItem>
  <TabItem value="Openshift">

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  name: <cluster-name>
  namespace: istio-system
spec:
  components:
    istio:
      kubeSpec:
        CNI:
          revision: canary
    ...
    xcp:
      isolationBoundaries:
      - name: global
        revisions:
        - name: stable
          istio:
            tsbVersion: 1.6.1
        - name: canary
          istio:
            tsbVersion: 1.6.1-rc1
  ...
```

  </TabItem>
</Tabs>
