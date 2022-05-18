---
weight: 20
title: 对等认证和请求认证
date: '2022-05-18T00:00:00+08:00'
type: book
---

Istio 提供两种类型的认证：对等认证和请求认证。

## 对等认证

对等认证用于服务间的认证，以验证建立连接的客户端。

当两个服务试图进行通信时，相互 TLS 要求它们都向对方提供证书，因此双方都知道它们在与谁交谈。如果我们想在服务之间启用严格的相互 TLS，我们可以使用 PeerAuthentication 资源，将 mTLS 模式设置为 STRICT。

使用 PeerAuthentication 资源，我们可以打开整个网状结构的相互 TLS（mTLS），而不需要做任何代码修改。

然而，Istio 也支持一种优雅的模式，我们可以选择在一个工作负载或命名空间的时间内进入相互 TLS。这种模式被称为许可模式。

当你安装 Istio 时，允许模式是默认启用的。启用允许模式后，如果客户端试图通过相互 TLS 连接到我，我将提供相互 TLS。如果客户端不使用相互 TLS，我也可以用纯文本响应。我是允许客户端做 mTLS 或不做的。使用这种模式，你可以在你的网状网络中逐渐推广相互 TLS。

简而言之，PeerAuthentication 谈论的是工作负载或服务的通信方式，它并没有说到最终用户。那么，我们怎样才能认证用户呢？

## 请求认证

请求认证（RequestAuthentication 资源）验证了附加在请求上的凭证，它被用于终端用户认证。

请求级认证是通过 [JSON Web Tokens（JWT）](https://jwt.io/) 验证完成的。Istio 支持任何 OpenID Connect 提供商，如 Auth0、Firebase 或 Google Auth、Keycloak、ORY Hydra。因此，就像我们使用 SPIFFE 身份来验证服务一样，我们可以使用 JWT 令牌来验证用户。