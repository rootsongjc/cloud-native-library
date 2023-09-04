---
title: 内部证书要求
description: 用于 TSB 内部通信的证书要求。
weight: 2
---

在继续之前，请确保你了解 TSB 中的 [4 种证书类型](../certificate-setup)，特别是内部证书。

{{<callout note "注意">}}
请注意，此处描述的证书仅用于 TSB 组件之间的通信，因此不属于通常由 Istio 或应用程序 TLS 证书管理的工作负载证书。
{{</callout>}}

{{<callout warning 提醒>}}
如果你在管理平面集群中安装了 `cert-manager`，你可以使用 tctl
自动在管理平面中安装所需的发行者和证书，并创建控制平面证书。有关更多详细信息，请参阅 [管理平面安装](../../self-managed/management-plane-installation) 和 [载入集群](../../self-managed/onboarding-clusters) 文档。
{{</callout>}}

要使用常规（非相互）TLS 进行 JWT 身份验证，XCP central 证书必须在其主体备用名称（SANs）中包含其地址。这将是 DNS 名称或 IP 地址。

与上述 mTLS 类似，管理平面中的 XCP central 使用存储在名为 `xcp-central-cert` 的管理平面命名空间（默认为 `tsb`）中的密钥中的证书。密钥必须包含标准的 `tls.crt`、`tls.key` 和 `ca.crt` 字段的数据。

以下是如果你使用 IP 地址作为 XCP central 证书的 `cert-manager` 资源示例。

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: xcp-central-cert
  namespace: tsb
spec:
  secretName: xcp-central-cert
  ipAddresses:
  - a.b.c.d  ## <--- 在此处输入 IP 地址
  issuerRef:
    name: xcp-identity-issuer
    kind: Issuer
  duration: 30000h
```

或者，如果你使用域名，编辑字段 `spec.dnsNames`。

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: xcp-central-cert
  namespace: tsb
spec:
  secretName: xcp-central-cert
  dnsNames:
  - example-tsb.tetrate.io ## <-- 在此处输入 DNS 名称
  issuerRef:
    name: xcp-identity-issuer
    kind: Issuer
  duration: 30000h
```

{{<callout warning "使用 tctl 创建证书时的 DNS 名称">}}
如果你使用 tctl 自动安装所需的发行者和证书，XCP central 证书的 DNS 名称将为 `central.xcp.tetrate.io`。
{{</callout>}}