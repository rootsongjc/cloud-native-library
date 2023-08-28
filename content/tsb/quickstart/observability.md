---
title: 拓扑和指标
weight: 8
---

在本部分中，你将检查 TSB 环境中 bookinfo 演示应用程序的服务拓扑和指标。

## 先决条件

在继续之前，请确保你已完成以下任务：

- 熟悉 TSB 概念。
- 安装 TSB 演示环境。
- 部署 Istio Bookinfo 示例应用程序。
- 创建租户和工作区。
- 创建配置组。
- 配置权限。
- 设置入口网关。

### 生成指标流量

在检查拓扑和指标之前，你需要为 bookinfo 应用程序生成流量以获得有意义的数据。使用提供的脚本生成流量：

将以下脚本保存为 `send-requests.sh` ：

```bash
#!/bin/bash
while true; do
    curl -s https://bookinfo.tetrate.com/productpage > /dev/null
    sleep 1
done
```

使脚本可执行并运行它：

```bash
chmod +x send-requests.sh
./send-requests.sh
```

该脚本每 1 秒向 bookinfo 产品页面发送一个请求，生成指标流量。

### 查看拓扑和指标

现在，你可以在 TSB UI 中检查服务拓扑和指标。

1. 在左侧面板中的“租户”下，选择“仪表板”。
2. 单击选择集群-命名空间。
3. 检查租户 `tetrate` 、命名空间 `bookinfo` 和集群 `demo` 对应的条目。
4. 单击选择。

设置你希望查看的数据的持续时间，并从 TSB UI 的顶部菜单栏启用自动刷新：

- 为你要查看的数据选择时间范围，例如最近 5 分钟。
- 单击“刷新指标”图标可手动重新加载指标或选择刷新间隔以进行自动刷新。

## 拓扑视图

浏览拓扑页面以可视化服务的拓扑图并检查与流量、延迟和错误率相关的指标：

![TSB 仪表板 UI：拓扑视图](../../assets/quickstart/topology.png)

## 指标和追踪

将鼠标悬停在服务实例上可查看更详细的指标，或单击查看全面的细分：

![TSB 仪表板 UI：服务实例指标](../../assets/quickstart/metrics-1.png)

TSB 自动对请求进行采样并收集请求子集的跟踪数据。选择一个服务并单击“跟踪”以列出通过该服务捕获的最新跟踪。你可以探索完整的跟踪来识别流量、时间和错误事件：

![TSB 仪表板 UI：检查跟踪](../../assets/quickstart/trace-1.png)

通过理解来解释跟踪：

- `tsb-gateway-bookinfo.bookinfo` 调用 `productpage.bookinfo.svc.cluster.local:9080` ，调用 `bookinfo` 命名空间中的 `productpage` 服务。
  - `productpage.bookinfo` 首先调用 `details.bookinfo.svc.cluster.local:9080` ，调用 `bookinfo` 命名空间中的 `details` 服务。
  - `productpage.bookinfo` 随后调用 `reviews.bookinfo.svc.cluster.local:9080` ，调用 `bookinfo` 命名空间中的 `reviews` 服务。
    - `reviews.bookinfo` 调用 `ratings.bookinfo.svc.cluster.local:9080` ，调用 `bookinfo` 命名空间中的 `ratings` 服务。

你可以观察调用者进行调用和目标服务读取并响应之间的时间间隔。这些间隔对应于网络调用延迟和网格 sidecar 代理的行为。

对于更复杂的调用图，你可以重新根显示以从内部服务开始，不包括前端网关和其他前端服务。

## 服务仪表板

导航到 TSB UI 中的“服务”窗格，然后选择 TSB 管理的服务之一。这将打开一个包含多个窗格的综合仪表板，允许你深入了解与该特定服务相关的各种指标：

![TSB 服务 UI：检查服务的指标](../../assets/quickstart/services-1.png)
