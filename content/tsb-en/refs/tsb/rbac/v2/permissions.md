---
title: Permissions
description: Permissions.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Permissions.







## Permission {#tetrateio-api-tsb-rbac-v2-permission}

A permission defines an action that can be performed on a
resource. By default access to resources is denied unless an
explicit permission grants access to perform an operation against
it.


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


INVALID

</td>

<td>

0

</td>

<td>

Default value to designate no value was explicitly set for the permission.

</td>
</tr>
    
<tr>
<td>


READ

</td>

<td>

1

</td>

<td>

The read permission grants read-only access to the resource.

</td>
</tr>
    
<tr>
<td>


WRITE

</td>

<td>

2

</td>

<td>

The write permission allows the subject to modify an existing resource.

</td>
</tr>
    
<tr>
<td>


CREATE

</td>

<td>

3

</td>

<td>

The create permission allows subjects to create child resources on the resource.

</td>
</tr>
    
<tr>
<td>


DELETE

</td>

<td>

4

</td>

<td>

The delete permission grants permissions to delete the resource.

</td>
</tr>
    
<tr>
<td>


SET_POLICY

</td>

<td>

5

</td>

<td>

The set-iam permission allows subjects to manage the access policies for the resources.

</td>
</tr>
    
</table>
  


