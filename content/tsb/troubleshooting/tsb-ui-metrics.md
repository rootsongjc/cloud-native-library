---
title: UI 指标故障排除
Description: 在 TSB 中当指标不可见时进行故障排除。
weight: 5
---

TSB 的用户界面显示了你服务的指标和健康状态。然而，如果没有显示任何指标或跟踪信息，那么你可能面临的问题可能是与你的服务或 TSB 中的某个指标组件之一有关。

本指南将引导你了解问题是与服务还是与 TSB 中的某个指标组件有关的方法。

## 指标

如果你看不到指标，请使用本指南的本节进行故障排除。

首先，请确保你的应用程序中有流量流动。你需要流量来生成指标。

检查你在 TSB 中设置的时间范围窗口是否正确，并且在该期间是否有流量。

![](../../assets/023f435-Tetrate_Service_Bridge.png)

检查在浏览器中运行 UI 查询是否返回状态。使用浏览器的 `inspect` 命令并检查请求/响应详细信息。

从检查器中选择 `Network` 选项卡，然后从 TSB 用户界面中打开你的应用程序。你应该看到浏览器和 TSB 后端之间的所有请求列表。

搜索最后一个 `graphql` 请求。

![](../../assets/71914d4-DevTools_-_35_247_59_43_8443_applications_prune-tenant_dev_bookinfo.png)

![](../../assets/47326cc-DevTools_-_35_247_59_43_8443_applications_prune-tenant_dev_bookinfo-2.png)

如果你看不到查询，这可能表明你的应用程序没有处理任何流量，或者你在 OAP 部署方面存在问题。

要检查 OAP，请执行以下步骤：

通过确认`tsb`命名空间中的`OAP` Pod 是否正在运行来检查`OAP` Pod 是否正常运行，并检查 Pod 的日志中是否有任何错误：

```bash
kubectl -n tsb logs -l app=oap
```

来自日志的错误将帮助你排查问题。

如果问题与 Elasticsearch 有关，请检查控制平面命名空间（istio-system）中的 OAP 是否通过将 OAP Pod 的监视端口转发到你的本地计算机来接收来自各种 Envoy 的访问日志服务（ALS）数据，并使用以下步骤查询一些指标：

在一个 shell 中启动到 OAP 的端口转发：

```bash
kubectl -n istio-system port-forward deployment/oap-deployment 1234
```

如果没有问题，你应该会看到：

```text
Forwarding from 127.0.0.1:1234 -> 1234
Forwarding from [::1]:1234 -> 1234
```

在另一个 shell 中，使用以下命令获取指标：

```bash
curl -s http://localhost:1234/ | grep "envoy_als_in_count"
```

你应该会看到类似于以下示例输出：

```text
envoy_als_in_count{id="router~10.28.0.25~tsb-gateway-7b7fbcdfb7-726bf.bookinfo~bookinfo.svc.cluster.local",cluster="tsb-gateway",} 67492.0
envoy_als_in_count{id="sidecar~10.28.0.19~details-v1-94d5d794-kt76x.bookinfo~bookinfo.svc.cluster.local",cluster="details.bookinfo",} 33747.0
envoy_als_in_count{id="sidecar~10.28.0.23~reviews-v3-5556b6949-pvqfn.bookinfo~bookinfo.svc.cluster.local",cluster="reviews.bookinfo",} 22500.0
envoy_als_in_count{id="sidecar~10.28.0.24~productpage-v1-665ddb5664-ts6pz.bookinfo~bookinfo.svc.cluster.local",cluster="productpage.bookinfo",} 101240.0
envoy_als_in_count{id="sidecar~10.28.0.22~reviews-v2-6cb744f8ff-mf8s6.bookinfo~bookinfo.svc.cluster.local",cluster="reviews.bookinfo",} 22498.0
envoy_als_in_count{id="sidecar~10.28.0.20~ratings-v1-744894fbdb-ctvpd.bookinfo~bookinfo.svc.cluster.local",cluster="ratings.bookinfo",} 22499.0
envoy_als_in_count{id="sidecar~10.28.0.21~reviews-v1-f7c7c7b45-8v2sf.bookinfo~bookinfo.svc.cluster.local",cluster="reviews.bookinfo",} 11249.0
```

