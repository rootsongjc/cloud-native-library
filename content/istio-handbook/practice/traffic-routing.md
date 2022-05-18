---
weight: 40
title: 路由流量
date: '2022-05-18T00:00:00+08:00'
type: book
---

我们已经建立了一个新的 Docker 镜像，它使用了与当前运行的前端服务不同的标头。让我们看看如何部署所需的资源并将一定比例的流量路由到不同的前端服务版本。

在我们创建任何资源之前，让我们删除现有的前端部署（`kubectl delete deploy frontend`），并创建一个版本标签设置为 `original` 。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  selector:
    matchLabels:
      app: frontend
      version: original
  template:
    metadata:
      labels:
        app: frontend
        version: original
      annotations:
        sidecar.istio.io/rewriteAppHTTPProbers: "true"
    spec:
      containers:
        - name: server
          image: gcr.io/google-samples/microservices-demo/frontend:v0.2.1
          ports:
          - containerPort: 8080
          readinessProbe:
            initialDelaySeconds: 10
            httpGet:
              path: "/_healthz"
              port: 8080
              httpHeaders:
              - name: "Cookie"
                value: "shop_session-id=x-readiness-probe"
          livenessProbe:
            initialDelaySeconds: 10
            httpGet:
              path: "/_healthz"
              port: 8080
              httpHeaders:
              - name: "Cookie"
                value: "shop_session-id=x-liveness-probe"
          env:
          - name: PORT
            value: "8080"
          - name: PRODUCT_CATALOG_SERVICE_ADDR
            value: "productcatalogservice:3550"
          - name: CURRENCY_SERVICE_ADDR
            value: "currencyservice:7000"
          - name: CART_SERVICE_ADDR
            value: "cartservice:7070"
          - name: RECOMMENDATION_SERVICE_ADDR
            value: "recommendationservice:8080"
          - name: SHIPPING_SERVICE_ADDR
            value: "shippingservice:50051"
          - name: CHECKOUT_SERVICE_ADDR
            value: "checkoutservice:5050"
          - name: AD_SERVICE_ADDR
            value: "adservice:9555"
          - name: ENV_PLATFORM
            value: "gcp"
          resources:
            requests:
              cpu: 100m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 128Mi
```

将以上文件存储为 `frontend-original.yaml` 并使用 `kubectl apply -f frontend-original.yaml` 命令创建部署。

现在我们准备创建一个 DestinationRule，定义两个版本的前端——现有的（`original`）和新的（`v1`）。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: frontend
spec:
  host: frontend.default.svc.cluster.local
  subsets:
    - name: original
      labels:
        version: original
    - name: v1
      labels:
        version: 1.0.0
```

将上述 YAML 保存为 `frontend-dr.yaml`，并使用 `kubectl apply -f frontend-dr.yaml` 创建它。

接下来，我们将更新 VirtualService，并指定将所有流量路由到的子集。在这种情况下，我们将把所有流量路由到原始版本的前端。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: frontend-ingress
spec:
  hosts:
    - '*'
  gateways:
    - frontend-gateway
  http:
  - route:
    - destination:
        host: frontend
        port:
          number: 80
        subset: original
```

将上述 YAML 保存为 `frontend-vs.yaml`，并使用 `kubectl apply -f frontend-vs.yaml` 更新 VirtualService 资源。

现在我们将 VirtualService 配置为将所有进入的流量路由到 `original` 子集，我们可以安全地创建新的前端部署。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-v1
spec:
  selector:
    matchLabels:
      app: frontend
      version: 1.0.0
  template:
    metadata:
      labels:
        app: frontend
        version: 1.0.0
      annotations:
        sidecar.istio.io/rewriteAppHTTPProbers: "true"
    spec:
      containers:
        - name: server
          image: gcr.io/tetratelabs/boutique-frontend:1.0.0
          ports:
          - containerPort: 8080
          readinessProbe:
            initialDelaySeconds: 10
            httpGet:
              path: "/_healthz"
              port: 8080
              httpHeaders:
              - name: "Cookie"
                value: "shop_session-id=x-readiness-probe"
          livenessProbe:
            initialDelaySeconds: 10
            httpGet:
              path: "/_healthz"
              port: 8080
              httpHeaders:
              - name: "Cookie"
                value: "shop_session-id=x-liveness-probe"
          env:
          - name: PORT
            value: "8080"
          - name: PRODUCT_CATALOG_SERVICE_ADDR
            value: "productcatalogservice:3550"
          - name: CURRENCY_SERVICE_ADDR
            value: "currencyservice:7000"
          - name: CART_SERVICE_ADDR
            value: "cartservice:7070"
          - name: RECOMMENDATION_SERVICE_ADDR
            value: "recommendationservice:8080"
          - name: SHIPPING_SERVICE_ADDR
            value: "shippingservice:50051"
          - name: CHECKOUT_SERVICE_ADDR
            value: "checkoutservice:5050"
          - name: AD_SERVICE_ADDR
            value: "adservice:9555"
          - name: ENV_PLATFORM
            value: "gcp"
          resources:
            requests:
              cpu: 100m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 128Mi
```

将上述 YAML 保存为 `frontend-v1.yaml`，然后用 `kubectl apply -f frontend-v1.yaml` 创建它。

如果我们在浏览器中打开 `INGRESS_HOST`，我们仍然会看到原始版本的前端。让我们更新 VirtualService 中的权重，开始将 30% 的流量路由到 v1 的子集。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: frontend-ingress
spec:
  hosts:
    - '*'
  gateways:
    - frontend-gateway
  http:
  - route:
    - destination:
        host: frontend
        port:
          number: 80
        subset: original
      weight: 70
    - destination:
        host: frontend
        port:
          number: 80
        subset: v1
      weight: 30
```

将上述 YAML 保存为 `frontend-30.yaml`，然后用 `kubectl apply -f frontend-30.yaml` 更新 VirtualService。

如果我们刷新几次网页，我们会注意到来自前端 v1 的更新标头，看起来像下图中的样子。

![更新后的Header](../../images/008i3skNly1gteccmga5mj60aa031mx302.jpg "更新后的Header")

如果我们打开 Kiali 并点击 Graph，我们会发现有两个版本的前端在运行，如下图所示。

![在 Kiali 中有两个版本](../../images/008i3skNly1gteccjeuy9j30fs0aswf4.jpg "在 Kiali 中有两个版本")