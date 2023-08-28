---
title: External Authorization
description: How to authorize incoming requests.
weight: 5
---

Tetrate Service Bridge (TSB) provides authorization capabilities to authorize every HTTP request coming to Gateways and Workloads. TSB supports local authorization by using JWT claims and external authorization (ext-authz) which uses a service running externally to determine if a request should be allowed or denied. 

You may decide to use an external authorization system if you have a separate in-house system, you want to use another authentication schema than JWT or if you want to integrate with a third party authorization solution such as [Open Policy Agent](https://www.openpolicyagent.org/) (OPA) or [PlainID](https://www.plainid.com/).

Ext-authz can be configured in different contexts, such as [Tier-1 Gateways](../../refs/tsb/gateway/v2/tier1_gateway#tier1externalserver), [Ingress Gateways](../../refs/tsb/gateway/v2/ingress_gateway), and in [Traffic Settings](../../refs/tsb/traffic/v2/traffic_setting#trafficsetting). Following table shows some possible ways in which external authorization can be used with TSB:


| Context          | Sample Usage |
|------------------|--------------|
| Tier-1 Gateway   | Tier-1 Gateways can be configured to only accept requests with valid JWT and claim for authenticated APIs, requests with proper basic authorization, etc |
| Ingress Gateway  | Ingress Gateways / Tier-2 Gateways / Application Gateways can be configured to implement business logic such as limiting APIs based on user entitlements 
| Traffic Settings | Ext-authz in Traffic Settings applies to all proxies in the associated namespaces. This is particularly useful to limit access to parts of a service API |
