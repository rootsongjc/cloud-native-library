---
title: Agent Configuration
description: Specifies configuration of the Onboarding Agent.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

`Agent Configuration` specifies configuration of the
`Workload Onboarding Agent`.

In most cases, `Workload Onboarding Agent` can automatically recognize the host
environment, e.g. `AWS EC2`, which makes explicit `Agent Configuration` optional.

By default, `Workload Onboarding Agent` comes with the minimal configuration:

```yaml
apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
kind: AgentConfiguration
```

which at runtime is interpreted as an equivalent of:

```yaml
apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
kind: AgentConfiguration
host:
  auto: {}
sidecar:
  istio: {}
  stdout:
    filename: /dev/stdout
  stderr:
    filename: /dev/stderr
```

The above configuration means that `Workload Onboarding Agent` should infer host
environment automatically, should be in control of the `Istio Sidecar`
pre-installed on that host, should redirect standard output of the
`Istio Sidecar` into its own output.

Most users do not need to change the default configuration.

Users who make use of Istio revisions, need to specify the revision the
pre-installed `Istio Sidecar` corresponds to, e.g.:

```yaml
apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
kind: AgentConfiguration
sidecar:
  istio:
    revision: canary
```

Users who want to redirect standard output of the `Istio Sidecar` into a
separate file (instead of mixing together output of the `Workload Onboarding Agent`
and output of the `Istio Sidecar`), should use the following configuration:

```yaml
apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
kind: AgentConfiguration
sidecar:
  stdout:
    filename: ./relative/path/to/file
  stderr:
    filename: /absolute/path/to/file
```

Relative path of a log file is interpreted as relative to the working
directory of the `Workload Onboarding Agent`.

Advanced users who would like to utilize `Workload Onboarding Agent` in an
environment that is not supported out-of-the-box, can develop custom
`Workload Onboarding Agent Plugins` and use them by providing an explicit
`Agent Configuration`, e.g.:

```yaml
apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
kind: AgentConfiguration
host:
  custom:
    credential:
    - plugin:
        name: custom-credential-provider
        path: /path/to/custom-credential-provider-binary
    hostinfo:
      plugin:
        name: custom-hostinfo-provider
        path: /path/to/custom-hostinfo-provider-binary
        env:
        - name: CONFIG
          value: /path/to/config
        args:
        - --name=value
settings:
  connection:
    timeout: 60s
    retryPolicy:
      exponentialBackoff:
        initialInterval: 10s
        maxInterval: 120s
```

`Workload Onboarding Agent Plugin` is an auxiliary executable (e.g. binary,
`shell` script, `Python` script, etc) installed in addition to the
`Workload Onboarding Agent`.

`Workload Onboarding Agent` executes a `Workload Onboarding Agent Plugin` to
procure platform-specific information.

```text
+--------------------------------------------------------+
| Host (e.g., VM or container)                           |
|                                                        |
|  +------------------+            +------------------+  |
|  |                  |            |                  |  |
|  |     Workload     | ---------> |     Workload     |  |
|  | Onboarding Agent | (executes) | Onboarding Agent |  |
|  |                  |            |      Plugin      |  |
|  +------------------+            +------------------+  |
|                                                        |
+--------------------------------------------------------+
```

`Workload Onboarding Agent Plugin` is modeled as a `gRPC` service with unary call
method(s). However, `Workload Onboarding Agent Plugin` does not run a network server.
Instead, semantics of an unary RPC call is mapped onto execution of a process.

To make a call to the plugin, `Workload Onboarding Agent`:
- runs executable of the `Workload Onboarding Agent Plugin`
- passes parameters in via environment variables with the following names:
  * `PLUGIN_NAME` - mandatory - e.g., `aws-ec2-credential`
  * `RPC_SERVICE_NAME` - mandatory - e.g. `tetrateio.api.onboarding.private.component.agent.plugin.credential.v1alpha1.CredentialPlugin`
  * `RPC_METHOD_NAME` - mandatory - e.g. `GetCredential`
