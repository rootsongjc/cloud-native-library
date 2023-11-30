---
title: 使用 TLS 验证的外部授权
weight: 3
description: 安全地在 TSB 和外部授权服务之间保护流量。
---

TSB 支持指定用于保护与外部授权服务器通信的[TLS 或 mTLS](../../../refs/tsb/auth/v2/auth#clienttlssettings)参数。本文将向你展示如何通过将 CA 证书添加到授权配置来为外部授权服务器配置 TLS 验证。

在开始之前，请确保你：
- 熟悉[TSB 概念](../../../concepts/)
- 安装了 TSB 环境。你可以使用[TSB 演示](../../../setup/self-managed/demo-installation)进行快速安装
- 完成了[TSB 用法快速入门](../../../quickstart)。本文假设你已经创建了租户并熟悉工作空间和配置组。还需要将 tctl 配置到你的 TSB 环境中。

本文中的示例将建立在["在 Ingress Gateways 中配置外部授权"](../ingress-gateway)之上。在继续之前，请确保已完成该文档，并注意你将在命名空间 `httpbin` 上工作。

## 创建 TLS 证书

为了使 Ingress Gateway 到授权服务的流量启用 TLS，你必须拥有 TLS 证书。本文假设你已经有 TLS 证书，通常包括服务器证书和私钥，以及用于客户端的根证书作为 CA。本文使用以下文件：

1. `authz.crt` 作为服务器证书
2. `authz.key` 作为证书私钥
3. `authz-ca.crt` 作为 CA 证书

如果你决定使用其他文件名，请在下面的示例中相应地替换它们。

{{<callout note 自签名证书>}}
出于示例目的，你可以使用此[脚本](../../../quickstart/ingress-gateway#certificate-for-gateway)创建自签名证书。
{{</callout>}}

拥有文件后，使用服务器证书和私钥创建 Kubernetes secret。

```bash
kubectl create secret tls -n httpbin opa-certs \
  --cert=authz.crt \
  --key=authz.key
```

你还需要 CA 证书来验证 TLS 连接。
创建一个名为 `authz-ca` 的 `ConfigMap`，其中包含 CA 证书：

```bash
kubectl create configmap -n httpbin authz-ca \
  --from-file=authz-ca.crt
```

## 使用 TLS 证书部署授权服务

按照["在 TSB 中安装 Open Policy Agent"](../../../reference/samples/opa#terminating-tls)中的说明设置带有终止 TLS 的 Sidecar代理的 OPA 实例。

## 修改 Ingress Gateway

你需要向 Ingress Gateway 添加 CA 证书以验证 TLS 连接。
创建一个名为 `httpbing-ingress-gateway.yaml` 的文件，其中包含以下内容。此清单添加了覆盖以读取包含 CA 证书的 `authz-ca` 的 `ConfigMap` 到 Ingress Gateway 部署。

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: httpbin-ingress-gateway
  namespace: httpbin
spec:
  kubeSpec:
    service:
      type: LoadBalancer
    overlays:
    - apiVersion: apps/v1
      kind: Deployment
      name: httpbin-ingress-gateway
      patches:
      - path: spec.template.spec.volumes[-1]
        value:
          name: authz-ca
          configMap:
            name: authz-ca
      - path: spec.template.spec.containers.[name:istio-proxy].volumeMounts[-1]
        value:
          name: authz-ca
          mountPath: /etc/certs
          readOnly: true
```

使用 kubectl 应用：

```bash
kubectl apply -f httpbin-ingress-gateway.yaml
```

然后更新 Ingress Gateway 配置以启用 TLS 验证：

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
 organization: tetrate
 name: httpbin-ingress-gateway
 group: httpbin
 workspace: httpbin
 tenant: tetrate
spec:
 workloadSelector:
   namespace: httpbin
   labels:
     app: httpbin-ingress-gateway
 http:
   - name: httpbin
     port: 443
     hostname: "httpbin.tetrate.com"
     tls:
      mode: SIMPLE
      secretName: httpbin-certs
     routing:
       rules:
         - route:
             host: "httpbin/httpbin.httpbin.svc.cluster.local"
             port: 8080
     authorization:
       external:
         tls:
           mode: SIMPLE
           files:
             caCertificates: /etc/certs/authz-ca.crt
         uri: grpcs://opa.opa.svc.cluster.local:18443
```

使用 tctl 应用：

```bash
tctl apply -f ext-authz-ingress-gateway-tls.yaml
```

## 测试

你可以使用与["在 Ingress Gateways 中配置外部授权"](../ingress-gateway#testing)中显示的相同测试步骤。