---
weight: 20
title: 部署 Online Boutique 应用
date: '2022-05-18T00:00:00+08:00'
type: book
---

在集群和 Istio 准备好后，我们可以克隆在 Online Boutique 应用库。

**1. 克隆仓库**

```bash
git clone https://github.com/GoogleCloudPlatform/microservices-demo.git
```

**2. 前往  `microservices-demo` 目录**

```bash
cd microservices-demo
```

**3. 创建 Kubernetes 资源**

```bash
kubectl apply -f release/kubernetes-manifests.yaml
```

**4. 检查所有 Pod 都在运行**

```bash
$ kubectl get pods
NAME                                     READY   STATUS    RESTARTS   AGE
adservice-5c9c7c997f-n627f               2/2     Running   0          2m15s
cartservice-6d99678dd6-767fb             2/2     Running   2          2m16s
checkoutservice-779cb9bfdf-l2rs9         2/2     Running   0          2m18s
currencyservice-5db6c7d559-9drtc         2/2     Running   0          2m16s
emailservice-5c47dc87bf-dk7qv            2/2     Running   0          2m18s
frontend-5fcb8cdcdc-8c9dk                2/2     Running   0          2m17s
loadgenerator-79bff5bd57-q9qkd           2/2     Running   4          2m16s
paymentservice-6564cb7fb9-f6dwr          2/2     Running   0          2m17s
productcatalogservice-5db9444549-hkzv7   2/2     Running   0          2m17s
recommendationservice-ff6878cf5-jsghw    2/2     Running   0          2m18s
redis-cart-57bd646894-zb7ch              2/2     Running   0          2m15s
shippingservice-f47755f97-dk7k9          2/2     Running   0          2m15s
```

**5. 创建 Istio 资源**

```bash
kubectl apply -f ./istio-manifests
```

部署了一切后，我们就可以得到入口网关的 IP 地址并打开前端服务：

```bash
INGRESS_HOST="$(kubectl -n istio-system get service istio-ingressgateway \
   -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
echo "$INGRESS_HOST"
```

在浏览器中打开 `INGRESS_HOST`，你会看到前端服务，如下图所示。

![前端服务](../../images/008i3skNly1gtec50smyvj60x10u0q7g02.jpg "前端服务")

我们需要做的最后一件事是删除 `frontend-external` 服务。`frontend-external` 服务是一个 LoadBalancer 服务，它暴露了前端。由于我们正在使用 Istio 的入口网关，我们不再需要这个 LoadBalancer 服务了。

要删除服务，运行：

```sh
kubectl delete svc frontend-external
```

Online Boutique 应用清单还包括一个负载发生器，它正在生成对所有服务的请求——这是为了让我们能够模拟网站的流量。