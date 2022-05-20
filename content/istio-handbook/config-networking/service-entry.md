---
weight: 60
title: ServiceEntry
date: '2022-05-18T00:00:00+08:00'
type: book
---

`ServiceEntry` 可以在 Istio 的内部服务注册表中添加额外的条目，这样网格中自动发现的服务就可以访问 / 路由到这些手动指定的服务。服务条目描述了服务的属性（DNS 名称、VIP、端口、协议、端点）。这些服务可以是网格的外部服务（如 Web API），也可以是不属于平台服务注册表的网格内部服务（如与 Kubernetes 中的服务通信的一组虚拟机）。此外，服务条目的端点也可以通过使用 `workloadSelector` 字段动态选择。这些端点可以是使用 `WorkloadEntry` 对象声明的虚拟机工作负载或 Kubernetes pod。在单一服务下同时选择 pod 和 VM 的能力允许将服务从 VM 迁移到 Kubernetes，而不必改变与服务相关的现有 DNS 名称。

## 示例

下面的例子声明了一些内部应用程序通过 HTTPS 访问的外部 API。Sidecar 检查了 ClientHello 消息中的 SNI 值，以路由到适当的外部服务。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: external-svc-https
spec:
  hosts:
  - api.dropboxapi.com
  - www.googleapis.com
  - api.facebook.com
  location: MESH_EXTERNAL
  ports:
  - number: 443
    name: https
    protocol: TLS
  resolution: DNS
```

下面的配置在 Istio 的注册表中添加了一组运行在未被管理的虚拟机上的 MongoDB 实例，因此这些服务也可以被视为网格中的任何其他服务。相关的 DestinationRule 被用来启动与数据库实例的 mTLS 连接。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: external-svc-mongocluster
spec:
  hosts:
  - mymongodb.somedomain # 未使用
  addresses:
  - 192.192.192.192/24 # VIP
  ports:
  - number: 27018
    name: mongodb
    protocol: MONGO
  location: MESH_INTERNAL
  resolution: STATIC
  endpoints:
  - address: 2.2.2.2
  - address: 3.3.3.3
```

相关的 DestinationRule。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: mtls-mongocluster
spec:
  host: mymongodb.somedomain
  trafficPolicy:
    tls:
      mode: MUTUAL
      clientCertificate: /etc/certs/myclientcert.pem
      privateKey: /etc/certs/client_private_key.pem
      caCertificates: /etc/certs/rootcacerts.pem
```

下面的例子在一个 VirtualService 中使用 ServiceEntry 和 TLS 路由的组合，根据 SNI 值将流量引导到内部出口（egress）防火墙。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: external-svc-redirect
spec:
  hosts:
  - wikipedia.org
  - "*.wikipedia.org"
  location: MESH_EXTERNAL
  ports:
  - number: 443
    name: https
    protocol: TLS
  resolution: NONE
```

相关的 VirtualService，根据 SNI 值进行路由。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: tls-routing
spec:
  hosts:
  - wikipedia.org
  - "*.wikipedia.org"
  tls:
  - match:
    - sniHosts:
      - wikipedia.org
      - "*.wikipedia.org"
    route:
    - destination:
        host: internal-egress-firewall.ns1.svc.cluster.local
```

带有 TLS 匹配的 VirtualService 是为了覆盖默认的 SNI 匹配。在没有 VirtualService 的情况下，流量将被转发到维基百科的域。

下面的例子演示了专用出口（egress）网关的使用，所有外部服务流量都通过该网关转发。`exportTo` 字段允许控制服务声明对网格中其他命名空间的可见性。默认情况下，服务会被输出到所有命名空间。下面的例子限制了对当前命名空间的可见性，用 `.` 表示，所以它不能被其他命名空间使用。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: external-svc-httpbin
  namespace : egress
spec:
  hosts:
  - httpbin.com
  exportTo:
  - "."
  location: MESH_EXTERNAL
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: DNS
```

定义一个网关来处理所有的出口（egress）流量。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
 name: istio-egressgateway
 namespace: istio-system
spec:
 selector:
   istio: egressgateway
 servers:
 - port:
     number: 80
     name: http
     protocol: HTTP
   hosts:
   - "*"
