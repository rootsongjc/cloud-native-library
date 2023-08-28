---
title: "使用 IngressGateway 和 ServiceRoute 基于子集的流量路由"
weight: 2
---

在本操作指南中，你将了解如何通过基于 URI 端点、标头和端口匹配流量并将其路由到目标服务的`主机:端口`来设置基于子集的流量路由。

## 先决条件

在继续之前，请确保你已完成以下任务：

- 熟悉 [TSB 概念](../../../concepts/)。
- 安装 [TSB 演示环境](../../../setup/self-managed/demo-installation)。
- 创建一个[租户](../../../quickstart/tenant/)。

## 创建工作区和配置组

首先，使用以下 YAML 配置创建工作区和配置组：

<details>
  <summary>helloworld-ws-groups.yaml</summary>

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

将其保存为 `helloworld-ws-groups.yaml` ，并将其与 `tctl` 一起应用：

```bash
tctl apply -f helloworld-ws-groups.yaml
```

## 部署你的应用程序

首先创建命名空间并启用 Istio sidecar 注入：

```bash
kubectl create namespace helloworld
kubectl label namespace helloworld istio-injection=enabled
```

接下来，使用以下 YAML 配置部署你的应用程序：

<details>
  <summary>helloworld-2-subsets.yaml</summary>

```yaml
apiVersion: v1
kind: Service
metadata:
  name: helloworld
  labels:
    app: helloworld
    service: helloworld
spec:
  ports:
    - port: 5000
      name: http
  selector:
    app: helloworld
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helloworld-v1
  labels:
    app: helloworld
    version: v1
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
        - name: helloworld
          image: docker.io/istio/examples-helloworld-v1
          resources:
            requests:
              cpu: '100m'
          imagePullPolicy: IfNotPresent #Always
          ports:
            - containerPort: 5000
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helloworld-v2
  labels:
    app: helloworld
    version: v2
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
        - name: helloworld
          image: docker.io/istio/examples-helloworld-v2
          resources:
            requests:
              cpu: '100m'
          imagePullPolicy: IfNotPresent #Always
          ports:
            - containerPort: 5000
```

</details>

将其保存为 `helloworld-2-subsets.yaml` ，并将其与 `kubectl` 一起应用：

```bash
kubectl apply -f helloworld-2-subsets.yaml -n helloworld
```

## 部署应用程序 IngressGateway

使用以下 YAML 配置部署应用程序 IngressGateway：

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

将其保存为 `helloworld-ingress.yaml` ，并将其与 `kubectl` 一起应用：

```bash
kubectl apply -f helloworld-ingress.yaml
```

获取网关IP：

```bash
export GATEWAY_IP=$(kubectl -n helloworld get service tsb-helloworld-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $GATEWAY_IP
```

## 网关证书

在本例中，你将在网关处使用简单的TLS公开应用程序。你需要为它提供一个存储在Kubernetes密钥中的TLS证书：

```bash
kubectl create secret tls -n helloworld helloworld-cert \
    --cert /path/to/some/helloworld-cert.pem \
    --key /path/to/some/helloworld-key.pem
```

## 部署 IngressGateway 和 ServiceRoute

使用以下 YAML 配置创建 IngressGateway：

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

将其保存为 `helloworld-gw.yaml` ，并将其与 `tctl` 一起应用：

```bash
tctl apply -f helloworld-gw.yaml
```

创建一个 ServiceRoute，根据标头匹配流量并将其路由到不同的子集：

<details>
  <summary>helloworld-header-based-routing-service-route.yaml</summary>

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: ServiceRoute
metadata:
  name: helloworld-service-route
  group: helloworld-trf
  workspace: helloworld-ws
  tenant: tetrate
  organization: tetrate
spec:
  service: helloworld/helloworld.helloworld.svc.cluster.local
  portLevelSettings:
    - port: 5000
      trafficType: HTTP
  subsets:
    - name: v1
      labels:
        version: v1
      weight: 50
    - name: v2
      labels:
        version: v2
      weight: 50
  httpRoutes:
    - name: http-route-match-header-and-port
      match:
        - name: match-header-and-port
          headers:
            end-user:
              exact: jason
          port: 5000
      destination:
        - subset: v1
          weight: 80
          port: 5000
        - subset: v2
          weight: 20
          port: 5000
    - name: http-route-match-port
      match:
        - name: match-port
          port: 5000
      destination:
        - subset: v1
          weight: 100
          port: 5000
```

</details>

将其保存为 `helloworld-header-based-routing-service-route.yaml` ，并将其与 `tctl` 一起应用：

```bash
tctl apply -f helloworld-header-based-routing-service-route.yaml
```

## 验证

###  带标头的请求

发送带有标头 `end-user: jason` 的连续curl请求。流量将以 80:20 的比例在 `v1` 和 `v2` 之间路由。

```bash
for i in {1..20}; do curl -k "https://helloworld.tetrate.com/hello" \
--resolve "helloworld.tetrate.com:443:$GATEWAY_IP" \
-H "end-user: jason" 2>&1; done
```

### 无标头请求

发送不带任何标头的连续卷曲请求。所有流量都将路由到 `v1` 。

```bash
for i in {1..20}; do curl -k "https://helloworld.tetrate.com/hello" \
--resolve "helloworld.tetrate.com:443:$GATEWAY_IP" 2>&1; done
```

通过执行这些步骤，你已使用 IngressGateway 和 ServiceRoute 成功设置基于子集的流量路由。
