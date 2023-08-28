---
title: Security Setting
description: Security settings for proxy workloads in a security group.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

`SecuritySetting` allows configuring security related properties
such as TLS authentication and access control for traffic arriving
at a proxy workload in a security group.

Security settings can be propagated along any defined security settings in the configuration hierarchy.
How security settings are propagated can be configured by specifying a *PropagationStrategy*.

The following example creates a security group for the proxy workloads in
`ns1`, `ns2` and `ns3` namespaces owned by its parent workspace
`w1` under tenant `mycompany` and defines a security setting that
only allows mutual TLS authenticated traffic from other proxy workloads in
the same group.

```yaml
apiVersion: security.tsb.tetrate.io/v2
kind: Group
metadata:
  name: t1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  namespaceSelector:
    names:
    - "*/ns1"
    - "*/ns2"
    - "*/ns3"
  configMode: BRIDGED
```

And the associated security settings for all proxy workloads in the group

```yaml
apiVersion: security.tsb.tetrate.io/v2
kind: SecuritySetting
metadata:
  name: defaults
  group: t1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  authenticationSettings:
    trafficMode: REQUIRED
  authorization:
    mode: GROUP
```

The following example customizes the `allowedSources` to allow
traffic from the namespaces within the group as well as the
`catalog-sa` service account from `ns4` namespace.

```yaml
apiVersion: security.tsb.tetrate.io/v2
kind: SecuritySetting
metadata:
  name: custom
  group: t1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  authenticationSettings:
    trafficMode: REQUIRED
    http:
      rules:
        jwt:
        - issuer: "https://auth.tetrate.io"
          jwksUri: "https://oauth2.auth.tetrate.io/certs"
        - issuer: "https://auth.tetrate.internal"
          jwksUri: "https://oauth2.auth.tetrate.internal/certs"
  authorization:
    mode: CUSTOM
    serviceAccounts:
    - "ns1/*"
    - "ns2/*"
    - "ns3/*"
    - "ns4/catalog-sa"
    http:
      external:
        uri: "https://policy.auth.tetrate.io"
        includeRequestHeaders:
        - authorization
```

The following example **rejects all** traffic arriving at workloads from namespaces
that belong to security group `t1`.

```yaml
apiVersion: security.tsb.tetrate.io/v2
kind: SecuritySetting
metadata:
  name: defaults
  group: t1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  authenticationSettings:
    trafficMode: REQUIRED
  authorization:
    mode: RULES
    rules:
      denyAll: true
```

The following example **accepts all** traffic arriving at workloads from namespaces
that belong to security group `t1`. All authenticated requests are accepted
because any workload is targeted to be allowed nor denied.

```yaml
apiVersion: security.tsb.tetrate.io/v2
kind: SecuritySetting
metadata:
  name: defaults
  group: t1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  authenticationSettings:
    trafficMode: REQUIRED
  authorization:
    mode: RULES
```

The following example **accepts all** traffic arriving at workloads in namespaces that belong
to security group `t1` traffic, **except** from workloads belonging to workspace `w2`.

```yaml
apiVersion: security.tsb.tetrate.io/v2
kind: SecuritySetting
metadata:
  name: defaults
  group: t1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  authenticationSettings:
    trafficMode: REQUIRED
  authorization:
    mode: RULES
    rules:
      deny:
       - from:
           fqn: organizations/myorg/tenants/mycompany/workspaces/w2
         to:
           fqn: organizations/myorg/tenants/mycompany/workspaces/w1/securitygroups/t1
```

The following example accepts traffic arriving at workloads in namespaces that belong
to security group `t1` traffic, from workloads belonging to workspace `w2`.
Hence, only authenticated request to workloads in security group `t1` coming from
workloads in workspace `w2` are accepted. All other request will be rejected.

```yaml
apiVersion: security.tsb.tetrate.io/v2
kind: SecuritySetting
metadata:
  name: defaults
  group: t1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  authenticationSettings:
    trafficMode: REQUIRED
  authorization:
    mode: RULES
    rules:
      allow:
       - from:
           fqn: organizations/myorg/tenants/mycompany/workspaces/w2
         to:
           fqn: organizations/myorg/tenants/mycompany/workspaces/w1/securitygroups/t1
```

