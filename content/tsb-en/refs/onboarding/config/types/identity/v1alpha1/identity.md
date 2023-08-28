---
title: Workload Identity
description: Platform-specific identity of a workload joining the mesh.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

WorkloadIdentity represents a platform-specific identity of a workload
joining the mesh.

E.g.,

* `AWS EC2` instance identity:

  ```yaml
  aws:
    partition: aws
    account: '123456789012'
    region: ca-central-1
    zone: ca-central-1b
    ec2:
      instance_id: i-1234567890abcdef0
      iam_role:
        name: example-role
  ```

* `GCP GCE` instance identity:

  ```yaml
  gcp:
    project_number: '234567890121'
    project_id: gcp-example
    region: us-central1
    zone: us-central1-a
    gce:
      instance_id: '693197132356332126'
  ```

* `Azure Compute` instance identity:

  ```yaml
  azure:
    subscription: 531bed28-f708-4fc5-b0c1-2c1edde46e4f
    resource_group: azure-example
    compute:
      instance_id: fc13d26e-d3c0-458e-b353-686d5ca19506
  ```

* `JWT` identity:

  ```yaml
  jwt:
    issuer: https://mycompany.corp
    subject: us-east-datacenter1-vm007
    attributes:
      region: us-east
      datacenter: datacenter1
      instance_name: vm007
      instance_hostname: vm007.internal.corp
      instance_role: app-ratings
  ```





## WorkloadIdentity {#tetrateio-api-onboarding-config-types-identity-v1alpha1-workloadidentity}

WorkloadIdentity represents a platform-specific identity of a workload
joining the mesh.



  
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


aws

</td>

<td>

[tetrateio.api.onboarding.config.types.identity.aws.v1alpha1.AwsIdentity](../../../../../onboarding/config/types/identity/aws/v1alpha1/aws#tetrateio-api-onboarding-config-types-identity-aws-v1alpha1-awsidentity) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> kind</sup>_ <br/> `AWS`-specific identity of a workload.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


jwt

</td>

<td>

[tetrateio.api.onboarding.config.types.identity.jwt.v1alpha1.JwtIdentity](../../../../../onboarding/config/types/identity/jwt/v1alpha1/jwt#tetrateio-api-onboarding-config-types-identity-jwt-v1alpha1-jwtidentity) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> kind</sup>_ <br/> `JWT` identity of a workload.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



