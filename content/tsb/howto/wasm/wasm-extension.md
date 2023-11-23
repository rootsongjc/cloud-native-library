---
title: TSB 配置
description: 展示了如何在 TSB 中创建 WASM 扩展并将它们分配到层次结构中的组件。
weight: 2
---

本文将描述 WASM 扩展在 TSB 中是如何定义的，以及它们如何分配给层次结构中的组件。

## TSB 中的 WASM

为了控制网格中允许的扩展，避免安全泄漏并简化扩展升级过程，TSB 拥有一个[WASM 扩展](../../../refs/tsb/extension/v2/wasm-extension)目录，
管理员将在其中注册所有可用于不同组件中使用的扩展。
此目录将包含每个扩展的描述、镜像和执行属性。
当扩展的新版本可用时，更改 WASM 扩展目录记录的内容将将更新传播到该扩展的所有分配。

![UI](../../../assets/howto/wasm/wasm-ui.png)

这些扩展被打包为 OCI 镜像，包含 WASM 文件，并部署在容器镜像仓库中，Istio 将从中拉取并提取内容。
使用 OCI 镜像交付 WASM 扩展的好处在于，安全性已经实现并标准化，与其他工作负载镜像一样。

扩展可以允许全局使用，也可以在一组租户中受到限制，这将影响扩展可以附加的位置。

在扩展在目录中创建后，它们将启用并可用于与同一组织层次结构中的 TSB 组件的附件中使用。它们的属性将成为附件的配置。
可以配置 WASM 扩展的组件包括：[组织](../../../refs/tsb/v2/organization)、[租户](../../../refs/tsb/v2/tenant)、[工作区](../../../refs/tsb/v2/workspace)、[安全组](../../../refs/tsb/security/v2/security-group)、[入口网关](../../../refs/tsb/gateway/v2/ingress-gateway)、[出口网关](../../../refs/tsb/gateway/v2/egress-gateway)和[第一层网关](../../../refs/tsb/gateway/v2/tier1-gateway)。

## 在 TSB 资源中使用 WASM 扩展

WASM 扩展可以在[组织设置](../../../refs/tsb/v2/organization-setting)、[租户设置](../../../refs/tsb/v2/tenant-setting)、[工作区设置](../../../refs/tsb/v2/workspace-setting)的`defaultSecuritySettings`属性中指定，并将影响层次结构中属于这些资源的所有工作负载。
此外，这些附件可以在 IngressGateway、EgressGateway 和 Tier1Gateway 的[`extension`](../../../refs/tsb/types/v2/types#wasmextensionattachment)属性中指定，只有与这些网关链接的工作负载才会受到 WASM 扩展的影响。TSB 将使用工作负载选择器来指定工作负载。

```yaml
  extension:
    - fqn: "organizations/tetrate/extensions/wasm-add-header"
      config:
        header: x-wasm-header
        value: igw-tsb
```

在 TSB 中使用 WASM 扩展的另一种方式是使用 Istio 直接模式，创建一个[IstioInternalGroup](../../../refs/tsb/istiointernal/v2/istio-internal-group#group)和一个[WasmPlugin](https://istio.io/latest/docs/reference/config/proxy-extensions/wasm-plugin/)，并引用该组。
例如：

```yaml
apiVersion: istiointernal.tsb.tetrate.io/v2
kind: Group
metadata:
  organization: tetrate
  tenant: mytenant
  workspace: myworkspace
  name: internal-group
spec:
  namespaceSelector:
    names:
      - "*/httpbin"
```

然后直接创建 Istio WasmPlugin：

```yaml
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: demo-wasm-add-header
  namespace: app-namespace
  annotations:
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: mytenant
    tsb.tetrate.io/workspace: myworkspace
    tsb.tetrate.io/istioInternalGroup: internal-group
spec:
  selector:
    matchLabels:
      app: httpbin
  url: oci://docker.io/tetrate/xcp-wasm-e2e:0.3
  imagePullPolicy: IfNotPresent
  pluginConfig:
    header: x-wasm-header
    value: xcp
```
