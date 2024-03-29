---
title: WorkloadEntry Annotations
description: WorkloadEntry Annotations
---

List of annotations on a [WorkloadEntry] resource supported by the [tctl x sidecar-bootstrap] command.

## Usage example

```yaml
apiVersion: networking.istio.io/v1beta1
kind: WorkloadEntry
metadata:
  name: my-vm
  namespace: my-namespace
  annotations:
    sidecar-bootstrap.istio.io/ssh-user: istio-proxy
    sidecar-bootstrap.istio.io/proxy-config-dir: /etc/istio-proxy
    sidecar-bootstrap.istio.io/proxy-instance-ip: 10.0.0.1

    sidecar.istio.io/logLevel: debug
    sidecar.istio.io/componentLogLevel: upstream:info,config:trace
    sidecar.istio.io/statsInclusionRegexps: .* # enable all Envoy metrics
    proxy.istio.io/config: |
      concurrency: 3
spec:
  ...
```

## Standard Istio annotations


### proxy.istio.io/config

> Overrides for the proxy configuration for this specific proxy. Available options can be found at https://istio.io/docs/reference/config/istio.mesh.v1alpha1/#ProxyConfig.

### sidecar.istio.io/interceptionMode

> Specifies the mode used to redirect inbound connections to Envoy (REDIRECT or TPROXY).

### sidecar.istio.io/proxyImage

> Specifies the Docker image to be used by the Envoy sidecar.

### sidecar.istio.io/logLevel

> Specifies the log level for Envoy.

### sidecar.istio.io/componentLogLevel

> Specifies the component log level for Envoy.

### sidecar.istio.io/agentLogLevel

> Specifies the log output level for pilot-agent.

### sidecar.istio.io/statsInclusionPrefixes

> Specifies the comma separated list of prefixes of the stats to be emitted by Envoy.

### sidecar.istio.io/statsInclusionSuffixes

> Specifies the comma separated list of suffixes of the stats to be emitted by Envoy.

### sidecar.istio.io/statsInclusionRegexps

> Specifies the comma separated list of regexes the stats should match to be emitted by Envoy.


## Annotations specific to [tctl x sidecar-bootstrap] command


### sidecar-bootstrap.istio.io/istio-revision

> Istio revision the Istio proxy should connect to.
> 
> By default, default Istio revision is assumed.

### sidecar-bootstrap.istio.io/mesh-expansion-configmap

> Name of the Kubernetes config map that holds configuration intended for those
> Istio Proxies that expand the mesh.
> 
> ConfigMap should include the following keys:
> * `PROXY_CONFIG` - (mandatory) ProxyConfig in YAML format (see https://istio.io/latest/docs/reference/config/istio.mesh.v1alpha1/#ProxyConfig)
> 
> This configuration is applied on top of mesh-wide default ProxyConfig,
> but prior to the workload-specific ProxyConfig from `proxy.istio.io/config` annotation
> on a WorkloadEntry.
> 
> By default, config map is considered undefined and thus expansion proxies will
> have the same configuration as the regular ones.

### sidecar-bootstrap.istio.io/ssh-host

> IP address or DNS name of the machine represented by this WorkloadEntry to use
> instead of WorkloadEntry.Address for SSH connections initiated by the `tctl x sidecar-bootstrap` command.
> 
> This setting is intended for those scenarios where `tctl x sidecar-bootstrap` command
> will be run on a machine without direct connectivity to the WorkloadEntry.Address.
> E.g., one might set WorkloadEntry.Address to the `Internal IP` of a VM
> and set value of this annotation to the `External IP` of that VM.
> 
> By default, value of WorkloadEntry.Address is assumed.

### sidecar-bootstrap.istio.io/ssh-port

> Port of the SSH server on the machine represented by this WorkloadEntry to use
> for SSH connections initiated by the `tctl x sidecar-bootstrap` command.
> 
> By default, "22" is assumed.

### sidecar-bootstrap.istio.io/ssh-user

> User on the machine represented by this WorkloadEntry to use for SSH connections
> initiated by the `tctl x sidecar-bootstrap` command.
> 
> Make sure that user has enough permissions to create the config dir and
> to run Docker container without `sudo`.
> 
> By default, a user running `tctl x sidecar-bootstrap` command is assumed.

### sidecar-bootstrap.istio.io/scp-path

> Path to the `scp` binary on the machine represented by this WorkloadEntry to use
> in SSH connections initiated by the `tctl x sidecar-bootstrap` command.
> 
> By default, "/usr/bin/scp" is assumed.

### sidecar-bootstrap.istio.io/proxy-config-dir

> Directory on the machine represented by this WorkloadEntry where `tctl x sidecar-bootstrap` command
> should copy bootstrap bundle to.
> 
> By default, "/tmp/istio-proxy" is assumed (the most reliable default value for out-of-the-box experience).

### sidecar-bootstrap.istio.io/proxy-image-hub

> Hub with Istio Proxy images that the machine represented by this WorkloadEntry
> should pull from instead of the mesh-wide hub.
> 
> By default, mesh-wide hub is assumed.

### sidecar-bootstrap.istio.io/proxy-container-name

> Name for a container with Istio Proxy.
> 
> If you need to run multiple Istio Proxy containers on the same machine, make sure each of them has a unique name.
> 
> By default, "istio-proxy" is assumed.

### sidecar-bootstrap.istio.io/proxy-instance-ip

> IP address of the machine represented by this WorkloadEntry that Istio Proxy
> should bind `inbound` listeners to.
> 
> This setting is intended for those scenarios where Istio Proxy cannot bind to
> the IP address specified in the WorkloadEntry.Address (e.g., on AWS EC2 where
> a VM can only bind the private IP but not the public one).
> 
> By default, WorkloadEntry.Address is assumed.

### istio.tetrate.io/proxy-type

> The type of Istio proxy that machines represented by this WorkloadEntry will run.
> 
> Valid options are "sidecar" to run as a sidecar proxy beside an application, and "gateway" to run
> as a gateway without an application workload.
> 
> By default the proxy will run as a sidecar.


[WorkloadEntry]: https://istio.io/latest/docs/reference/config/networking/workload-entry/
[tctl x sidecar-bootstrap]: https://docs.tetrate.io/service-bridge/en-us/reference/cli/reference/experimental#tctl-experimental-sidecar-bootstrap
