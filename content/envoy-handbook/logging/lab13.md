---
weight: 60
title: 实验 13：使用 gRPC 访问日志服务（ALS）记录日志
date: '2022-05-18T00:00:00+08:00'
type: book
---

本实验涵盖了如何配置 Envoy 使用独立的 gRPC 访问日志服务（ALS）。我们将使用一个[基本的 gRPC 服务器](https://github.com/tetratelabs/envoy-als)，它实现了 `StreamAccessLogs` 函数，并将收到的日志从 Envoy 输出到标准输出。

让我们先把 ALS 服务器作为一个 Docker 容器来运行。

```sh
docker run -dit -p 5000:5000 gcr.io/tetratelabs/envoy-als:0.1.0
```

ALS 服务器默认监听端口为 5000，所以如果我们看一下 Docker 容器的日志，它们应该类似于下面的内容。

```sh
$ docker logs [container-id]
Creating new ALS server
2021/11/05 20:24:03 Listening on :5000
```

输出告诉我们，ALS 正在监听 `5000` 端口。

在 Envoy 配置中，有两个要求需要配置。首先是使用 `access_log` 字段的访问日志和一个名为 `HttpGrpcAccessLogConfig` 的日志类型。其次，在访问日志配置中，我们必须引用 gRPC 服务器。为此定义一个 Envoy 集群。

下面是配置记录器并指向名为 `grpc_als_cluster的` Envoy 集群的片段。

```yaml
...
access_log:
- name: envoy.access_loggers.http_grpc
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.access_loggers.grpc.v3.HttpGrpcAccessLogConfig
    common_config:
      log_name: "mygrpclog"
      transport_api_version: V3
      grpc_service: 
        envoy_grpc:
          cluster_name: grpc_als_cluster
...
```

下一个片段是集群配置，在这一点上我们应该已经很熟悉了。在我们的例子中，我们在同一台机器上运行 gRPC 服务器，端口为 5000。

```yaml
...
  clusters:
    - name: grpc_als_cluster
      connect_timeout: 5s
      type: STRICT_DNS
      http2_protocol_options: {}
      load_assignment:
        cluster_name: grpc_als_cluster
        endpoints:
        - lb_endpoints:
          - endpoint:
              address:
                socket_address:
                  address: 127.0.0.1
                  port_value: 5000
...
```

让我们把这两块放在一起，得出一个使用 gRPC 访问日志服务的 Envoy 配置示例。

```yaml
static_resources:
  listeners:
  - name: listener_0
    address:
      socket_address:
        address: 0.0.0.0
        port_value: 10000
    filter_chains:
    - filters:
      - name: envoy.filters.network.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          stat_prefix: ingress_http
          access_log:
          - name: envoy.access_loggers.http_grpc
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.access_loggers.grpc.v3.HttpGrpcAccessLogConfig
              common_config:
                log_name: "mygrpclog"
                transport_api_version: V3
                grpc_service: 
                  envoy_grpc:
                    cluster_name: grpc_als_cluster
          http_filters:
          - name: envoy.filters.http.router
          route_config:
            name: my_first_route
            virtual_hosts:
            - name: direct_response_service
              domains: ["*"]
              routes:
              - match:
                  prefix: "/404"
                direct_response:
                  status: 404
                  body:
                    inline_string: "404"
              - match:
                  prefix: "/"
                direct_response:
                  status: 200
                  body:
                    inline_string: "200"
  clusters:
    - name: grpc_als_cluster
      connect_timeout: 5s
      type: STRICT_DNS
      http2_protocol_options: {}
      load_assignment:
        cluster_name: grpc_als_cluster
        endpoints:
        - lb_endpoints:
          - endpoint:
              address:
                socket_address:
                  address: 127.0.0.1
                  port_value: 5000
```

将上述 YAML 保存为 `6-lab-2-grpc-als.yaml`，并使用 func-e 启动 Envoy 代理。

```sh
func-e run -c 6-lab-2-grpc-als.yaml &
```

我们正在后台运行 Docker 容器和 Envoy，所以我们现在可以用 `curl` 向 Envoy 代理发送几个请求。

```sh
$ curl localhost:10000
200
```

代理的回应是 `200`，因为那是我们在配置中所定义的。你会注意到没有任何日志输出到标准输出，这是预期的。

要看到这些日志，我们必须看一下 Docker 容器的日志。你可以使用 `docker ps` 来获取容器 ID，然后运行 logs 命令。

```sh
$ docker logs 96f
Creating new ALS server
2021/11/05 20:24:03 Listening on :5000
2021/11/05 20:33:52 Received value
2021/11/05 20:33:52 {"identifier":{"node":{"userAgentName":"envoy","userAgentBuildVersion":{"version":{"majorNumber":1,"minorNumber":20},"metadata":{"fields":{"build.type":{"stringValue":"RELEASE"},"revision.sha":{"stringValue":"96701cb24611b0f3aac1cc0dd8bf8589fbdf8e9e"},"revision.status":{"stringValue":"Clean"},"ssl.version":{"stringValue":"BoringSSL"}}}},"extensions":[{"name":"envoy.matching.common_inputs.environment_variable","category":"envoy.matching.common_inputs"},{"name":"envoy.access_loggers.file","category":"envoy.access_loggers"},{"name":"envoy.access_loggers.http_grpc","category":"envoy.access_loggers"},{"name":"envoy.access_loggers.open_telemetry","category":"envoy.access_loggers"},{"name":"envoy.access_loggers.stderr","category":"envoy.access_loggers"},{"name":"envoy.access_loggers.stdout","category":"envoy.access_loggers"},{"name":"envoy.acc...
...
```

然后我们会注意到从 Envoy 代理发送到我们 gRPC 服务器的日志条目。gRPC 服务器中的代码很简单，只是将收到的值转换为一个字符串并输出。

下面是完整的 `StreamAccessLogs` 函数的样子。

```go
func (s *server) StreamAccessLogs(stream v3.AccessLogService_StreamAccessLogsServer) error {
  for {
    in, err := stream.Recv()
    log.Println("Received value")
    if err == io.EOF {
      return nil
    }
    if err != nil {
      return err
    }
    str, _ := s.marshaler.MarshalToString(in)
    log.Println(str)
  }
}
```

在这一点上，我们可以从收到的数据流中解析具体的数值，并决定如何格式化它们以及将它们发送到哪里。

