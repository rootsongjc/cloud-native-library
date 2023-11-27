---
title: 配置 Authz 以支持代理协议
description: 如何配置默认情况下在服务端口而不是工作负载端口生成授权策略。
weight: 8
---

默认情况下，授权策略是使用服务器的工作负载端口来匹配流量的。但是在某些情况下，比如使用 curl 时使用 `--haproxy-protocol`，Envoy 代理会尝试在服务端口而不是工作负载端口上匹配传入的流量。本文档提供了一种允许用户执行此操作的方法。

在开始之前，请确保你已经做了以下准备：
- 熟悉 [TSB 概念](../../../concepts/)
- 安装 [TSB 演示](../../../setup/self-managed/demo-installation) 环境
- 部署 [Istio Bookinfo](../../../quickstart/deploy-sample-app) 示例应用程序
- 创建一个 [Tenant](../../../quickstart/tenant)
- 创建一个 [Workspace](../../../quickstart/workspace)
- 创建 [Config Groups](../../../quickstart/config-groups)
- 配置 [Permissions](../../../quickstart/permissions)
- 配置 [Ingress Gateway](../../../quickstart/ingress-gateway)

## 应用 haproxy-protocol EnvoyFilter

在监听器上启用 haproxy-protocol。创建以下 `haproxy-filter.yaml` 文件：

```
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: proxy-protocol
  namespace: bookinfo
spec:
  workloadSelector:
    labels:
      istio: ingressgateway
  configPatches:
  - applyTo: LISTENER
    patch:
      operation: MERGE
      value:
        listener_filters:
        - name: proxy_protocol
          typed_config:
            "@type": "type.googleapis.com/envoy.extensions.filters.listener.proxy_protocol.v3.ProxyProtocol"
            allow_requests_without_proxy_protocol: true
        - name: tls_inspector
          typed_config:
            "@type": "type.googleapis.com/envoy.extensions.filters.listener.tls_inspector.v3.TlsInspector"
```

使用 `kubectl` 应用：

```bash
kubectl apply -f haproxy-filter.yaml
```

## 配置 TSB 网关

更新 `gateway.yaml` 文件如下：

```
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
Metadata:
  organization: tetrate
  name: bookinfo-gw-ingress
  group: bookinfo-gw
  workspace: bookinfo-ws
  tenant: tetrate
spec:
  workloadSelector:
    namespace: bookinfo
    labels:
      app: tsb-gateway-bookinfo
  http:
    - name: bookinfo
      port: 443
      hostname: "bookinfo.tetrate.com"
      tls:
        mode: SIMPLE
        secretName: bookinfo-certs
      routing:
        rules:
          - route:
              host: "bookinfo/productpage.bookinfo.svc.cluster.local"
```

使用 `tctl` 应用：

```bash
tctl apply -f gateway.yaml
```

## 配置 Ingress Gateway 对象

要在服务端口而不是工作负载端口上启用授权，请更新你的 `ingress.yaml` 文件：

```
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: tsb-gateway-bookinfo
  namespace: bookinfo
spec:
  kubeSpec:
    service:
      type: LoadBalancer
      annotations:
        xcp.tetrate.io/authz-ports: "443" # 此注释防止 TSB 在创建 Istio 授权策略时将此端口翻译为工作负载端口
```

使用 `kubectl` 应用：

```bash
kubectl apply -f ingress.yaml
```

## 测试

要测试你的 Ingress 是否正确使用 haproxy-protocol，请尝试以下 curl 请求：

```bash
curl -k -s --connect-to bookinfo.tetrate.com:443:$GATEWAY_IP \
    "https://bookinfo.tetrate.com/productpage" | \
    grep -o "<title>.*</title>"
```
