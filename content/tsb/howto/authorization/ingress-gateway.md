---
title: 在 Ingress Gateways 中配置外部授权
weight: 2
description: 如何使用 Open Policy Agent（OPA）示例配置 Ingress Gateway 外部授权。
---

在本文中，将使用 httpbin 作为工作负载。传入 Ingress GW 的请求将由 OPA 检查。如果请求被视为未经授权，那么将以 403（Forbidden）响应拒绝请求。

以下图像显示了在使用外部授权系统时的请求和响应流程，你将部署 OPA 作为独立服务。

![](../../../assets/howto/authorization/ingress_gateway_flow.png)

## 部署 `httpbin` 服务

按照[此文档中的所有说明](../../../reference/samples/httpbin)创建`httpbin`服务。

## 部署 OPA 服务

参考"[安装 Open Policy Agent](../../../reference/samples/opa)"文档，创建[具有基本身份验证的策略](../../../reference/samples/opa#example-policy-with-basic-authentication)并[部署 OPA 作为独立服务](../../../reference/samples/opa#basic-deployment)。

## 配置 Ingress Gateway

你需要为`httpbin`再次配置 Ingress Gateway 以使用 OPA。创建名为 `httpbin-ingress.yaml` 的文件，其中包含以下内容：

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
             port: 8000
     authorization:
       external:
         uri: grpc://opa.opa.svc.cluster.local:9191
```

使用 `tctl apply` 命令应用配置：

```bash
tctl apply -f httpbin-ingress.yaml
```

## 测试

你可以通过从外部机器或本地环境向`httpbin` Ingress Gateway 发送 HTTP 请求来测试外部授权。

在以下示例中，由于你无法控制 httpbin.tetrate.com，你必须欺骗 curl 以使其认为 httpbin.tetrate.com 解析为 Ingress Gateway 的 IP 地址。

使用以下命令获取之前创建的 Ingress Gateway 的 IP 地址。

```bash
kubectl -n httpbin get service httpbin-ingress-gateway \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

然后执行以下命令，通过 Ingress Gateway 发送 HTTP 请求到 httpbin 服务。将 `<gateway-ip>` 替换为你在前一步中获取的值。

请记住，示例 OPA 策略包含两个用户 `alice` 和 `bob`，可以使用基本身份验证进行授权。

以下命令应显示 `200`。同样，将用户名更改为 `bob` 也应显示 `200`。

```bash
curl -u alice:password "https://httpbin.tetrate.com/get" \
  --resolve "httpbin.tetrate.com:443:<gateway-ip>" \
  --cacert certs/httpbin-ca.crt \
  -s \
  -o \
  -w "%{http_code}\n"
```

以下命令向用户 `alice` 提供错误的密码。这应该显示 `403`。

```bash
curl -u alice:wrongpassword "https://httpbin.tetrate.com/get" \
  --resolve "httpbin.tetrate.com:443:<gateway-ip>" \
  --cacert certs/httpbin-ca.crt \
  -s \
  -o \
  -w "%{http_code}\n"
```

最后，如果提供的用户不是 `alice` 或 `bob`，则应显示 `403`。

```bash
curl -u charlie:password "https://httpbin.tetrate.com/get" \
  --resolve "httpbin.tetrate.com:443:<gateway-ip>" \
  --cacert certs/httpbin-ca.crt \
  -s \
  -o \
  -w "%{http_code}\n"
```
