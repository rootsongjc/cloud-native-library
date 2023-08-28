---
title: WASM Extension
description: WASM Extension definition
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

The WASM extension resource allows defining custom WASM extensions that are packaged in OCI images.
The resource allows specifying extension metadata that helps understand how extensions work and how they can be used.
Once defined, extensions can be referenced in Ingress and Egress Gateways and Security Groups so that traffic
is captured and processed by the extension accordingly.
By default, extensions are globally available, but they can be assigned to specific Tenants as well
to further control and constraint where in the Organization the extensions are allowed to be used.

```yaml
apiVersion: extension.tsb.tetrate.io/v2
kind: WasmExtension
metadata:
  organization: org
  name: wasm-auth
spec:
  allowedIn:
    - organizations/org/tenants/tenant1
  url: oci://docker.io/example/my-wasm-extension:1.0
  source: https://github.com/example/wasm-extension
  description: |
    Long description for the extension such as an
    entire README file
  phase: AUTHZ
  priority: 1000
  config:
    some_key: some_value
```

WASM extensions can also reference HTTP endpoints:

```yaml
apiVersion: extension.tsb.tetrate.io/v2
kind: WasmExtension
metadata:
  organization: org
  name: wasm-http
spec:
  url: http://tetrate.io/my-extension.wasm
  source: https://github.com/example/wasm-extension
  description: |
    Long description for the extension such as an
    entire README file
  phase: AUTHZ
  priority: 1000
  config:
    some_key: some_value
```





## EnvVar {#tetrateio-api-tsb-extension-v2-envvar}





  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


name

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Name of the environment variable. Must be a C_IDENTIFIER, by following this regex: [A-Za-z_][A-Za-z0-9_]*

</td>

<td>

