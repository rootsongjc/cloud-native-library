---
title: 在 Tier-1 网关中使用外部授权
weight: 4
description: 如何使用 Open Policy Agent (OPA) 来授权来自公共网络的请求。
---

TSB 提供了授权功能，用于授权来自公共网络的请求。本文将描述如何使用 Open Policy Agent (OPA) 配置 Tier-1 网关授权。

在开始之前，请确保您：
- 熟悉[TSB 概念](../../../concepts/)。
- 已完成了 Tier-1 网关路由到 Tier-2 网关，并在 TSB 中已配置了[httpbin](../../../reference/samples/httpbin)。
- 创建了一个租户，并了解工作空间和配置组。
- 针对您的 TSB 环境配置了 `tctl`。

以下图示展示了在Tier-1网关中使用OPA的请求/响应流程。来到Tier-1网关的请求将由OPA检查。如果请求被视为未经授权，则请求将被拒绝并返回403（禁止）响应，否则它们将被发送到Tier-2网关。

## 部署 `httpbin` 服务

按照[本文中的说明](../../../reference/samples/httpbin)创建 `httpbin` 服务，并确保该服务在 `httpbin.tetrate.com` 上公开。

## 配置 OPA

在此示例中，您将部署 OPA 作为其自己独立的服务。如果尚未这样做，请为 OPA 服务创建一个命名空间：

```bash
kubectl create namespace opa
```

按照[OPA 文档](../../../reference/samples/opa)中的说明创建[使用基本身份验证的 OPA 策略](../../../reference/samples/opa#example--policy-with-basic-authentication)，并在 `opa` 命名空间中部署 OPA 服务和代理。

```
kubectl apply -f opa.yaml
```

然后更新您的 Tier-1 网关配置以使用 OpenAPI 规范，将以下部分添加到 Tier-1 网关，并使用 tctl 应用它们：

```
apiVersion: gateway.tsb.tetrate.io/v2
kind: Tier1Gateway
metadata:
 organization: tetrate
 tenant: tetrate
 workspace: tier1
 group: tier1
 name: tier1gw
spec:
 workloadSelector:
   namespace: tier1
   labels:
     app: tier1gw
     istio: ingressgateway
 externalServers:
 - name: httpbin
   hostname: httpbin.tetrate.com
   port: 443
   tls:
     mode: SIMPLE
     secretName: tier1-cert
   clusters:
   - labels:
       network: tier2
   authorization:
     external:
       uri: grpc://opa.opa.svc.cluster.local:9191
```

## 测试

您可以按照["在 Ingress Gateways 中配置外部授权"](../ingress-gateway#testing)中的说明进行外部授权测试，但需要获取 Tier-1 网关地址而不是 Ingress 网关地址。

要获取 Tier-1 网关地址，请执行以下命令：

```bash
kubectl -n tier1 get service tier1-gateway \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

然后按照[说明](../ingress-gateway#testing)操作，但请将 `gateway-ip` 的值替换为 Tier-1 网关的地址。