The following example uses a combination of allows and denies to show how rules are evaluated.
Let's say we have a workspace `w3` which contains 3 security groups, `sg31`, `sg32`, and `sg33`. Besides we also
have workspace `w1` and `w2`.
Security group `sg31` contains workloads that handle sensitive data, and we want to
only accept requests arriving from the same workspace `w3` and explicitly reject requests coming from `sg32`.
Hence, only authenticated request to workloads in security group `sg31` coming from
workloads in workspace `w3` and security group `sg31` or `sg33` will be accepted. Requests coming from `sg32`
will be rejected. Moreover, a request coming from any workload that belongs to another
workspace (`w1`, or `w2`), or security group that belong to another workspace, will also be reject
by default because it is not in the list of allowed resource FQNs.

```yaml
apiVersion: security.tsb.tetrate.io/v2
kind: SecuritySetting
metadata:
  name: defaults
  group: sg31
  workspace: w3
  tenant: mycompany
  organization: myorg
spec:
  authenticationSettings:
    trafficMode: REQUIRED
  authorization:
    mode: RULES
    rules:
      allow:
       - from:
           fqn: organizations/myorg/tenants/mycompany/workspaces/w3
         to:
           fqn: organizations/myorg/tenants/mycompany/workspaces/w3/securitygroups/sg31
      deny:
       - from:
           fqn: organizations/myorg/tenants/mycompany/workspaces/w3/securitygroups/sg32
         to:
           fqn: organizations/myorg/tenants/mycompany/workspaces/w3/securitygroups/sg31
```

The following example customizes the `WAFSettings` to enforce Web Application
Firewall rules on sidecars in namespaces reside in SecurityGroup.

Please **DO NOT** use it in production.

```yaml
apiVersion: security.tsb.tetrate.io/v2
kind: SecuritySetting
metadata:
  name: defaults
  group: t1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  waf:
    rules:
      - SecRuleEngine ON
      - Include @owasp_crs/*.conf
```

The following example customizes the `Extensions` to enable
the execution of the WasmExtensions list specified, detailing
custom properties for the execution of each extension.

```yaml
apiVersion: security.tsb.tetrate.io/v2
kind: SecuritySetting
metadata:
  name: defaults
  group: t1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  extension:
  - fqn: hello-world # fqn of imported extensions in TSB
    config:
      foo: bar
```





## AuthenticationSettings {#tetrateio-api-tsb-security-v2-authenticationsettings}

AuthenticationSettings represents configuration related to authenticating traffic
within the mesh and end-user credentials if present. It is **HIGHLY RECOMMENDED** to
enable mutual TLS when end-user credentials are present. Sending credentials like JWT
over plaintext is a security risk.



  
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


trafficMode

</td>

<td>

