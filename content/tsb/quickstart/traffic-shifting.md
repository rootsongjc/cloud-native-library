---
title: 流量转移
weight: 9
---

在此场景中，你将学习如何使用服务路由在演示应用程序中的不同版本的评论服务之间转移流量。

## 先决条件

在继续之前，请确保你已完成以下任务：

- 熟悉 TSB 概念。
- 安装 TSB 演示环境。
- 部署 Istio Bookinfo 示例应用程序。
- 创建租户、工作区、配置组、权限、入口网关，并检查服务拓扑和指标。

## 仅提供 v1 服务

### 使用用户界面

1. 在左侧面板的“租户”下，选择“工作区”。
2. 在 `bookinfo-ws` 工作区卡上，单击“流量组”。
3. 单击你之前创建的 `bookinfo-traffic` 流量组。
4. 选择流量设置选项卡。
5. 在流量设置下，单击服务路由。
6. 单击“添加新...”以使用默认名称 `default-serviceroute` 创建新的服务路由。
7. 将其重命名为 `bookinfo-traffic-reviews` 。
8. 将服务设置为 `bookinfo/reviews.bookinfo.svc.cluster.local` 。
9. 展开 bookinfo-traffic-reviews。
10. 展开子集。
11. 单击“添加新子集...”以创建一个名为 `subset-0` 的新子集。
12. 点击 `subset-0` ：

- 将名称设置为 `v1` 。
- 将权重设置为 `100` 。
- 单击添加标签，并将标签设置为 `version` ，将值设置为 `v1` 。

13.  单击保存更改。

### 使用tctl

创建以下 `reviews.yaml` 文件：

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: ServiceRoute
Metadata:
  organization: tetrate
  name: bookinfo-traffic-reviews
  group: bookinfo-traffic
  workspace: bookinfo-ws
  tenant: tetrate
spec:
  service: bookinfo/reviews.bookinfo.svc.cluster.local
  subsets:
    - name: v1
      labels:
        version: v1
```

使用 `tctl` 应用配置：

```bash
tctl apply -f reviews.yaml
```

### 验证结果

打开 https://bookinfo.tetrate.com/productpage 并刷新页面几次。你将看到仅显示评论 v1（无星级）。

### 在 v1 和 v2 之间拆分流量

### 使用用户界面

1. 选择服务路由的 `v1` 子集。
2. 输入 `50` 作为重量。
3. 单击 `v1` 子集下方的添加新子集...以创建一个名为 `subset-1` 的新子集。
4. 点击 `subset-1` ：
   - 将名称设置为 `v2` 。
   - 输入 `50` 作为重量。
   - 单击添加标签，并将标签设置为 `version` ，将值设置为 `v2` 。
5. 单击保存更改。

### 使用tctl

更新 `reviews.yaml` 文件以在 `v1` 和 `v2` 之间均匀分配流量：

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: ServiceRoute
Metadata:
  organization: tetrate
  name: bookinfo-traffic-reviews
  group: bookinfo-traffic
  workspace: bookinfo-ws
  tenant: tetrate
spec:
  service: bookinfo/reviews.bookinfo.svc.cluster.local
  subsets:
    - name: v1
      labels:
        version: v1
      weight: 50
    - name: v2
      labels:
        version: v2
      weight: 50
```

使用 `tctl` 应用更新的配置：

```bash
tctl apply -f reviews.yaml
```

### 验证结果

再次访问 https://bookinfo.tetrate.com/productpage 并刷新页面多次。你将看到评论在 v1（无星级）和 v2（黑色星级）版本之间切换。

## 仅提供 v2 服务

### 使用用户界面

1. 选择服务路由的 `v1` 子集。
2. 单击“删除 v1”将其删除。
3. 选择服务路由的 `v2` 子集。
4. 将权重设置为 `100` 。
5. 单击保存更改。

### 使用tctl

更新 `reviews.yaml` 文件以将 100% 流量路由到 `v2` 版本：

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: ServiceRoute
Metadata:
  organization: tetrate
  name: bookinfo-traffic-reviews
  group: bookinfo-traffic
  workspace: bookinfo-ws
  tenant: tetrate
spec:
  service: bookinfo/reviews.bookinfo.svc.cluster.local
  subsets:
    - name: v2
      labels:
        version: v2
```

使用 `tctl` 应用更新的配置：

```bash
tctl apply -f reviews.yaml
```

### 验证结果

再次访问 https://bookinfo.tetrate.com/productpage 并刷新页面多次。你将看到仅显示 v2 版本的评论（黑星评级）。

通过执行这些步骤，你已使用 TSB 的服务路由功能成功管理演示应用程序中不同版本的评论服务之间的流量转移。
