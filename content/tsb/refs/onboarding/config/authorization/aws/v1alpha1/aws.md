---
title: AWS Identity Matcher
description: Specification of matching workloads with AWS-specific identities.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

AwsIdentityMatcher specifies matching workloads with `AWS`-specific
identities.

For example, the following configuration will match any EC2 VM instance in
account `123456789012`, region `ca-central-1` and zone `ca-central-1b`:

```yaml
partitions:
- aws
accounts:
- '123456789012'
regions:
- ca-central-1
zones:
- ca-central-1b
ec2: {}
```

The matcher can also be used to to limit to VMs associated with a specific
IAM role as shown below:

```yaml
partitions:
- aws
accounts:
- '123456789012'
regions:
- ca-central-1
zones:
- ca-central-1b
ec2:
  iamRoleNames:
  - example-role
```

The following matcher will limit to ECS instances in the `bookinfo` cluster
and with a specific IAM role:

```yaml
partitions:
- aws
accounts:
- '123456789012'
regions:
- ca-central-1
zones:
- ca-central-1b
ecs:
  clusters:
  - prod-cluster
  iamRoleNames:
  - example-role
```





## AwsIdentityMatcher {#tetrateio-api-onboarding-authorization-aws-v1alpha1-awsidentitymatcher}

AwsIdentityMatcher specifies matching workloads with `AWS`-specific identities.



  
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


partitions

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Match workloads in these `AWS Partitions`.

E.g., `aws`, `aws-cn`, `aws-us-gov`, etc.

Empty list means match any partition.

See https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;items: `{string:{min_len:1}}`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


accounts

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Match workloads in these `AWS Accounts`.

E.g., `123456789012`.

Cannot be empty.

See https://docs.aws.amazon.com/general/latest/gr/acct-identifiers.html

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;min_items: `1`<br/>&nbsp;&nbsp;items: `{string:{pattern:^[0-9]{12}$}}`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


regions

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Match workloads in these `AWS Regions`.

E.g., `us-east-2`, `eu-west-3`, `cn-north-1`, etc.

Empty list means match any region.

See https://docs.aws.amazon.com/general/latest/gr/rande.html#regional-endpoints

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;items: `{string:{min_len:1}}`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


zones

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Match workloads in these `AWS Availability Zones`.

E.g., `us-east-2a`, `eu-west-3b`, `ap-southeast-1c`, etc.

Empty list means match any availability zone.

See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;items: `{string:{min_len:1}}`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


ec2

</td>

<td>

[tetrateio.api.onboarding.authorization.aws.v1alpha1.Ec2InstanceMatcher](../../../../../onboarding/config/authorization/aws/v1alpha1/aws#tetrateio-api-onboarding-authorization-aws-v1alpha1-ec2instancematcher) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> kind</sup>_ <br/> Match `AWS EC2` instances with these instance specific criteria.

If present but empty, it matches any `EC2` instance matching the other fields.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Ec2InstanceMatcher {#tetrateio-api-onboarding-authorization-aws-v1alpha1-ec2instancematcher}

Ec2Instance specifies matching `AWS EC2` instances.



  
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


iamRoleNames

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Match `AWS EC2` instances associated with these `AWS IAM Role` names.

E.g., `example-role`.

Empty list means match any `EC2` instance (no matter whether it has an
`AWS IAM Role` associated with it or not).

See https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;items: `{string:{min_len:1}}`<br/>}<br/>

</td>
</tr>
    
</table>
  



