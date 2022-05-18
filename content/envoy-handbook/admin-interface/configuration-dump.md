---
weight: 20
title: 配置转储
date: '2022-05-18T00:00:00+08:00'
type: book
---

`/config_dump` 端点是一种快速的方法，可以将当前加载的 Envoy 配置显示为 JSON 序列化的 proto 消息。

Envoy 输出以下组件的配置，并按照下面的顺序排列。

- 自举（bootstrap）
- 集群（clusters）
- 端点（endpoints）
- 监听器（listeners）
- 范围路由（scoped routes）
- 路由（routes）
- 秘密（secrets）

### 包括 EDS 配置

为了输出端点发现服务（EDS）的配置，我们可以在查询中加入 `?include_eds` 参数。

### 筛选输出

同样，我们可以通过提供我们想要包括的资源和一个掩码来过滤输出，以返回一个字段的子集。

例如，为了只输出静态集群配置，我们可以在资源查询参数中使用 `static_clusters` 字段，从 [`ClustersConfigDump` proto](https://www.envoyproxy.io/docs/envoy/latest/api-v3/admin/v3/config_dump.proto#envoy-v3-api-msg-admin-v3-clustersconfigdump) 在 `resource` 查询参数中使用。

```yaml
$ curl localhost:9901/config_dump?resource=static_clusters
{
 "configs": [
  {
   "@type": "type.googleapis.com/envoy.admin.v3.ClustersConfigDump.StaticCluster",
   "cluster": {
    "@type": "type.googleapis.com/envoy.config.cluster.v3.Cluster",
    "name": "instance_1",
  },
  ...
  {
   "@type": "type.googleapis.com/envoy.admin.v3.ClustersConfigDump.StaticCluster",
   "cluster": {
    "@type": "type.googleapis.com/envoy.config.cluster.v3.Cluster",
    "name": "instance_2",
...
```

#### 使用`mask`参数

为了进一步缩小输出范围，我们可以在 `mask` 参数中指定该字段。例如，只显示每个集群的  `connect_timeout`  值。

```yaml
$ curl localhost:9901/config_dump?resource=static_clusters&mask=cluster.connect_timeout
{
 "configs": [
  {
   "@type": "type.googleapis.com/envoy.admin.v3.ClustersConfigDump.StaticCluster",
   "cluster": {
    "@type": "type.googleapis.com/envoy.config.cluster.v3.Cluster",
    "connect_timeout": "5s"
   }
  },
  {
   "@type": "type.googleapis.com/envoy.admin.v3.ClustersConfigDump.StaticCluster",
   "cluster": {
    "@type": "type.googleapis.com/envoy.config.cluster.v3.Cluster",
    "connect_timeout": "5s"
   }
  },
  {
   "@type": "type.googleapis.com/envoy.admin.v3.ClustersConfigDump.StaticCluster",
   "cluster": {
    "@type": "type.googleapis.com/envoy.config.cluster.v3.Cluster",
    "connect_timeout": "1s"
   }
  }
 ]
}
```

#### 使用正则表达式

另一个过滤选项是指定一个正则表达式来匹配加载的配置的名称。例如，要输出所有名称字段与正则表达式 `.*listener.*` 相匹配的监听器，我们可以这样写。

```
$ curl localhost:9901/config_dump?resource=static_clusters&name_regex=.*listener.*

{
 "configs": [
  {
   "@type": "type.googleapis.com/envoy.admin.v3.ListenersConfigDump.StaticListener",
   "listener": {
    "@type": "type.googleapis.com/envoy.config.listener.v3.Listener",
    "name": "listener_0",
    "address": {
     "socket_address": {
      "address": "0.0.0.0",
      "port_value": 10000
     }
    },
    "filter_chains": [
     {}
    ]
   },
   "last_updated": "2021-11-15T20:06:51.208Z"
  }
 ]
}
```

同样，`/init_dump` 端点列出了各种 Envoy 组件的未就绪目标的当前信息。和配置转储一样，我们可以使用 `mask` 查询参数来过滤特定字段。

## 证书

`/certs` 输出所有加载的 TLS 证书。数据包括证书文件名、序列号、主题候补名称和到期前天数。结果是 JSON 格式的，遵循 `admin.v3.Certificates` proto。