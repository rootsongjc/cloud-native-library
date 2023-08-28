---
title: Firewall Information
description: Guide on firewall rules.
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

If your environment has strict network policies that prevent any unauthorized
communication between two namespaces, you may need to add one or more exceptions
to your network policies to allow communication between the sidecars and the
local Istio Control Plane, as well as between the local Istio Control Plane and
the TSB management plane.

The following information can be used to derive the appropriate set of firewall
rules.

## Communication between TSB, Control Plane and Workloads

### Between Istio and TSB

:::note TSB Load Balancer port
TSB Load Balancer (also known as `front-envoy`) has default port 8443. This port value is user configurable. 
For example, it can be changed to 443. If the default port is changed, then all components that communicate via `front-envoy` need to be adjusted accordingly to match the user-defined value of the `front-envoy` port.
:::

| Source |  Destination
| --- | ---
| `xcp-edge.istio-system` | TSB Load Balancer IP, port `9443`
| `oap.istio-system` | TSB Load Balancer IP, port `8443` or user defined `front-envoy` port
| `otel-collector.istio-system` | TSB Load Balancer IP, port `8443` or user defined `front-envoy` port
| `oap.istio-system` | Elasticsearch target IP and port <br /> *(If using demo deployment of Elasticsearch or using front-envoy as Elasticsearch proxy, change to TSB Load Balancer IP, port `8443` or user defined `front-envoy` port)*

### Between Sidecars on k8s and Istio Control Plane

| Source | Destination
| --- | ---
| Sidecars or load balancers in any application namespace or <br /> shared load balancer in any namespace to access Istio Pilot xDS server. | `istiod.istio-system`, port `15012`
| Sidecars or load balancers in any application namespace or <br /> shared load balancer in any namespace to access SkyWalking OAP metrics server. | `oap.istio-system`, port `11800`
| Sidecars or load balancers in any application namespace or <br /> shared load balancer in any namespace to access SkyWalking OAP trace server. | `oap.istio-system`, port `9411`

### Between Sidecars on VMs and Istio Control Plane

| Source | Destination
| --- | ---
| Sidecars on VMs to access Istio Pilot xDS server,<br /> SkyWalking OAP metrics server, trace server | VM Gateway (`vmgateway.istio-system`) Load Balancer IP,<br /> port `15443`


### Between Sidecars on VMs and workloads on k8s

| Source | Destination
| --- | ---
| Sidecars on VMs to access workloads on k8s | Either k8s pods directly,<br />Or VM Gateway (`vmgateway.istio-system`) Load Balancer IP,<br /> port `15443`


### Between workloads on k8s and Sidecars on VMs

| Source | Destination
| --- | ---
| k8s pods to access workloads on VMs | VM IP


### Between workloads in cluster A and workloads in cluster B

| Source | Destination
| --- | ---
| k8s pods or VMs (cluster A) | per-Service Gateway Load Balancer IP,<br /> port `15443` (cluster B)
| k8s pods or VMs (cluster B) | per-Service Gateway Load Balancer IP,<br /> port `15443` (cluster A)


:::danger Shared Load Balancers
If you are using a shared load balancer, then the load balancer envoy will need
to be able to talk to all attached applications and their services. Since this
information is not known in advance, we cannot provide definitive information on
the ports to open in a firewall.
:::


## TSB components ports

Following are ports and protocols used by TSB components. 

### Cert manager

| Port | Protocol | Description
| --- | --- | ---
| 10250 | HTTPS | Webhooks service port
| 6080 | HTTP | Health checks

### Management plane

| Port | Protocol | Description
| --- | --- | ---
| **Management plane operator <br />`tsb-operator-management-plane.tsb`** | | 
| 8383 | HTTP | Prometheus telemetry
| 443 | HTTPS | Webhooks service port
| 9443 | HTTPS | Webhook container port, forwarded from 443
| **TSB API server `tsb.tsb`** | | 
| 8000 | HTTP | HTTP API
| 9080 | GRPC | GRPC API
| 42422 | HTTP | Prometheus telemetry
| 9082 | HTTP | Health checks
| **Open Telemetry `otel-collector.tsb`** | | 
| 9090 | HTTP | Prometheus telemetry
| 9091 | HTTP | Collector endpoint
| 13133 | HTTP | Health checks
| **TSB front-envoy `envoy.tsb`** | | 
| 8443 | HTTP/GRPC | TSB HTTP and GRPC API port
| 9443 | TCP | XCP port
| **IAM `iamserver.tsb`** | | 
| 8000 | HTTP | HTTP API
| 9080 | GRPC | GRPC API
| 42422 | HTTP | Prometheus telemetry
| 9082 | HTTP | Health checks
| **MPC `mpc.tsb`** | | 
| 9080 | GRPC | GRPC API
| 42422 | HTTP | Prometheus telemetry
| 9082 | HTTP | Health checks
| **OAP `oap.tsb`** | | 
| 11800 | GRPC | GRPC API
| 12800 | HTTP | REST API
| 1234 | HTTP | Prometheus telemetry
| 9411 | HTTP | Trace query
| 9412 | HTTP | Trace collect
| **TSB UI `web.tsb`** | | 
| 8080 | HTTP | HTTP service port and health check
| **XCP operator central <br />`xcp-operator-central.tsb`** | | 
| 8383 | HTTP | Prometheus telemetry
| 443 | HTTPS | Webhooks service port
| **XCP central `central.tsb`** | | 
| 8090 | HTTP | Debug interface
| 9080 | GRPC | GRPC API
| 8080 | HTTP | Prometheus telemetry
| 443 | HTTPS | Webhooks service port
| 8443 | HTTPS | Webhook container port, forwarded from 443

