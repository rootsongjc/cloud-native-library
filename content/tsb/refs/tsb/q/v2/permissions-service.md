---
title: Permissions Service
description: Service to manage centralized approval policies.
---

<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Service to manage centralized approval policies.


## Permissions {#tetrateio-api-tsb-q-v2-permissions}

The Permissions service exposes methods to query permission information on existing records.
$hide_from_yaml


### QueryResourcePermissions

<PanelContent>
<PanelContentCode>

rpc QueryResourcePermissions ([tetrateio.api.tsb.q.v2.QueryResourcePermissionsRequest](../../../tsb/q/v2/permissions_service#tetrateio-api-tsb-q-v2-queryresourcepermissionsrequest)) returns ([tetrateio.api.tsb.q.v2.QueryResourcePermissionsResponse](../../../tsb/q/v2/permissions_service#tetrateio-api-tsb-q-v2-queryresourcepermissionsresponse))

</PanelContentCode>



QueryResourcePermission looks up permissions that are allowed for the current principal.
Multiple records can be queried with a single request. Query limit is 100, multiple requests
are required to lookup more than the limit.

</PanelContent>

### GetResourcePermissions

<PanelContent>
<PanelContentCode>

rpc GetResourcePermissions ([tetrateio.api.tsb.q.v2.GetResourcePermissionsRequest](../../../tsb/q/v2/permissions_service#tetrateio-api-tsb-q-v2-getresourcepermissionsrequest)) returns ([tetrateio.api.tsb.q.v2.GetResourcePermissionsResponse](../../../tsb/q/v2/permissions_service#tetrateio-api-tsb-q-v2-getresourcepermissionsresponse))

</PanelContentCode>



GetResourcePermission looks up permissions that are allowed for the current principal.
on the given resource FQN. This is similar to QueryResourcePermission but limited to a single
resource FQN.

</PanelContent>






## GetResourcePermissionsRequest {#tetrateio-api-tsb-q-v2-getresourcepermissionsrequest}

Request to query permissions on a single record by FQN.



  
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


fqn

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Fully-qualified name of the resource

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## GetResourcePermissionsResponse {#tetrateio-api-tsb-q-v2-getresourcepermissionsresponse}

Response with permission rules.



  
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


rules

</td>

<td>

List of [tetrateio.api.tsb.rbac.v2.Role.Rule](../../../tsb/rbac/v2/role#tetrateio-api-tsb-rbac-v2-role-rule) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Query {#tetrateio-api-tsb-q-v2-query}

Query format of the resource lookup for the permission check



  
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


queryId

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OPTIONAL_ <br/> Optional ID that is an open string the caller can use for correlation purposes.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


fqn

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> kind</sup>_ <br/> Fully-qualified name of the resource.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## QueryResourcePermissionsRequest {#tetrateio-api-tsb-q-v2-queryresourcepermissionsrequest}

Request to query permissions on multiple records.

Example:
QueryResourcePermissionsRequest {
  Queries: []Query{
    Query{
      QueryID: "1234",
      Kind: Query_Fqn{
        Fqn: "tetrate/tenants/default/workspaces/example"
      }
    }
  }
}



  
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


queries

</td>

<td>

List of [tetrateio.api.tsb.q.v2.Query](../../../tsb/q/v2/permissions_service#tetrateio-api-tsb-q-v2-query) <br/> One or more resources to query permissions on, limited to 100 per request.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;min_items: `1`<br/>&nbsp;&nbsp;max_items: `100`<br/>}<br/>

</td>
</tr>
    
</table>
  


## QueryResourcePermissionsResponse {#tetrateio-api-tsb-q-v2-queryresourcepermissionsresponse}

Response with permissions for the requested queries.

Example:
QueryResourcePermissionsResponse {
  Results: []Result{
    Result{
      Request: Query{
        QueryID: "1234",
        Kind: Query_Fqn{
          Fqn: "tetrate/tenants/default/workspaces/example"
        }
      },
      Rules: []*Role_Rule{
        {
           Types: []*Role_ResourceType{
             {
               ApiGroup: "api.tsb.tetrate.io/v2",
               Kinds: []string{"Workspace"}
             }
           },
           Permissions: []Permission{"READ"}
        }
      }
    }
  }
}



  
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


results

</td>

<td>

List of [tetrateio.api.tsb.q.v2.QueryResourcePermissionsResponse.Result](../../../tsb/q/v2/permissions_service#tetrateio-api-tsb-q-v2-queryresourcepermissionsresponse-result) <br/> List of permission results for the requested queries

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### Result {#tetrateio-api-tsb-q-v2-queryresourcepermissionsresponse-result}

Represents a result for the requested query



  
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


request

</td>

<td>

[tetrateio.api.tsb.q.v2.Query](../../../tsb/q/v2/permissions_service#tetrateio-api-tsb-q-v2-query) <br/> _REQUIRED_ <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


rules

</td>

<td>

List of [tetrateio.api.tsb.rbac.v2.Role.Rule](../../../tsb/rbac/v2/role#tetrateio-api-tsb-rbac-v2-role-rule) <br/> set of allowed RBAC rules that the current principal has on the matching resource.
If the query produced no results, the rules set will be empty.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



