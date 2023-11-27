---
title: 降低 Istio 资源消耗
description: 如何通过使用 TSB 流量设置来降低 Istio 控制平面和所有网关的 CPU 和内存使用量。
weight: 11
---

本文描述了如何通过使用 TSB 流量设置来降低网格中的控制平面和所有网关使用的 CPU 和内存数量，该设置将生成一个 [sidecar](https://istio.io/latest/docs/reference/config/networking/sidecar/) 资源。

## 先决条件

- 熟悉 [TSB 概念](../../concepts/)。
- 安装 [TSB 演示](../../setup/self-managed/demo-installation) 环境。
- 创建一个 [租户](../../quickstart/tenant)。

## 准备环境

在此场景中，我们将部署三个不同的应用程序：`bookinfo`、`httpbin` 和 `helloworld`。每个应用程序都将在接收流量并将其转发到应用程序的同一命名空间中拥有其 `ingressgateway`。

首先，为每个应用程序创建一个命名空间并启用 sidecar 注入：

```bash
$ kubectl create ns <ns>
$ kubectl label namespace <ns> istio-injection=enabled
```

现在，在每个命名空间中部署应用程序：

```bash
$ kubectl apply -n bookinfo -f https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/platform/kube/bookinfo.yaml
$ kubectl apply -n helloworld -f https://raw.githubusercontent.com/istio/istio/master/samples/helloworld/helloworld.yaml
$ kubectl apply -n httpbin -f https://raw.githubusercontent.com/istio/istio/master/samples/httpbin/httpbin.yaml
```

然后，在每个命名空间中部署 `ingressgateway`：

```bash
$ cat <<EOF | kubectl apply -f -
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: tsb-gateway-<ns>
  namespace: <ns>
spec:
  kubeSpec:
    service:
      type: LoadBalancer
EOF
```

你现在应该有三个命名空间：`bookinfo`、`httpbin` 和 `helloworld`。现在创建不同的工作区和网关组，以将应用程序引入到 TSB。你可以使用此示例来为所有应用程序使用它：

```bash
$ cat <<EOF | tctl apply -f -
apiVersion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
 organization: tetrate
 tenant: tetrate
 name: bookinfo
spec:
 namespaceSelector:
   names:
     - "demo/bookinfo"
---
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
 organization: tetrate
 tenant: tetrate
 workspace: bookinfo
 name: bookinfo-gg
spec:
 namespaceSelector:
   names:
     - "demo/bookinfo"
 configMode: BRIDGED
EOF
```

最后，应用 `ingressgateways` 以生成网关和虚拟服务：

```bash
$ cat <<EOF | tctl apply -f -
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
 organization: tetrate
 tenant: tetrate
 workspace: httpbin
 group: httpbin-gg
 name: httpbin-gw
spec:
 workloadSelector:
   namespace: httpbin
   labels:
     app: tsb-gateway-httpbin
     istio: ingressgateway
 http:
   - name: httpbin
     port: 80
     hostname: httpbin.tetrate.io
     routing:
       rules:
         - route:
             host: httpbin/httpbin.httpbin.svc.cluster.local
---
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
 organization: tetrate
 tenant: tetrate
 workspace: helloworld
 group: helloworld-gg
 name: helloworld-gw
spec:
 workloadSelector:
   namespace: helloworld
   labels:
     app: tsb-gateway-helloworld
     istio: ingressgateway
 http:
   - name: helloworld
     port: 80
     hostname: helloworld.tetrate.io
     routing:
       rules:
         - route:
             host: helloworld/helloworld.helloworld.svc.cluster.local
---
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
 organization: tetrate
 tenant: tetrate
 workspace: bookinfo
 group: bookinfo-gg
 name: bookinfo-gw
spec:
 workloadSelector:
   namespace: bookinfo
   labels:
     app: tsb-gateway-bookinfo
     istio: ingressgateway
 http:
   - name: bookinfo
     port: 80
     hostname: bookinfo.tetrate.io
     routing:
       rules:
         - match:
             - uri:
                 exact: /productpage
             - uri:
                 prefix: /static
             - uri:
                 exact: /login
             - uri:
                 exact: /logout
             - uri:
                 prefix: /api/v1/products
           route:
             host: bookinfo/productpage.bookinfo.svc.cluster.local
             port: 9080
EOF
```

场景将如下所示：

![](../../assets/operations/lower_resources_topology.png)

## 降低控制平面和 sidecar 资源

此时，所有 sidecar 都已连接，并具有关于彼此的信息。你可以从 istio-proxy 获取配置转储，其中将看到它了解的所有端点。对于此示例，你可以使用 `helloworld` pod：

```bash
$ kubectl exec <pod> -c istio-proxy -n helloworld -- pilot-agent request GET config_dump > config_dump.json
```

由于这是一个小型场景，你可能不会注意到 CPU 和内存资源的许多改进，但为了了解你将要执行的操作，可以检查配置大小。在应用任何限制之前，这是

当前的大小：

```bash
$ du -h config_dump.json                                                                                                                                 
2.1M	config_dump.json
```

这是由控制平面生成并发送给所有代理的所有端点信息。因此，为了限制网关生成的信息量，你可以使用 sidecar 资源选择特定网关需要的信息。

由于你有三个完全不同的应用程序，它们之间不进行通信，因此你可以创建一个流量设置，以允许所有工作负载在同一工作区下进行通信。由于流量设置与流量组相关联，因此需要创建两个资源：

```bash
$ cat <<EOF | tctl apply -f -
apiVersion: traffic.tsb.tetrate.io/v2
kind: Group
metadata:
  organization: tetrate
  tenant: tetrate
  workspace: helloworld
  name: helloworld-tg
spec:
  namespaceSelector:
    names:
      - "demo/helloworld"
  configMode: BRIDGED
---
apiVersion: traffic.tsb.tetrate.io/v2
kind: TrafficSetting
metadata:
  organization: tetrate
  tenant: tetrate
  workspace: helloworld
  group: helloworld-tg
  name: default
spec:
  reachability:
    mode: NAMESPACE
EOF
```

有多种可达性模式可供选择，你可以选择工作区中的所有命名空间，或创建自定义配置来限制 sidecar 配置适用的工作负载范围，从而提高粒度。此流量设置将创建一个带有配置的 sidecar 资源，该配置用于确定工作负载应了解的服务范围。通过此配置，控制平面将配置所选工作负载，以仅接收有关如何访问 `helloworld` 命名空间中的服务的配置，而不是推送有关网格中所有服务的配置。

由控制平面推送的配置大小减少了服务网格内存和网络使用。现在，你可以再次获取配置转储并比较大小：

```bash
$ kubectl exec <pod> -c istio-proxy -n helloworld -- pilot-agent request GET config_dump > config_dump.json
$ du -h config_dump.json                                                                                                                                 
1.0M	config_dump.json
```

请注意，由于当前 sidecar 不具有关于其他命名空间中其他端点的信息，因此无法访问它们，请在应用 sidecar 配置时小心。你可以运行以下命令查看生成的 sidecar 资源：

```bash
$ kubectl get sidecar -n helloworld -o yaml
```

{{<callout note 注意>}}
有关如何改进 Istio 控制平面性能的更多信息，你可以阅读这篇[博客文章](https://tetrate.io/blog/performance-optimization-for-istio/)，其中详细解释了此过程。
{{</callout>}}