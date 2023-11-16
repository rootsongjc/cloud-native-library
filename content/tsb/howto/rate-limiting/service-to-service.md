---
title: 服务之间的速率限制
weight: 3
---

TSB 能够为网关和 sidecar 都应用速率限制。在本文档中，我们将启用 sidecar 的速率限制，以控制服务之间的流量配额。

在开始之前，请确保你已经完成以下步骤：
- 熟悉 [TSB 概念](../../../concepts/) 
- 安装 TSB 环境。你可以使用 [TSB 演示](../../../setup/self-managed/demo-installation) 进行快速安装
- 完成了 [TSB 使用快速入门](../../../quickstart)。本文档假定你已经创建了租户，熟悉工作区和配置组，并配置了 tctl 到你的 TSB 环境。

## 启用速率限制服务器

请阅读并按照 [启用速率限制服务器文档](../internal-rate-limiting) 中的说明操作。

{{<callout note 演示安装>}}
如果你使用 [TSB 演示](../../../setup/self-managed/demo-installation) 安装，你已经有一个正在运行并且可以使用的速率限制服务，可以跳过这一部分。
{{</callout>}}

如果你打算在多集群设置中使用相同的速率限制服务器，所有集群都必须指向相同的 [Redis 后端和域](../../../refs/install/controlplane/v1alpha1/spec#ratelimitserver)。

## 部署 `httpbin` 服务

请按照 [本文档中的说明](../../../reference/samples/httpbin) 创建 `httpbin` 服务。你可以跳过 "暴露 `httpbin` 服务"、"创建证书" 和 "载入 `httpbin` 应用程序" 部分。

## 创建 TrafficSetting

创建一个 TrafficSetting 对象，保存在名为 `service-to-service-rate-limiting-traffic-setting.yaml` 的文件中。在此示例中，速率限制设置为每个路径每分钟最多 4 次请求。将 `organization` 和 `tenant` 替换为适当的值。

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: TrafficSetting
metadata:
  organization: <organization>
  tenant: <tenant>
  workspace: httpbin
  group: httpbin-traffic
  name: httpbin-traffic-settings-ratelimit
spec:
  rateLimiting:
    settings:
      rules:
      - dimensions:
        - header:
            name: ":path"
            value: 
              prefix: "/"
        limit:
          requestsPerUnit: 4
          unit: MINUTE
```

使用 `tctl` 应用此清单：

```bash
tctl apply -f service-to-service-rate-limiting-traffic-setting.yaml
```

## 部署 `sleep` 服务

由于你将配置服务之间的速率限制，因此需要另一个服务作为 `httpbin` 服务的客户端。

请按照 [本文档中的说明](../../../reference/samples/sleep-service) 创建 `sleep` 服务。你可以跳过 "创建 `sleep` 工作区" 部分。

## 测试

你可以通过从 `sleep` 服务发送 HTTP 请求到 `httpbin` 服务来测试速率限制，并观察在一定数量的请求后速率限制生效。

要从 sleep 服务发送请求，你需要确定 sleep 服务内的 Pod。
执行以下命令以查找 Pod 名称：

```bash
kubectl get pod -n sleep -l app=sleep -o jsonpath={.items..metadata.name}
```

然后从此 Pod 发送请求到 `httpbin` 服务，该服务应该可以在 `http://httpbin.httpbin:8000` 上访问。确保将 `<sleep-pod>` 的值替换为适当的值：

```bash
kubectl exec <sleep-pod> -n sleep -c sleep -- \
  curl http://httpbin.httpbin:8000/get \
    -s \
    -o /dev/null \
    -w "%{http_code}\n"
```

重复执行上述命令超过 4 次。在 4 次请求之后，你应该会看到响应代码从 200 变为 429。

由于速率限制规则基于请求路径，访问 `httpbin` 上的另一个路径，你应该会再次看到 200 响应：

```bash
kubectl exec <sleep-pod> -n sleep -c sleep -- \
  curl http://httpbin.httpbin:8000/headers \
    -s \
    -o /dev/null \
    -w "%{http_code}\n"
```

类似于前面的示例，重复执行上述命令超过 4 次应该会导致速率限制生效，你应该开始看到 429 而不是 200。
