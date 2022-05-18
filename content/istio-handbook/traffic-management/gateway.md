---
weight: 20
title: Gateway
date: '2022-05-18T00:00:00+08:00'
type: book
---

作为 Istio 安装的一部分，我们安装了 Istio 的入口和出口网关。这两个网关都运行一个 Envoy 代理实例，它们在网格的边缘作为负载均衡器运行。入口网关接收入站连接，而出口网关接收从集群出去的连接。

使用入口网关，我们可以对进入集群的流量应用路由规则。我们可以有一个指向入口网关的单一外部 IP 地址，并根据主机头将流量路由到集群内的不同服务。

![入口和出口网关](../../images/008i3skNly1gsy17fz49vj318g0p0jto.jpg "入口和出口网关")

我们可以使用 Gateway 资源来配置网关。网关资源描述了负载均衡器的暴露端口、协议、SNI（服务器名称指示）配置等。

下面是一个网关资源的例子：

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: my-gateway
  namespace: default
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - dev.example.com
    - test.example.com
```

上述网关资源设置了一个代理，作为一个负载均衡器，为入口暴露 80 端口。网关配置被应用于 Istio 入口网关代理，我们将其部署到 `istio-system` 命名空间，并设置了标签 `istio: ingressgateway`。通过网关资源，我们只能配置负载均衡器。`hosts` 字段作为一个过滤器，只有以 `dev.example.com` 和 `test.example.com` 为目的地的流量会被允许通过。为了控制和转发流量到 Kubernetes 内部运行的实际服务，我们必须将 VirtualService 资源绑定到它。

![Gateway 和 VirtualService](../../images/008i3skNly1gtcwbmwin2j61op0u0gp802.jpg "Gateway 和 VirtualService")

例如，我们作为 Istio 安装 `demo` 的一部分而部署的 Ingress 网关创建了一个具有 LoadBalancer 类型的 Kubernetes 服务，并为其分配了一个外部 IP：

```sh
$ kubectl get svc -n istio-system
NAME                   TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)                                                                      AGE
istio-egressgateway    ClusterIP      10.0.146.214   <none>           80/TCP,443/TCP,15443/TCP                                                     7m56s
istio-ingressgateway   LoadBalancer   10.0.98.7      XX.XXX.XXX.XXX   15021:31395/TCP,80:32542/TCP,443:31347/TCP,31400:32663/TCP,15443:31525/TCP   7m56s
istiod                 ClusterIP      10.0.66.251    <none>           15010/TCP,15012/TCP,443/TCP,15014/TCP,853/TCP                                8m6s
```

> LoadBalancer Kubernetes 服务类型的工作方式取决于我们运行 Kubernetes 集群的方式和地点。对于云管理的集群（GCP、AWS、Azure等），在你的云账户中配置了一个负载均衡器资源，Kubernetes LoadBalancer 服务将获得一个分配给它的外部 IP 地址。假设我们正在使用 Minikube 或 Docker Desktop。在这种情况下，外部 IP 地址将被设置为 localhost（Docker Desktop），或者，如果我们使用 Minikube，它将保持待定，我们将不得不使用 minikube tunnel 命令来获得一个IP地址。

除了入口网关，我们还可以部署一个出口网关来控制和过滤离开网格的流量。

就像我们配置入口网关一样，我们可以使用相同的网关资源来配置出口网关。这使我们能够集中管理所有流出的流量、日志和授权。