---
weight: 20
title: Envoy 示例
date: '2022-05-18T00:00:00+08:00'
type: book
---

让我们以 Web 前端和 customer 服务为例，看看 Envoy 如何确定将请求从 Web 前端发送到 customer 服务（`customers.default.svc.cluster.local`）的位置。使用 `istioctl proxy-config` 命令，我们可以列出 web 前端 pod 的所有监听器。

```sh
$ istioctl proxy-config listeners web-frontend-64455cd4c6-p6ft2
ADDRESS      PORT  MATCH   DESTINATION
10.124.0.10  53    ALL     Cluster: outbound|53||kube-dns.kube-system.svc.cluster.local
0.0.0.0      80    ALL     PassthroughCluster
10.124.0.1   443   ALL     Cluster: outbound|443||kubernetes.default.svc.cluster.local
10.124.3.113 443   ALL     Cluster: outbound|443||istiod.istio-system.svc.cluster.local
10.124.7.154 443   ALL     Cluster: outbound|443||metrics-server.kube-system.svc.cluster.local
10.124.7.237 443   ALL     Cluster: outbound|443||istio-egressgateway.istio-system.svc.cluster.local
10.124.8.250 443   ALL     Cluster: outbound|443||istio-ingressgateway.istio-system.svc.cluster.local
10.124.3.113 853   ALL     Cluster: outbound|853||istiod.istio-system.svc.cluster.local
0.0.0.0      8383  ALL     PassthroughCluster
0.0.0.0      15001 ALL     PassthroughCluster
0.0.0.0      15006 ALL     Inline Route: /*
0.0.0.0      15010 ALL     PassthroughCluster
10.124.3.113 15012 ALL     Cluster: outbound|15012||istiod.istio-system.svc.cluster.local
0.0.0.0      15014 ALL     PassthroughCluster
0.0.0.0      15021 ALL     Non-HTTP/Non-TCP
10.124.8.250 15021 ALL     Cluster: outbound|15021||istio-ingressgateway.istio-system.svc.cluster.local
0.0.0.0      15090 ALL     Non-HTTP/Non-TCP
10.124.7.237 15443 ALL     Cluster: outbound|15443||istio-egressgateway.istio-system.svc.cluster.local
10.124.8.250 15443 ALL     Cluster: outbound|15443||istio-ingressgateway.istio-system.svc.cluster.local
10.124.8.250 31400 ALL     Cluster: outbound|31400||istio-ingressgateway.istio-system.svc.cluster.local
```

从 Web 前端到客户的请求是一个向外的 HTTP 请求，端口为 80。这意味着它被移交给了`0.0.0.0:80`的虚拟监听器。我们可以使用 Istio CLI 按地址和端口来过滤监听器。你可以添加`-o json`来获得监听器的 JSON 表示：

```sh
$ istioctl proxy-config listeners web-frontend-58d497b6f8-lwqkg --address 0.0.0.0 --port 80 -o json
...
"rds": {
   "configSource": {"ads": {},
      "resourceApiVersion": "V3"
   },
   "routeConfigName": "80"
},
...
```

Listener 使用 RDS（路由发现服务）来寻找路由配置（在我们的例子中是 80）。路由附属于监听器，包含将虚拟主机映射到集群的规则。这允许我们创建流量路由规则，因为 Envoy 可以查看头文件或路径（请求元数据）并对流量进行路由。

一个路由（route）选择一个集群（cluster）。一个集群是一组接受流量的类似的上游主机 —— 它是一个端点的集合。例如，Web 前端服务的所有实例的集合就是一个集群。我们可以在一个集群内配置弹性功能，如断路器、离群检测和 TLS 配置。

使用 `routes` 命令，我们可以通过名称过滤所有的路由来获得路由的详细信息。

```sh
$ istioctl proxy-config routes  web-frontend-58d497b6f8-lwqkg --name 80 -o json

[
    {
        "name": "80",
        "virtualHosts": [
            {
                "name": "customers.default.svc.cluster.local:80",
                "domains": [
                    "customers.default.svc.cluster.local",
                    "customers.default.svc.cluster.local:80",
                    "customers",
                    "customers:80",
                    "customers.default.svc.cluster",
                    "customers.default.svc.cluster:80",
                    "customers.default.svc",
                    "customers.default.svc:80",
                    "customers.default",
                    "customers.default:80",
                    "10.124.4.23",
                    "10.124.4.23:80"
                ],
                ],
                "routes": [
                    {
                        "match": {"prefix": "/"},
                        "route": {
                            "cluster": "outbound|80|v1|customers.default.svc.cluster.local",
                            "timeout": "0s",
                            "retryPolicy": {
                                "retryOn": "connect-failure,refused-stream,unavailable,cancelled,retriable-status-codes",
                                "numRetries": 2,
                                "retryHostPredicate": [
                                    {"name": "envoy.retry_host_predicates.previous_hosts"}
                                ],
                                "hostSelectionRetryMaxAttempts": "5",
                                "retriableStatusCodes": [503]
                            },
                            "maxGrpcTimeout": "0s"
                        },
...
```

路由`80`配置为每个服务都有一个虚拟主机。然而，由于我们的请求被发送到`customers.default.svc.cluster.local`，Envoy 会选择与其中一个域匹配的虚拟主机（`customers.default.svc.cluster.local:80`）。

一旦域被匹配，Envoy 就会查看路由，并选择第一个匹配请求的路由。由于我们没有定义任何特殊的路由规则，它匹配第一个（也是唯一的）定义的路由，并指示 Envoy 将请求发送到名为 `outbound|80|v1|customers.default.svc.cluster.local` 的集群。

> 注意集群名称中的 `v1` 是因为我们部署了一个 `DestinationRule` 来创建 `v1` 子集。如果一个服务没有子集，这部分就留空：`outbound|80||customers.default.svc.cluster.local`。

现在我们有了集群的名称，我们可以查询更多的细节。为了得到一个清楚显示 FQDN、端口、子集和其他信息的输出，你可以省略 `-o json` 标志。

```sh
$ istioctl proxy-config cluster web-frontend-58d497b6f8-lwqkg --fqdn customers.default.svc.cluster.local
SERVICE FQDN                            PORT     SUBSET     DIRECTION     TYPE     DESTINATION RULE
customers.default.svc.cluster.local     80       -          outbound      EDS      customers.default
customers.default.svc.cluster.local     80       v1         outbound      EDS      customers.default
```

最后，使用集群的名称，我们可以查询请求最终将到达的实际端点：

```sh
$ istioctl proxy-config endpoints  web-frontend-58d497b6f8-lwqkg --cluster "outbound|80|v1|customers.default.svc.cluster.local"
ENDPOINT            STATUS      OUTLIER CHECK     CLUSTER
10.120.0.4:3000     HEALTHY     OK                outbound|80|v1|customers.default.svc.cluster.local
```

端点地址等于客户应用程序正在运行的 pod IP。如果我们扩展 customer 的部署，额外的端点会出现在输出中，像这样：

```sh
$ istioctl proxy-config endpoints web-frontend-58d497b6f8-lwqkg --cluster "outbound|80|v1|customers.default.svc.cluster.local"
ENDPOINT            STATUS      OUTLIER CHECK     CLUSTER
10.120.0.4:3000     HEALTHY     OK                outbound|80|v1|customers.default.svc.cluster.local
10.120.3.2:3000     HEALTHY     OK                outbound|80|v1|customers.default.svc.cluster.local
```

我们也可以用下图来形象地说明上述流程。

![Envoy 详情](../../images/008i3skNly1gt2p7osd79j30zk0k0mzf.jpg "Envoy 详情")
