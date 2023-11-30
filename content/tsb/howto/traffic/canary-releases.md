---
title: 金丝雀发布
weight: 6
description: 使用 TSB 进行金丝雀发布的指南。
---

本操作指南将向你展示如何对新的示例服务进行金丝雀发布。你将学习如何在 TSB 中部署和注册服务，以及如何调整其设置以遵循金丝雀部署过程。

- 你将创建一个工作区和你需要注册应用程序的组
- 通过应用程序入口网关公开应用程序
- 执行金丝雀发布。

在开始之前，请确保：

- 你已经启动并运行了一个 TSB 管理平面。
- 你已经配置了 tctl 以与 TSB 管理平面通信。
- 你将要部署应用程序的集群正在运行一个 TSB 控制平面，并且已经正确注册到 TSB 管理平面。

本指南使用一个`hello world`应用程序，如果你将其用于生产，请根据你的应用程序的正确信息更新相关字段。

## 开始

以下 YAML 文件包含三个对象 - 用于应用程序的工作区、用于配置应用程序入口的网关组以及用于配置金丝雀发布过程的流量组。将其存储为[`ws-groups.yaml`](../../../assets/howto/ws-groups.yaml)。

<details>
<summary>ws-groups.yaml</summary>

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  name: helloworld
  organization: tetrate
  tenant: tetrate
spec:
  namespaceSelector:
    names:
      - '*/helloworld'
---
apiVersion: traffic.tsb.tetrate.io/v2
kind: Group
metadata:
  name: helloworld-traffic
  workspace: helloworld
  organization: tetrate
  tenant: tetrate
spec:
  namespaceSelector:
    names:
      - '*/helloworld'
---
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
  name: helloworld-gateway
  workspace: helloworld
  organization: tetrate
  tenant: tetrate
spec:
  namespaceSelector:
    names:
      - '*/helloworld'
```
</details>

使用 tctl 应用：

```bash
tctl apply -f ws-groups.yaml
```

要部署你的应用程序，首先创建命名空间并启用 Istio sidecar 注入。

```bash
kubectl create namespace helloworld
kubectl label namespace helloworld istio-injection=enabled
```

然后部署你的应用程序。

将文件存储为[`helloworld.yaml`](../../../assets/howto/helloworld.yaml)，并使用`kubectl`应用：

<details>
<summary>helloworld.yaml</summary>

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helloworld-v1
  namespace: helloworld
spec:
  replicas: 1
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
kubectl apply -f helloworld.yaml
```

在继续之前，你应确保没有流量被意外地定向到应用程序的任何新版本。然后，在你之前创建的流量组中创建一个`ServiceRoute`，以便所有`helloworld`流量仅发送到版本`v1`。

将文件存储为`serviceroute.yaml`，并使用`tctl`应用：

<details>
<summary>serviceroute.yaml</summary>


```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: ServiceRoute
metadata:
  name: helloworld-canary
  group: helloworld-traffic
  workspace: helloworld
  organization: tetrate
  tenant: tetrate
spec:
  service: helloworld/helloworld.helloworld.svc.cluster.local
  subsets:
    - name: v1
      labels:
        version: v1
      weight: 100
```
</details>

```bash
tctl apply -f serviceroute.yaml
```

太棒了！现在你需要让你的应用程序对外可访问。你需要为你的应用程序部署一个入口网关，并配置它将传入的流量路由到我们的应用程序服务。

在这个示例中，你将使用网关的简单 TLS 公开应用程序。你需要为它提供存储在 Kubernetes 秘密中的 TLS 证书。

```bash
kubectl create secret tls -n helloworld helloworld-certs \
    --cert /path/to/some/helloworld-cert.pem \
    --key /path/to/some/helloworld-key.pem
```

现在你可以部署你的入口网关。

将文件存储为[`hello-ingress.yaml`](../../../assets/howto/hello-ingress.yaml)，并使用`kubectl`应用：

<details>
<summary>hello-ingress.yaml</summary>

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: tsb-gateway-helloworld
  namespace: helloworld
spec:
  kubeSpec:
    service:
      type: LoadBalancer
```
</details>

```bash
kubectl apply -f hello-ingress.yaml
```

集群中的 TSB 数据平面 Operator 将获取此配置并在你的应用程序命名空间中部署网关的资源。现在所剩的就是配置网关，以便将流量路由到你的应用程序。

将文件存储为[`helloworld-gateway.yaml`](../../../assets/howto/hello-gateway.yaml)，并使用`tctl`应用：

<details>
<summary>helloworld-gateway.yaml</summary>

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
  name: helloworld-ingress
  group: helloworld-gateway
  workspace: helloworld
  organization: tetrate
  tenant: tetrate
spec:
  workloadSelector:
    namespace: helloworld
    labels:
      app: tsb-gateway-helloworld
  http:
    - name: helloworld
      port: 443
      hostname: helloworld.tetrate.com
      tls:
        mode: SIMPLE
        secretName: helloworld-certs
      routing:
        rules:
          - route:
              host: helloworld/helloworld.helloworld.svc.cluster.local
```
</details>

```bash
tctl apply -f helloworld-gateway.yaml
```

此时，你可以通过向网关服务 IP 发送`helloworld.tetrate.com`的 HTTPS 请求来验证你的应用程序是否可访问。

```bash
curl -k -s --connect-to helloworld.tetrate.com:443:$GATEWAY_IP "https://helloworld.tetrate.com/"
```

现在，你的应用程序正在运行并提供服务请求，部署新版本的应用程序。

将文件存储为[`helloworld-v2.yaml`](../../../assets/howto/helloworld-v2.yaml)，并使用`kubectl`应用：

<details>
<summary>helloworld-v2.yaml</summary>
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helloworld-v2
  namespace: helloworld
spec:
  replicas: 1
  selector:
    matchLabels:
      app: helloworld
      version: v2
  template:
    metadata:
      labels:
        app: helloworld
        version: v2
    spec:
      containers:
        - name: hello
          image: 'gcr.io/google-samples/hello-app:2.0'
          env:
            - name: 'PORT'
              value: '8080'
```
</details>

```bash
kubectl apply -f helloworld-v2.yaml
```

由于你创建了一个针对所有流量发送到版本`v1`的服务路由。在此时，版本`v2`将不会收到任何请求。通过修改服务路由，以将 80% 的流量发送到我们已知的稳定版本`v1`，并将 20% 的流量发送到版本`v2`，开始进行金丝雀发布。

将文件存储为[`serviceroute-20.yaml`](../../../assets/howto/serviceroute-20.yaml)，并使用`tctl`应用：

<details>
<summary>serviceroute-20.yaml</summary>

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: ServiceRoute
metadata:
  name: helloworld-canary
  group: helloworld-traffic
  workspace: helloworld
  organization: tetrate
  tenant: tetrate
spec:
  service: helloworld/helloworld.helloworld.svc.cluster.local
  subsets:
    - name: v1
      labels:
        version: v1
      weight: 80
    - name: v2
      labels:
        version: v2
      weight: 20
```
</details>

```bash
tctl apply -f serviceroute-20.yaml
```

如果你不断使用 Web 浏览器刷新你的应用程序，你会看到大多数请求到达旧的`v1`版本。其他请求将显示新`v2`版本的输出。要完成金丝雀发布，你需要重复此最后一步，直到所有流量都发送到新版本并得到改进（或者如果你发现新版本有问题，可以撤销并将所有流量发送回版本`v1`）。简单！
