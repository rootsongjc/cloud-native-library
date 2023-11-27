---
title: 分布式入口网关
description: 使用分布式入口网关实现弹性网格。
weight: 11
---

对于此场景，你需要两个已入网的集群，以配置它们之间的轮询和故障切换。

### 先决条件

在开始之前，请确保你已经：
- 熟悉 [TSB 概念](../../../concepts/)
- 安装了 [TSB 演示](../../../setup/self_managed/demo-installation) 环境
- 创建了 [租户](../../../quickstart/tenant)

### 创建工作区和网关组

以下 YAML 文件包含两个对象：一个用于应用程序的 `工作区`，以及一个 `网关` 组，以便你可以配置应用程序的入口。

将其保存为 [`httpbin-mgmt.yaml`](../../../assets/howto/httpbin-mgmt.yaml)，然后使用 tctl 应用：

```bash
tctl apply -f httpbin-mgmt.yaml
```

### 部署 httpbin

以下配置应该应用于两个集群，以部署你的应用程序，首先创建命名空间并启用 Istio sidecar 注入。

```bash
kubectl create namespace httpbin
kubectl label namespace httpbin istio-injection=enabled
```

然后部署你的应用程序。

```bash
kubectl apply -f \
    https://raw.githubusercontent.com/istio/istio/master/samples/httpbin/httpbin.yaml \
    -n httpbin
```

### 配置入口网关

在这个示例中，你将使用入口处的简单 TLS 暴露应用程序。你需要提供一个存储在 Kubernetes 密钥中的 TLS 证书。

```bash
kubectl create secret tls -n httpbin httpbin-cert \
    --cert /path/to/some/cert.pem \
    --key /path/to/some/key.pem
```

现在，你可以部署入口网关。

另存为 [`httpbin-ingress.yaml`](../../../assets/howto/httpbin-ingress.yaml)，然后使用 `kubectl` 应用：

```bash
kubectl apply -f httpbin-ingress.yaml
```

将上述配置应用于两个集群，将为它们创建相同的环境，现在我们将部署网关和虚拟服务。

集群中的 TSB 数据面运算符将获取此配置并在应用程序命名空间中部署网关的资源。剩下的工作就是配置网关，以便它将流量路由到你的应用程序。

另存为 [`httpbin-gw.yaml`](../../../assets/howto/httpbin-gw.yaml)，然后使用 `tctl` 应用：

```bash
tctl apply -f httpbin-gw.yaml
```

现在，你可以将两个入口网关服务的 IP 配置为你的 DNS 条目，并在它们之间配置轮询，或者只配置一个 IP 并将另一个集群用作故障切换。

你可以通过运行以下命令测试两个入口网关是否正常工作：

```bash
curl -s -o /dev/null --insecure -w "%{http_code}" \
    "https://httpbin.tetrate.com" \
    --resolve "httpbin.tetrate.com:443:$CLUSTER1_IP"
```

```bash
curl -s -o /dev/null --insecure -w "%{http_code}" \
    "https://httpbin.tetrate.com" \
    --resolve "httpbin.tetrate.com:443:$CLUSTER2_IP"
```