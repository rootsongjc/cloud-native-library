---
title: Audit
description: Audit Log Service
---


import {
  PanelContent,
  PanelContentCode,
} from "@theme/Panel";


<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Audit Log Service


## AuditService {#tetrateio-api-audit-v1-auditservice}

The Audit Service provides access to the Service Bridge audit log APIs.

All operations performed against TSB resources generate audit log events that can
be queried using the Audit log APIs. Those events include information about the
users that performed each action and about the actions themselves.

This API is integrated with the TSB permission system, and all its methods will only
return audit logs for those resources the users making the queries have permissions on.


### ListAuditLogs

<PanelContent>
<PanelContentCode>

rpc ListAuditLogs ([tetrateio.api.audit.v1.ListAuditLogsRequest](../../audit/v1/audit#tetrateio-api-audit-v1-listauditlogsrequest)) returns ([tetrateio.api.audit.v1.ListAuditLogsResponse](../../audit/v1/audit#tetrateio-api-audit-v1-listauditlogsresponse))

</PanelContentCode>



List audit logs. If no 'count' parameter has been specified, the last 25 audit logs are
returned.
This method will only return audit logs for those resources the user making the query has
permissions on.

</PanelContent>






## AuditLog {#tetrateio-api-audit-v1-auditlog}

AuditLog

A system log describing something that happened in the system.



  
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


createTime

</td>

<td>

[google.protobuf.Timestamp](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Timestamp) <br/> Time when the audit log was generated.

</td>

<td>

timestamp = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


severity

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Log severity (INFO, WARN, ERROR...).

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


kind

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The kind of the audit log (PolicyAssigned, ServiceOrphaned, etc).

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


message

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Audit log details.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


triggeredBy

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Person who triggered the audit log, or "SYSTEM" if the log was automatically
triggered by the system.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


properties

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Key value pairs with additional information for the audit log.

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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Fully-qualified name of object that made this record.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


operation

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Operation that was performed on the resource.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ListAuditLogsRequest {#tetrateio-api-audit-v1-listauditlogsrequest}

Request to get the audit logs.



  
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


count

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Number of audit logs to retrieve. By default is 25.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


sinceTimestamp

</td>

<td>

[google.protobuf.Timestamp](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Timestamp) <br/> Moment in time since we retrieve logs.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


severity

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Severity level to filter logs.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


kind

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The kind of the audit log to filter (PolicyAssigned, ServiceOrphaned, etc).

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


triggeredBy

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Filter by what triggered the event.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


text

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Text to filter by.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


recursive

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> If set to true, the audit log search will include the logs for all child
resources for the one configured in the `fqn` field

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


operation

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Operation that was performed on the resource.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ListAuditLogsResponse {#tetrateio-api-audit-v1-listauditlogsresponse}

The list of audit logs.



  
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


auditLogs

</td>

<td>

List of [tetrateio.api.audit.v1.AuditLog](../../audit/v1/audit#tetrateio-api-audit-v1-auditlog) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



