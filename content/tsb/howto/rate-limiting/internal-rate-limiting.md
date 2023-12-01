---
title: 启用内部速率限制服务器
weight: 1
---

TSB 带有每个控制平面集群的速率限制服务器组件。默认情况下，此功能已禁用。

此部分仅讨论[内部模式](../../rate-limiting)的安装过程，不涉及[外部服务器](../../rate-limiting)的安装。

## 配置

可以通过在 [ControlPlane Operator API](../../../refs/install/controlplane/v1alpha1/spec#controlplanecomponentset) 或 [Helm 值](../../../setup/helm/controlplane) 中明确指定 `rateLimitServer` 组件的配置并将其应用于相关的控制平面集群来启用速率限制服务器。`rateLimitServer` 需要一个 Redis 后端来跟踪速率限制属性计数，并且其详细信息需要包含在配置中。

你的 Control Plane Operator 配置可能如下所示：

```yaml
spec:
  ...
  components:
    rateLimitServer:
      domain: <domain>
      backend:
        redis:
          uri: <redis-uri>
```

注意在 `components` 对象中引入了 `rateLimitServer`。

`domain` 的值用于对速率限制的存储元数据进行分组。对所有 Control Planes 指定相同的 `domain` 将有效允许你配置跨所有集群的全局速率限制。如果使用不同的值为 `domain`，那么速率限制效果将仅局限于查看相同 `domain` 的那些集群。这假定 Control Planes 指定相同的 Redis 服务器。

我们建议你仅在同一地理区域内的集群中指定相同的域，例如 `us-east`。

`redis-uri` 的值是要使用的 Redis 实例的服务器名称和端口。你需要确保从控制平面集群能够访问此 URI。

## Redis 认证

如果你的 Redis 数据库需要密码，你可以自己创建密钥：

```bash
kubectl -n istio-system create secret generic \
  redis-credentials \
  --from-literal=REDIS_AUTH=<password>
```

如果运行的 TSB 版本 >= 1.4.0，你可以使用 [`tctl install manifest control-plane-secrets`](../../../reference/cli/reference/install#tctl-install-manifest-control-plane-secrets) 命令中的 `--redis-password` 参数来指定密码以生成适当的密钥。

### TLS

如果你的 Redis 数据库支持传输加密（TLS），则需要通过在 `redis-credentials` 密钥中将 `REDIS_TLS` 键设置为 `true` 来启用 Ratelimit Redis 客户端中的 TLS。示例命令如下：

```bash
kubectl -n istio-system create secret generic \
  redis-credentials \
  --from-literal=REDIS_AUTH=<password>
  --from-literal=REDIS_TLS=true
```

如果运行的 TSB 版本 >= 1.5.0，你可以使用 [`tctl install manifest control-plane-secrets`](../../../reference/cli/reference/install#tctl-install-manifest-control-plane-secrets) 命令中的 `--redis-tls` 参数来指定它以生成适当的密钥。你还可以使用 `--redis-tls-ca-cert` 参数指定自定义 CA 证书以验证 TLS 连接，以及使用 `--redis-tls-client-key` 和 `--redis-tls-client-cert` 参数指定 Redis 客户端密钥和证书（如果启用了客户端证书身份验证），这将在 [`tctl install manifest control-plane-secrets`](../../../reference/cli/reference/install#tctl-install-manifest-control-plane-secrets) 命令中生成适当的 `redis-credentials` 密钥。

## 部署服务器

创建一个使用上述示例的清单。确保在以前的示例中省略的控制平面中包含所有必要的字段。

如果要更新现有的控制平面，你可以使用 `kubectl get controlplane -n istio-system -o yaml` 来获取当前的值。

将清单保存到文件中，例如 `control-plane-with-rate-limiting.yaml`，然后使用 `kubectl` 应用它：

```bash
kubectl apply -f control-plane-with-rate-limiting.yaml
```

要检查速率限制服务器是否在集群中正常运行，请执行以下命令：

```bash
kubectl get pods -n istio-system | grep ratelimit
ratelimit-server-864654b5b5-d77bq                       1/1     Running   2          2d1h
```
