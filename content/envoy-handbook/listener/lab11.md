---
weight: 100
title: 实验 11：匹配传输和应用协议
date: '2022-05-18T00:00:00+08:00'
type: book
---

在这个实验中，我们将学习如何使用 TLS 检查器过滤器来选择一个特定的过滤器链。单个过滤器链将根据 `transport_protocol` 和 `application_protocol将`流量分配到不同的上游集群。

我们将为我们的上游主机使用 `mendhak/http-https-echo` Docker 镜像。这些容器可以被配置为监听 HTTP/HTTPS 并将响应回传。

我们将运行镜像的三个实例来代表非 TLS HTTP、TLS HTTP/1.1 和 TLS HTTP/2 协议。

```sh
# non-TLS HTTP
docker run -dit -p 8080:8080 -t mendhak/http-https-echo:18

# TLS HTTP1.1
docker run -dit -e HTTPS_PORT=443 -p 443:443 -t mendhak/http-https-echo:18

# TLS HTTP2
docker run -dit -e HTTPS_PORT=8443 -p 8443:8443 -t mendhak/http-https-echo:18
```

为了确保这三个容器都在运行，我们可以用 curl 发送几个请求，看看是否得到了回应。从输出中，我们还可以检查主机名是否与实际的 Docker 容器 ID 相符。

```sh
# non-TLS HTTP
$ curl http://localhost:8080
{
  "path": "/",
  "headers": {
    "host": "localhost:8080",
    "user-agent": "curl/7.64.0",
    "accept": "*/*"
  },
  "method": "GET",
  "body": "",
  "fresh": false,
  "hostname": "localhost",
  "ip": "::ffff:172.18.0.1",
  "ips": [],
  "protocol": "http",
  "query": {},
  "subdomains": [],
  "xhr": false,
  "os": {
    "hostname": "100db0dce742"
  },
  "connection": {}
}
```

> 注意在向其他两个容器发送请求时，我们将使用 `-k` 标志来告诉 curl 跳过对服务器 TLS 证书的验证。此外，我们可以使用 `--http1.1` 和 `--http2` 标志来发送 HTTP1.1 或 HTTP2 请求。

```sh
# HTTP1.1
$ curl -k --http1.1 https://localhost:443
{
  "path": "/",
  "headers": {
    "host": "localhost",
    "user-agent": "curl/7.64.0",
    "accept": "*/*"
  },
  "method": "GET",
  "body": "",
  "fresh": false,
  "hostname": "localhost",
  "ip": "::ffff:172.18.0.1",
  "ips": [],
  "protocol": "https",
  "query": {},
  "subdomains": [],
  "xhr": false,
  "os": {
    "hostname": "51afc40f7506"
  },
  "connection": {
    "servername": "localhost"
  }
}

$ curl -k --http2 https://localhost:8443
{
  "path": "/",
  "headers": {
    "host": "localhost:8443",
    "user-agent": "curl/7.64.0",
    "accept": "*/*"
  },
  "method": "GET",
  "body": "",
  "fresh": false,
  "hostname": "localhost",
  "ip": "::ffff:172.18.0.1",
  "ips": [],
  "protocol": "https",
  "query": {},
  "subdomains": [],
  "xhr": false,
  "os": {
    "hostname": "40e7143e6a55"
  },
  "connection": {
    "servername": "localhost"
  }
}
```

一旦我们验证了容器的正确运行，我们就可以创建 Envoy 配置。我们将使用 `tls_inspector` 和 `filter_chain_match` 字段来检查传输协议是否是 TLS，以及应用协议是否是 HTTP1.1（`http/1.1`）或 HTTP2（`h2）`。基于这些信息，我们会有不同的集群，将流量转发到上游主机（Docker 容器）。记住 HTTP 运行在端口 `8080`，TLS HTTP/1.1 运行在端口 `443`，TLS HTTP2 运行在端口 `8443`。

```yaml
static_resources:
  listeners:
  - address:
      socket_address:
        address: 0.0.0.0
        port_value: 10000
    listener_filters:
    - name: "envoy.filters.listener.tls_inspector"
      typed_config:
        "@type": type.googleapis.com/envoy.extensions.filters.listener.tls_inspector.v3.TlsInspector
    filter_chains:
    - filter_chain_match:
        # Match TLS and HTTP2
        transport_protocol: tls
        application_protocols: [h2]
      filters:
      - name: envoy.filters.network.tcp_proxy
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
          cluster: service-tls-http2
          stat_prefix: https_passthrough
    - filter_chain_match:
        # Match TLS and HTTP1.1
        transport_protocol: tls
        application_protocols: [http/1.1]
      filters:
      - name: envoy.filters.network.tcp_proxy
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
          cluster: service-tls-http1.1
          stat_prefix: https_passthrough
    - filter_chain_match:
      # No matches here, go to HTTP upstream
      filters:
      - name: envoy.filters.network.tcp_proxy
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
          cluster: service-http
          stat_prefix: ingress_http
  clusters:
  - name: service-tls-http2
    type: STRICT_DNS
    lb_policy: ROUND_ROBIN
    load_assignment:
      cluster_name: service-tls-http2
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: 127.0.0.1
                port_value: 8443
  - name: service-tls-http1.1
    type: STRICT_DNS
    lb_policy: ROUND_ROBIN
    load_assignment:
      cluster_name: service-tls-http1.1
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: 127.0.0.1
                port_value: 443
  - name: service-http
    type: STRICT_DNS
    lb_policy: ROUND_ROBIN
    load_assignment:
      cluster_name: service-http
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: 127.0.0.1
                port_value: 8080
admin:
  address:
    socket_address:
      address: 0.0.0.0
      port_value: 9901
```

将上述 YAML 保存为 `tls.yaml`，并使用 `func-e run -c tls.yaml` 运行它。

为了测试这一点，我们可以像以前一样发出类似的 curl 请求，并检查主机名是否与正在运行的 Docker 容器相符。

```sh
$ curl http://localhost:10000 | jq '.os.hostname'
"100db0dce742"

$ curl -k --http1.1 https://localhost:10000 | jq '.os.hostname'
"51afc40f7506"

$ curl -k --http2 https://localhost:10000 | jq '.os.hostname'
"40e7143e6a55"
```

另外，我们可以检查各个容器的日志，看看请求是否被正确发送。

{{< cta cta_text="下一章" cta_link="../../logging/" >}}