[tetrateio.api.tsb.security.v2.SecuritySetting.AuthenticationMode](../../../tsb/security/v2/security_setting#tetrateio-api-tsb-security-v2-securitysetting-authenticationmode) <br/> Traffic authentication mode is used to specify if mTLS or plaintext traffic is accepted

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


http

</td>

<td>

[tetrateio.api.tsb.auth.v2.Authentication](../../../tsb/auth/v2/auth#tetrateio-api-tsb-auth-v2-authentication) <br/> HTTP request authentication is used to configure authentication of origin/end-user
credentials like JSON Web Token (JWT). It is highly recommended to set traffic
authentication mode to REQUIRED so that it is transported only over mutual TLS

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## AuthorizationRules {#tetrateio-api-tsb-security-v2-authorizationrules}

`AuthorizationRules` specifies which target workloads are allowed or denied.
When the mode is `RULES`, by default, if no authorization rules are provided all requests will be accepted.
Currently, when a list of allow or deny rules are provided, a workload can only be targeted
by providing the workspace or security group resource the workload belongs to.
When different target workloads are allowed, denied or all workload are denied,
to evaluate if a request is accepted or rejected, denies are evaluated first, and finally allows.
Accepting or denying a request from a workload is determined by:

- If deny_all is true, deny the request

- If deny is defined and there are any denied target workload, deny the request.

- If there are no allowed target workload, allow the request.

- If allow is defined and there are any allowed target workload, allow the request.

- Deny the request.



  
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

List of [tetrateio.api.tsb.security.v2.Rule](../../../tsb/security/v2/security_setting#tetrateio-api-tsb-security-v2-rule) <br/> Allow specifies a list of rules. If a request matches at least one rule, the request is accepted.
If no allow rules are provided, all requests are allowed.
Each rule must be unique, no duplicates are allowed.
A rule that is fully contained by another rule is not allowed.
For instance, defining a rule from workspace `w1` to `w2` and another rule
from security group `sg1` (which belongs to workspace `w1`) to `sg2` (which belongs to workspace `w2`)
is not allowed. It is not allowed, because from security group `sg1` to `sg2` rule is already allowed by
the rule from workspace `w1` to `ws2`.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


denyAll

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Deny all specifies whether all requests should be rejected.
If it is true all requests will be rejected.
If it is false the list of deny rules will be evaluated.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


deny

</td>

<td>

List of [tetrateio.api.tsb.security.v2.Rule](../../../tsb/security/v2/security_setting#tetrateio-api-tsb-security-v2-rule) <br/> Deny specifies a list of rules. If a request matches at least one rule, the request is rejected.
If deny rules are provided, the match will never occur, so no request can be rejected.
Each rule must be unique, no duplicates are allowed.
A rule that is fully contained by another rule is not allowed.
For instance, defining a rule from workspace `w1` to `w2` and another rule
from security group `sg1` (which belongs to workspace `w1`) to `sg2` (which belongs to workspace `w2`)
is not allowed. It is not allowed, because from security group `sg1` to `sg2` rule is already denied by
the rule from workspace `w1` to `w2`.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## AuthorizationSettings {#tetrateio-api-tsb-security-v2-authorizationsettings}

`AuthorizationSettings` define the set of service accounts in one
or more namespaces allowed to access a workload (and hence its
sidecar) in the mesh.



  
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

[tetrateio.api.tsb.security.v2.AuthorizationSettings.Mode](../../../tsb/security/v2/security_setting#tetrateio-api-tsb-security-v2-authorizationsettings-mode) <br/> A short cut for specifying the set of allowed callers.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


serviceAccounts

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> When the mode is `CUSTOM`, `serviceAccounts` specify the allowed
set of service accounts (and the workloads using them). Must be
in the `<namespace>/<service-account-name>` format.

- `./*` indicates all service accounts in the namespace where the sidecar resides.

- `ns1/*` indicates all service accounts in the `ns1` namespace.

- `ns1/svc1-sa` indicates `svc1-sa` service account in `ns1` namespace.

Namespace should be a valid kubernetes namespace, which
follows [RFC 1123 Label Names](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#dns-label-names) rules.
Service account should be a valid kubernetes service account, which
follows [DNS Subdomain Names](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#dns-subdomain-names) rules.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;items: `{string:{pattern:^\\./\\*$|^[^.*]+/[*]{1}$|^[^.*]+/[^*]+$}}`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


http

</td>

<td>

[tetrateio.api.tsb.auth.v2.Authorization](../../../tsb/auth/v2/auth#tetrateio-api-tsb-auth-v2-authorization) <br/> This is for configuring HTTP request authorization. Currently, we only
support authorizing through an external backend/policy engine like OPA.
Inline authorization rules for JWT are not yet supported for sidecars.

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

[tetrateio.api.tsb.security.v2.AuthorizationRules](../../../tsb/security/v2/security_setting#tetrateio-api-tsb-security-v2-authorizationrules) <br/> When the mode is `RULES`, you can allow or deny workload-to-workload communication by specifying
in the `rules` field which target workloads are allowed or denied to communicate with other target workloads.
When the mode is `RULES`, if no authorization rules are provided all requests will be accepted.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Rule {#tetrateio-api-tsb-security-v2-rule}

`Rule` matches request from a targeted resource (and the workloads that belong to the resource),
to another targeted resource (and the workloads that belong to the resource).
A match occurs when `from` and `to` matches the request.
Only resources of type Tenant, Workspace, or Security Group can be targeted.



  
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


from

</td>

<td>

[tetrateio.api.tsb.security.v2.Rule.From](../../../tsb/security/v2/security_setting#tetrateio-api-tsb-security-v2-rule-from) <br/> _REQUIRED_ <br/> From specifies the source of a request.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


to

</td>

<td>

[tetrateio.api.tsb.security.v2.Rule.To](../../../tsb/security/v2/security_setting#tetrateio-api-tsb-security-v2-rule-to) <br/> _REQUIRED_ <br/> To specifies the destination of a request.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### From {#tetrateio-api-tsb-security-v2-rule-from}

From includes the target resource (and the workloads that belong to the resource)
which will be the source of a request.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The target resource identified by FQN which will be the source of a request.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### To {#tetrateio-api-tsb-security-v2-rule-to}

To includes the target resource (and the workloads that belong to the resource)
which will be destination of a request.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The target resource identified by FQN which will be the destination of a request.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## SecuritySetting {#tetrateio-api-tsb-security-v2-securitysetting}

A security setting applies configuration to a set of proxy workloads in a
security group or a workspace. When applied to a security group,
missing fields will inherit values from the workspace-wide setting if any.



  
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


authentication

</td>

<td>

[tetrateio.api.tsb.security.v2.SecuritySetting.AuthenticationMode](../../../tsb/security/v2/security_setting#tetrateio-api-tsb-security-v2-securitysetting-authenticationmode) <br/> DEPRECATED: Specifies whether the proxy workloads should accept only mutual TLS
authenticated traffic or allow legacy plaintext traffic as well.
This field is deprecated in favor of `authentication_settings` and will
be removed in the future release

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


authorization

</td>

<td>

[tetrateio.api.tsb.security.v2.AuthorizationSettings](../../../tsb/security/v2/security_setting#tetrateio-api-tsb-security-v2-authorizationsettings) <br/> The set of service accounts in one or more namespaces allowed or denied to
access a workload (and hence its sidecar) in the mesh.
Authorization is affected by the security setting's defined propagation strategy.
If `STRICTER` is used the most restrictive AuthorizationSettings mode along the configuration
hierarchy will prevail.

AuthorizationSettings mode can only be changed from `UNSET` to `DISABLED` to `CLUSTER` to `WORKSPACE`
to `NAMESPACE` to `GROUP` to `RULES` to `CUSTOM`.
Restricting two `CUSTOM` AuthorizationSettings is a special case. A service account is considered stricter
if it belongs to the same namespace and it has a concrete service account other than
a wildcard. Hence, the only possibilities to restrict service accounts is from "ns/\*" to "ns/svc1-sa".
When two lists of service accounts are compared (a parent and a child list) only the service accounts
from the child list that are stricter (following the previously mentioned rules) or equal to any of
the parent defined service accounts will be used. If none of the children's service accounts is stricter or equal,
then the parent defined list will be used.
For instance, a parent defines "ns/\*", "ns2/svc-sa", and "./\*" service accounts, whereas a child defines
"ns/svc1-sa", "ns3/svc-sa", and "./*". The effective strictest list will be "ns/svc1-sa", and "./*".
"ns3/svc2-sa" is discarded because it will extend the set of service accounts allowed to access
the workload/s, as parent's defined service accounts does not include "ns3/*" or "ns3/svc2-sa".

Restricting two `rules` AuthorizationSettings is also a special case. To consider a `rules` stricter,
both allowed and denied rules list need to be considered as stricter.
Allowed rules can only be refined by subsets of the initial rule.
Hence, you cannot allow more workloads, only less.
For instance, if an allow rule **from** workspace `w1` **to** `w2` has been specified higher up in the hierarchy,
it can only be refined with the same resource or lineage resources lower down in the resource hierarchy.
Which means, if `w1` has a child security group `sg1`, only `sg1` and `w1` itself are considered as
a stricter **from** resource target.
In the same way, if `w2` has a child security group `sg2`, only `sg2` and `w2` itself are considered as
a stricter **to** resource target.
On the other hand, any provided list of denied rules lower down in the hierarchy,
will be considered always stricter, because all ancestor's denied rules are also taken into consideration.
Basically, stricter `rules` AuthorizationSettings can only allow the same or less,
and/or deny more workloads.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


authenticationSettings

</td>

<td>

[tetrateio.api.tsb.security.v2.AuthenticationSettings](../../../tsb/security/v2/security_setting#tetrateio-api-tsb-security-v2-authenticationsettings) <br/> Authentication settings is used to set workload-to-workload traffic
and end-user/origin authentication configuration.
Authentication settings is affected by the security setting's defined propagation strategy.
If `STRICTER` is used the most restrictive AuthenticationSettings traffic mode along the configuration
hierarchy will prevail.
AuthenticationSettings traffic mode can only be changed from `UNSET` to `OPTIONAL` to `REQUIRED`.
Authentication settings http will use replace propagation strategy.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


waf

</td>

<td>

[tetrateio.api.tsb.security.v2.WAFSettings](../../../tsb/security/v2/waf_settings#tetrateio-api-tsb-security-v2-wafsettings) <br/> NOTICE: this feature is in alpha stage and under active development.
it would encounter breaking changes in further release and should not be adopted in production
WAF settings is used to set firewall rules.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


propagationStrategy

</td>

<td>

[tetrateio.api.tsb.types.v2.PropagationStrategy](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-propagationstrategy) <br/> Propagation strategy specifies how a security setting is propagated along
the configuration hierarchy. The default strategy is `REPLACE`.
The propagation strategy from security settings can only be changed from `REPLACE`
to `STRICTER` along the settings in the configuration hierarchy. Any security setting propagation
strategy changed from the default one, higher up in the configuration hierarchy, will prevail
over any other defined security setting propagation strategy further down in the configuration hierarchy.
For instance, if an organization's default security setting propagation strategy is changed to `STRICTER`,
a restrictive propagation strategy will be used at tenant, workspace default security settings and group security
settings. `STRICTER` propagation strategy will be used even though, tenant, workspace or group security settings
specifies a `REPLACE` propagation strategy.

Security setting properties affected by the propagation strategy are:

- Authorization

- AuthenticationSettings

- Extension

All the other properties will use the default `REPLACE` propagation strategy.
How each property affected by the propagation strategy will be restricted is explained in more detail
at each property.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


extension

</td>

<td>

List of [tetrateio.api.tsb.types.v2.WasmExtensionAttachment](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-wasmextensionattachment) <br/> Extensions specifies all the WasmExtensions assigned to this SecuritySettings
with the specific configuration for each extension. This custom configuration
will override the one configured globally to the extension.
Each extension has a global configuration including enabling and priority
that will condition the execution of the assigned extensions.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


configGenerationMetadata

</td>

<td>

[tetrateio.api.tsb.types.v2.ConfigGenerationMetadata](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-configgenerationmetadata) <br/> Metadata values that will be add into the Istio generated configurations.
When using YAML APIs like`tctl` or `gitops`, put them into the `metadata.labels` or
`metadata.annotations` instead.
This field is only necessary when using gRPC APIs directly.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  




### Mode {#tetrateio-api-tsb-security-v2-authorizationsettings-mode}

A short cut for defining the common authorization patterns


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


UNSET

</td>

<td>

0

</td>

<td>

Inherit from parent if possible. Otherwise treated as `DISABLED`.

</td>
</tr>
    
<tr>
<td>


NAMESPACE

</td>

<td>

1

</td>

<td>

The workload allows traffic from any other authenticated workload in its own
namespace.

</td>
</tr>
    
<tr>
<td>


GROUP

</td>

<td>

2

</td>

<td>

The workload allows traffic from any other authenticated workload in the security group.

</td>
</tr>
    
<tr>
<td>


WORKSPACE

</td>

<td>

3

</td>

<td>

The workload allows traffic from any other authenticated workload in the workspace.

</td>
</tr>
    
<tr>
<td>


CLUSTER

</td>

<td>

4

</td>

<td>

The workload allows traffic from any other authenticated workload in the cluster.

</td>
</tr>
    
<tr>
<td>


DISABLED

</td>

<td>

5

</td>

<td>

Authorization is disabled.

</td>
</tr>
    
<tr>
<td>


CUSTOM

</td>

<td>

6

</td>

<td>

The workload allows traffic from service accounts defined explicitly.

</td>
</tr>
    
<tr>
<td>


RULES

</td>

<td>

7

</td>

<td>

The workload allows or denies traffic from any other authenticated workload that belongs
to the specified rules.

</td>
</tr>
    
</table>
  



### AuthenticationMode {#tetrateio-api-tsb-security-v2-securitysetting-authenticationmode}

AuthenticationMode indicates whether to accept only Istio mutual
TLS authenticated traffic or allow legacy plaintext traffic as
well.


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


UNSET

</td>

<td>

0

</td>

<td>

Inherit from parent, if has one. Otherwise treated as OPTIONAL.

</td>
</tr>
    
<tr>
<td>


OPTIONAL

</td>

<td>

1

</td>

<td>

Accept both plaintext and mTLS authenticated connections.

</td>
</tr>
    
<tr>
<td>


REQUIRED

</td>

<td>

2

</td>

<td>

Accept only mutual TLS authenticated connections.

</td>
</tr>
    
</table>
  


