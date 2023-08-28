---
title: Onboarding Policy
description: Authorizes matching workloads to join the mesh and become a part of a WorkloadGroup.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

`Onboarding Policy` authorizes matching workloads to join the mesh and become
a part of a [WorkloadGroup](https://istio.io/latest/docs/reference/config/networking/workload-group/).

By default, none of the workloads are allowed to join the mesh.

A workload is only allowed to join the mesh if there is an `OnboardingPolicy`
resource that explicitly authorizes that.

For the purposes of authorization, a workload is considered to have the identity
of the host it is running on.

E.g., workloads that run on VMs in the cloud are considered to have
cloud-specific identity of that VM. In case of `AWS EC2` instances,
VM identity includes `AWS Partition`, `AWS Account` number, `AWS Region`,
`AWS Zone`, `EC2 instance id`, `AWS IAM Role` name, etc.

As part of the `Workload Onboarding` flow, `Workload Onboarding Agent` (that
runs alongside the workload) will interact with cloud-specific metadata
APIs to procure a credential (digitally signed data item) that can be passed
to a third-party (`Workload Onboarding Endpoint`) as a proof of identity.

Once `Workload Onboarding Endpoint` has verified validity of the credential,
i.e. audience, expiration time, digital signature, etc, it looks for an
`OnboardingPolicy` resource that allows a workload with that identity to join
the mesh.

`OnboardingPolicy` resource consists of a list of rules.

Each rule describes what workload identities it is applicable to and what
`WorkloadGroups` the workload is allowed to join.

E.g., consider the following example of a very permissive `OnboardingPolicy`:

```yaml
apiVersion: authorization.onboarding.tetrate.io/v1alpha1
kind: OnboardingPolicy
metadata:
  name: allow-aws-ec2-vms
  namespace: bookinfo
spec:
  allow:
  - workloads:
    - aws:
        accounts:
        - '123456789012'
        ec2: {}                 # any AWS EC2 instance from the above account
    onboardTo:
    - workloadGroupSelector: {} # any WorkloadGroup from that namespace
```

The above policy allows any workload running on an `AWS EC2` instance of the
`AWS Account` `123456789012` to join any `WorkloadGroup` in the `bookinfo`
namespace.

The next example adds a constraint on `AWS Regions` the `AWS EC2` instance may
belong to:

```yaml
apiVersion: authorization.onboarding.tetrate.io/v1alpha1
kind: OnboardingPolicy
metadata:
  name: allow-aws-ec2-vms
  namespace: bookinfo
spec:
  allow:
  - workloads:
    - aws:
        regions:
        - ca-central-1
        accounts:
        - '123456789012'
        ec2: {}                 # any AWS EC2 instance from the above account and region
    onboardTo:
    - workloadGroupSelector: {} # any WorkloadGroup from that namespace
```

The next example puts a constraint on `WorkloadGroups` the workload may join:

```yaml
apiVersion: authorization.onboarding.tetrate.io/v1alpha1
kind: OnboardingPolicy
metadata:
  name: allow-aws-ec2-vms
  namespace: bookinfo
spec:
  allow:
  - workloads:
    - aws:
        accounts:
        - '123456789012'
        ec2: {}                 # any AWS EC2 instance from the above account
    onboardTo:
    - workloadGroupSelector:
        matchLabels:
          app: ratings          # any WorkloadGroup from that namespace that has a label `app=ratings`
```

The following example puts a constraint on `AWS IAM Role` an `AWS EC2` instance
must be associated with to limit the scope of the rule to a narrow subset of
`AWS EC2` instances in that `AWS Account`:

```yaml
apiVersion: authorization.onboarding.tetrate.io/v1alpha1
kind: OnboardingPolicy
metadata:
  name: allow-aws-ec2-vms
  namespace: bookinfo
spec:
  allow:
  - workloads:
    - aws:
        accounts:
        - '123456789012'
        ec2:
          iamRoleNames:
          - ratings-role        # any AWS EC2 instance from the above account that is
                                # associated with one of IAM Roles on that list
    onboardTo:
    - workloadGroupSelector:
        matchLabels:
          app: ratings          # any WorkloadGroup from that namespace that has a label `app=ratings`
  - workloads:
    - aws:
        accounts:
        - '123456789012'
        ec2:
          iamRoleNames:
          - reviews-role        # any AWS EC2 instance from the above account that is
                                # associated with one of IAM Roles on that list
    onboardTo:
    - workloadGroupSelector:
        matchLabels:
          app: reviews          # any WorkloadGroup from that namespace that has a label `app=reviews`
```

The above policy will allow `AWS EC2` instances associated with `AWS IAM Role`
`ratings-role` to join `WorkloadGroups` that have label `app=ratings`,
while `AWS EC2` instances associated with `AWS IAM Role` `reviews-role` to join
`WorkloadGroups` that have label `app=reviews`.

The final example demonstrates other constraints that can be put on
`AWS EC2` instances:

```yaml
apiVersion: authorization.onboarding.tetrate.io/v1alpha1
kind: OnboardingPolicy
metadata:
  name: allow-aws-ec2-vms
  namespace: bookinfo
spec:
  allow:
  - workloads:
    - aws:
        partitions:
        - aws
        accounts:
        - '123456789012'
        regions:
        - ca-central-1
        zones:
        - ca-central-1b
        ec2: {}           # any AWS EC2 instance from the above partitions/accounts/regions/zones
    - aws:
        partitions:
        - aws
        accounts:
        - '123456789012'
        regions:
        - us-east-1
        zones:
        - us-east-1a
        ec2:
          iamRoleNames:
          - example-role  # any AWS EC2 instance from the above partitions/accounts/regions/zones
                          # associated with one of IAM Roles on that list
    onboardTo:
    - workloadGroupSelector:
        matchLabels:
          app: ratings
```

To onboard workloads from custom on-premise environments, you can leverage support for
[OIDC ID Tokens](https://openid.net/specs/openid-connect-core-1_0.html#IDToken).

If workloads in your custom environment can authenticate themselves by means of an
[OIDC ID Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken),
you can define policies corresponding to those tokens.

For example,

```yaml
apiVersion: authorization.onboarding.tetrate.io/v1alpha1
kind: OnboardingPolicy
metadata:
  name: allow-onpremise-jwt-vms
  namespace: bookinfo
spec:
  allow:
  - workloads:
    - jwt:
        issuer: "https://mycompany.corp"
        subjects:
        - "us-east-datacenter1-vm007"
        - "us-west-datacenter2-vm008"
    onboardTo:
    - workloadGroupSelector:
        matchLabels:
          app: ratings
```

The above policy applies to those workloads that can authenticate themselves by means of
an [OIDC ID Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken)
issued by `https://mycompany.corp` with a subject `us-east-datacenter1-vm007`
or `us-west-datacenter2-vm008`.

In those cases where [OIDC ID Tokens](https://openid.net/specs/openid-connect-core-1_0.html#IDToken)
from a given issuer include a map of fine-grained attributes associated with a workload,
it is possible to define rules that match those attributes.

E.g.,

```yaml
apiVersion: authorization.onboarding.tetrate.io/v1alpha1
kind: OnboardingPolicy
metadata:
  name: allow-onpremise-jwt-vms
  namespace: bookinfo
spec:
  allow:
  - workloads:
    - jwt:
        issuer: "https://mycompany.corp"
        attributes:
        - name: "region"
          values:
          - "us-east"
          - "us-west"
        - name: "instance_role"
          values:
          - "app-ratings"
    onboardTo:
    - workloadGroupSelector:
        matchLabels:
          app: ratings
```

The above policy applies the workloads that can authenticate themselves by means of
an [OIDC ID Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken)
issued by `https://mycompany.corp` that includes
1) attribute `region` with one of the values `us-east` or `us-west`
and
2) attribute `instance_role` with the value `app-ratings`.





## OnboardingPolicyRule {#tetrateio-api-onboarding-authorization-v1alpha1-onboardingpolicyrule}

OnboardingPolicyRule authorizes matching workloads to join the mesh and
become a part of a
[WorkloadGroup](https://istio.io/latest/docs/reference/config/networking/workload-group/).



  
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


workloads

</td>

<td>

List of [tetrateio.api.onboarding.authorization.v1alpha1.WorkloadIdentityMatcher](../../../../onboarding/config/authorization/v1alpha1/policy#tetrateio-api-onboarding-authorization-v1alpha1-workloadidentitymatcher) <br/> _REQUIRED_ <br/> Select the workloads to which this rule applies.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;min_items: `1`<br/>&nbsp;&nbsp;items: `{message:{required:true}}`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


onboardTo

</td>

<td>

List of [tetrateio.api.onboarding.authorization.v1alpha1.WorkloadGroupMatcher](../../../../onboarding/config/authorization/v1alpha1/policy#tetrateio-api-onboarding-authorization-v1alpha1-workloadgroupmatcher) <br/> _REQUIRED_ <br/> List of `WorkloadGroups` these workloads are allowed to join.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;min_items: `1`<br/>&nbsp;&nbsp;items: `{message:{required:true}}`<br/>}<br/>

</td>
</tr>
    
</table>
  


## OnboardingPolicySpec {#tetrateio-api-onboarding-authorization-v1alpha1-onboardingpolicyspec}

OnboardingPolicySpec is the specification of a policy that authorizes
matching workloads to join the mesh and become a part of a
[WorkloadGroup](https://istio.io/latest/docs/reference/config/networking/workload-group/).



  
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


allow

</td>

<td>

List of [tetrateio.api.onboarding.authorization.v1alpha1.OnboardingPolicyRule](../../../../onboarding/config/authorization/v1alpha1/policy#tetrateio-api-onboarding-authorization-v1alpha1-onboardingpolicyrule) <br/> _REQUIRED_ <br/> List of authorization rules.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;min_items: `1`<br/>&nbsp;&nbsp;items: `{message:{required:true}}`<br/>}<br/>

</td>
</tr>
    
</table>
  


## WorkloadGroupMatcher {#tetrateio-api-onboarding-authorization-v1alpha1-workloadgroupmatcher}

WorkloadGroupMatcher specifies matching `WorkloadGroups`.



  
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


workloadGroupSelector

</td>

<td>

[k8s.io.apimachinery.pkg.apis.meta.v1.LabelSelector](#) <br/> Selector of [WorkloadGroup](https://istio.io/latest/docs/reference/config/networking/workload-group/)s.

This field follows standard label selector semantics;
if present but empty, it selects all `WorkloadGroups`.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## WorkloadIdentityMatcher {#tetrateio-api-onboarding-authorization-v1alpha1-workloadidentitymatcher}

WorkloadIdentityMatcher specifies matching workloads according to their
platform-specific identities.



  
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

[tetrateio.api.onboarding.authorization.aws.v1alpha1.AwsIdentityMatcher](../../../../onboarding/config/authorization/aws/v1alpha1/aws#tetrateio-api-onboarding-authorization-aws-v1alpha1-awsidentitymatcher) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> kind</sup>_ <br/> Match workloads with `AWS`-specific identities.

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

[tetrateio.api.onboarding.authorization.jwt.v1alpha1.JwtIdentityMatcher](../../../../onboarding/config/authorization/jwt/v1alpha1/jwt#tetrateio-api-onboarding-authorization-jwt-v1alpha1-jwtidentitymatcher) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> kind</sup>_ <br/> Match workloads with [JWT](https://openid.net/specs/openid-connect-core-1_0.html#IDToken) identities.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



