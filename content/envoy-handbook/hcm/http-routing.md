---
weight: 2
title: HTTP 路由
date: '2022-05-18T00:00:00+08:00'
type: book
---

前面提到的路由器过滤器（`envoy.filters.http.router`）就是实现 HTTP 转发的。路由器过滤器几乎被用于所有的 HTTP 代理方案中。路由器过滤器的主要工作是查看路由表，并对请求进行相应的路由（转发和重定向）。

路由器使用传入请求的信息（例如，`host ` 或 `authority` 头），并通过虚拟主机和路由规则将其与上游集群相匹配。

所有配置的 HTTP 过滤器都使用包含路由表的路由配置（`route_config`）。尽管路由表的主要消费者将是路由器过滤器，但其他过滤器如果想根据请求的目的地做出任何决定，也可以访问它。

一组**虚拟主机**构成了路由配置。每个虚拟主机都有一个逻辑名称，一组可以根据请求头被路由到它的域，以及一组指定如何匹配请求并指出下一步要做什么的路由。

Envoy 还支持路由级别的优先级路由。每个优先级都有其连接池和断路设置。目前支持的两个优先级是 DEFAULT 和 HIGH。如果我们没有明确提供优先级，则默认为 DEFAULT。

这里有一个片段，显示了一个路由配置的例子。

```yaml
route_config:
  name: my_route_config # 用于统计的名称，与路由无关
  virtual_hosts:
  - name: bar_vhost
    domains: ["bar.io"]
    routes:
      - match:
          prefix: "/"
        route:
          priority: HIGH
          cluster: bar_io
  - name: foo_vhost
    domains: ["foo.io"]
    routes:
      - match:
          prefix: "/"
        route:
          cluster: foo_io
      - match:
          prefix: "/api"
        route:
          cluster: foo_io_api
```

当一个 HTTP 请求进来时，虚拟主机、域名和路由匹配依次发生。

1. `host`或`authority`头被匹配到每个虚拟主机的`domains`字段中指定的值。例如，如果主机头被设置为 `foo.io`，则虚拟主机 `foo_vhost` 匹配。
1. 接下来会检查匹配的虚拟主机内`routs`下的条目。如果发现匹配，就不做进一步检查，而是选择一个集群。例如，如果我们匹配了 `foo.io` 虚拟主机，并且请求前缀是 `/api`，那么集群 `foo_io_api` 就被选中。
1. 如果提供，虚拟主机中的每个虚拟集群（`virtual_clusters`）都会被检查是否匹配。如果有匹配的，就使用一个虚拟集群，而不再进行进一步的虚拟集群检查。

> 虚拟集群是一种指定针对特定端点的重组词匹配规则的方式，并明确为匹配的请求生成统计信息。

虚拟主机的顺序以及每个主机内的路由都很重要。考虑下面的路由配置。

```yaml
route_config:
  virtual_hosts:
  - name: hello_vhost
    domains: ["hello.io"]
    routes:
      - match:
          prefix: "/api"
        route:
          cluster: hello_io_api
      - match:
          prefix: "/api/v1"
        route:
          cluster: hello_io_api_v1
```

如果我们发送以下请求，哪个路由 / 集群被选中？

```sh
curl hello.io/api/v1
```

第一个设置集群 `hello_io_api的`路由被匹配。这是因为匹配是按照前缀的顺序进行评估的。然而，我们可能错误地期望前缀为 `/api/v1` 的路由被匹配。为了解决这个问题，我们可以调换路由的顺序，或者使用不同的匹配规则。