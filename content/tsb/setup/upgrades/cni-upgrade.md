---
title: 修订的 Istio CNI 和升级
description: 如何管理修订的 Istio CNI 并将 Istio CNI 从一个修订版本升级到另一个版本。
weight: 4
---

在继续之前，请确保你熟悉[Istio 隔离边界](../../isolation-boundaries)功能。

## 修订的 Istio CNI

在修订的 Istio 环境中，Istio CNI 可以绑定到特定的 Istio 修订版本。考虑以下隔离边界配置，允许管理修订的 Istio 环境：

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

一旦有了修订版本，可以按照以下所示的隔离边界配置启用 Istio CNI，并指定修订版本：

**非 OpenShift**

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

**OpenShift**

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

{{<callout note "Brownfield 设置">}}
在棕地设置中，已启用隔离边界和 Istio CNI - `revision`值默认为具有最新的`revisions[].istio.tsbVersion`的修订版本。
如果存在多个这样的`tsbVersion`，则会根据`revisions[].name`的字母顺序优先考虑。
{{</callout>}}

## Istio CNI 升级

一旦 Istio CNI 与修订版本绑定，升级到不同的修订版本就非常简单。

首先，在隔离边界配置中添加一个`canary` Istio 控制平面。

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

然后，更新 Istio CNI 设置下的`revision`值，指向`canary`修订版本，如下所示。

{{<callout note "Openshift">}}
对于 Openshift 环境，默认情况下启用 Istio CNI，不需要特定的配置。因此，在 Openshift 中管理修订的 Istio CNI 只支持`revision`字段。
{{</callout>}}

**非 Openshift**

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

**Openshift**

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