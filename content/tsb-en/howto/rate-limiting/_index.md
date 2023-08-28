---
title: Rate Limiting Traffic
description: How to apply rate limiting on your network.
weight: 4
---

Rate limiting allows you to restrict the traffic through TSB to a predetermined limit based on traffic attributes such as source IP address and HTTP Headers.

You may want to consider rate limiting if you are concerned with any of the following:
* To prevent malicious activity such as DDoS attacks.
* To prevent your applications and its resources (such as a database) from getting overloaded.
* To implement some form of business logic such as creating different API limits for different set of users.

TSB supports two modes for Rate limiting: internal and external.

## Internal Rate Limiting

This mode implements global rate limiting within a cluster or across multiple clusters.
In this mode, you can use the [API](../../refs/tsb/gateway/v2/ingress_gateway#ratelimitsettings) to configure limits based on various traffic attributes.

![](../../assets/howto/rate_limiting_internal.png)

Behind the scenes, TSB's Global Control Plane deploys a rate limit server in each cluster which acts as a global service that receives metadata from multiple Envoy proxies and makes a rate limiting decision based on the configuration.

This mode requires the user to setup a Redis server, which acts as a storage backend to persist rate limit metadata counts. 

We recommend using this mode if you want to leverage the rate limiting feature without implementing your own rate limiting service.

For details on how to enable internal rate limiting, [please read this document](./../rate_limiting/internal_rate_limiting)

## External Rate Limiting

In this mode, a rate limit server that implements the [Envoy Rate Limit Service interface](https://www.envoyproxy.io/docs/envoy/latest/api-v3/traffic/ratelimit/v3/rls.proto) and configure the [API](../../refs/tsb/gateway/v2/ingress_gateway#externalratelimitservicesettings) to send rate limit metadata to your server based on the specified criteria.

![](../../assets/howto/rate_limiting_external.png)

The rate limit decision made by the external rate limit server is enforced in the Envoy proxy within TSB.

We recommend using this mode if you want to implement your own rate limiting service or you want to separate the rate limiting decision logic from TSB into its own Service.

## Rate Limiting Contexts

Rate limiting can be configured in different contexts. While you are able to customize its behavior as you wish in any of these contexts, some types of rate limitings are better handled at a particular context.

|                                                                          |  |
|--------------------------------------------------------------------------|--|
| [Tier1Gateway](./../rate_limiting/tier1_gateway) ([YAML](../../refs/tsb/gateway/v2/tier1_gateway#tier1externalserver)) | Restrict malicious traffic based on source IP addresses |
| [IngressGateway / Tier2 Gateway / Application Gateway](./../rate_limiting/ingress_gateway) ([YAML](../../refs/tsb/gateway/v2/ingress_gateway)) |  Implement rate limiting based on business logic, or safeguard your application from being overloaded |
| [TrafficSettings](./../rate_limiting/service_to_service) ([YAML](../../refs/tsb/traffic/v2/traffic_setting#trafficsetting)) | Apply rate limiting to all proxies in the namespaces associated with the TrafficSettings. Useful to safeguard the application from being overloaded |

import DocCardList from '@theme/DocCardList';

<DocCardList />
