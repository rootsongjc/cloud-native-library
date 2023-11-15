---
title: TSB 入口网关中的速率限制
weight: 2
---

在本文档中，我们将启用入口网关中的速率限制，并展示如何基于 HTTP 请求中的 `user-agent` 字符串进行速率限制。

在开始之前，请确保你已经完成以下步骤：
- 熟悉 [TSB 概念](../../../concepts)
- 安装 TSB 环境。你可以使用 [TSB 演示](../../../setup/self-managed/demo-installation) 进行快速安装
- 完成了 [TSB 使用快速入门](../../../quickstart)。本文档假定你已经创建了租户，熟悉工作区和配置组，并配置了 tctl 到你的 TSB 环境。

## 启用速率限制服务器

请阅读并按照 [启用速率限制服务器文档](../internal-rate-limiting) 中的说明操作。

{{<callout note 演示安装>}}
如果你使用 [TSB 演示](../../../setup/self-managed/demo-installation) 安装，你已经有一个正在运行并且可以使用的速率限制服务，可以跳过这一部分。
{{</callout>}}

## 部署 `httpbin` 服务

请按照 [本文档中的说明](../../../reference/samples/httpbin) 创建 `httpbin` 服务。你可以跳过 "创建证书" 和 "载入 `httpbin` 应用程序" 部分。

## 基于 User-agent 进行速率限制

创建一个名为 `rate-limiting-ingress-config.yaml` 的文件，用于编辑现有的入口网关，以便对每个 User-agent 头的值进行速率限制，限制为每分钟 5 次请求。将 `organization` 和 `tenant` 替换为适当的值。

其他速率限制选项的详细信息可以在 [此文档](../../../refs/tsb/gateway/v2/ingress-gateway) 中找到。

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
  name: httpbin-gateway # 不需要与 spec.labels.app 相同
  organization: <organization>
  tenant: <tenant>
  group: httpbin-gateway
  workspace: httpbin
spec:
  workloadSelector:
    namespace: httpbin
    labels:
      app: httpbin-ingress-gateway # 为 httpbin 创建的入口网关的名称
  http:
    - name: httpbin
      hostname: "httpbin.tetrate.com"
      port: 80
      routing:
        rules:
          - route:
              host: "httpbin/httpbin.httpbin.svc.cluster.local"
              port: 8000
      rateLimiting:
        settings:
          rules:
          - dimensions:
            - header:
                name: user-agent
            limit:
              requestsPerUnit: 5
              unit: MINUTE
```

使用 `tctl` 配置入口网关：

```bash
tctl apply -f rate-limiting-ingress-config.yaml
```

## 测试 

你可以通过从外部计算机或本地环境发送 HTTP 请求到 `httpbin` 入口网关来测试速率限制，并观察在一定数量的请求后速率限制生效。

在以下示例中，由于你无法控制 `httpbin.tetrate.com`，你需要欺骗 `curl`，让它认为 `httpbin.tetrate.com` 解析为 Tier-1 网关的 IP 地址。

使用以下命令获取之前创建的 Tier-1 网关的 IP 地址。

```bash
kubectl -n httpbin get service httpbin-ingress-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

然后执行以下命令，将 HTTP 请求发送到入口网关的 `httpbin` 服务。将 `<gateway-ip>` 替换为你在上一步中获取的值。

```bash
curl -k -v "http://httpbin.tetrate.com/get" \
    --resolve "httpbin.tetrate.com:80:<gateway-ip>" \
    -s \
    -o /dev/null \
    -w "%{http_code}\n"
```

前面的 5 个请求应该会在屏幕上显示 "200"。之后，你应该开始看到 "429"。

你可以将 `user-agent` 头更改为另一个唯一的值以获得成功的响应。

```bash
curl -k -v -A "another-agent" \
    "http://httpbin.tetrate.com/get" \
    --resolve "httpbin.tetrate.com:80:<gateway-ip>" \
    -s \
    -o /dev/null \
    -w "%{http_code}\n"
```

在 5 次请求之后，你应该再次开始看到 "429"，直到你再次更改头部。
