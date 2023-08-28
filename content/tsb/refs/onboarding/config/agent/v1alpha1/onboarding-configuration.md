---
title: Onboarding Configuration
description: Specifies where to onboard the workload to.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

`Onboarding Configuration` specifies where to onboard the workload to.

To be able to onboard a workload into a service mesh, a user must configure
`Workload Onboarding Agent` with the location of the
`Workload Onboarding Endpoint` and a name of the
[WorkloadGroup](https://istio.io/latest/docs/reference/config/networking/workload-group/)
to join.

By default, `Workload Onboarding Agent` will read `Onboarding Configuration`
from a file `/etc/onboarding-agent/onboarding.config.yaml`, which must be
created by the user.

If `Onboarding Configuration` file is missing or its contents is not
valid, `Workload Onboarding Agent` will not be able to start.

Consider the following example of the minimal valid configuration:

```yaml
apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
kind: OnboardingConfiguration
onboardingEndpoint:
  host: onboarding.example.org  # (1)
workloadGroup:
  namespace: bookinfo           # (2)
  name: ratings                 # (2)
```

The above configuration instructs `Workload Onboarding Agent` to connect to the
`Workload Onboarding Endpoint` reachable at the address
`onboarding.example.org:15443` (1) and automatically register the workload
as a member of the `WorkloadGroup` `"bookinfo/ratings"` (2).

`Workload Onboarding Endpoint` might decline the workload from being registered in
the mesh in case there is no `WorkloadGroup` with that name or there is no
`OnboardingPolicy` that authorizes this particular workload to join this
particular `WorkloadGroup`.

If a registration attempt fails, `Workload Onboarding Agent` will continue trying
indefinitely until both the `WorkloadGroup` and allowing `OnboardingPolicy` exist
in the mesh.

`Onboarding Configuration` can also be used to customize workload's
appearance in the mesh, e.g. a set of labels associated with the workload,
IP address of the workload that other mesh members should use to make
requests to it, etc.

E.g., consider the following example:

```yaml
apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
kind: OnboardingConfiguration
onboardingEndpoint:
  host: onboarding.example.org
workloadGroup:
  namespace: bookinfo
  name: ratings
workload:
  labels:
    version: v1  # (1)
```

The above configuration instructs `Workload Onboarding Agent` to register the
workload in the mesh and customize the set of labels associated with it.

By default, a workload is associated only with labels configured in the
respective `WorkloadGroup` resource.

By means of the above configuration, the workload will receive one extra
label `version=v1` (1).

Notice that `Onboarding Configuration` gives users an option to
specify additional labels for the workload, but it does not allow to override
labels specified in the `WorkloadGroup`. E.g., if a `WorkloadGroup` specifies
label `app=ratings`, `Onboarding Configuration` can not be used
to override it with `app=details`.

As a rule of thumb, users should specify labels common to all workloads in
the group using the `WorkloadGroup` resource, e.g. `app` label.
Labels that can be unique to every individual workload in the group, e.g.
`version` label, should be specified using `Onboarding Configuration`.

Next, `Onboarding Configuration` can be used to fine-tune workload
registration in the mesh on a feature-by-feature basis.

E.g., consider the following example:

```yaml
apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
kind: OnboardingConfiguration
onboardingEndpoint:
  host: onboarding.example.org
workloadGroup:
  namespace: bookinfo
  name: ratings
settings:
  connectedOver: INTERNET  # (1)
```

The above configuration instructs `Workload Onboarding Agent` to register the
workload in the mesh by its `Public IP` address (aka `Internet IP`) rather
than `Private IP` (aka `VPC IP`) (1).

Normally, workloads should be connected to the rest of the mesh over a
private network, which improves security and therefore is the default
behavior.

However, in those cases where private network connectivity between the
workload and the rest of the mesh is not possible or not practical, users can
use `Onboarding Configuration` to opt for connectivity over `Internet`
instead.

In the above example, the workload will be registered in the mesh by its
`Public IP` address (aka `Internet IP`). In practice, it means that other
workloads in the mesh will use that `Public IP` to connect to this workload.

Lastly, `Onboarding Configuration` provides support for non-production
scenarios, such as getting started try-outs and disposable environments for
demos and trials.

In those cases where users find it acceptable to disable certain security
safeguards in favour of simplicity of the setup, they can utilize the following
configuration options.

If a user has no means to create a DNS record for the `Workload Onboarding Endpoint`,
he/she can workaround this constraint by fine-tuning `Onboarding Configuration`
the following way:

```yaml
apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
kind: OnboardingConfiguration
onboardingEndpoint:
  host: 1.2.3.4                    # (1)
  transportSecurity:
    tls:
      sni: onboarding.example.org  # (2)
workloadGroup:
  namespace: bookinfo
  name: ratings
```

The above configuration instructs `Workload Onboarding Agent` to connect to
`1.2.3.4` (1), yet validate server certificate as if the connection was made
to `onboarding.example.org` (2), removing the need to register DNS record for
`onboarding.example.org` or to modify `/etc/hosts` file on the `Agent`'s host.

Furthermore, if a user has no means to issue a certificate for the
`Workload Onboarding Endpoint` signed by a trusted CA, he/she can workaround this
constraint by using a self-signed certificate and fine-tuning
`Onboarding Configuration` the following way:

```yaml
apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
kind: OnboardingConfiguration
onboardingEndpoint:
  host: onboarding.example.org
  transportSecurity:
    tls:
      insecureSkipVerify: true  # (1)
workloadGroup:
  namespace: bookinfo
  name: ratings
```

The above configuration instructs `Workload Onboarding Agent` not to verify
certificate of the `Workload Onboarding Endpoint` at all (which is insecure!),
tolerating this way self-signed certificates.

:warning: `WARNING`: `NEVER` use `insecureSkipVerify` setting in
                        production scenarios!





## OnboardingConfiguration {#tetrateio-api-onboarding-config-agent-v1alpha1-onboardingconfiguration}

OnboardingConfiguration specifies where to onboard the workload to.



  
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


onboardingEndpoint

</td>

<td>

[tetrateio.api.onboarding.config.agent.v1alpha1.OnboardingConfiguration.OnboardingEndpoint](../../../../onboarding/config/agent/v1alpha1/onboarding_configuration#tetrateio-api-onboarding-config-agent-v1alpha1-onboardingconfiguration-onboardingendpoint) <br/> _REQUIRED_ <br/> Location of the `Workload Onboarding Plane`.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


workloadGroup

</td>

<td>

[tetrateio.api.onboarding.config.types.core.v1alpha1.NamespacedName](../../../../onboarding/config/types/core/v1alpha1/namespaced_name#tetrateio-api-onboarding-config-types-core-v1alpha1-namespacedname) <br/> _REQUIRED_ <br/> `WorkloadGroup` to join.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


workload

</td>

<td>

[tetrateio.api.onboarding.config.types.registration.v1alpha1.WorkloadInfo](../../../../onboarding/config/types/registration/v1alpha1/registration#tetrateio-api-onboarding-config-types-registration-v1alpha1-workloadinfo) <br/> Information about the workload to present to the `Workload Onboarding Plane`.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


settings

</td>

<td>

[tetrateio.api.onboarding.config.types.registration.v1alpha1.Settings](../../../../onboarding/config/types/registration/v1alpha1/registration#tetrateio-api-onboarding-config-types-registration-v1alpha1-settings) <br/> Registration settings to present to the `Workload Onboarding Plane`.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### OnboardingEndpoint {#tetrateio-api-onboarding-config-agent-v1alpha1-onboardingconfiguration-onboardingendpoint}

OnboardingEndpoint specifies where to find the `Workload Onboarding Plane`.



  
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


host

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Address of the onboarding endpoint (can be hostname or IP address).

</td>

<td>

string = {<br/>&nbsp;&nbsp;address: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


port

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Port of the onboarding endpoint.
Defaults to `15443`.

</td>

<td>

int32 = {<br/>&nbsp;&nbsp;lte: `65535`<br/>&nbsp;&nbsp;gte: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


transportSecurity

</td>

<td>

[tetrateio.api.onboarding.config.types.config.v1alpha1.ClientTransportSecurity](../../../../onboarding/config/types/config/v1alpha1/transport_security#tetrateio-api-onboarding-config-types-config-v1alpha1-clienttransportsecurity) <br/> Transport layer security configuration.
Defaults to secure TLS client.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



