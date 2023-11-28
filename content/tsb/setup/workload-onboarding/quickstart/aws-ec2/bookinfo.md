---
title: 安装 Bookinfo 示例
weight: 1
---

为了演示在 Kubernetes 之外部署的工作负载如何与网格的其余部分集成，我们需要有其他应用程序可以与之通信。

在本指南中，你需要部署 [Istio Bookinfo](https://istio.io/latest/docs/examples/bookinfo/) 示例到你的 Kubernetes 集群中。

## 部署 Bookinfo 示例

创建命名空间 `bookinfo`，并添加正确的标签：

```bash
kubectl create namespace bookinfo
kubectl label namespace bookinfo istio-injection=enabled
```

部署 bookinfo 应用程序：

```bash
cat <<EOF | kubectl apply -n bookinfo -f -
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
spec:
  mtls:
    mode: STRICT
EOF

kubectl apply -n bookinfo -f https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/platform/kube/bookinfo.yaml

kubectl wait --for=condition=Available -n bookinfo deployments --all
```

为了从本地环境向 `bookinfo` 产品页面发送请求，你需要设置端口转发。

在单独的终端会话中运行以下命令：

```bash
kubectl port-forward -n bookinfo service/productpage 9080
```

产品页面将在 `http://localhost:9080` 上可访问。
要在可视上验证产品页面，请在浏览器中打开 `http://localhost:9080/productpage`。
如果多次刷新页面，你应该在页面上看到 3 次中有 2 次出现评分星级。

或者，要从命令行验证，请运行：

```bash
for i in `seq 1 9`; do
  curl -fsS "http://localhost:9080/productpage?u=normal" | grep "glyphicon-star" | wc -l | awk '{print $1" stars on the page"}'
done
```

3 次中有 2 次应该会得到消息 `10 stars on the page`：

```bash
10 stars on the page
0 stars on the page
10 stars on the page
```

## 缩减 `ratings` 应用程序

在本指南中，你将通过 VM 通过工作负载入网部署 `ratings` 应用程序。为了做到这一点，我们必须首先“禁用”与
bookinfo 示例一起部署的默认 `ratings` 应用程序。

运行以下命令并将 `ratings` 应用程序的副本数减少到 0：

```bash
kubectl scale deployment ratings-v1 -n bookinfo --replicas=0

kubectl wait --for=condition=Available -n bookinfo deployment/ratings-v1
```

要验证 `ratings` 应用程序已经被缩减，并且不再显示在产品页面上，请按照上一节中的说明访问产品页面。三次中的两次应该会看到消息 `Ratings service is currently unavailable`。