string = {<br/>&nbsp;&nbsp;pattern: `[A-Za-z_][A-Za-z0-9_]*`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


valueFrom

</td>

<td>

[tetrateio.api.tsb.extension.v2.EnvValueSource](../../../tsb/extension/v2/wasm_extension#tetrateio-api-tsb-extension-v2-envvaluesource) <br/> _REQUIRED_ <br/> Source for the environment variable's value.

</td>

<td>

enum = {<br/>&nbsp;&nbsp;defined_only: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


value

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Value for the environment variable.
Note that if `value_from` is `HOST`, it will be ignored.
Defaults to "".

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## GlobalTrafficSelector {#tetrateio-api-tsb-extension-v2-globaltrafficselector}

GlobalTrafficSelector provides a mechanism to select a specific traffic flow
for which this Wasm Extension will be enabled. This setting applies to all WASM
Extension attachments. These selectors can be overridden at attachments.
When all the sub conditions in the TrafficSelector are satisfied, the
traffic will be selected.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


mode

</td>

<td>

[tetrateio.api.tsb.types.v2.WorkloadMode](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-workloadmode) <br/> Criteria for selecting traffic by their direction.
Note that CLIENT and SERVER are analogous to OUTBOUND and INBOUND,
respectively.
For the gateway, the field should be CLIENT or CLIENT_AND_SERVER.
If not specified, the default value is CLIENT_AND_SERVER.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## VmConfig {#tetrateio-api-tsb-extension-v2-vmconfig}

Configuration for a Wasm VM.
more details can be found [here](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/wasm/v3/wasm.proto#extensions-wasm-v3-vmconfig).



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


env

</td>

<td>

List of [tetrateio.api.tsb.extension.v2.EnvVar](../../../tsb/extension/v2/wasm_extension#tetrateio-api-tsb-extension-v2-envvar) <br/> Specifies environment variables to be injected to this VM.
Note that if a key does not exist, it will be ignored.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## WasmExtension {#tetrateio-api-tsb-extension-v2-wasmextension}





  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


allowedIn

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> List of fqns where this extension is allowed to run.
If it is empty, the extension can be used across the entire organization.
Currently only Tenant resources are considered.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;items: `{string:{min_len:1}}`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


image

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Deprecated. Use the `url` field instead.
Repository and tag of the OCI image containing the WASM extension.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


source

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Source to find the code for the WASM extension

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


phase

</td>

<td>

[tetrateio.api.tsb.extension.v2.WasmExtension.PluginPhase](../../../tsb/extension/v2/wasm_extension#tetrateio-api-tsb-extension-v2-wasmextension-pluginphase) <br/> The phase in the filter chain where the extension will be injected.
https://istio.io/latest/docs/reference/config/proxy_extensions/wasm-plugin/#PluginPhase

</td>

<td>

enum = {<br/>&nbsp;&nbsp;defined_only: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


priority

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Determines the ordering of WasmExtensions in the same phase.
When multiple WasmExtensions are applied to the same workload in the same phase, they will be applied by priority, in descending order.
If no priority is assigned it will use the default 0 value.
In case of several extensions having the same priority in the same phase, the fqn will be used to sort them.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


config

</td>

<td>

[google.protobuf.Struct](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Struct) <br/> Configuration parameters sent to the WASM plugin execution
The configuration can be overwritten when instantiating the extensions in IngressGateways or Security groups.
The config is serialized using proto3 JSON marshaling and passed to proxy_on_configure when the host environment starts the plugin.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


imagePullPolicy

</td>

<td>

[tetrateio.api.tsb.extension.v2.WasmExtension.PullPolicy](../../../tsb/extension/v2/wasm_extension#tetrateio-api-tsb-extension-v2-wasmextension-pullpolicy) <br/> The pull behaviour to be applied when fetching Wasm module by either
OCI image or http/https. Only relevant when referencing Wasm module without
any digest, including the digest in OCI image URL or sha256 field in `vm_config`.
Defaults to IfNotPresent, except when an OCI image is referenced in the `url`
and the `latest` tag is used, in which case `Always` is the default,
mirroring K8s behaviour.

</td>

<td>

enum = {<br/>&nbsp;&nbsp;defined_only: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


imagePullSecret

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Credentials to use for OCI image pulling.
Name of a K8s Secret that contains a docker pull secret which is to be used
to authenticate against the registry when pulling the image.
If TSB is configured to use the WASM download proxy, this secret must exist in
the `istio-system` namespace of each cluster that has applications that use the
extension. If the downlaod proxy is disabled, the secret must exist in each
application namespace that is using the extension.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


vmConfig

</td>

<td>

[tetrateio.api.tsb.extension.v2.VmConfig](../../../tsb/extension/v2/wasm_extension#tetrateio-api-tsb-extension-v2-vmconfig) <br/> VM Configuration sent to the WASM plugin execution

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


url

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> URL of a Wasm module or OCI container. If no scheme is present, defaults to oci://, referencing an OCI image.
Other valid schemes are file:// for referencing .wasm module files present locally within the proxy container,
and http[s]:// for .wasm module files hosted remotely.

</td>

<td>

string = {<br/>&nbsp;&nbsp;pattern: `^(oci|https?|file)://`<br/>&nbsp;&nbsp;ignore_empty: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


match

</td>

<td>

[tetrateio.api.tsb.extension.v2.GlobalTrafficSelector](../../../tsb/extension/v2/wasm_extension#tetrateio-api-tsb-extension-v2-globaltrafficselector) <br/> Specifies the criteria to determine which traffic is passed to WasmExtension.
These settings are propagated to all WASMExtension Attachments. It can be overridden
at attachment points.
If a traffic satisfies the TrafficSelector,
the traffic passes to the WasmExtension.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  




## EnvValueSource {#tetrateio-api-tsb-extension-v2-envvaluesource}




<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th>Number</th>
<th class="description">Description</th>
</tr>
</thead>
    
<tr>
<td>


INLINE

</td>

<td>

0

</td>

<td>

Explicitly given key-value pairs to be injected to this VM.

</td>
</tr>
    
<tr>
<td>


HOST

</td>

<td>

1

</td>

<td>

Istio-proxy&#39;s* environment variables exposed to this VM.

</td>
</tr>
    
</table>
  



### PluginPhase {#tetrateio-api-tsb-extension-v2-wasmextension-pluginphase}

Plugin phases following Istio definition: https://istio.io/latest/docs/reference/config/proxy_extensions/wasm-plugin/#PluginPhase


<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th>Number</th>
<th class="description">Description</th>
</tr>
</thead>
    
<tr>
<td>


UNSPECIFIED_PHASE

</td>

<td>

0

</td>

<td>

Control plane decides where to insert the plugin. This will generally be at the end of the filter chain, right before the Router.
Do not specify PluginPhase if the plugin is independent of others.

</td>
</tr>
    
<tr>
<td>


AUTHN

</td>

<td>

1

</td>

<td>

Insert plugin before Istio authentication filters.

</td>
</tr>
    
<tr>
<td>


AUTHZ

</td>

<td>

2

</td>

<td>

Insert plugin before Istio authorization filters and after Istio authentication filters.

</td>
</tr>
    
<tr>
<td>


STATS

</td>

<td>

3

</td>

<td>

Insert plugin before Istio stats filters and after Istio authorization filters.

</td>
</tr>
    
</table>
  



### PullPolicy {#tetrateio-api-tsb-extension-v2-wasmextension-pullpolicy}

The pull behaviour to be applied when fetching a WASM module,
mirroring K8s behaviour.


<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th>Number</th>
<th class="description">Description</th>
</tr>
</thead>
    
<tr>
<td>


UNSPECIFIED_POLICY

</td>

<td>

0

</td>

<td>

Defaults to IfNotPresent, except for OCI images with tag `latest`, for which
the default will be Always.

</td>
</tr>
    
<tr>
<td>


IfNotPresent

</td>

<td>

1

</td>

<td>

If an existing version of the image has been pulled before, that
will be used. If no version of the image is present locally, we
will pull the latest version.

</td>
</tr>
    
<tr>
<td>


Always

</td>

<td>

2

</td>

<td>

We will always pull the latest version of an image when changing
this plugin. Note that the change includes `metadata` field as well.

</td>
</tr>
    
</table>
  


