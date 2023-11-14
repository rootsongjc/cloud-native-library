---
title: TSB configuration
description: Shows how to create WASM extensions and assign them into the hierarchy
weight: 2
---

This document will describe how the WASM extensions are defined in TSB and how are they assigned to the components on the hierarchy.

## WASM in TSB

In order to control the extensions allowed in the mesh, avoid security leakages and ease the process of extension upgrades, TSB has a [WASM extension](../../refs/tsb/extension/v2/wasm_extension) catalog,
where an administrator will register all the extensions that will be available to be used in the different components.
This catalog will contain the description, image and execution properties for each extension.
When a new version of the extension is available, changing the content of the WASM extension catalog record will propagate the update to all the assignments for that extension.

![UI](../../assets/howto/wasm/wasm-ui.png)

These extensions are packaged as OCI images, containing the WASM file, and deployed in a container images registry from where Istio will pull and extract the contents.
The benefit of using OCI images in order to deliver the WASM extensions is that the security is already implemented and standardized with the same approach as with the rest of workloads images.

Extensions can be allowed to be used globally or restricted in a set of Tenants, and this will affect where the extension can be attached.

After having the extensions created in the catalog they become enabled and available to be used in the attachments for the TSB components in the same organization hierarchy. And their properties will become the configuration for the attachments.
Components that can be configured with WASM extensions are : [Organization](../../refs/tsb/v2/organization), [Tenant](../../refs/tsb/v2/tenant), [Workspace](../../refs/tsb/v2/workspace), [SecurityGroup](../../refs/tsb/security/v2/security_group), [IngressGateway](../../refs/tsb/gateway/v2/ingress_gateway), [EgressGateway](../../refs/tsb/gateway/v2/egress_gateway) and [Tier1Gateway](../../refs/tsb/gateway/v2/tier1_gateway).


## Using WASM extensions in the TSB resources

WASM extensions can be specified in the [`defaultSecuritySettings`](../../refs/tsb/security/v2/security_setting) property of [OrganizationSetting](../../refs/tsb/v2/organization_setting), [TenantSetting](../../refs/tsb/v2/tenant_setting), [WorkspaceSetting](../../refs/tsb/v2/workspace_setting) , and in the spec of [SecuritySettings](../../refs/tsb/security/v2/security_setting), and
it will affect all the workloads belonging to those resources in the hierarchy.
Also, these attachments can be specified in the IngressGateway, EgressGateway and Tier1Gateway [`extension`](../../refs/tsb/types/v2/types#wasmextensionattachment) property, and only the workloads
linked to these gateways will be affected by the WASM extension. TSB will use workload selectors to specify the workloads.

```yaml
  extension:
    - fqn: "organizations/tetrate/extensions/wasm-add-header"
      config:
        header: x-wasm-header
        value: igw-tsb
```

Another way of using WASM extensions in TSB is using the Istio direct mode, creating an [IstioInternalGroup](../../refs/tsb/istiointernal/v2/istio_internal_group#group) and a [WasmPlugin](https://istio.io/latest/docs/reference/config/proxy_extensions/wasm-plugin/) with references to that group.
For example:

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

And then creating directly the Istio WasmPlugin:

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
