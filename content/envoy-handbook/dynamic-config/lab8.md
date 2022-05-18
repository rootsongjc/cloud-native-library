---
weight: 40
title: 实验 8：来自文件系统的动态配置
date: '2022-05-18T00:00:00+08:00'
type: book
---

我们将在这个实验中创建一个动态的 Envoy 配置，并通过单独的配置文件配置监听器、集群、路由和端点。

让我们从最小的 Envoy 配置开始。

```yaml
node:
  cluster: cluster-1
  id: envoy-instance-1
dynamic_resources:
  lds_config:
    path: ./lds.yaml
  cds_config:
    path: ./cds.yaml
admin:
  address:
    socket_address:
      address: 127.0.0.1
      port_value: 9901
  access_log:
  - name: envoy.access_loggers.file
    typed_config:
      "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
```

将上述 YAML 保存到 `envoy-proxy-1.yaml` 文件。我们还需要创建空的（暂时的）`cds.yaml` 和 `lds.yaml` 文件。

```sh
touch {cds,lds}.yaml
```

我们现在可以用这个配置来运行 Envoy 代理：`func-e run -c envoy-proxy-1.yaml`。如果我们看一下生成的配置（比如 `localhost:9901/config_dump`），我们会发现它是空的，因为我们没有提供任何监听器或集群。

接下来让我们创建监听器和路由配置。

```yaml
version_info: "0"
resources:
- "@type": type.googleapis.com/envoy.config.listener.v3.Listener
  name: listener_0
  address:
    socket_address:
      address: 0.0.0.0
      port_value: 10000
  filter_chains:
  - filters:
    - name: envoy.filters.network.http_connection_manager
      typed_config:
        "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
        stat_prefix: listener_http
        http_filters:
        - name: envoy.filters.http.router
        rds:
          route_config_name: route_config_1
          config_source:
            path: ./rds.yaml
```

创建一个空的 `rds.yaml` 文件（`touch rds.yaml`），并将上述 YAML 保存为 `lds.yaml`。因为 Envoy 只关注文件路径的移动，所以保存文件不会触发配置重载。为了触发重载，让我们覆盖 `lds.yaml` 文件。

```sh
mv lds.yaml tmp; mv tmp lds.yaml
```

上述命令触发了重载，我们应该从 Envoy 得到以下日志条目：

```sh
[2021-09-07 19:04:06.710][2113][info][upstream] [source/server/lds_api.cc:78] lds: add/update listener 'listener_0'
```

同样，如果我们向 `localhost:10000` 发送请求，我们会得到一个 HTTP 404。

接下来让我们创建 `rds.yaml` 的内容。

```yaml
version_info: "0"
resources:
- "@type": type.googleapis.com/envoy.config.route.v3.RouteConfiguration
  name: route_config_1
  virtual_hosts:
  - name: vh
    domains: ["*"]
    routes:
    - match:
        prefix: "/headers"
      route:
        cluster: instance_1
```

强制重载：

```sh
mv rds.yaml tmp; mv tmp rds.yaml
```

最后，我们还需要对集群进行配置。在这之前，让我们运行一个 httpbin 容器。

```sh
docker run -d -p 5050:80 kennethreitz/httpbin
```

现在我们更新集群（`cds.yaml`）并强制重载（`mv cds.yaml tmp; mv tmp cds.yaml`）：

```yaml
version_info: "0"
resources:
- "@type": type.googleapis.com/envoy.config.cluster.v3.Cluster
  name: instance_1
  connect_timeout: 5s
  load_assignment:
    cluster_name: instance_1
    endpoints:
    - lb_endpoints:
      - endpoint:
          address:
            socket_address:
              address: 127.0.0.1
              port_value: 5050
```

当 Envoy 更新配置时，我们会得到以下日志条目：

```
$ [2021-09-07 19:09:15.582][2113][info][upstream] [source/common/upstream/cds_api_helper.cc:65] cds: added/updated 1 cluster(s), skipped 0 unmodified cluster(s)
```

现在我们可以提出请求并验证流量是否到达集群中定义的端点。

```sh
$ curl localhost:10000/headers
{
  "headers": {
    "Accept": "*/*",
    "Host": "localhost:10000",
    "User-Agent": "curl/7.64.0",
    "X-Envoy-Expected-Rq-Timeout-Ms": "15000"
  }
}
```

注意我们是如何将端点与集群配置在同一个文件中的。我们可以通过单独定义端点（`eds.yaml`）将两者分开。

让我们从创建 `eds.yaml` 文件开始：

```yaml
version_info: "0"
resources:
- "@type": type.googleapis.com/envoy.config.endpoint.v3.ClusterLoadAssignment
  cluster_name: instance_1
  endpoints:
  - lb_endpoints:
    - endpoint:
        address:
          socket_address:
            address: 127.0.0.1
            port_value: 5050
```

将上述 YAML 保存为 `eds.yaml`。

为了使用这个端点文件，我们需要更新集群（`cds.yaml`）以读取 `eds.yaml` 中的端点。

```yaml
version_info: "0"
resources:
- "@type": type.googleapis.com/envoy.config.cluster.v3.Cluster
  name: instance_1
  connect_timeout: 5s
  type: EDS
  eds_cluster_config:
    eds_config:
      path: ./eds.yaml
```

通过运行 `mv cds.yaml tmp; mv tmp cds.yaml` 来强制重载。Envoy 会重新加载配置，我们就可以像以前一样向 `localhost:10000/headers` 发送请求。现在的区别是，不同的配置在不同的文件中，可以分别更新。

{{< cta cta_text="下一章" cta_link="../../listener/" >}}