- writes request message serialized into JSON to the `stdin` of the
  plugin process
- if plugin process exists with a `0` code, reads from `stdout` response message
  serialized into JSON
- if plugin process exists with a `non-0` code, reads from `stdout`
  [RPC status](https://github.com/googleapis/googleapis/blob/master/google/rpc/status.proto)
  message serialized into JSON
- in a corner case where plugin process starts writing to `stdout` a response
  message, then encounters a failure and continues by writing to `stdout` an
  [RPC status](https://github.com/googleapis/googleapis/blob/master/google/rpc/status.proto)
  message, `Workload Onboarding Agent` should look at the exit code of the plugin
  process to decide how to interpret contents of `stdout`
- plugin process must only print to `stdout` either a response message or an
  [RPC status](https://github.com/googleapis/googleapis/blob/master/google/rpc/status.proto)
  message
- plugin process may print to `stderr` any data, e.g. diagnostic messages

In some cases instead of developing a custom plugin it is possible to reuse a built-in
behavior.

E.g., instead of developing a custom HostInfo plugin you can reuse built-in behavior that
simply lists available network interfaces instead of interacting with the platform-specific
metadata API.

```yaml
apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
kind: AgentConfiguration
host:
  custom:
    credential:
    - plugin:
        name: custom-credential-provider
        path: /path/to/custom-credential-provider-binary
    hostinfo:
      basic:
        networkInterfaces:
          include:
          - ^eth[0-9]*$
```





## AgentConfiguration {#tetrateio-api-onboarding-config-agent-v1alpha1-agentconfiguration}

AgentConfiguration specifies configuration of the
`Workload Onboarding Agent`.



  
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

[tetrateio.api.onboarding.config.agent.v1alpha1.HostEnvironment](../../../../onboarding/config/agent/v1alpha1/agent_configuration#tetrateio-api-onboarding-config-agent-v1alpha1-hostenvironment) <br/> Configuration of the host environment.
Defaults to automatically inferred configuration that will work
out-of-the-box if `Workload Onboarding Agent` is deployed into `AWS EC2`.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


sidecar

</td>

<td>

[tetrateio.api.onboarding.config.agent.v1alpha1.Sidecar](../../../../onboarding/config/agent/v1alpha1/agent_configuration#tetrateio-api-onboarding-config-agent-v1alpha1-sidecar) <br/> Configuration of the pre-installed sidecar.
Defaults to `Istio Sidecar` installed at a well-known location
(i.e., `/usr/local/bin/pilot-agent`, `/usr/local/bin/envoy`, etc).

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

[tetrateio.api.onboarding.config.agent.v1alpha1.Settings](../../../../onboarding/config/agent/v1alpha1/agent_configuration#tetrateio-api-onboarding-config-agent-v1alpha1-settings) <br/> In-depth runtime configuration.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## BasicHostInfo {#tetrateio-api-onboarding-config-agent-v1alpha1-basichostinfo}

BasicHostInfo specifies how to collect basic information about the host
in a cross-platform way.



  
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


networkInterfaces

</td>

<td>

[tetrateio.api.onboarding.config.agent.v1alpha1.BasicHostInfo.NetworkInterfaces](../../../../onboarding/config/agent/v1alpha1/agent_configuration#tetrateio-api-onboarding-config-agent-v1alpha1-basichostinfo-networkinterfaces) <br/> Filter on network interfaces that should be taken into account to
determine IP addresses of the host.
By default, all network interfaces will be taken into account,
including Docker bridge(s) if any.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### NetworkInterfaces {#tetrateio-api-onboarding-config-agent-v1alpha1-basichostinfo-networkinterfaces}

NetworkInterfaces specifies a filter on network interfaces that should
be taken into account to determine IP addresses of the host.

For a network interface to be taken into account its name must be matched
by one of the regular expressions on the `include` list and none of the
regular expressions on the `exclude` list.



  
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


include

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Names of network interfaces that should be taken into account.

The value is a regular expression (RE2 syntax).

E.g., `^eth.*$`, `eth0`, etc.

Empty list means take into account network interfaces with any name.

See https://golang.org/s/re2syntax

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;items: `{string:{min_len:1}}`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


exclude

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Names of network interfaces that should not be taken into account.

The value is a regular expression (RE2 syntax).

E.g., `^docker.*$`, `docker0`, etc.

See https://golang.org/s/re2syntax

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;items: `{string:{min_len:1}}`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ConnectionSettings {#tetrateio-api-onboarding-config-agent-v1alpha1-connectionsettings}

ConnectionSettings specifies settings that control execution of agent plugins,
e.g. a timeout for a single plugin call, a retry policy for failed plugin calls, etc.
The same settings apply to agent plugins of all kinds, e.g. credential plugins,
host info plugins, etc.



  
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


timeout

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> Timeout for a single plugin call.
Must be greater than 1 millisecond.
Defaults to `30s`.

</td>

<td>

duration = {<br/>&nbsp;&nbsp;gte: `{nanos:1000000}`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


retryPolicy

</td>

<td>

[tetrateio.api.onboarding.config.agent.v1alpha1.RetryPolicy](../../../../onboarding/config/agent/v1alpha1/agent_configuration#tetrateio-api-onboarding-config-agent-v1alpha1-retrypolicy) <br/> Retry policy for failed plugin calls.
Defaults to the exponential backoff starting at `1s` and raising up to `15s`
between retry attempts.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## CredentialSource {#tetrateio-api-onboarding-config-agent-v1alpha1-credentialsource}

CredentialSource specifies a source of a platform-specific credential.

`Workload Onboarding Agent` uses CredentialSource to procure a
platform-specific credential.



  
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


plugin

</td>

<td>

[tetrateio.api.onboarding.config.agent.v1alpha1.Plugin](../../../../onboarding/config/agent/v1alpha1/agent_configuration#tetrateio-api-onboarding-config-agent-v1alpha1-plugin) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> kind</sup>_ <br/> Plugin (an executable binary) as a source of a platform-specific
credential.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ExponentialBackoff {#tetrateio-api-onboarding-config-agent-v1alpha1-exponentialbackoff}

ExponentialBackoff specifies exponential backoff strategy.



  
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


initialInterval

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> The initial interval between retry attempts.
Must be greater than 1 millisecond.

</td>

<td>

duration = {<br/>&nbsp;&nbsp;gte: `{nanos:1000000}`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


maxInterval

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> The maximum interval between retry attempts.
Must be greater than 1 millisecond.

</td>

<td>

duration = {<br/>&nbsp;&nbsp;gte: `{nanos:1000000}`<br/>}<br/>

</td>
</tr>
    
</table>
  


## HostEnvironment {#tetrateio-api-onboarding-config-agent-v1alpha1-hostenvironment}

HostEnvironment specifies information about the host environment.



  
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


auto

</td>

<td>

[tetrateio.api.onboarding.config.agent.v1alpha1.HostEnvironment.Auto](../../../../onboarding/config/agent/v1alpha1/agent_configuration#tetrateio-api-onboarding-config-agent-v1alpha1-hostenvironment-auto) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> kind</sup>_ <br/> Automatically inferred environment.

This is the default mode.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


custom

</td>

<td>

[tetrateio.api.onboarding.config.agent.v1alpha1.HostEnvironment.Custom](../../../../onboarding/config/agent/v1alpha1/agent_configuration#tetrateio-api-onboarding-config-agent-v1alpha1-hostenvironment-custom) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> kind</sup>_ <br/> Custom environment configured explicitly by the user.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


aws

</td>

<td>

[tetrateio.api.onboarding.config.agent.v1alpha1.HostEnvironment.Aws](../../../../onboarding/config/agent/v1alpha1/agent_configuration#tetrateio-api-onboarding-config-agent-v1alpha1-hostenvironment-aws) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> kind</sup>_ <br/> `AWS` environment.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### Aws {#tetrateio-api-onboarding-config-agent-v1alpha1-hostenvironment-aws}

`AWS` environment.



  
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


ec2

</td>

<td>

[tetrateio.api.onboarding.config.agent.v1alpha1.HostEnvironment.Aws.Ec2](../../../../onboarding/config/agent/v1alpha1/agent_configuration#tetrateio-api-onboarding-config-agent-v1alpha1-hostenvironment-aws-ec2) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> kind</sup>_ <br/> `AWS EC2` environment.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### Custom {#tetrateio-api-onboarding-config-agent-v1alpha1-hostenvironment-custom}

Custom environment configured explicitly by the user.

In this mode a user has to explicitly configure a list of
`Workload Onboarding Agent Plugins` that procure information about the host
using platform-specific APIs, e.g. plugin(s) to procure platform-specific
credential of the host, a plugin to procure IP address(es) of the host,
etc.



  
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


credential

</td>

<td>

List of [tetrateio.api.onboarding.config.agent.v1alpha1.CredentialSource](../../../../onboarding/config/agent/v1alpha1/agent_configuration#tetrateio-api-onboarding-config-agent-v1alpha1-credentialsource) <br/> _REQUIRED_ <br/> Source(s) of an environment-specific credential.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;min_items: `1`<br/>&nbsp;&nbsp;items: `{message:{required:true}}`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


hostinfo

</td>

<td>

[tetrateio.api.onboarding.config.agent.v1alpha1.HostInfoSource](../../../../onboarding/config/agent/v1alpha1/agent_configuration#tetrateio-api-onboarding-config-agent-v1alpha1-hostinfosource) <br/> Source of an environment-specific host information.

Defaults to basic information about the host that can be collected in any
environment.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## HostInfoSource {#tetrateio-api-onboarding-config-agent-v1alpha1-hostinfosource}

HostInfoSource specifies a source of platform-specific information about
the host.

`Workload Onboarding Agent` uses HostInfoSource to procure platform-specific
information about the host.



  
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


plugin

</td>

<td>

[tetrateio.api.onboarding.config.agent.v1alpha1.Plugin](../../../../onboarding/config/agent/v1alpha1/agent_configuration#tetrateio-api-onboarding-config-agent-v1alpha1-plugin) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> kind</sup>_ <br/> Plugin (an executable binary) as a source of platform-specific
information about the host.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


basic

</td>

<td>

[tetrateio.api.onboarding.config.agent.v1alpha1.BasicHostInfo](../../../../onboarding/config/agent/v1alpha1/agent_configuration#tetrateio-api-onboarding-config-agent-v1alpha1-basichostinfo) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> kind</sup>_ <br/> Collect basic information about the host in a cross-platform way.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## IstioSidecar {#tetrateio-api-onboarding-config-agent-v1alpha1-istiosidecar}

Sidecar specifies configuration of the pre-installed `Istio Sidecar`.



  
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


revision

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Istio revision the pre-installed `Istio Sidecar` corresponds to.

E.g., `canary`, `alpha`, etc.

If omitted, it is assumed that the pre-installed `Istio Sidecar`
corresponds to the `default` Istio revision.

Notice that the value constraints here are stricter than the ones in Istio.
Apparently, Istio validation rules allow values that lead to internal failures
at runtime, e.g. values with capital letters or values longer than 56 characters.
Stricter validation rules here are meant to prevent those hidden pitfalls.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>&nbsp;&nbsp;max_len: `56`<br/>&nbsp;&nbsp;pattern: `^[a-z0-9](?:[-a-z0-9]*[a-z0-9])?$`<br/>&nbsp;&nbsp;ignore_empty: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## Output {#tetrateio-api-onboarding-config-agent-v1alpha1-output}

Destination for process output.



  
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


filename

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> kind</sup>_ <br/> Path to a file with standard output of the process.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Plugin {#tetrateio-api-onboarding-config-agent-v1alpha1-plugin}

Plugin specifies a `Workload Onboarding Agent Plugin` as a source of
platform-specific information.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Plugin reference name.
E.g., `my-platform-credential`.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


path

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Path to the plugin executable.
Defaults to `onboarding-agent-{{ plugin name }}-plugin` that will be
looked up on the `PATH`.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


env

</td>

<td>

List of [tetrateio.api.onboarding.config.agent.v1alpha1.Plugin.EnvVar](../../../../onboarding/config/agent/v1alpha1/agent_configuration#tetrateio-api-onboarding-config-agent-v1alpha1-plugin-envvar) <br/> Environment variables of the plugin.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


args

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Arguments of the plugin.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;items: `{string:{min_len:1}}`<br/>}<br/>

</td>
</tr>
    
</table>
  


### EnvVar {#tetrateio-api-onboarding-config-agent-v1alpha1-plugin-envvar}

EnvVar specifies a single environment variable.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Name of the environment variable.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


value

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Value of the environment variable.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## RetryPolicy {#tetrateio-api-onboarding-config-agent-v1alpha1-retrypolicy}

RetryPolicy specifies a retry policy for failed plugin calls.



  
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


exponentialBackoff

</td>

<td>

[tetrateio.api.onboarding.config.agent.v1alpha1.ExponentialBackoff](../../../../onboarding/config/agent/v1alpha1/agent_configuration#tetrateio-api-onboarding-config-agent-v1alpha1-exponentialbackoff) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> backoff</sup>_ <br/> Exponential backoff strategy.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Settings {#tetrateio-api-onboarding-config-agent-v1alpha1-settings}

Settings specifies in-depth runtime configuration.



  
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


connection

</td>

<td>

[tetrateio.api.onboarding.config.agent.v1alpha1.ConnectionSettings](../../../../onboarding/config/agent/v1alpha1/agent_configuration#tetrateio-api-onboarding-config-agent-v1alpha1-connectionsettings) <br/> Settings that control execution of agent plugins.

Please notice that these settings apply only to execution of
the Onboarding Agent plugins. These settings have no effect on
requests from the Onboarding Agent to the Onboarding Plane.

Also, notice that there is no physical "network connection"
between the Onboarding Agent and its plugins. Onboarding Agent
Plugin is a command-line tool that gets executed on demand; it
uses standard input/output to receive/return data rather than
network sockets.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Sidecar {#tetrateio-api-onboarding-config-agent-v1alpha1-sidecar}

Sidecar specifies configuration of the pre-installed sidecar.



  
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


istio

</td>

<td>

[tetrateio.api.onboarding.config.agent.v1alpha1.IstioSidecar](../../../../onboarding/config/agent/v1alpha1/agent_configuration#tetrateio-api-onboarding-config-agent-v1alpha1-istiosidecar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> kind</sup>_ <br/> Configuration of the pre-installed `Istio Sidecar`.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


stdout

</td>

<td>

[tetrateio.api.onboarding.config.agent.v1alpha1.Output](../../../../onboarding/config/agent/v1alpha1/agent_configuration#tetrateio-api-onboarding-config-agent-v1alpha1-output) <br/> Destination for the standard output of the sidecar.
Relative path is interpreted as relative to the working directory of the
`Workload Onboarding Agent`.
Defaults to `/dev/stdout`.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


stderr

</td>

<td>

[tetrateio.api.onboarding.config.agent.v1alpha1.Output](../../../../onboarding/config/agent/v1alpha1/agent_configuration#tetrateio-api-onboarding-config-agent-v1alpha1-output) <br/> Destination for the standard error output of the sidecar.
Relative path is interpreted as relative to the working directory of the
`Workload Onboarding Agent`.
Defaults to `/dev/stderr`.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



