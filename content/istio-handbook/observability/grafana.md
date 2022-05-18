---
weight: 30
title: Grafana
date: '2022-05-18T00:00:00+08:00'
type: book
---

[Grafana](https://grafana.com/) 是一个用于分析和监控的开放平台。Grafana 可以连接到各种数据源，并使用图形、表格、热图等将数据可视化。通过强大的查询语言，你可以定制现有的仪表盘并创建更高级的可视化。

通过 Grafana，我们可以监控 Istio 安装和服务网格中运行的应用程序的健康状况。

我们可以使用 `grafana.yaml` 来部署带有预配置仪表盘的 Grafana 示例安装。该 YAML 文件在 Istio 安装包的 `/samples/addons` 下。

确保在部署 Grafana 之前部署 Promeheus 插件，因为 Grafana 使用 Prometheus 作为其数据源。

运行下面的命令来部署 Grafana 和预配置的仪表盘：

```sh
$ kubectl apply -f istio-1.9.0/samples/addons/grafana.yaml
serviceaccount/grafana created
configmap/grafana created
service/grafana created
deployment.apps/grafana created
configmap/istio-grafana-dashboards created
configmap/istio-services-grafana-dashboards created
```

> 我们不打算在生产中运行这个 Grafana，因为它没有经过性能或安全方面的优化。

Kubernetes 将 Grafana 部署在 `istio-system` 命名空间。要访问 Grafana，我们可以使用 `istioctl dashboard` 命令。

```sh
$ istioctl dashboard grafana
http://localhost:3000
```

我们可以在浏览器中打开 `http://localhost:3000`，进入 Grafana。然后，点击首页和 Istio 文件夹，查看已安装的仪表板，如下图所示。

![Grafana 仪表板](../../images/008i3skNly1gsxzlwj8nhj60i50hoq3q02.jpg "Grafana 仪表板")

Istio Grafana 安装时预配置了以下仪表板：

**1. Istio 控制平面仪表板**

从 Istio 控制平面仪表板，我们可以监控 Istio 控制平面的健康和性能。

![Istio 控制平面仪表板](../../images/008i3skNly1gsxzp9t40gj30vu0ss41r.jpg "Istio 控制平面仪表板")

这个仪表板将向我们显示控制平面的资源使用情况（内存、CPU、磁盘、Go routines），以及关于 Pilot 、Envoy 和 Webhook 的信息。

**2. Istio 网格仪表板**

网格仪表盘为我们提供了在网格中运行的所有服务的概览。仪表板包括全局请求量、成功率以及 4xx 和 5xx 响应的数量。

![Istio 网格仪表板](../../images/008i3skNly1gsxztuxt4sj30su0rfgny.jpg "Istio 网格仪表板")

**3. Istio 性能仪表板**

性能仪表盘向我们展示了 Istio 主要组件在稳定负载下的资源利用率。

![Istio 性能仪表板](../../images/008i3skNly1gsxzvfrchmj30rw0um41m.jpg "Istio 性能仪表板")

**4. Istio 服务仪表板**

服务仪表板允许我们在网格中查看关于我们服务的细节。

我们可以获得关于请求量、成功率、持续时间的信息，以及显示按来源和响应代码、持续时间和大小的传入请求的详细图表。

![Istio 服务仪表板](../../images/008i3skNly1gsxzz72kwzj30rw0umq6r.jpg "Istio 服务仪表板")

**5. Istio Wasm 扩展仪表板**

Istio Wasm 扩展仪表板显示与 WebAssembly 模块有关的指标。从这个仪表板，我们可以监控活动的和创建的 Wasm 虚拟机，关于获取删除 Wasm 模块和代理资源使用的数据。

![Istio Wasm 扩展仪表板](../../images/008i3skNly1gtcuxkthdpj60ua0u0mzk02.jpg "Istio Wasm 扩展仪表板")

**6. Istio 工作负载仪表板**

这个仪表板为我们提供了一个工作负载的详细指标分类。

![Istio 工作负载仪表板](../../images/008i3skNly1gsy00w9qlxj30rw0umq65.jpg "Istio 工作负载仪表板")
