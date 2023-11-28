---
title: 从本地虚拟机上进行工作负载上线
weight: 3
---

## 启动工作负载上线代理

创建文件 `/etc/onboarding-agent/onboarding.config.yaml`，并填入以下内容。将 `<ONBOARDING_ENDPOINT_ADDRESS>` 替换为[之前获取的值](../../aws-ec2/enable-workload-onboarding)。

```yaml
apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
kind: OnboardingConfiguration
onboardingEndpoint:
  host: "<ONBOARDING_ENDPOINT_ADDRESS>"
  transportSecurity:
    tls:
      sni: onboarding-endpoint.example    # (1)
workloadGroup:                            # (2)
  namespace: bookinfo
  name: ratings
workload:
  labels:
    version: v5                           # (3)
```

此配置指示工作负载上线代理使用一个地址连接到工作负载上线终端点，但对 DNS 名称 `onboarding-endpoint.example` 验证 TLS 证书 (1)。

代理将尝试加入你之前创建的 `WorkloadGroup` (2)。

在 (3) 中指定的额外标签将与工作负载关联，但不会影响工作负载与 `WorkloadGroup` 的匹配。

此配置暗示 Kubernetes 集群和本地虚拟机位于同一网络或已连接的网络中。

将上述配置文件放置在正确的位置后，执行以下命令以启动工作负载上线代理：

```bash
# 启用
sudo systemctl enable onboarding-agent

# 启动
sudo systemctl start onboarding-agent
```

通过执行以下命令验证 `Istio Sidecar` 是否已启动：

```bash
curl -f -i http://localhost:15000/ready
```

你应该会得到类似于以下内容的输出：

```bash
HTTP/1.1 200 OK
content-type: text/plain; charset=UTF-8
server: envoy

LIVE
```

## 验证工作负载

从你的本地机器上，验证工作负载是否已正确上线。

执行以下命令：

```bash
kubectl get war -n bookinfo 
```

如果工作负载已正确上线，你应该会得到类似于以下内容的输出：

```bash
NAMESPACE   NAME                                                           AGENT CONNECTED   AGE
bookinfo    ratings-jwt-my-corp--vm007-datacenter1-us-east.internal.corp   True              1m
```

### 验证从 Kubernetes 到本地虚拟机的流量

要验证从 Kubernetes Pod 到本地虚拟机的流量，请在 Kubernetes 上部署的 Bookinfo 应用程序上创建一些负载，并确认请求被路由到本地虚拟机上部署的 `ratings` 应用程序。

如果尚未设置端口转发，请在你的本地机器上[设置端口转发](../../aws-ec2/bookinfo)。

然后运行以下命令：

```bash
for i in `seq 1 9`; do
  curl -fsS "http://localhost:9080/productpage?u=normal" | grep "glyphicon-star" | wc -l | awk '{print $1" stars on the page"}'
done
```

其中两次中的一次应该会显示消息 `10 stars on the page`。

此外，你可以通过检查由 Istio sidecar 代理的传入 HTTP 请求的[访问日志](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage)来验证虚拟机是否接收到流量。

执行以下命令：

```bash
journalctl -u onboarding-agent -o cat
```

你应该会看到类似以下内容的输出：

```text
[2021-10-25T11:06:13.553Z] "GET /ratings/0 HTTP/1.1" 200 - via_upstream - "-" 0 48 3 2 "-" "curl/7.68.0" "1928e798-dfe7-45a6-9020-d0f3a8641d03" "172.31.7.211:9080" "127.0.0.1:9080" inbound|9080|| 127.0.0.1:40992 172.31.7.211:9080 172.31.7.211:35470 - default
```

### 验证从本地虚拟机到 Kubernetes 的流量

SSH 进入本地虚拟机并执行以下命令：

```bash
for i in `seq 1 5`; do
  curl -i \
    --resolve details.bookinfo:9080:127.0.0.2 \
    details.bookinfo:9080/details/0
done
```

上述命令将向 Bookinfo `details` 应用程序发出 `5` 个 HTTP 请求。`curl` 将解析 Kubernetes 集群本地的 DNS 名称 `details.bookinfo` 为 Istio 代理的 `egress` 监听器的 IP 地址（根据[你之前创建的 sidecar 配置](../configure-workload-onboarding)为 `127.0.0.2`）。

你应该会得到类似以下内容的输出：

```bash
HTTP/1.1 200 OK
content-type: application/json
server: envoy

{"id":0,"author":"William Shakespeare","year":1595,"type":"paperback",   "pages":200,"publisher":"PublisherA","language":"

English",   "ISBN-10":"1234567890","ISBN-13":"123-1234567890"}
```
