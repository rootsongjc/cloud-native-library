---
weight: 3
title: "JWT SPIFFE 可验证身份文档"
linkTitle: "JWT SVID"
---

JWT-SVID 是 SPIFFE 规范集中的第一个基于令牌的 SVID。旨在在解决跨第 7 层边界断言身份时提供即时价值，与现有应用程序和库的兼容性是核心要求。

JWT-SVID 是一种带有一些限制的标准 JWT 令牌。JOSE 在安全实现上一直存在困难，在安全社区中被认为是一项可能在部署和实现中引入漏洞的技术。JWT-SVID 采取措施尽量减轻这些问题，同时不破坏与现有应用程序和库的兼容性。

JWT-SVID 是使用 JWS 紧凑序列化的 JSON Web Signature (JWS) 数据结构。不得使用 JWS JSON 序列化。

## JOSE 头

历史上，JOSE 头的密码灵活性引入了一系列流行的 JWT 实现中的漏洞。为了避免这样的陷阱，本规范限制了一些最初允许的内容。本节描述了允许的注册头以及其值。JWT-SVID JOSE 头中未描述的任何头部，无论是注册的还是私有的，都不得包含在其中。

只支持 JWS。

### 算法

`alg` 头必须设置为 [RFC 7518](https://tools.ietf.org/html/rfc7518) 第 [3.3](https://tools.ietf.org/html/rfc7518#section-3.3)、[3.4](https://tools.ietf.org/html/rfc7518#section-3.4) 或 [3.5](https://tools.ietf.org/html/rfc7518#section-3.5) 节定义的值之一。接收到 `alg` 参数设置为其他值的令牌的验证器必须拒绝该令牌。

支持的 `alg` 值为：

| alg 参数值 | 数字签名算法                               |
| ---------- | ------------------------------------------ |
| RS256      | 使用 SHA-256 的 RSASSA-PKCS1-v1_5          |
| RS384      | 使用 SHA-384 的 RSASSA-PKCS1-v1_5          |
| RS512      | 使用 SHA-512 的 RSASSA-PKCS1-v1_5          |
| ES256      | 使用 P-256 和 SHA-256 的 ECDSA             |
| ES384      | 使用 P-384 和 SHA-384 的 ECDSA             |
| ES512      | 使用 P-521 和 SHA-512 的 ECDSA             |
| PS256      | 使用 SHA-256 和 SHA-256 MGF1 的 RSASSA-PSS |
| PS384      | 使用 SHA-384 和 SHA-384 MGF1 的 RSASSA-PSS |
| PS512      | 使用 SHA-512 和 SHA-512 MGF1 的 RSASSA-PSS |

### 密钥 ID

`kid` 头是可选的。

### 类型

`typ` 头是可选的。如果设置，其值必须是 `JWT` 或 `JOSE`。

## JWT 声明

JWT-SVID 规范没有引入任何新的声明，但它对 [RFC 7519](https://tools.ietf.org/html/rfc7519) 定义的注册声明设置了一些限制。未在本文档中描述的注册声明，以及私有声明，可以根据实现者的需求使用。但应注意，在未定义的声明上依赖可能会影响互操作性，因为生成和使用令牌的应用程序必须独立协商。在引入其他声明时，实现者应谨慎行事，并仔细考虑其对 SVID 互操作性的影响，特别是在实现者无法控制生产者和消费者的环境中。如果绝对有必要使用其他声明，建议按照 [RFC 7519](https://tools.ietf.org/html/rfc7519) 的建议使其抗冲突。

本节概述了 JWT-SVID 规范对现有注册声明所施加的要求和限制。

### 主题

`sub` 声明必须设置为其所属工作负载的 SPIFFE ID。这是对工作负载身份进行断言的主要声明。

### 受众

`aud` 声明必须存在，包含一个或多个值。验证器必须拒绝没有设置 `aud` 声明的令牌，或者验证器所识别的值不存在作为 `aud` 元素。强烈建议在正常情况下将值的数量限制为一个。有关更多信息，请参见安全注意事项部分。

所选择的值是特定于站点的，并且应该限定在要呈现给的服务范围内。例如，`reports` 或 `spiffe://example.org/reports` 是适用于向报告服务呈现的令牌的合适值。不建议使用 `production` 或 `spiffe://example.org/` 等值，因为它们的范围很广，如果 `production` 中的单个服务受到损害，则可能导致冒充。

### 过期时间

`exp` 声明必须设置，验证器必须拒绝没有此声明的令牌。鼓励实施者将有效期保持尽可能小，但本规范对其值没有设置任何硬上限。

## 令牌签名和验证

JWT-SVID 的签名和验证语义与常规 JWT/JWS 相同。验证器在处理之前必须确保 `alg` 头设置为支持的值。

JWT-SVID 的签名是根据 [RFC 7519 第 7 节](https://tools.ietf.org/html/rfc7519#section-7) 中概述的步骤进行计算和验证的。`aud` 和 `exp` 声明必须存在，并根据 [RFC 7519](https://tools.ietf.org/html/rfc7519) 第 [4.1.3](https://tools.ietf.org/html/rfc7519#section-4.1.3) 和 [4.1.4](https://tools.ietf.org/html/rfc7519#section-4.1.4) 节进行处理。接收到没有设置 `aud` 和 `exp` 声明的令牌的验证器必须拒绝该令牌。

## 令牌传输

本节描述了 JWT-SVID 可以从一个工作负载传输到另一个工作负载的方式。

### 序列化

JWT-SVID 必须使用 [RFC 7515 第 3.1 节](https://tools.ietf.org/html/rfc7515#section-3.1) 中描述的紧凑序列化方法进行序列化，正如 [RFC 7519 第 1 节](https://tools.ietf.org/html/rfc7519#section-1) 所要求的那样。请注意，这排除了使用 JWS 未保护的头部，正如 JOSE 头 部分所规定的那样。

### HTTP

通过 HTTP 传输的 JWT-SVID 应该在“Authorization”头部（HTTP/2 的“authorization”）中使用“Bearer”身份验证方案进行传输，该方案在 [RFC 6750 第 2.1 节](https://tools.ietf.org/html/rfc6750#section-2.1) 中定义。例如，在 HTTP/1.1 中使用 `Authorization: Bearer <serialized_token>`，在 HTTP/2 中使用 `authorization: Bearer <serialized_token>`。

### gRPC

gRPC 协议使用 HTTP/2。因此，HTTP 部分 中的 HTTP 传输指南同样适用。具体而言，gRPC 实现应该使用值为 `Bearer <serialized_token>` 的元数据键 `authorization`。

## 在 SPIFFE Bundle 中的表示

本节描述了 JWT-SVID 签名密钥如何发布到和从 SPIFFE Bundle 中消费。有关 SPIFFE Bundle 的更多信息，请参见 SPIFFE 信任域和 Bundle 规范。

### 发布 SPIFFE Bundle 元素

给定信任域的 JWT-SVID 签名密钥在 SPIFFE Bundle 中表示为符合 [RFC 7517](https://tools.ietf.org/html/rfc7517) 的 JWK 条目，每个签名密钥一个条目。

每个 JWK 条目的 `use` 参数必须设置为 `jwt-svid`。此外，每个 JWK 条目的 `kid` 参数必须设置。

### 使用 SPIFFE Bundle

SPIFFE Bundle 可能包含许多不同类型的 JWK 条目。在使用这些条目进行验证之前，实现必须提取 JWT-SVID 特定的密钥。可以通过其 `use` 参数的值来识别表示 JWT-SVID 签名密钥的条目，该值必须为 `jwt-svid`。如果没有具有 `jwt-svid` 使用值的条目，则表示 Bundle 的信任域不支持 JWT-SVID。

提取 JWK 条目后，可以根据 [RFC 7517](https://tools.ietf.org/html/rfc7517) 描述的方式直接用于 JWT-SVID 验证。

## 安全注意事项

本节概述了在使用 JWT-SVID 时实施者和用户应考虑的安全注意事项。

### 重放保护

作为承载令牌，JWT-SVID 容易受到重放攻击的影响。通过要求设置 `aud` 和 `exp` 声明，本规范已经采取措施改善了这种情况，但在保留与 [RFC 7515](https://tools.ietf.org/html/rfc7519) 的验证兼容性的同时无法完全解决。理解这个风险非常重要。建议设置较短的 `exp` 声明值。某些用户可能希望利用 `jti` 声明，尽管增加了额外的开销。虽然本规范允许使用 `jti` 声明，但应注意，JWT-SVID 验证器不必跟踪 `jti` 的唯一性。

### 受众

赋予 JWT-SVID 接收方隐式信任。发送到一个受众的令牌可以被重播到另一个受众，如果存在多个受众。例如，如果 Alice 有一个包含 Bob 和 Chuck 作为受众的令牌，并将该令牌传输给 Chuck，那么 Chuck 可以通过将相同的令牌发送给 Bob 来冒充 Alice。因此，在发行具有多个受众的 JWT-SVID 时应格外小心。强烈建议使用单个受众的 JWT-SVID 令牌，以限制重放的范围。

### 传输安全

JWT-SVID 与其他承载令牌方案存在相同的风险，即令牌被拦截后，攻击者可以利用其可重放性获得 JWT-SVID 所授予的完全权限。虽然通过 `exp` 声明强制令牌过期可以减轻风险，但总会存在一个漏洞窗口。因此，在传输 JWT-SVID 的通信渠道上的每个跳跃/链接都应提供机密性（例如，从工作负载到负载均衡器，从负载均衡器到另一个工作负载）。值得注意的例外是非网络链接，其具有合理的安全假设，例如在同一主机上的两个进程之间的 Unix 域套接字。

## 附录 A. 验证参考

以下表格为正在实施 JWT-SVID 验证器的任何人提供快速参考。如果使用现成的库，则实施者有责任确保采取了以下验证步骤。

此外，请参阅 JWT-SVID Schema 获取更正式的参考。

| 字段 | 类型   | 要求                                                         |
| ---- | ------ | ------------------------------------------------------------ |
| alg  | Header | 设置为算法表中的一个值。否则拒绝。                           |
| aud  | Claim  | 至少有一个值存在。用户应提前配置至少一个可接受的值。否则拒绝。 |
| exp  | Claim  | 必须设置。不能过期（允许有一小段宽限期）。否则拒绝。         |