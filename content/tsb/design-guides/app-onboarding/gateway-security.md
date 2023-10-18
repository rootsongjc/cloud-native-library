---
title:  针对服务配置额外的安全措施
weight: 8
---

当一个服务使用 **Gateway** 资源公开时，应用所有者可以配置一系列措施来保护他们的服务。[Gateway 资源](https://docs.tetrate.io/service-bridge/refs/tsb/gateway/v2/gateway)（[TSB](https://docs.tetrate.io/service-bridge/refs/tsb/gateway/v2/gateway) / [TSE](https://docs.tetrate.io/service-express/refs/tsb/gateway/v2/gateway)）支持以下功能：

 * 在集群或服务实例之间提供跨集群的 HTTP 支持，支持 TLS、路由、负载平衡和重定向
 * 在集群或服务实例之间提供跨集群的 TCP 支持，支持 TLS、路由和负载平衡
 * 使用 JWT 令牌进行身份验证
 * 针对外部授权服务进行授权
 * 基于客户端地址、HTTP 标头、路径和方法的每秒、每分钟或每小时的速率限制
 * 使用 WASM 插件实现自定义流量管理功能

## 安全功能

从安全角度来看，两个有用的功能是：

1. 身份验证和授权
    与其将身份验证方法构建到目标服务中，不如让 Ingress Gateway 根据 JWT 令牌的内容检查和授权流量。这简化了服务配置，集中了身份验证，确保与其他服务的一致性，并允许在没有任何应用程序更改的情况下采用不同的安全姿态（例如，开发、测试和生产）。

2. 速率限制
    通过在 Ingress Gateway 中限制每秒/每分钟/每小时的请求，可以保护上游服务免受流量激增的影响。可以对资源的个体 '贪婪' 使用者（例如爬取机器人和蜘蛛）进行限制，并且可以使试图接管账户的暴力尝试变得不可能。

## 应用程序：配置身份验证和授权

Tetrate 平台提供了授权功能，以授权由 Ingress Gateway 接收的每个 HTTP 请求。它支持使用 JWT 声明进行本地授权，并支持外部授权（[ext-authz](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/ext_authz_filter)）来确定是否允许或拒绝请求。

如果你有一个单独的内部系统，或者希望使用与 JWT 不同的其他身份验证架构，或者希望与第三方授权解决方案（如 Open Policy Agent (OPA) 或 PlainID）集成，你可能会决定使用外部授权系统：

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Gateway
metadata:
  name: ingress-bookinfo
  group: g1
  workspace: w1
  tenant: tse
  organization: tse
spec:
  workloadSelector:
    namespace: ns1
    labels:
      app: gateway
  http:
  - name: bookinfo
    port: 9443
    hostname: bookinfo.com
    tls:
      mode: SIMPLE
      secretName: bookinfo-certs
    authentication:
      rules:
        jwt:
        - issuer: https://accounts.google.com
          jwksUri: https://www.googleapis.com/oauth2/v3/certs
        - issuer: "auth.mycompany.com"
          jwksUri: https://auth.mycompany.com/oauth2/jwks
    authorization:
      external:
        uri: https://company.com/authz
        includeRequestHeaders:
          - Authorization # 将标头转发到授权服务。
    routing:
      rules:
      - route:
          serviceDestination:
            host: ns1/productpage.ns1.svc.cluster.local
```

有关详细信息，请查看 [Tetrate Service Bridge how-tos](https://docs.tetrate.io/service-bridge/howto/authorization/)，这也适用于 TSE。

## 应用程序：配置速率限制

速率限制允许你将流量通过你的 Ingress Gateway 限制到预定的限制。你可以对流量属性进行分类，如源 IP 地址和 HTTP 标头，分别对每个类别进行速率限制。

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Gateway
metadata:
  name: ingress-bookinfo
  group: g1
  workspace: w1
  tenant: tse
  organization: tse
spec:
  workloadSelector:
    namespace: ns1
    labels:
      app: gateway
  http:
  - name: bookinfo
    port: 9443
    hostname: bookinfo.com
    tls:
      mode: SIMPLE
      secretName: bookinfo-certs
    routing:
      rules:
      - route:
          serviceDestination:
            host: ns1/productpage.ns1.svc.cluster.local
    rateLimiting:
      settings:
        rules:
          # 对远程地址为 1.2.3.4 的客户端进行每小时 10 次的速率限制
        - dimensions:
          - remoteAddress:
              value: 1.2.3.4
          limit:
            requestsPerUnit: 10
            unit: HOUR
          # 对 user-agent 标头中的每个唯一值进行每分钟 50 次的速率限制
        - dimensions:
          - header:
              name: user-agent
          limit:
            requestsPerUnit: 50
            unit: MINUTE
          # 对每个唯一的客户端远程地址进行每秒 100 次的速率限制
          # 对 HTTP 请求的 GET 方法和路径前缀为 /productpage 的进行限制
        - dimensions:
          - remoteAddress:
              value: "*"
          - header:
              name: ":path"
              value:
                prefix: /productpage
          - header:
              name: ":method"
              value:
                exact: "GET"
          limit:
            requestsPerUnit: 100
            unit: SECOND
```

如果你关心以下任何方面，你可能需要考虑速率限制：

 * 防止恶意的基于容量的活动，如 DDoS 攻击或暴力攻击
 * 限制不良行为的蜘蛛、机器人或爬取器的影响
 * 防止你的应用程序及其资源（如数据库）过载
 * 实施公平的业务逻辑，如为不同的用户组应用不同的 API 限制。

有关详细信息，请查看 [Tetrate Service Bridge 速率限制文档](https://docs.tetrate.io/service-bridge/howto/rate_limiting/)，这也适用于 TSE。