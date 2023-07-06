---
title: "JWT 组件详解"
date: 2023-03-27T17:00:00+08:00
draft: false
summary: "JSON Web Token（通常缩写为 JWT）是一种通常与 OAuth2 等标准协议一起使用的令牌。本文解释了 JWT 的组成部分和工作原理。"
tags: ["JWT"]
categories: ["其他"]
authors: ["Dan Moore"]
links:
  - icon: globe
    icon_pack: fa
    name: 原文
    url: https://fusionauth.io/learn/expert-advice/tokens/jwt-components-explained
---

> 译者注：本文译自 [Fusion Auth Developer](https://fusionauth.io/learn/expert-advice/tokens/jwt-components-explained)。JSON Web Token（通常缩写为 JWT）是一种通常与 OAuth2 等标准协议一起使用的令牌。本文解释了 JWT 的组成部分和工作原理。

在我们继续之前，重要的是要注意 JWT 通常被错误地称为 `JWT Tokens`。在末尾添加 `Token` 将会使其变成 `JSON Web Token Token`。因此，在本文中，我们省略末尾的 `Token` 并简单地称之为 `JWT`，因为这是更正确的名称。同样地，由于 JWT 通常用作身份验证和授权过程的一部分，一些人将其称为 `Authentication Tokens` 或 `JWT Authentication Tokens`。从技术上讲，JWT 只是一个包含 Base64 编码的 JSON 的令牌。它可以用于许多不同的用例，*包括*身份验证和授权。因此，在本文中，我们不使用这个术语，而是讨论如何在身份验证过程中使用 JWT。

让我们开始吧！这是一个新生成的 JWT。为清楚起见添加了换行符，但它们通常不存在。

```bash
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImY1ODg5MGQxOSJ9.eyJhdWQiO
iI4NWEwMzg2Ny1kY2NmLTQ4ODItYWRkZS0xYTc5YWVlYzUwZGYiLCJleHAiOjE2NDQ4ODQ
xODUsImlhdCI6MTY0NDg4MDU4NSwiaXNzIjoiYWNtZS5jb20iLCJzdWIiOiIwMDAwMDAwM
C0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDEiLCJqdGkiOiIzZGQ2NDM0ZC03OWE5LTR
kMTUtOThiNS03YjUxZGJiMmNkMzEiLCJhdXRoZW50aWNhdGlvblR5cGUiOiJQQVNTV09SR
CIsImVtYWlsIjoiYWRtaW5AZnVzaW9uYXV0aC5pbyIsImVtYWlsX3ZlcmlmaWVkIjp0cnV
lLCJhcHBsaWNhdGlvbklkIjoiODVhMDM4NjctZGNjZi00ODgyLWFkZGUtMWE3OWFlZWM1M
GRmIiwicm9sZXMiOlsiY2VvIl19.dee-Ke6RzR0G9avaLNRZf1GUCDfe8Zbk9L2c7yaqKME
```

这可能看起来像是一堆乱码，但随着您对 JWT 以及它们在 OAuth2 或身份验证过程中的使用方式了解得更多，它开始变得更有意义了。

有几种类型的 JSON Web 令牌，但我将重点介绍已签名的 JWT，因为它们是最常见的。签名的 JWT 也可以称为 JWS。它由三个部分组成，以句号分隔。

有一个标头，在上面的 JWT 中以`eyJhbGc`开头。然后有一个主体或有效载荷，上面以`eyJhdWQ`开头。最后有一个签名，在示例 JWT 中以`dee-K`开头。

JWT 如何工作？让我们拆开这个示例 JWT 并深入了解一下。

##  JWT 标头解释

`eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImY1ODg5MGQxOSJ9`是 JWT 的标头。JWT 标头包含有关 JWT 的元数据，包括密钥标识符、用于登录的算法和其他信息。

如果您通过 base64 解码器运行上述标头：

```bash
echo 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImY1ODg5MGQxOSJ9'|base64 -d
```

你会看到这个 JSON：

```json
{"alg":"HS256","typ":"JWT","kid":"f58890d19"}%
```

`HS256`表示 JWT 是使用对称算法签名的，特别是使用 SHA-256 的 HMAC。

算法列表和实现支持级别如下。

| “alg” Param Value | Digital Signature or MAC Algorithm             | Implementation Requirements |
| ----------------- | ---------------------------------------------- | --------------------------- |
| HS256             | HMAC using SHA-256                             | Required                    |
| HS384             | HMAC using SHA-384                             | Optional                    |
| HS512             | HMAC using SHA-512                             | Optional                    |
| RS256             | RSASSA-PKCS1-v1_5 using SHA-256                | Recommended                 |
| RS384             | RSASSA-PKCS1-v1_5 using SHA-384                | Optional                    |
| RS512             | RSASSA-PKCS1-v1_5 using SHA-512                | Optional                    |
| ES256             | ECDSA using P-256 and SHA-256                  | Recommended+                |
| ES384             | ECDSA using P-384 and SHA-384                  | Optional                    |
| ES512             | ECDSA using P-521 and SHA-512                  | Optional                    |
| PS256             | RSASSA-PSS using SHA-256 and MGF1 with SHA-256 | Optional                    |
| PS384             | RSASSA-PSS using SHA-384 and MGF1 with SHA-384 | Optional                    |
| PS512             | RSASSA-PSS using SHA-512 and MGF1 with SHA-512 | Optional                    |
| none              | No digital signature or MAC performed          | Optional                    |

此表取自 RFC 7518。由于仅 HS256 需要符合规范，请查阅用于创建 JWT 的软件或库以获取有关受支持算法的详细信息。

其他元数据也存储在 JWT 的这一部分中。`typ`标头指示 JWT 的类型。在本例中，该值为`JWT`，但其他值均有效。例如，如果 JWT 符合 RFC 9068，它可能具有`at+JWT`指示它是访问令牌的值。

该`kid`值指示用于签署 JWT 的密钥。对于对称密钥，`kid`可用于在秘密保险库中查找值。对于非对称签名算法，此值让 JWT 的消费者查找与签署此 JWT 的私钥相对应的正确公钥。正确处理此值对于签名验证和 JWT 负载的完整性至关重要。

通常情况下，将标头值的大部分处理过程转移到库中。有许多优秀的开源 JWT 处理库。您应该了解这些库的价值，但可能不必实现实际处理。

## JWT 令牌主体

有效载荷或主体是使 JWT 变得有趣的地方。此部分包含创建 JWT 以传输的数据。例如，如果 JWT 表示授权访问某些数据或功能的用户，则有效载荷包含用户数据，例如角色或其他授权信息。

这是来自示例 JWT 的有效负载：

```json
eyJhdWQiOiI4NWEwMzg2Ny1kY2NmLTQ4ODItYWRkZS0xYTc5YWVlYzUwZGYiLCJleHAiOjE2NDQ4ODQxODUsImlhdCI6MTY0NDg4MDU4NSwiaXNzIjoiYWNtZS5jb20iLCJzdWIiOiIwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDEiLCJqdGkiOiIzZGQ2NDM0ZC03OWE5LTRkMTUtOThiNS03YjUxZGJiMmNkMzEiLCJhdXRoZW50aWNhdGlvblR5cGUiOiJQQVNTV09SRCIsImVtYWlsIjoiYWRtaW5AZnVzaW9uYXV0aC5pbyIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJhcHBsaWNhdGlvbklkIjoiODVhMDM4NjctZGNjZi00ODgyLWFkZGUtMWE3OWFlZWM1MGRmIiwicm9sZXMiOlsiY2VvIl19
```

如果您通过 base64 解码器运行示例负载：

```bash
echo 'eyJhdWQiOiI4NWEwMzg2Ny1kY2NmLTQ4ODItYWRkZS0xYTc5YWVlYzUwZGYiLCJleHAiOjE2NDQ4ODQxODUsImlhdCI6MTY0NDg4MDU4NSwiaXNzIjoiYWNtZS5jb20iLCJzdWIiOiIwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDEiLCJqdGkiOiIzZGQ2NDM0ZC03OWE5LTRkMTUtOThiNS03YjUxZGJiMmNkMzEiLCJhdXRoZW50aWNhdGlvblR5cGUiOiJQQVNTV09SRCIsImVtYWlsIjoiYWRtaW5AZnVzaW9uYXV0aC5pbyIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJhcHBsaWNhdGlvbklkIjoiODVhMDM4NjctZGNjZi00ODgyLWFkZGUtMWE3OWFlZWM1MGRmIiwicm9sZXMiOlsiY2VvIl19' |base64 -d
```

你会看到这个 JSON：

```json
{
  "aud": "85a03867-dccf-4882-adde-1a79aeec50df",
  "exp": 1644884185,
  "iat": 1644880585,
  "iss": "acme.com",
  "sub": "00000000-0000-0000-0000-000000000001",
  "jti": "3dd6434d-79a9-4d15-98b5-7b51dbb2cd31",
  "authenticationType": "PASSWORD",
  "email": "admin@fusionauth.io",
  "email_verified": true,
  "applicationId": "85a03867-dccf-4882-adde-1a79aeec50df",
  "roles": [
    "ceo"
  ]
}
```

请注意，创建签名 JWT 的算法可以删除 base64 填充，因此 JWT 末尾可能缺少符号。您可能需要将其添加回去才能解码 JWT 令牌。这取决于内容的长度。您可以[在此处了解更多信息](https://datatracker.ietf.org/doc/html/rfc7515#appendix-C)。

如上所述，负载是您的应用程序所关心的，所以让我们更仔细地看一下这个 JSON。对象的每个键都称为“声明”（Claim）。

一些声明是众所周知的，其含义由 IETF 等标准机构规定。您可以在此处查看[此类声明的示例](https://www.iana.org/assignments/jwt/jwt.xhtml)。这些包括示例令牌中的`iss`和`aud`声明。当它们出现在 JWT 的有效负载中时，这两者都具有定义的含义。

还有其他非标准声明，例如`authenticationType`。这些声明可能代表业务领域或自定义数据。例如，`authenticationType`是 FusionAuth 使用的专有声明，用于指示身份验证方法，例如密码、刷新令牌或通过无密码链接。

您可以向 JWT 添加您想要的任何声明，包括对 JWT 的下游消费者有用的数据。从`roles`声明中可以看出，声明不必是简单的 JSON 原语。它们可以是任何可以用 JSON 表示的数据结构。

## 声明验证

当代码与 JWT 一起出现时，它应该验证某些声明。至少，应检查这些声明：

- `iss`标识 JWT 的发行者。只要 JWT 的发行者和消费者就有效值达成一致，并且消费者验证声明与已知的良好值相匹配，这个字符串到底是什么并不重要（UUID、域名、URL 或其他内容）。
- `aud`标识令牌的受众，即谁应该使用它。可以是标量或数组值。同样，JWT 的发行者和消费者应该就可接受的特定值达成一致。
- `nbf` 和 `exp`。这些声明确定令牌有效的时间范围。如果您要发行令牌以供将来使用，则该声明可能很有用。应始终设置 `exp` 声明，即 JWT 不再有效的时间。与其他声明不同，它们具有定义的值格式：自 unix 纪元以来的秒数。

除了这些之外，还要验证业务领域特定的声明。例如，使用上述 JWT 的人可以在`authenticationType`未知值时拒绝访问。

避免将未使用的声明放入 JWT。虽然 JWT 的大小没有限制，但通常它们越大，签名和验证它们所需的 CPU 就越多，传输它们所需的时间也就越多。Benchmark 期望 JWT 了解性能特征。

## 声明和安全

拥有令牌的任何人都可以看到已签名 JWT 的声明。

正如您在上面看到的，要以明文形式查看声明，您只需要一个 base64 解码器，它可以在每个命令行和互联网上的任何地方使用。

因此，您不应将任何应该保密的内容放入 JWT 中。这包括：

- 私人信息，例如政府 ID
- 密码之类的秘密
- 任何会泄露信息的东西，比如整数 id

另一个安全问题与`aud`声明的验证有关。由于消费代码已经拥有令牌，验证`aud`声明是否多此一举？`aud`声明表明谁应该接收这个 JWT，但代码已经有了它。不，总是验证声明。

为什么？

想象一下您有两个不同 API 的场景。一个是创建和管理待办事项，另一个是计费 API，用于转账。这两个 API 都期望一些用户具有`admin`角色。然而，就可以采取的行动而言，该角色意味着截然不同的事情。

如果待办事项 API 和计费 API 均未验证是否为它们创建了任何给定的 JWT，则攻击者可以从具有该`admin`角色的待办事项 API 中获取 JWT，并将其呈现给计费 API。

这最多是一个错误，最坏的情况是特权升级，对银行账户产生负面影响。

## **JWT 签名**

JWT 的签名很关键，因为它保证了负载和标头的完整性。验证签名必须是 JWT 的任何消费者执行的第一步。如果签名不匹配，则不应进行进一步处理。

虽然您可以阅读[规范的相关部分](https://datatracker.ietf.org/doc/html/rfc7515#page-15)以了解签名是如何生成的，但高级概述是：

- 标头变成了 base64 URL 编码的字符串
- 负载被转换为 base64 URL 编码的字符串
- 它们由`.` 连接
- 生成的字符串通过所选的加密算法运行，连同相应的密钥
- 签名是 base64 URL 编码的
- 编码后的签名以 `.` 作为分隔符附加到字符串

当收到 JWT 时，可以执行相同的操作。如果生成的签名正确，则 JWT 的内容与创建时没有变化。

## **JSON Web 令牌限制**

在规范中，JSON Web Tokens 的长度没有硬性限制。实际上，考虑一下：

- 你打算在哪里存储 JWT
- 大型 JWT 的性能损失是什么

## 存储

JWT 可以在 HTTP 标头中发送，存储在 cookie 中，并放置在表单参数中。在这些场景中，存储决定了 JWT 的最大长度。

例如，浏览器中 cookie 的典型存储限制通常为 4096 字节，包括名称。HTTP 标头的限制因软件组件而异，但 8192 字节似乎是一个常见值。

请查阅相关规范或其他资源以了解特定用例的限制，但请放心，JWT 没有固有的大小限制。

## 性能影响

由于 JWT 可以包含许多不同类型的用户信息，因此开发人员可能会忍不住在其中放入太多信息。这会降低签名和验证步骤以及传输中的性能。

对于前者的示例，以下是签署和验证两个不同 JWT 的基准测试结果。每个操作进行了 50,000 次。

第一个 JWT 的正文长度约为 180 个字符；总编码令牌长度在 300 到 600 之间，具体取决于所使用的签名算法。

```bash
hmac sign
  1.632396   0.011794   1.644190 (  1.656177)
hmac verify
  2.452983   0.015723   2.468706 (  2.487930)
rsa sign
 28.409793   0.117695  28.527488 ( 28.697615)
rsa verify
  3.086154   0.011869   3.098023 (  3.109780)
ecc sign
  4.248960   0.017153   4.266113 (  4.285231)
ecc verify
  7.057758   0.027116   7.084874 (  7.113594)
```

下一个 JWT 负载大约有 1800 个字符，因此是前一个令牌大小的十倍。这具有 2400 到 2700 个字符的总令牌长度。

```bash
hmac sign
  3.356960   0.018175   3.375135 (  3.389963)
hmac verify
  4.283810   0.018320   4.302130 (  4.321095)
rsa sign
 32.703723   0.172346  32.876069 ( 33.072665)
rsa verify
  5.300321   0.027455   5.327776 (  5.358079)
ecc sign
  6.557596   0.032239   6.589835 (  6.624320)
ecc verify
  9.184033   0.035617   9.219650 (  9.259225)
```

您可以看到，对于较长的 JWT，总时间增加了，但通常不是线性的。所用时间的增加范围从 RSA 签名的大约 20% 到 HMAC 签名的大约 100%。

请注意传输更长的 JWT 所花费的额外时间；这可以用与任何其他 API 或 HTML 内容相同的方式进行测试和优化。

## 结论

已签名的 JWT 具有标头、正文和签名。每个都在确保 JWT 可用于安全地存储和传输关键信息（无论是否与身份有关）方面发挥着至关重要的身份验证作用。了解所有这三个组件对于正确使用 JWT 也至关重要。
