---
title: 定制 TSB Kubernetes 组件
Description: 说明如何在 Kubernetes 中配置 TSB 组件，包括使用覆盖进行高级资源配置的示例。
weight: 12
---

本文描述了如何自定义 Kubernetes 部署的 TSB 组件，包括使用覆盖来执行由 Tetrate Service Bridge (TSB) 操作员部署的资源的高级配置，使用示例说明。

## 背景

TSB 广泛使用[操作员（Operator）](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/)模式在 Kubernetes 中部署和配置所需的部分。

通常，通过操作员来进行自定义和微调参数，操作员负责创建必要的资源并控制其生命周期。

例如，当你创建一个 IngressGateway CR 时，TSB 操作员会获取此信息并部署和/或更新相关资源，如 Kubernetes Service 对象，通过创建清单并应用它们。清单将使用你提供的某些参数，以及由 TSB 计算的其他默认值。

然而，TSB 并不一定会暴露用于微调 Service 对象的所有参数。如果 TSB 提供了所有用于配置 Service 对象的钩子，那么 TSB 将不得不实际上复制整个 Kubernetes API，这在现实中既不可行也不可取。

这就是我们使用覆盖的地方，它允许你覆盖并应用于正在部署的资源的自定义配置。有关覆盖工作原理的更多详细信息，请阅读[参考文档中关于覆盖的文档](../../refs/install/kubernetes/k8s)。

{{<callout warning 注意>}}
覆盖作为 TSB 功能的一种逃生机制提供，应谨慎使用。当前可能通过覆盖可用的配置很可能会在未来通过 TSB 操作员来执行。
{{</callout>}}

## 示例说明

在接下来的示例中，使用 `kubectl edit` 直接编辑部署的清单来应用必要的配置。如果你拥有原始清单，你也可以选择使用 `kubectl apply`，但你必须提供整个资源定义，而不仅仅是要编辑的部分。

示例清单只显示了需要指定的最小信息，以及指定要进行这些更改的上下文（位置）的信息。

{{<callout note 注意>}}
根据你的特定 Kubernetes 环境，你可能需要修改示例的内容以使其正常运行。
{{</callout>}}

{{<callout note "Helm 安装">}}
本文档中提供的所有示例也可以应用于 Helm 安装，通过编辑管理平面或控制平面 Helm 值来实现。

对于管理平面，[Helm 值](../../setup/helm/managementplane) 中的 `spec` 字段与 TSB [`ManagementPlane` CR](../../refs/install/managementplane/v1alpha1/spec) 相同。

对于控制平面，[Helm 值](../../setup/helm/controlplane) 中的 `spec` 字段与 TSB [`ControlPlane` CR](../../refs/install/controlplane/v1alpha1/spec) 相同。
{{</callout>}}

{{<callout note OpenShift>}}
如果你使用 OpenShift，请使用以下命令将下面的 `kubectl` 命令替换为 `oc`。
{{</callout>}}

一旦你研究了这些示例，你可能会使用更复杂的覆盖来进行工作。你应该知道的一个注意事项是，你只能为每个对象有一个覆盖。例如，以下规范在语法上是有效的，但只会应用于 `quux.corge.grault` 的最后一个 `patch`：

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

这是因为清单在 `overlays` 下包含了指向同一个对象（`my-object`）的多个条目，在这种情况下只有最后一个条目实际应用。要对 `foo.bar.baz` 和 `quux.corge.grault` 进行修补，必须将所有 `patch` 规范合并到单个对象下，如下所示：

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

## 覆盖示例用法

### 配置具有提升权限的 CNI

某些环境，如 SELinux 或 OpenShift，需要特殊权限才能在主机系统中写入文件。要启用此功能，必须通过编辑 `ControlPlane` CR 来将 `install-cni.securityContext.privileged` 属性设置为 `true`。

使用 `kubectl edit` 编辑 TSB 控制平面的 `ControlPlane` CR，并使用以下代码片段作为如何编辑清单的示例。

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

### 更改 XCP 服务类型

对于某些环境，XCP 边缘无法使用 LoadBalancer 服务类型，或者需要添加注释。你可以通过将以下覆盖应用于 `ControlPlane` CR 来修改它们：

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

### 保留端点 IP 地址

Kubernetes 提供了一种保留连接到应用程序的客户端的 IP 地址的方法，可以用来将流量路由到节点本地或整个集群范围的端点。

对于此示例，假设你已部署了以下 Ingress Gateway，并且其服务类型为 `LoadBalancer`：

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

使用 `kubectl edit` 编辑应用程序的 IngressGateway CR，并使用以下代码片段作为如何编辑清单的示例。

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

### 为 `istiod` 添加主机别名

在某些情况下，`istiod` 可能需要与没有 DNS 记录的服务通信。典型的示例是当需要从 Vault 或其他密钥管理器中获取自定义 Istio CA 时。`hostAlias` 补丁将直接将主机名映射到 IP 地址，类似于在 VM 主机文件中静态添加条目。

使用 `kubectl edit` 编辑 TSB 控制平面的 `ControlPlane` CR，并使用以下代码片段作为如何编辑清单的示例。将 `<hostname-FQDN>` 和 `<ip address>` 替换为适当的值。

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

### 配置 Sidecar 资源限制

Sidecar API 资源不允许你指定 sidecar 的资源使用限制或定义，但通过向 `ControlPlane` CR 添加覆盖是可能的。在此示例中，我们将在 `resources` 字段下覆盖资源限制。

使用 `kubectl edit` 编辑 TSB 控制平面的 `ControlPlane` CR，并使用以下代码片段作为如何编辑清单的示例。根据需要更新实际的资源限制值。

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

### 转发客户端信息

某些应用程序需要了解连接到应用程序的客户端的证书信息。TSB 使用 `x-forwarded-client-cert` 标头将此信息传递给后端服务器。为启用此功能，你需要配置 ControlPlane 和 IngressGateway(s) 的 Envoy 代理。

对于 ControlPlane，请使用 `kubectl edit` 编辑 TSB 控制平面的 `ControlPlane` CR，并使用以下代码片段作为如何编辑清单的示例。

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

对于 IngressGateway，请使用 `kubectl edit` 编辑应用程序的 IngressGateway CR，并使用以下代码片段作为如何编辑清单的示例。根据需要替换 `<ingress-name>` 和 `<namespace>` 值。

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

### 控制 TSB UI 的用户会话不活动时间

默认情况下，TSB UI 的用户会话在不活动 15 分钟后过期。你可以通过通过覆盖机制设置 `SESSION_AGE_IN_MINUTES` 环境变量来覆盖此值。

假设你希望允许用户在 Web UI 中登录 60 分钟。使用 `kubectl edit` 编辑 TSB 控制平面的 `ControlPlane` CR，并使用以下代码片段作为如何编辑清单的示例。

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

强烈建议将 `SESSION_AGE_MINUTES` 设置为最小值，以符合访问 UI 的安全最佳实践。

### 在 TSB 组件中设置环境变量

有时候，你需要设置 TSB 组件的任意环境变量 - 例如，对于包含 Log4j（版本 2.10 或更高版本）的 Java 二进制文件，为了应对与 Log4j 相关的安全漏洞，可以将 `LOG4J_FORMAT_MSG_NO_LOOKUPS` 环境变量设置为 `true`。为此，你可以使用 TSB 操作员配置中 Kubernetes 组件规范的 `env` 部分。

要设置 Management Plane（TSB）集群的值，你需要更新 `ManagementPlane` CR：

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

并且要设置控制平面（应用程序）集群的值，你需要更新 ControlPlane 资源：

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