```

和相关的 VirtualService，从 Sidecar 路由到网关服务（`istio-egressgateway.istio-system.svc.cluster.local`），以及从网关路由到外部服务。请注意，VirtualService 被导出到所有命名空间，使它们能够通过网关将流量路由到外部服务。迫使流量通过像这样一个受管理的中间代理是一种常见的做法。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: gateway-routing
  namespace: egress
spec:
  hosts:
  - httpbin.com
  exportTo:
  - "*"
  gateways: # 同时应用于网格内的网关和所有 sidecar
  - mesh
  - istio-egressgateway
  http:
  - match:
    - port: 80
      gateways:
      - mesh # 应用于网格内的所有 sidecar
    route:
    - destination:
        host: istio-egressgateway.istio-system.svc.cluster.local
  - match:
    - port: 80
      gateways:
      - istio-egressgateway # 仅应用于网关
    route:
    - destination:
        host: httpbin.com
```

下面的例子演示了在外部服务的主机中使用通配符。如果连接必须被路由到应用程序请求的 IP 地址（即应用程序解析 DNS 并试图连接到一个特定的 IP），发现模式必须被设置为 `NONE`。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: external-svc-wildcard-example
spec:
  hosts:
  - "*.bar.com"
  location: MESH_EXTERNAL
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: NONE
```

下面的例子演示了一个通过客户主机上的 Unix 域套接字提供的服务。解析必须设置为 `STATIC` 以使用 Unix 地址端点。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: unix-domain-socket-example
spec:
  hosts:
  - "example.unix.local"
  location: MESH_EXTERNAL
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: STATIC
  endpoints:
  - address: unix:///var/run/example/socket
```

对于基于 HTTP 的服务，可以创建一个由多个 DNS 可寻址端点支持的 VirtualService。在这种情况下，应用程序可以使用 `HTTP_PROXY` 环境变量来透明地将 VirtualService 的 API 调用重新路由到所选择的后端。例如，下面的配置创建了一个不存在的外部服务，名为`foo.bar.com`，由三个域名支持：`us.foo.bar.com:8080`，`uk.foo.bar.com:9080`和`in.foo.bar.com:7080`。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: external-svc-dns
spec:
  hosts:
  - foo.bar.com
  location: MESH_EXTERNAL
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: DNS
  endpoints:
  - address: us.foo.bar.com
    ports:
      http: 8080
  - address: uk.foo.bar.com
    ports:
      http: 9080
  - address: in.foo.bar.com
    ports:
      http: 7080
```

有了`HTTP_PROXY=http://localhost/`，从应用程序到 `http://foo.bar.com` 的调用将在上面指定的三个域中进行负载均衡。换句话说，对 `http://foo.bar.com/baz` 的调用将被转译成 `http://uk.foo.bar.com/baz`。

