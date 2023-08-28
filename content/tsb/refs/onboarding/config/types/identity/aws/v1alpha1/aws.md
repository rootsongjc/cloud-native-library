---
title: AWS Identity
description: AWS-specific identity of a workload.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

AwsIdentity represents an `AWS`-specific identity of a workload.

E.g.,

* `AWS EC2` instance identity:

  ```yaml
  partition: aws
  account: '123456789012'
  region: ca-central-1
  zone: ca-central-1b
  ec2:
    instance_id: i-1234567890abcdef0
    iam_role:
      name: example-role
  ```

* `AWS ECS` task identity:

  ```yaml
  partition: aws
  account: '123456789012'
  region: ca-central-1
  zone: ca-central-1b
  ecs:
    task_id: 16aeded318d842bb8226e5bc678cd446
    cluster: bookinfo
    iam_role:
      name: example-role
  ```





## AwsIdentity {#tetrateio-api-onboarding-config-types-identity-aws-v1alpha1-awsidentity}

AwsIdentity represents an `AWS`-specific identity of a workload.



  
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


partition

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> `AWS Partition`.

E.g., `aws`, `aws-cn`, `aws-us-gov`, etc.

See https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


account

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> `AWS Account`.

E.g., `123456789012`.

See https://docs.aws.amazon.com/general/latest/gr/acct-identifiers.html

</td>

<td>

string = {<br/>&nbsp;&nbsp;pattern: `^[0-9]{12}$`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


region

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> `AWS Region`.

E.g., `us-east-2`, `eu-west-3`, `cn-north-1`, etc.

See https://docs.aws.amazon.com/general/latest/gr/rande.html#regional-endpoints

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


zone

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> `AWS Availability Zone`.

E.g., `us-east-2a`, `eu-west-3b`, `ap-southeast-1c`, etc.

See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


ec2

</td>

<td>

[tetrateio.api.onboarding.config.types.identity.aws.v1alpha1.Ec2Instance](../../../../../../onboarding/config/types/identity/aws/v1alpha1/aws#tetrateio-api-onboarding-config-types-identity-aws-v1alpha1-ec2instance) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> kind</sup>_ <br/> `AWS EC2` instance.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Ec2Instance {#tetrateio-api-onboarding-config-types-identity-aws-v1alpha1-ec2instance}

Ec2Instance represents `AWS EC2` instance.



  
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


instanceId

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> `EC2` instance ID.

E.g., `i-1234567890abcdef0`.

See https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-instances.html

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


iamRole

</td>

<td>

[tetrateio.api.onboarding.config.types.identity.aws.v1alpha1.IamRole](../../../../../../onboarding/config/types/identity/aws/v1alpha1/aws#tetrateio-api-onboarding-config-types-identity-aws-v1alpha1-iamrole) <br/> `AWS IAM Role` associated with the `AWS EC2` instance.

See https://docs.aws.amazon.com/cli/latest/reference/iam/add-role-to-instance-profile.html

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## IamRole {#tetrateio-api-onboarding-config-types-identity-aws-v1alpha1-iamrole}

IamRole represents `AWS IAM Role`.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Role name.

E.g., `example-role`.

See https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  



