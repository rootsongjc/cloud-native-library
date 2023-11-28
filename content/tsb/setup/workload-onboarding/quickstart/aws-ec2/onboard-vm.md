---
title: 虚拟机工作负载上线
weight: 5
---

## 启动 Workload Onboarding Agent

创建文件 `/etc/onboarding-agent/onboarding.config.yaml`，内容如下。
将 `ONBOARDING_ENDPOINT_ADDRESS` 替换为 [你之前获取的值](../enable-workload-onboarding)。

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
settings:
  connectedOver: INTERNET                 # (4)
```

此配置指示 Workload Onboarding Agent 使用一个地址连接到 Workload Onboarding Endpoint，但对 DNS 名称 `onboarding-endpoint.example` 进行 TLS 证书验证（1）。

代理将尝试加入你之前创建的 `WorkloadGroup`（2）。

在（3）中指定的额外标签将与工作负载关联。它不会影响工作负载与 `WorkloadGroup` 的匹配。

此配置还指示 Workload Onboarding Agent 通知此工作负载通过 `INTERNET` 连接到网格的其他部分（而不是 `VPC`）。网格中的其他节点将尝试使用工作负载的公共 IP 连接到此工作负载。由于你在不同网络中启动了 Kubernetes 集群和 EC2 实例，因此这是必需的。

在将上述配置文件放置在正确位置后，执行以下命令启动 Workload Onboarding Agent：

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

你应该会得到类似以下的输出：

```bash
HTTP/1.1 200 OK
content-type: text/plain; charset=UTF-8
server: envoy

LIVE
```

## 验证工作负载 

从本地机器上，验证工作负载是否已正确加入。

执行以下命令：

```bash
kubectl get war -n bookinfo 
```

如果工作负载已正确加入，你应该会得到类似以下的输出：

```bash
NAMESPACE   NAME                                                              AGENT CONNECTED   AGE
bookinfo    ratings-aws-aws-123456789012-us-east-2b-ec2-i-1234567890abcdef0   True              1m
```

### 验证从 Kubernetes 到 VM 的流量

为了验证从 Kubernetes Pod 到 AWS EC2 实例的流量，对 Kubernetes 上部署的 Bookinfo 应用程序创建一些负载，并确认请求是否被路由到部署在 AWS EC2 实例上的 `ratings` 应用程序。

在本地机器上，[如果尚未这样做，请设置端口转发](../bookinfo)。

然后运行以下命令：

```bash
for i in `seq 1 9`; do
  curl -fsS "http://localhost:9080/productpage?u=normal" | grep "glyphicon-star" | wc -l | awk '{print $1" stars on the page"}'
done
```

其中两次中你应该会收到消息 `10 stars on the page`。

此外，你可以通过检查 Istio sidecar 代理传输的入站 HTTP 请求的[访问日志](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage)来验证 VM 是否接收流量。

执行以下命令：

```bash
journalctl -u onboarding-agent -o cat
```

你应该会看到类似以下的输出：

```text
[2021-10-25T11:06:13.553Z] "GET /ratings/0 HTTP/1.1" 200 - via_upstream - "-" 0 48 3 2 "-" "curl/7.68.0" "1928e798-dfe7-45a6-9020-d0f3a8641d03" "172.31.7.211:9080" "127.0.0.1:9080" inbound|9080|| 127.0.0.1:40992 172.31.7.211:9080 172.31.7.211:35470 - default
```

### 验证从 VM 到 Kubernetes 的流量

SSH 进入 AWS EC2 实例并执行以下命令：

```bash
for i in `seq 1 5`; do
  curl -i \
    --resolve details.bookinfo:9080:127.0.0.2 \
    details.bookinfo:9080/details/0
done
```

上述命令将向 Bookinfo `details` 应用程序

发出 `5` 个 HTTP 请求。
`curl` 将解析 Kubernetes 集群的本地 DNS 名称 `details.bookinfo`，将其解析为 Istio 代理的 `egress` 监听器的 IP 地址（根据[你之前创建的 sidecar 配置](../configure-workload-onboarding)为 `127.0.0.2`）。

你应该会得到类似以下的输出：

```bash
HTTP/1.1 200 OK
content-type: application/json
server: envoy

{"id":0,"author":"William Shakespeare","year":1595,"type":"paperback",   "pages":200,"publisher":"PublisherA","language":"English",   "ISBN-10":"1234567890","ISBN-13":"123-1234567890"}
```
