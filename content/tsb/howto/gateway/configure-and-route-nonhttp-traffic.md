---
title: 配置和路由 TSB 中的 HTTP、非 HTTP（多协议）和多端口服务流量
description: 配置使用 TSB 的非 HTTP 服务器的指南，以及在网关中配置 HTTP 和非 HTTP（多端口、多协议）服务器。
weight: 12
---

本操作指南将向你展示如何配置 TSB 中的非 HTTP 服务器。阅读本文档后，你应该熟悉在 `IngressGateway` 和 `Tier1Gateway` API 中使用 TCP 部分的方法。

## 概要
工作流程与配置 `IngressGateway` 和 `Tier1Gateway` 中的 HTTP 服务器完全相同。但是，非 HTTP 支持多端口服务。

在开始之前，请确保你已经：
- 熟悉 [TSB 概念](../../../concepts/)
- 熟悉 [载入集群](../../../setup/self-managed/onboarding-clusters)
- 创建了 [租户](../../../quickstart/tenant)

## 设置
* 安装了 TSB 的四个集群 - 管理平面、Tier-1 和 Tier-2 边缘集群。
* 在 Tier-2 集群中，在 `echo` 命名空间部署了 Tier-2 网关。
* 在 Tier-1 集群中，在 `tier1` 命名空间部署了 Tier-1 网关。
* 在两个网关中，端口 `8080` 和 `9999` 应可用（为简单起见，我们认为服务和目标端口相同）。要安装网关，请参阅[此处](../../../quickstart/ingress-gateway)。
* 在 Tier-2 集群中部署与 HTTP 和非 HTTP 流量配合使用的应用程序。在此演示中，你将部署 Istio 示例目录中的应用程序到 echo 命名空间中。
    * `helloworld` 用于 HTTP 流量。[清单在这里](https://github.com/istio/istio/blob/master/samples/helloworld/helloworld.yaml)
    * `tcp-echo` 用于非 HTTP 流量。[清单在这里](https://github.com/istio/istio/blob/master/samples/tcp-echo/tcp-echo.yaml)
* 确保你具有部署网关配置所需的权限。

## TSB 配置

### 配置工作区和组
首先创建工作区。在这里，我们假设集群已作为 `cluster-0`、`cluster-1`、`cluster-2` 和 `cluster-3` 载入。还假设 `cluster-3` 是 Tier-1，`cluster-0` 安装了 TSB 管理平面。
```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
 name: tcp-http-demo
 organization: tetrateio
 tenant: tetrate
spec:
 namespaceSelector:
   names:
     - "cluster-1/echo"
     - "cluster-2/echo"
     - "cluster-3/tier1"
```

为 Tier-1 和 Tier-2 网关分别配置不同的组。
```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
 name: tcp-http-test-t2-group
 organization: tetrateio
 tenant: tetrate
 workspace: tcp-http-demo
spec:
 namespaceSelector:
   names:
   - "cluster-1/echo"
   - "cluster-2/echo"
---
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
 name: tcp-http-test-t1-group
 organization: tetrateio
 tenant: tetrate
 workspace: tcp-http-demo
spec:
 configMode: BRIDGED
 namespaceSelector:
   names:
   - "cluster-3/tier1"
```
### 为网关提供证书和密钥
你必须在部署网关工作负载所在的命名空间中创建两个密钥。
* `hello-tlscred` 用于 Helloworld 应用程序
* `echo-tlscred` 用于 TCP-echo 应用程序

你可以使用工具如 `openssl` 为证书提供密钥并创建密钥，如下所示。
```bash
# 为 helloworld 应用程序创建密钥。这里证书和密钥被提供在 helloworld.crt 和 helloworld.key 中
kubectl --context=<kube-cluster-context> -n <gateway-ns> create secret tls hello-tlscred \
          --cert=helloworld.crt --key=helloworld.key

# 为 tcp-echo 应用程序创建密钥
kubectl --context=<kube-cluster-context> -n <gateway-ns> create secret tls echo-tlscred \
          --cert=echo.crt --key=echo.key
```

### 配置 Tier-2 集群中的 Ingress Gateway
一些注意事项：
* 针对端口 8080 的配置需要 TLS，主机名必须不同。否则，将会出错。
* 凭据存储为命名空间中运行网关工作负载的秘密。在 Tier-2 中，它是 `echo` 命名空间，在 Tier-1 中是 `tier1` 命名空间。

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
 name: tcp-http-t2-gateway
 organization: tetrateio
 tenant: tetrate
 workspace: tcp-http-demo
 group: tcp-http-test-t2-group
spec:
 workloadSelector:
   namespace: echo
   labels:
     app: tsb-gateway-echo
 http:
 - name: http-hello
   port: 8080
   hostname: hello.tetrate.io
   tls:
     mode: SIMPLE
     secretName: hello-tlscred
   routing:
     rules:
     - route:
         host: echo/helloworld.echo.svc.cluster.local
         port: 5000
 tcp:
 # echo.tetrate.io:8080 接收非 HTTP 流量。还有 hello.tetrate.io:8080 接收此端口上的 HTTP 流量。
 # 为了区分两个服务，你需要具有不同的主机名和 TLS，以便客户端可以使用不同的 SNI 来区分它们。这是“多协议”/“多流量类型”的一部分。


 - name: tcp-echo
   port: 8080 # 与前一个 HTTP 服务器相同的端口，但主机名不同。
   hostname: echo.tetrate.io
   tls:
     mode: SIMPLE
     secretName: echo-tlscred
   route:
     host: echo/tcp-echo.echo.svc.cluster.local
     port: 9000

 # 已经定义了一个名为 echo.tetrate.io 的服务，端口为 8080。还可以有另一个 TCP 服务，使用相同的主机名但在不同端口上。这是“多端口”部分。
 - name: tcp-echo-2
   port: 9999
   hostname: echo.tetrate.io
   route:
     host: echo/tcp-echo.echo.svc.cluster.local
     port: 9001
```

### 配置 Tier-1 网关
此处定义的主机：端口应与 `IngressGateway` 中定义的主机：端口完全匹配，流量类型也应与在 `IngressGateway` 中定义的流量类型完全匹配。
```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Tier1Gateway
metadata:
 name: tcp-http-t1-gateway
 organization: tetrateio
 tenant: tetrate
 workspace: tcp-http-demo
 group: tcp-http-test-t1-group
spec:
 workloadSelector:
   namespace: tier1
   labels:
     app: tsb-gateway-tier1
 externalServers:
 # 这与 Tier-2 网关配置中定义的 hello.tetrate.io:8080 相匹配
 # 注意：配置之间的名称不需要相同，但主机名必须匹配。
 - name: http-hello
   hostname: hello.tetrate.io
   port: 8080
   tls:
     mode: SIMPLE
     secretName: hello-tlscred
 tcpExternalServers:
 # 这与 echo.tetrate.io:8080 相匹配。配置之间的名称不需要相同，但主机名必须匹配。
 - name: tcp-echo
   hostname: echo.tetrate.io
   port: 8080
   tls:
     mode: SIMPLE
     secretName: echo-tlscred

 # 这与 Tier-2 配置中的 echo.tetrate.io:9999 相匹配。
 - name: tcp-echo-2
   hostname: echo.tetrate.io
   port: 9999
```

## 集群之间的流量路由

### 南北流量（从 Tier-1 到 Tier-2 集群）
首先，找到 Tier-1 网关的外部 IP 地址，并将其保存在 `TIER1_IP` 变量中。
```bash
$ export TIER1_IP=<tier1-gateway-ip>
```
#### 路由 HTTPS 流量
```bash
$ curl -svk --resolve hello.tetrate.io:8080:$TIER1_IP https://hello.tetrate.io:8080/hello
```
**注意**：除非用于测试目的，否则不要使用 `-k` 标志。它会跳过服务器证书验证，不安全。

#### 路由非 HTTP 流量
1. TLS 流量 - 可能会出现与服务器证书相关的一些警告。由于这是演示，可以忽略它们。
```bash
$ openssl s_client -connect $TIER1_IP:8080 -servername echo.tetrate.io
```

2. 普通 TCP 流量
```bash
$ echo hello | nc -v $TIER1_IP 9999
```

### 东西流量（在 Tier-2 集群之间）
在路由东西流量时，将使用在 `hostname` 字段中定义的 DNS 名称。从你希望发送流量的已注入 Istio sidecar 的 pod 中执行 `nc` 来进行非 HTTP（但是 TCP）流量的路由。此处不需要在此处启动 TLS，因为 TLS 发起是由 sidecar 执行的。

```bash
kubectl -n echo exec -it <pod-name> -c app -- sh -c "echo hello | nc -v echo.tetrate.io 8080"
kubectl -n echo exec -it <pod-name> -c app -- sh -c "echo hello | nc -v echo.tetrate.io 9999"
kubectl -n echo exec -it <pod-name> -c app -- curl -sv hello.tetrate.io:8080
```
