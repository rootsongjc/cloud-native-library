---
title: 客户端负载均衡
description: 如何设置多个副本并在它们之间进行负载均衡。
weight: 3
---

下面的 YAML 文件包含三个对象 - 一个用于应用程序的"工作空间"，一个用于配置应用程序入口的"网关组"，以及一个允许你配置金丝雀发布流程的"流量组"。

将文件存储为[`helloworld-ws-groups.yaml`](../../../assets/howto/helloworld-ws-groups.yaml)，并使用`tctl`应用：

```bash
tctl apply -f helloworld-ws-groups.yaml
```

要部署你的应用程序，首先创建命名空间并启用 Istio sidecar 注入。

```bash
kubectl create namespace helloworld
kubectl label namespace helloworld istio-injection=enabled
```

然后部署你的应用程序。

存储为[`helloworld-1.yaml`](../../../assets/howto/helloworld-1.yaml)，并使用`kubectl`应用：

```bash
kubectl apply -f helloworld-1.yaml
```

请注意，此部署将使用 3 个副本。

在这个示例中，你将使用网关以简单的 TLS 方式公开应用程序。你需要提供一个 TLS 证书，将其存储在 Kubernetes 的一个密钥保管库中。

```bash
kubectl create secret tls -n helloworld helloworld-cert \
    --cert /path/to/some/helloworld-cert.pem \
    --key /path/to/some/helloworld-key.pem
```

现在你可以部署你的入口网关。

另存为[`helloworld-ingress.yaml`](../../../assets/howto/helloworld-ingress.yaml)，并使用`kubectl`应用：

```bash
kubectl apply -f helloworld-ingress.yaml
```

集群中的 TSB 数据面操作员将获取此配置并在你的应用程序命名空间中部署网关的资源。最后，配置网关以将流量路由到你的应用程序。

存储为[`helloworld-gw.yaml`](../../../assets/howto/helloworld-gw.yaml)，并使用`tctl`应用：
```bash
tctl apply -f helloworld-gw.yaml
```

你可以通过打开你的网络浏览器并将其指向网关服务的 IP 或域名（根据你的配置而定）来检查你的应用程序是否可访问。

在这一点上，你的应用程序将默认使用轮询进行负载均衡。现在，配置客户端负载均衡并使用源 IP。

另存为[`helloworld-client-lb.yaml`](../../../assets/howto/helloworld-client-lb.yaml)，并使用`tctl`应用：

```bash
tctl apply -f helloworld-client-lb.yaml
```

现在，同一 Pod 将被用作所有来自同一 IP 的请求的后端。

在这个示例中，你使用了源 IP，但还有其他允许的方法; 使用 HTTP 请求的头部，或配置 HTTP Cookie。