如果应用程序正在使用，右侧的数字应该会增加。

如果你看不到任何指标，或者指标随时间不变化，请检查你的应用程序 Sidecar（Envoy）是否通过执行 Istio Sidecar 的`port-forward`在端口 15000 上将 ALS 指标发送到控制平面 OAP，然后查询`envoy_accesslog_service`指标。 `cx_active`指标（即当前连接数）的标准数量是两个。

下面的示例使用`bookinfo`应用程序的`productpage`服务：

```bash
# 在一个shell中启动端口转发
kubectl -n bookinfo port-forward deployment/productpage-v1 15000
Forwarding from 127.0.0.1:15000 -> 15000
Forwarding from [::1]:15000 -> 15000

# 在另一个shell中使用curl获取配置
curl -s http://localhost:15000/clusters | grep "envoy_accesslog_service" | grep cx_active
envoy_accesslog_service::10.31.243.206:11800::cx_active::2
```

如果计数器不符合你的预期，请通过编辑 OAP 的`config.yml`文件，使用以下命令将`debug`日志级别添加到 OAP 中：

```bash
kubectl -n istio-system edit cm oap-config
```

搜索以下行并去掉注释：

```xml
<!-- uncomment following line when need to debug ALS raw data
   <logger name="io.tetrate.spm.user.receiver

.envoy" level="DEBUG"/>
-->
```

以使其变成：

```xml
<logger name="io.tetrate.spm.user.receiver.envoy" level="DEBUG"/>
```

然后，重新启动 OAP 以使配置更改生效：

```bash
kubectl -n istio-system delete pod -l app=oap
```

现在，你可以搜索`downstream_remote_address`的日志。如果你有可搜索的日志，这意味着指标已经到达了 OAP 服务。

- 在 Elasticsearch 后端中搜索<br/>
  指标存储在 Elasticsearch（ES）索引中。你可以通过发送一些查询来检查 ES 的状态和健康状况。<br/>

由于 ES 服务器不受 TSB 管理，请参考你的文档以获取正确的连接字符串。<br/>

在示例中，我们将端口转发到`tsb`命名空间中的 ES Pod：

```bash
# 端口转发到ES服务器
kubectl -n tsb port-forward statefulset/elasticsearch 9200

# 检查集群健康状况
curl -s  'http://localhost:9200/_cluster/health?pretty=true'
{
    "cluster_name" : "elasticsearch",
    "status" : "yellow",
    "timed_out" : false,
    "number_of_nodes" : 1,
    "number_of_data_nodes" : 1,
    "active_primary_shards" : 64,
    "active_shards" : 64,
    "relocating_shards" : 0,
    "initializing_shards" : 0,
    "unassigned_shards" : 5,
    "delayed_unassigned_shards" : 0,
    "number_of_pending_tasks" : 0,
    "number_of_in_flight_fetch" : 0,
    "task_max_waiting_in_queue_millis" : 0,
    "active_shards_percent_as_number" : 92.7536231884058
}
```

`status` 行应该是绿色或黄色的。如果是红色的，那么问题就出在 ES 集群上。你可以使用以下命令检查索引的状态：

```bash
# 查询2020年3月26日的索引状态
curl -H'Content-Type: application/json' -s -XGET 'http://localhost:9200/_cat/shards/*20200326
```

你应该会看到所有索引的列表。它们都应该处于`STARTED`状态。下一列包含文档数和索引大小。通过在不同时间运行该命令，你应该会看到这些数字增加。

```
service_5xx-20200326                                 0 p STARTED  31236   1.4mb 10.28.1.12 elasticsearch-0
service_instance_relation_client_call_sla-20200326   0 p STARTED  53791   5.1mb 10.28.1.12 elasticsearch-0
endpoint_percentile-20200326                         0 p STARTED 128707  12.7mb 10.28.1.12 elasticsearch-0
endpoint_2xx-20200326                                0 p STARTED 123131   7.4mb 10.28.1.12 elasticsearch-0
...
```
