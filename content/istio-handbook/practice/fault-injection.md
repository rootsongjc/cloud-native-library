---
weight: 50
title: 错误注入
date: '2022-05-18T00:00:00+08:00'
type: book
---

在本节中，我们将为推荐服务引入 5 秒的延迟。Envoy 将为 50% 的请求注入延迟。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: recommendationservice
spec:
  hosts:
  - recommendationservice
  http:
  - route:
      - destination:
          host: recommendationservice
    fault:
      delay:
        percentage:
          value: 50
        fixedDelay: 5s
```

将上述 YAML 保存为 `recommendation-delay.yaml`，然后用 `kubectl apply -f recommendation-delay.yaml` 创建 VirtualService。

我们可以在浏览器中打开 `INGRESS_HOST`，然后点击其中一个产品。推荐服务的结果显示在屏幕底部的”Other Products You Might Light“部分。如果我们刷新几次页面，我们会注意到，该页面要么立即加载，要么有一个延迟加载页面。这个延迟是由于我们注入了 5 秒的延迟。

我们可以打开 Grafana（`getmesh istioctl dash grafana`）和 Istio 服务仪表板。确保从服务列表中选择`recommendationsservice`，在 Reporter 下拉菜单中选择 `source`，并查看显示延迟的 **Client Request Duration**，如下图所示。

![Recommendations 服务延迟](../../images/008i3skNly1gtecw2e4wkj61qu0u043002.jpg "Recommendations 服务延迟")

同样地，我们可以注入一个中止。在下面的例子中，我们为发送到产品目录服务的 50% 的请求注入一个 HTTP 500。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: productcatalogservice
spec:
  hosts:
  - productcatalogservice
  http:
  - route:
      - destination:
          host: productcatalogservice
    fault:
      abort:
        percentage:
          value: 50
        httpStatus: 500
```

将上述 YAML 保存为 `productcatalogservice-abort.yaml`，然后用 `kubectl apply -f productcatalogservice-abort.yaml` 更新 VirtualService。

如果我们刷新几次产品页面，我们应该得到如下图所示的错误信息。

![注入错误](../../images/008i3skNly1gtecw01ervj30y30msjup.jpg "注入错误")

请注意，错误信息说，失败的原因是故障过滤器中止。如果我们打开 Grafana（`getmesh istioctl dash grafana`），我们也会注意到图中报告的错误。

我们可以通过运行 `kubectl delete vs productcatalogservice` 来删除 VirtualService。