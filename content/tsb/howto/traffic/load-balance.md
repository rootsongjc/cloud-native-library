---
title: 客户端负载均衡
description: 如何设置多个副本并在它们之间进行负载均衡。
weight: 3
---

下面的 YAML 文件包含三个对象：
- 用于应用程序的 Workspace
- 用于配置应用程序入口的 GatewayGroup
- 以及一个允许你配置金丝雀发布流程的 TrafficGroup

将文件存储为[`helloworld-ws-groups.yaml`](../../../assets/howto/helloworld-ws-groups.yaml)，并使用`tctl`应用：

<details>
<summary>helloworld-ws-group.yaml</summary>

```yaml
apiversion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: tetrate
  tenant: tetrate
  name: helloworld-ws
spec:
  namespaceSelector:
    names:
      - '*/helloworld'
---
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
  organization: tetrate
  tenant: tetrate
  workspace: helloworld-ws
  name: helloworld-gw
spec:
  namespaceSelector:
    names:
      - '*/helloworld'
  configMode: BRIDGED
---
apiVersion: traffic.tsb.tetrate.io/v2
kind: Group
metadata:
  organization: tetrate
  tenant: tetrate
  workspace: helloworld-ws
  name: helloworld-trf
spec:
  namespaceSelector:
    names:
      - '*/helloworld'
  configMode: BRIDGED
```
</details>

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

<details>
<summary>helloworld-1.yaml</summary>

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helloworld-v1
  namespace: helloworld
spec:
  replicas: 3
  selector:
    matchLabels:
      app: helloworld
      version: v1
  template:
    metadata:
      labels:
        app: helloworld
        version: v1
    spec:
      containers:
        - name: hello
          image: 'gcr.io/google-samples/hello-app:1.0'
          env:
            - name: 'PORT'
              value: '8080'
---
apiVersion: v1
kind: Service
metadata:
  name: helloworld
  namespace: helloworld
spec:
  selector:
    app: helloworld
  ports:
    - protocol: TCP
      port: 443
      targetPort: 8080
```
</details>

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

<details>
<summary>helloworld-ingress.yaml</summary>

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: tsb-helloworld-gateway
  namespace: helloworld
spec:
  kubeSpec:
    service:
      type: LoadBalancer
```
</details>

```bash
kubectl apply -f helloworld-ingress.yaml
```

集群中的 TSB 数据面 Operator 将获取此配置并在你的应用程序命名空间中部署网关的资源。最后，配置网关以将流量路由到你的应用程序。

存储为[`helloworld-gw.yaml`](../../../assets/howto/helloworld-gw.yaml)，并使用`tctl`应用：

<details>
<summary>helloworld-gw.yaml</summary>

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
  name: helloworld-gateway
  group: helloworld-gw
  workspace: helloworld-ws
  tenant: tetrate
  organization: tetrate
spec:
  workloadSelector:
    namespace: helloworld
    labels:
      app: tsb-helloworld-gateway
  http:
    - name: helloworld
      port: 443
      hostname: helloworld.tetrate.com
      tls:
        mode: SIMPLE
        secretName: helloworld-cert
      routing:
        rules:
          - route:
              host: helloworld/helloworld.helloworld.svc.cluster.local
              port: 5000
```
</details>

```bash
tctl apply -f helloworld-gw.yaml
```

你可以通过打开你的网络浏览器并将其指向网关服务的 IP 或域名（根据你的配置而定）来检查你的应用程序是否可访问。

在这一点上，你的应用程序将默认使用轮询进行负载均衡。现在，配置客户端负载均衡并使用源 IP。

另存为[`helloworld-client-lb.yaml`](../../../assets/howto/helloworld-client-lb.yaml)，并使用`tctl`应用：

<details>
<summary>helloworld-client-lb.yaml</summary>

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: ServiceRoute
metadata:
  name: helloworld-client-lb
  group: helloworld-trf
  workspace: helloworld-ws
  tenant: tetrate
  organization: tetrate
spec:
  service: helloworld/helloworld
  subsets:
    - name: v1
      labels:
        version: v1
  stickySession:
    useSourceIp: true
```
</details>

```bash
tctl apply -f helloworld-client-lb.yaml
```

现在，同一 Pod 将被用作所有来自同一 IP 的请求的后端。

在这个示例中，你使用了源 IP，但还有其他允许的方法; 使用 HTTP 请求的头部，或配置 HTTP Cookie。
