---
title: 外部授权
weight: 5
description: 如何授权传入请求。
---

Tetrate Service Bridge (TSB) 提供了授权功能，用于授权传入的所有 HTTP 请求，包括传入 Gateways 和 Workloads 的请求。TSB 支持本地授权，使用 JWT 声明，以及外部授权 (ext-authz)，后者使用在外部运行的服务来确定是否应允许或拒绝请求。

如果你有一个独立的内部系统，希望使用不同于 JWT 的身份验证方案，或者希望集成第三方授权解决方案，比如 [Open Policy Agent](https://www.openpolicyagent.org/) (OPA) 或 [PlainID](https://www.plainid.com/)，你可以决定使用外部授权系统。

Ext-authz 可以在不同的上下文中进行配置，例如 [Tier-1 Gateways](../../refs/tsb/gateway/v2/tier1-gateway#tier1externalserver)、[Ingress Gateways](../../refs/tsb/gateway/v2/ingress-gateway) 以及 [Traffic Settings](../../refs/tsb/traffic/v2/traffic-setting#trafficsetting)。以下表格显示了在 TSB 中如何使用外部授权的一些可能方式：

| 上下文       | 示例用途                                                     |
| ------------ | ------------------------------------------------------------ |
| Tier-1 网关  | 可以配置 Tier-1 网关，仅接受带有有效 JWT 和经过身份验证 API 声明的请求，以及带有适当基本授权的请求等 |
| Ingress 网关 | Ingress 网关 / Tier-2 网关 / 应用程序网关可以配置以实施基于用户权益限制 API 的业务逻辑 |
| 交通设置     | 交通设置中的 Ext-authz 适用于关联命名空间中的所有代理。这在限制对服务 API 的部分访问方面特别有用 |