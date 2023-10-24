---
weight: 1
title: "在 Envoy 中集成 SPIRE"
linkTitle: "Envoy"
---

本文指导你如何配置 Envoy 代理与 SPIFFE 和 SPIRE 配合使用。

Envoy 是一种流行的开源服务代理，广泛用于提供抽象、安全、经过身份验证和加密的服务间通信。Envoy 拥有丰富的配置系统，允许灵活地与第三方进行交互。

该配置系统的一个组成部分是 Secret Discovery Service 协议或 SDS。Envoy 使用 SDS 从 SDS 提供者检索和维护更新的“密钥”。在 TLS 身份验证的上下文中，这些密钥是 TLS 证书、私钥和可信 CA 证书。SPIRE 代理可以配置为 Envoy 的 SDS 提供者，使其能够直接向 Envoy 提供所需的密钥材料以进行 TLS 身份验证。SPIRE 代理还会根据需要重新生成短期密钥和证书。

有关如何将 SPIRE 与 Envoy 集成的基于 Kubernetes 的示例，请参阅[使用 X.509 证书集成 Envoy](https://github.com/spiffe/spire-tutorials/tree/main/k8s/envoy-x509)和[使用 JWT 集成 Envoy](https://github.com/spiffe/spire-tutorials/tree/main/k8s/envoy-jwt)。

## 工作原理

当 Envoy 连接到 SPIRE 代理提供的 SDS 服务器时，代理会对 Envoy 进行验证，并确定应向 Envoy 公开哪些服务标识和 CA 证书，以通过 SDS。

随着服务标识和 CA 证书的轮换，更新会流式传输回 Envoy，使其可以立即将其应用于新连接，无需中断或停机，并且无需私钥接触磁盘。换句话说，SPIRE 丰富的定义和验证服务的方法可以用于定位 Envoy 进程、为其定义标识，并为其提供 Envoy 可用于 TLS 通信的 X.509 证书和信任信息。

![](../../images/spire_plus_envoy.png)

**高级别图示，显示了两个 Envoy 代理在使用 SPIRE 代理 SDS 实现获取用于相互认证的 TLS 通信的密钥的两个服务之间。**

## 配置 SPIRE

在 SPIRE v0.10 版本中，默认启用了 SDS 支持，因此不需要进行 SPIRE 配置更改。在早期版本的 SPIRE 中，SPIRE 代理配置文件中需要设置 `enable_sds = true`。该设置现已停用，应在 SPIRE v0.10 及更高版本的 SPIRE 代理配置文件中删除该设置。

## 配置 Envoy

### SPIRE 代理集群

必须配置 Envoy 以与 SPIRE 代理通信，方法是配置一个指向 SPIRE 代理提供的 Unix 域套接字的集群。

例如：

```yaml
clusters:
  - name: spire_agent
    connect_timeout: 0.25s
    http2_protocol_options: {}
    hosts:
    - pipe:
      path: /tmp/spire-agent/public/api.sock
```

`connect_timeout` 影响当 Envoy 在启动时 SPIRE 代理未运行或 SPIRE 代理重新启动时，Envoy 能够快速响应的速度。

### TLS 证书

要从 SPIRE 获取 TLS 证书和私钥，可以在 TLS 上下文中设置 SDS 配置。

例如：

```yaml
tls_context:
  common_tls_context:
    tls_certificate_sds_secret_configs:
      - name: "spiffe://example.org/backend"
      sds_config:
        api_config_source:
          api_type: GRPC
          grpc_services:
            envoy_grpc:
              cluster_name: spire_agent
```

TLS 证书的名称是 Envoy 作为代理的服务的 SPIFFE ID。

### 验证上下文

Envoy 使用可信 CA 证书来验证对等证书。验证上下文提供这些可信 CA 证书。SPIRE 可以为每个信任域提供验证上下文。

要获取信任域的验证上下文，可以在 TLS 上下文的 SDS 配置中配置验证上下文，将验证上下文的名称设置为信任域的 SPIFFE ID。

例如：

```yaml
tls_context:
  common_tls_context:
    validation_context_sds_secret_config:
      name: "spiffe://example.org"
      sds_config:
        api_config_source:
          api_type: GRPC
          grpc_services:
            envoy_grpc:
              cluster_name: spire_agent
```

SPIFFE 和 SPIRE 的重点是促进安全身份验证作为授权的构建块，而不是授权本身，因此验证上下文中的授权相关字段（例如 `match_subject_alt_names`）不在其范围之内。相反，我们建议你利用 Envoy 的广泛过滤器框架执行授权。

此外，你可以配置 Envoy 以将客户端证书详细信息转发到目标服务，使其能够执行自己的授权步骤，例如使用嵌入在客户端 X.509-SVID 的 URI SAN 中的 SPIFFE ID。