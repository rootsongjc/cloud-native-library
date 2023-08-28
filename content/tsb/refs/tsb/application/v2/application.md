---
title: Application
description: Configuration for Applications.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Applications are logical groupings of services that are related to each other,
typically within a trusted group.
A common example are three tier applications composed of a frontend, a backend and a
datastore service.

Applications are often consumed through APIs, and a single Application can expose one
or more of those APIs. These APIs will define the hostnames that are exposed and the
methods exposed in each hostname.

```yaml
apiVersion: application.tsb.tetrate.io/v2
kind: Application
metadata:
  name: three-tier
  organization: myorg
  tenant: tetrate
spec:
  workspace: organizations/myorg/tenants/tetrate/three-tier
```





## Application {#tetrateio-api-tsb-application-v2-application}

An Application represents a set of logical groupings of services that are related to each other
and expose a set of APIs that implement a complete set of business logic.



  
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


workspace

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> FQN of the workspace this application is part of.
The application will configure IngressGateways for the attached APIs
in the different namespaces exposed by this workspace.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


namespaceSelector

</td>

<td>

[tetrateio.api.tsb.types.v2.NamespaceSelector](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-namespaceselector) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> scope</sup>_ <br/> _INPUT_ONLY_ <br/> Optional set of namespaces this application can configure.
If configured, a Gateway Group including these namespaces will be created for the application. If
no namespaces are configured and no existing gateway group is set, a new gateway group claiming all
namespaces in the workspace (`*/*`) will be created by default.
All Ingress Gateway resources created for the APIs attached to the application will be created in
the application's gateway group.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


gatewayGroup

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> scope</sup>_ <br/> Optional FQN of the Gateway Group to be used by the application.
If configured, this gateway group will be used by the application. If
no namespaces are configured and no existing gateway group is set, a new gateway group claiming all
namespaces in the workspace (`*/*`) will be created by default.
All Ingress Gateway resources created for the APIs attached to the application will be created in
the application's gateway group.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


services

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Optional list of services that are part of the application. This is a list of FQNs of services in the
service registry.
If omitted, the application is assumed to own all the services in the workspace.
Note that a service can only be part of one application. If any of the services in the list is already
in use by an existing application, application creation/modification will fail.
If the list of services is not explicitly set and any service in the workspace is already in use by
another application, application creation/modification will fail.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;items: `{string:{min_len:1}}`<br/>}<br/>

</td>
</tr>
    
</table>
  



