---
weight: 90
title: ProxyConfig
date: '2022-05-18T00:00:00+08:00'
type: book
---

`ProxyConfig` 暴露了代理级别的配置选项。`ProxyConfig` 可以在每个工作负载、命名空间或整个网格的基础上进行配置。`ProxyConfig` 不是一个必要的资源；有默认值。

注意：`ProxyConfig` 中的字段不是动态配置的——更改需要重新启动工作负载才能生效。

对于任何命名空间，包括根配置命名空间，只有一个无工作负载选择器的 `ProxyConfig` 资源是有效的。

对于带有工作负载选择器的资源，只有一个选择任何特定工作负载的资源才有效。

对于网格级别的配置，请将资源放在你的 Istio 安装的根配置命名空间中，而不使用工作负载选择器：

```yaml
apiVersion: networking.istio.io/v1beta1
kind: ProxyConfig
metadata:
  name: my-proxyconfig
  namespace: istio-system
spec:
  concurrency: 0
  image:
    type: distroless
```

对于命名空间级别的配置，将资源放在所需的命名空间中，不需要工作负载选择器：

```yaml
apiVersion: networking.istio.io/v1beta1
kind: ProxyConfig
metadata:
  name: my-ns-proxyconfig
  namespace: user-namespace
spec:
  concurrency: 0
```

对于工作负载级别的配置，在 `ProxyConfig` 资源上设置选择器字段：

```yaml
apiVersion: networking.istio.io/v1beta1
kind: ProxyConfig
metadata:
  name: per-workload-proxyconfig
  namespace: example
spec:
  selector:
    labels:
      app: ratings
  concurrency: 0
  image:
    type: debug
```

如果 ProxyConfig CR 被定义为与工作负载相匹配，它将与 `proxy.istio.io/config` 注释合并（如果存在的话），对于重叠的字段，CR 优先于注释。同样地，如果定义了一个网格的 `ProxyConfig` CR，并且设置了 `MeshConfig.DefaultConfig`，那么这两个资源将被合并，对于重叠的字段，CR 优先。

## 配置项

下图是 `ProxyConfig` 的资源配置拓扑图。

{{< figure src="../../images/proxyconfig.png" alt="ProxyConfig"  caption="ProxyConfig 资源配置拓扑图" width="50%">}}

`ProxyConfig` 的顶级配置如下。

- `selector`：可选的。选择器指定应用此 `ProxyConfig` 资源的 pod/VM 的集合。如果不设置，`ProxyConfig` 资源将被应用于定义该资源的命名空间中的所有工作负载。 
- `concurrency`：要运行的工作线程的数量。如果没有设置，默认为 2。如果设置为 0，这将被配置为使用机器上的所有内核，使用 CPU 请求和限制来选择一个值，限制优先于请求。
- `environmentVariables`：代理的额外环境变量。以`ISTIO_META_` 开头的名字将被包含在生成的引导配置中，并被发送到XDS 服务器。
- `image`：指定代理镜像的细节。

### ProxyImage 配置

用于构建代理镜像 URL：`$hub/$imagename/$tag-$imagetype` 。例如：`docker.io/istio/proxyv2:1.11.1` 或 `docker.io/istio/proxyv2:1.11.1-distroless` 。

- `imageType`：Istio 会发布 default、debug 和 distroless 镜像。如果这些镜像类型（例如：centos）被发布到指定的镜像仓库，则允许使用其他值。支持的值：default、debug、distroless。

## 参考

- [ProxyConfig - istio.io](https://istio.io/latest/docs/reference/config/networking/proxy-config/)

{{< cta cta_text="下一章" cta_link="../../observability/" >}}