---
weight: 90
title: 实验 10：TLS 检查器过滤器
date: '2022-05-18T00:00:00+08:00'
type: book
---

在这个实验中，我们将看一个例子，说明我们如何设置 Envoy，以便在一个 IP 地址上用不同的证书为多个网站服务。

我们将使用自签名的证书进行测试，但如果使用真实签名的证书，其过程是相同的。

使用 `openssl`，我们将在 `certs` 文件夹中为 `www.hello.com` 和 `www.example.com` 创建自签名证书。

```sh
$ mkdir certs && cd certs

$ openssl req -nodes -new -x509 -keyout www_hello_com.key -out www_hello_com.cert -subj "/C=US/ST=Washington/L=Seattle/O=Hello LLC/OU=Org/CNwww.hello.com"

$ openssl req -nodes -new -x509 -keyout www_example_com.key -out www_example_com.cert -subj "/C=US/ST=Washington/L=Seattle/O=Example LLC/OU=Org/CN www.example.com"
```

对于每个通用名称，我们最终会有两个文件：私钥和证书（例如，`www_example_com.key` 和 `www_example_com.cert`）。

我们将为每个过滤链的匹配分别配置 `transport_socket` 字段。下面是一个如何定义 TLS 传输套接字并提供密钥和证书的片段。

```yaml
...
      transport_socket:
        name: envoy.transport_sockets.tls
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.DownstreamTlsContext
          common_tls_context:
            tls_certificates:
            - certificate_chain:
                filename: certs/www_hello_com.cert
              private_key:
                filename: certs/www_hello_com.key
...
```

因为我们想根据 SNI 使用不同的证书，我们将在 TLS 监听器中添加一个 TLS 检查器过滤器，使用 `filter_chain_match` 和 `server_names` 字段来根据 SNI 进行匹配。

下面是两个过滤链匹配部分：注意每个过滤链匹配都有自己的 `transport_socket`，有指向证书和密钥文件的指针。

```yaml
    listener_filters:
      - name: "envoy.filters.listener.tls_inspector"
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.listener.tls_inspector.v3.TlsInspector
    filter_chains:
    - filter_chain_match:
        server_names: "www.example.com"
      filters:
        transport_socket:
          name: envoy.transport_sockets.tls
          ...
        http:filters:
          ...
    - filter_chain_match:
        server_names: "www.hello.com"
      filters:
        transport_socket:
          name: envoy.transport_sockets.tls
          ...
        http:filters:
          ...
```

你可以在 `5-lab-2-tls_match.yaml` 文件中找到完整的配置，用 `func-e run -c 5-lab-2-tls_match.yaml` 运行它。由于我们将只使用 `openssl` 进行连接，我们不需要集群端点的运行。

为了检查 SNI 匹配是否正常工作，我们可以使用 `openssl` 并连接到提供服务器名称的 Envoy 监听器。例如：

```yaml
$ openssl s_client -connect 0.0.0.0:443 -servername www.example.com
CONNECTED(00000003)
depth=0 C = US, ST = Washington, L = Seattle, O = Example LLC, OU = Org, CN = www.example.com
verify error:num=18:self signed certificate
verify return:1
depth=0 C = US, ST = Washington, L = Seattle, O = Example LLC, OU = Org, CN = www.example.com
verify return:1
---
Certificate chain
 0 s:C = US, ST = Washington, L = Seattle, O = Example LLC, OU = Org, CN = www.example.com
   i:C = US, ST = Washington, L = Seattle, O = Example LLC, OU = Org, CN = www.example.com
...
```

该命令将根据所提供的服务器名称返回正确的对等证书。

