---
title: 带 TLS 验证的外部速率限制
weight: 6
---

一旦你配置了[外部速率限制服务器](../external-rate-limiting)，你可能希望确保与速率限制服务的通信安全。TSB 支持指定[TLS 或 mTLS](../../../refs/tsb/auth/v2/auth#clienttlssettings)参数来确保与外部速率限制服务器的通信的安全性。本文档将向你展示如何通过将 CA 证书添加到速率限制配置中来为外部速率限制服务器配置 TLS 验证。

在开始之前，请确保你已完成以下准备工作：
- 熟悉 [TSB 概念](../../../concepts/)
- 安装 TSB 环境。你可以使用 [TSB 演示](../../../setup/self-managed/demo-installation) 进行快速安装
- 完成 [TSB 使用快速入门](../../../quickstart)。本文假定你已经创建了租户，并熟悉工作空间和配置组。还需要配置 tctl 到你的 TSB 环境。
- 完成了 [设置外部速率限制服务器](../external-rate-limiting)。本文将继续你在设置外部速率限制服务器中所做的工作。你将在 `ext-ratelimit` 命名空间中工作，并且应该已经正确配置了带有外部速率限制的 Ingress 网关。

## TLS 证书

要启用 Ingress 网关到速率限制服务的 TLS，请确保你拥有一个 TLS 证书。本文假定你已经拥有 TLS 证书，通常包括服务器证书和私钥，以及客户端将使用的 CA 作为根证书。

本文假定以下文件已存在。如果你使用不同的文件名，请相应地更改它们：

| 文件名          | 描述 |
|--------------------|-------------|
| `ratelimit.crt`    | 服务器证书 |
| `ratelimit.key`    | 证书私钥 |
| `ratelimit-ca.crt` | CA 证书 |

:::注意 自签名证书
为了示例的目的，你可以选择使用自签名证书。
你可以使用[这里显示的脚本](../../../quickstart/ingress-gateway#certificate-for-gateway)生成自签名证书，但请确保根据需要调整输入参数。
:::注意

一旦你拥有证书文件，请使用服务器证书和私钥创建 Kubernetes 密钥对。

```bash
kubectl create secret tls -n ext-ratelimit ratelimit-certs \
  --cert=ratelimit.crt \
  --key=ratelimit.key
```

## 使用 TLS 证书部署速率限制服务

在本示例中，你将使用 Envoy 速率限制服务。Envoy 代理 sidecar 作为透明代理，将在将请求发送到速率限制服务之前验证并终止 TLS。

创建一个包含以下内容的 Envoy 配置文件，将其命名为 [`proxy-config-tls.yaml`](../../../assets/howto/rate-limiting/proxy-config-tls.yaml)

执行以下命令将配置存储到 Kubernetes 中作为 `ConfigMap`。

```bash
kubectl create configmap -n ext-ratelimit ratelimit-proxy \
  --from-file=proxy-config-tls.yaml
```

你需要使用 Envoy sidecar 部署速率限制服务以终止 TLS。创建一个名为 [`ratelimit-tls.yaml`](../../../assets/howto/rate-limiting/ratelimit-tls.yaml) 的文件，其内容如下。

然后使用 `kubectl` 应用此文件：

```bash
kubectl apply -f ratelimit-tls.yaml
```

一旦应用了新配置，请确保 `ratelimit-tls` 服务正常运行。
请注意，如果你遵循了[设置外部速率限制服务器](../external-rate-limiting)的说明，你还将看到 `ratelimit` 和 `redis` 服务。

```bash
kubectl get pods -n ext-ratelimit

NAME                             READY   STATUS    RESTARTS   AGE
ratelimit-d5c5b64ff-m87dt        1/1     Running   0          2h
ratelimit-tls-568c5cdc69-z82xf   2/2     Running   0          

 89s
redis-7d757c948f-42sxg           1/1     Running   0          2h
```

## 在 Ingress 网关中启用速率限制服务器的 TLS 验证

`ratelimit-tls` 服务现在可以终止 TLS，但是 Ingress 网关也必须配置以验证 TLS 连接。

首先，创建一个名为 `ratelimit-ca` 的 `ConfigMap` 来存储来自 `ratelimit-ca.crt` 的 CA 信息：

```bash
kubectl create configmap -n httpbin ratelimit-ca \
  --from-file=ratelimit-ca.crt
```

然后将 `ratelimit-ca` `ConfigMap` 添加到 Ingress 网关 pod 中。为此，你需要编辑[ `httpbin-ingress-gateway.yaml` 文件](../../../reference/samples/httpbin#expose-the-httpbin-service) 并添加一个读取你在先前步骤中创建的 `ConfigMap` 的覆盖层，然后将配置挂载到 Ingress 网关部署中。

使用 kubectl 应用以更新现有的 Ingress 网关

```bash
kubectl apply -f httpbin-ingress-gateway.yaml
```

最后，更新 [`ext-ratelimit-ingress-gateway.yaml`](../external-rate-limiting#configure-ingress-gateway) 中的 Ingress 网关配置，并启用 TLS 验证：

使用 tctl 应用

```bash
tctl apply -f ext-ratelimit-ingress-gateway-tls.yaml
```

## 测试

要验证设置是否正常工作，你可以使用与[“设置外部速率限制服务器的测试步骤”](../external-rate-limiting#testing)中显示的相同的测试步骤。