---
title: Tier-1 网关中的速率限制
weight: 4
---

在本文档中，我们将启用 Tier-1 网关中的速率限制，并展示如何根据客户端 IP 地址进行速率限制。

在开始之前，请确保你已经完成以下准备工作：
- 熟悉 [TSB 概念](../../concepts/)
- 安装 TSB 环境。你可以使用 [TSB 演示](../../../setup/self-managed/demo-installation) 进行快速安装
- 完成 [TSB 快速入门](../../../quickstart)。本文档假定你已经创建了租户并熟悉工作区和配置组。还需要将 tctl 配置到你的 TSB 环境中。

## 部署 Tier-1 网关和 Ingress 网关

在应用任何速率限制之前，请阅读 [使用 Tier-1 网关进行多集群流量转移](../../gateway/multi-cluster-traffic-shifting) 并熟悉使用 Tier-1 网关设置多集群配置的方法。

其余文档假定你已完成上述步骤。

## 启用速率限制服务器

阅读并按照 [启用速率限制服务器文档](../internal-rate-limiting) 中的说明进行操作。

{{<callout note 演示安装>}}
如果你使用 [TSB 演示](../../../setup/self-managed/demo-installation) 安装，你已经有一个正在运行并且可以使用的速率限制服务，可以跳过本节。
{{</callout>}}

## 部署 `httpbin` 服务

按照[此文档中的说明](../../../reference/samples/httpbin) 创建 `httpbin` 服务，并确保该服务在 `httpbin.tetrate.com` 处暴露。

## 创建 Tier-1 网关

创建一个名为 `rate-limiting-tier1-config.yaml` 的文件，该文件编辑现有的 Tier-1 网关，以在每个唯一的客户端（源）IP 地址上限制 10 个请求/分钟。将集群名称替换为部署 `httpbin` 服务的集群。

有关其他速率限制选项的详细信息，请参见[此文档](../../../refs/tsb/gateway/v2/ingress-gateway#ratelimitdimension-1)。

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Tier1Gateway
metadata:
  name: tier1-gateway
  group: tier1-gateway-group
  workspace: tier1-workspace
  tenant: tetrate
  organization: tetrate
spec:
  workloadSelector:
    namespace: tier1
    labels:
      app: tier1-gateway
  externalServers:
  - hostname: httpbin.tetrate.com
    name: httpbin
    port: 443
    rateLimiting:
      settings:
        rules:
        - dimensions:
          - remoteAddress:
              value: '*'
          limit:
            requestsPerUnit: 10
            unit: MINUTE
    tls:
      mode: SIMPLE
      # 确保使用之前创建的正确的密钥名称
      secretName: httpbin-certs
    clusters:
    - name: <cluster>
      weight: 100
```

使用 tctl 配置 Tier-1 网关：

```bash
tctl apply -f rate-limiting-tier1-config.yaml
```

## 测试

你可以通过从外部计算机或本地环境向 `httpbin` 服务发送 HTTP 请求来测试速率限制，并在一定数量的请求之后观察速率限制生效。

在以下示例中，由于你不能控制 `httpbin.tetrate.com`，你需要欺骗 `curl` 认为 `httpbin.tetrate.com` 解析为 Tier-1 网关的 IP 地址。

使用以下命令获取之前创建的 Tier-1 网关的 IP 地址。

```bash
kubectl -n tier1 get service tier1-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

然后执行以下命令，通过 Tier-1 网关向 `httpbin` 服务发送 HTTP 请求。将 `gateway-ip` 替换为你在前一步骤中获取的值。还需要传递 CA 证书，你应该在部署 `httpbin` 服务的步骤中创建了它。

```bash
curl -I "https://httpbin.tetrate.com/get" \
  --resolve "httpbin.tetrate.com:443:<gateway-ip>" \
  --cacert httpbin.crt \
  -s \
  -o /dev/null \
  -w "%{http_code}\n"
```

在一分钟内多次执行上述命令。在 10 次请求后，你将看到响应代码从 200 更改为 429。