### Control plane

| Port | Protocol | Description
| --- | --- | ---
| **Control plane operator <br />`tsb-operator-control-plane.istio-system`** | | 
| 8383 | HTTP | Prometheus telemetry
| 443 | HTTPS | Webhooks service port
| 9443 | HTTPS | Webhook container port, forwarded from 443
| **Open Telemetry `otel-collector.tsb`** | | 
| 9090 | HTTP | Prometheus telemetry
| 9091 | HTTP | Collector endpoint
| 13133 | HTTP | Health checks
| **OAP `oap.istio-system`** | | 
| 11800 | GRPC | GRPC API
| 12800 | HTTP | REST API
| 1234 | HTTP | Prometheus telemetry
| 15021 | HTTP | Envoy sidecar health check
| 15020 | HTTP | Envoy sidecar Merged Prometheus telemetry from Istio agent, Envoy, and application	
| 9411 | HTTP | Trace query
| 9412 | HTTP | Trace collect
| **Istio operator <br />`istio-operator.istio-system`** | | 
| 443 | HTTPS | Webhooks service port
| 8383 | HTTP | Prometheus telemetry
| **Istiod `istiod.istio-system`** | | 
| 443 | HTTPS | Webhooks service port
| 8080 | HTTP | Debug interface
| 15010 | GRPC | XDS and CA services (Plaintext, only for secure networks)
| 15012 | GRPC | XDS and CA services (TLS and mTLS, recommended for production use)
| 15014 | HTTP | Control plane monitoring
| 15017 | HTTPS	 | Webhook container port, forwarded from 443
| **XCP operator central <br />`xcp-operator-edge.istio-system`** | | 
| 8383 | HTTP | Prometheus telemetry
| 443 | HTTPS | Webhooks service port
| **XCP central `edge.istio-system`** | | 
| 8090 | HTTP | Debug interface
| 9080 | GRPC | GRPC API
| 8080 | HTTP | Prometheus telemetry
| 443 | HTTPS | Webhooks service port
| 8443 | HTTPS | Webhook container port, forwarded from 443
| **Onboarding operator <br />`onboarding-operator.istio-system`** | | 
| 443 | HTTPS | Webhooks service port
| 9443 | HTTPS | Webhook container port, forwarded from 443
| 9082 | HTTP | Health checks
| **Onboarding repository <br />`onboarding-repository.istio-system`** | | 
| 8080 | HTTP | HTTP service port
| 9082 | HTTP | Health checks
| **Onboarding plane <br />`onboarding-plane.istio-system`** | | 
| 8443 | HTTP | Onboarding API
| 9082 | HTTP | Health checks
| **VM Gateway `vmgateway.istio-system`** | | 
| 15021 | HTTP | Health checks
| 15012 | HTTP | Istiod
| 11800 | HTTP | OAP Metrics
| 9411 | HTTP | Tracing
| 15443 | HTTPS | mTLS traffic port
| 443 | HTTPS | HTTPS port

### Data plane

| Port | Protocol | Description
| --- | --- | ---
| **Data plane operator <br />`tsb-operator-data-plane.istio-gateway`** | | 
| 8383 | HTTP | Prometheus telemetry
| 443 | HTTPS | Webhooks service port
| 9443 | HTTPS | Webhook container port, forwarded from 443
| **Istio operator <br />`istio-operator.istio-gateway`** | | 
| 443 | HTTPS | Webhooks service port
| 8383 | HTTP | Prometheus telemetry
| **Istiod `istiod.istio-gateway`** | | 
| 443 | HTTPS | Webhooks service port
| 8080 | HTTP | Debug interface
| 15010 | GRPC | XDS and CA services (Plaintext, only for secure networks)
| 15012 | GRPC | XDS and CA services (TLS and mTLS, recommended for production use)
| 15014 | HTTP | Control plane monitoring
| 15017 | HTTPS	 | Webhook container port, forwarded from 443

### Sidecars

Refer to [Ports used by Istio](https://istio.io/latest/docs/ops/deployment/requirements/#ports-used-by-istio) for list of ports and protocols used by Istio sidecar proxy (Envoy).
