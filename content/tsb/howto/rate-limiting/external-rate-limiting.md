---
title: 配置外部速率限制服务器
weight: 5
---

TSB 支持使用外部速率限制服务器。本文档将通过一个示例描述如何配置 [Envoy rate limit service](https://github.com/envoyproxy/ratelimit) 并将其用作 TSB Ingress Gateway 中的外部速率限制服务器。

在开始之前，请确保你已经完成以下准备工作：
- 熟悉 [TSB 概念](../../../concepts/)
- 安装 TSB 环境。你可以使用 [TSB 演示](../../../setup/self-managed/demo-installation) 进行快速安装
- 完成 [TSB 快速入门](../../../quickstart)。本文档假定你已经创建了租户并熟悉工作区和配置组。还需要将 tctl 配置到你的 TSB 环境中。

{{<callout note 注意>}}
虽然本文档只描述了如何为 Ingress Gateway 应用外部服务器的速率限制，但你可以使用类似的配置方式对 Tier-1 网关和服务对服务（通过 TSB 流量设置）应用相同的速率限制。
{{</callout>}}

## 创建命名空间

在本示例中，我们将在 `ext-ratelimit` 命名空间中安装外部速率限制服务。如果目标集群中尚未存在该命名空间，请运行以下命令创建它：

```bash
kubectl create namespace ext-ratelimit
```

### 配置速率限制服务

{{<callout note 注意>}}
请阅读 [Envoy rate limit 文档](https://github.com/envoyproxy/ratelimit#configuration) 以了解关于域和描述符概念的详细信息。
{{</callout>}}

创建名为 [`ext-ratelimit-config.yaml`](../../../assets/howto/rate_limiting/ext-ratelimit-config.yaml) 的文件，其内容如下。此配置指定对每个唯一的请求路径的请求应限制为每分钟 4 次。

然后使用你创建的文件创建一个 `ConfigMap`：

```bash
kubectl -n ext-ratelimit apply -f ext-ratelimit-config.yaml
```

### 部署速率限制服务器和 Redis

部署 Redis 和 `envoyproxy/ratelimit`。创建一个名为 [`redis-ratelimit.yaml`](../../../assets/howto/rate_limiting/redis-ratelimit.yaml) 的文件，其内容如下：

```bash
kubectl -f redis-ratelimit.yaml
```

如果一切正常，你应该有一个正常工作的速率限制服务器。
通过执行以下命令来确保 Redis 和速率限制服务器正在运行：

```bash
kubectl get pods -n ext-ratelimit
```

你应该会看到类似以下的输出：

```
NAME                        READY   STATUS    RESTARTS   AGE
ratelimit-d5c5b64ff-m87dt   1/1     Running   0          14s
redis-7d757c948f-42sxg      1/1     Running   0          14s
```

## 配置 Ingress Gateway

本示例假定你正在对 [`httpbin`](../../../reference/samples/httpbin) 工作负载应用速率限制。如果尚未完成，请部署 `httpbin` 服务，创建 `httpbin` 工作区和配置组，并通过 Ingress Gateway 公开服务。

以下示例设置了 `httpbin-ratelimit` 域中的请求速率限制。请求路径存储在名为 `request-path` 的 `descriptorKey` 中，然后由速率限制服务器使用。

将此内容保存到一个名为 [`ext-ratelimit-ingress-gateway.yaml`](../../../assets/howto/rate_limiting/ext-ratelimit-ingress-gateway.yaml) 的文件中，并使用 `tctl` 应用它：

```bash
tctl apply -f ext-ratelimit-ingress-gateway.yaml
```

### 测试

你可以通过从外部计算机或本地环境向 httpbin Ingress Gateway 发送 HTTP 请求来测试速率限制，并在一定数量的请求之后观察速率限制生效。

在以下示例中，由于你不能控制 httpbin.tetrate.com，你需要欺骗 curl，使其认为 httpbin.tetrate.com 解析为 Ingress Gateway 的 IP 地址。

使用以下命令获取之前创建的 Ingress Gateway 的 IP 地址。

```bash
kubectl -n httpbin get service httpbin-ingress-gateway \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

然后执行以下命令，通过 Ingress Gateway 向 httpbin 服务发送 HTTP 请求。将 gateway-ip 替换为你在前一步骤中获取的值。

```bash
curl -k "http://httpbin.tetrate.com/get" \
    --resolve "httpbin.tetrate.com:80:<gateway-ip>" \
    -s \
    -o /dev/null \
    -w "%{http_code}\n"
```

在前 4 个请求中，你应该在屏幕上看到 "200"。之后，你应该开始看到 "429"。

你可以将请求路径更改为另一个唯一值以获取成功的响应。

```bash
curl -k "http://httpbin.tetrate.com/headers" \
    --resolve "httpbin.tetrate.com:80:<gateway-ip>" \
    -s \
    -o /dev/null \
    -w "%{http_code}\n"
```

在 4 次请求后，你应该再次开始看到 "429"，直到更改请求路径为止。

## 多集群使用速率限制服务器的考虑事项

如果你想要在多个集群中共享相同的速率限制规则，有两种可能的选择：

* 在一个集群中部署单个速率限制服务，并使其可以从所有共享规则的其他集群访问，或者
* 在每个集群中部署

速率限制服务，但让它们都使用相同的 Redis 后端。

在第二种情况下，你将需要让 Redis 可以从所有集群访问。每个速率限制服务器还应该使用相同的域值。