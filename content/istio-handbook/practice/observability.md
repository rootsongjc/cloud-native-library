---
weight: 30
title: 部署可观察性工具
date: '2022-05-18T00:00:00+08:00'
type: book
---

接下来，我们将部署可观察性、分布式追踪、数据可视化工具：

```bash
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.10/samples/addons/prometheus.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.10/samples/addons/grafana.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.10/samples/addons/kiali.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.10/samples/addons/extras/zipkin.yaml
```

>如果你在安装 Kiali 的时候发现以下错误 `No matches for kind "MonitoringDashboard" in version "monitoring.kiali.io/v1alpha1"` 请重新运行以上命令。

要从 Google Cloud Shell 打开仪表盘，我们可以运行 `getmesh istioctl dash kiali` 命令，例如，然后点击 Web Preview 按钮，选择仪表盘运行的端口（Kiali 为 `20001`）。如果你使用你的终端，运行 Istio CLI 命令就可以了。

下面是 Boutique 图表在 Kiali 中的样子：

![Boutique 应用在 Kiali 中的样子](../../images/008i3skNly1gtec8rpc6fj60vn0smtb802.jpg "Boutique 应用在 Kiali 中的样子")