下面的例子说明了包含主题（subject）替代名称的 `ServiceEntry` 的用法，其格式符合 [SPIFFE 标准](https://github.com/spiffe/spiffe/blob/master/standards/SPIFFE-ID.md)。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: httpbin
  namespace : httpbin-ns
spec:
  hosts:
  - httpbin.com
  location: MESH_INTERNAL
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: STATIC
  endpoints:
  - address: 2.2.2.2
  - address: 3.3.3.3
  subjectAltNames:
  - "spiffe://cluster.local/ns/httpbin-ns/sa/httpbin-service-account"
```

下面的例子演示了使用带有`workloadSelector`的`ServiceEntry`来处理服务`details.bookinfo.com`从 VM 到 Kubernetes 的迁移。该服务有两个基于虚拟机的实例，带有 sidecar，以及一组由标准部署对象管理的 Kubernetes pod。网格中该服务的消费者将自动在虚拟机和 Kubernetes 之间进行负载均衡。`details.bookinfo.com`服务的虚拟机安装了 sidecar，并使用`details-legacy`服务账户进行引导。Sidecar 接收 80 端口的 HTTP 流量（用 istio mutual TLS 包装），并将其转发给同一端口的 localhost 上的应用程序。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadEntry
metadata:
  name: details-vm-1
spec:
  serviceAccount: details
  address: 2.2.2.2
  labels:
    app: details
    instance-id: vm1
---
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadEntry
metadata:
  name: details-vm-2
spec:
  serviceAccount: details
  address: 3.3.3.3
  labels:
    app: details
    instance-id: vm2
```

假设还有一个 Kubernetes 部署，带有 pod 标签`app: details`，使用相同的服务账户`details`，下面的 ServiceEntry 声明了一个横跨虚拟机和 Kubernetes 的服务。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: details-svc
spec:
  hosts:
  - details.bookinfo.com
  location: MESH_INTERNAL
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: STATIC
  workloadSelector:
    labels:
      app: details
```

## 配置项

下图是 ServiceEntry 资源的配置拓扑图。

{{< figure src="../../images/serviceentry.png" alt="ServiceEntry"  caption="ServiceEntry 资源配置拓扑图" width="50%">}}

ServiceEntry 资源的顶级配置项如下：

- `hosts`：字符串数组类型。与ServiceEntry相关的主机。可以是带有通配符前缀的 DNS 名称。

  `hosts` 字段用于在 VirtualService 和 DestinationRule 中选择匹配的主机。
  对于 HTTP 流量，HTTP Host/Authority 标头将与 `hosts` 字段匹配。
  对于包含服务器名称指示（SNI）的HTTPs或TLS流量，SNI值将与`hosts`字段匹配。
  注意1：当解析被设置为DNS类型，并且没有指定端点时，主机字段将被用作端点的DNS名称来路由流量。

  注意2：如果主机名与另一个服务注册中心（如 Kubernetes）的服务名称相匹配，该 ServiceEntry 也提供其自身的端点集，则将被视为现有 Kubernetes 服务的装饰器。如果适用，服务条目中的属性将被添加到 Kubernetes 服务中。目前，`istiod` 只考虑以下附加属性。

  `subjectAltNames`：除了验证与服务的pod相关联的服务账户的SAN之外，这里指定的SAN也将被验证。

- `addresses`：字符串数组类型。与该服务相关的虚拟IP地址。可以是CIDR前缀。对于HTTP流量，生成的路由配置将包括地址和主机字段值的http路由域，目的地将根据HTTP主机/授权头来识别。如果指定了一个或多个IP地址，如果目的地IP与`addresses`字段中指定的IP/CIDR相匹配，传入的流量将被识别为属于该服务。如果地址字段为空，流量将仅根据目标端口进行识别。在这种情况下，访问该服务的端口必须不被网格中的任何其他服务所共享。换句话说，sidecar 将作为一个简单的TCP代理，将指定端口上的传入流量转发到指定的目标端点IP/主机。该字段不支持Unix域套接字地址。

- `ports`：与外部服务相关的端口。如果端点是 Unix 域套接字地址，必须有一个确切的端口。

- `location`：指定该服务是否应被视为网格的外部或网格的一部分。

- `resolution`：主机的服务发现模式。在为没有附带IP地址的TCP端口设置解析模式为NONE时，必须小心。在这种情况下，将允许到所述端口的任何IP的流量（即`0.0.0.0:<端口>`）。

- `endpoints`：与该服务相关的一个或多个端点。只能指定`endpoints` 或 `workloadSelector` 中的一个。 

- `workloadSelector`：仅适用于`MESH_INTERNAL`服务。只能指定`endpoints`或`workloadSelector`中的一个。根据标签选择一个或多个Kubernetes pod或VM工作负载（使用`WorkloadEntry`指定）。代表虚拟机的`WorkloadEntry`对象应与`ServiceEntry`定义在同一命名空间。

- `exportTo`：字符串数组类型。服务被导出的命名空间的列表。导出服务允许它被定义在其他命名空间中的 sidecar、 Gateway 和 VirtualService 使用。该功能为服务所有者和网格管理员提供了一种机制，以控制 ServiceEntry 在命名空间边界的可见性。

  如果没有指定命名空间，那么默认情况下，服务会被输出到所有命名空间。

  值 `.` 是保留的，它定义了导出到服务声明的同一命名空间。同样，值 `*` 也是保留的，它定义了导出到所有命名空间。

  对于 Kubernetes 服务，可以通过将注解 `networking.istio.io/exportTo` 设置为逗号分隔的命名空间列表来实现同等效果。

- `subjectAltNames`：字符串数组类型。如果指定了该值，代理将验证服务器证书的主题替代名称是否与指定值之一相匹配。

  注意：当将 `workloadEntry` 与 `workloadSelectors` 一起使用时，`workloadEntry` 中指定的服务账户也将被用于推导应被验证的额外主题替代名称。

关于 ServiceEntry 配置的详细用法请参考 [Istio 官方文档](https://istio.io/latest/docs/reference/config/networking/service-entry/)。

## 参考

- [Service Entry - istio.io](https://istio.io/latest/docs/reference/config/networking/service-entry/)