---
title: 使用 Tier-2 网关进行多集群流量路由
description: 使用 Tier-2 网关在集群之间切换流量。
weight: 6
---

Tier-2 网关或 IngressGateway 配置工作负载以充当进入网格的流量网关。入口网关还提供基本的 API 网关功能，如 JWT 令牌验证和请求授权。

在本指南中，你将会：
- 部署 [bookinfo 应用程序](https://istio.io/latest/docs/examples/bookinfo/) 分为两个不同的集群，配置为 Tier-2，一个集群中有 `productpage`，另一个集群中有 reviews、details 和 rating。

在开始之前，请确保你已经在 `cluster 1` 中部署了 `productpage`，并在 `cluster 2` 中部署了 details、ratings 和 reviews。对于此演示，我们假设你已经在 TSB 中部署和配置了 Bookinfo。

- 所有组件中的控制平面都需要共享相同的[信任根](https://istio.io/latest/docs/tasks/security/cert-management/plugin-ca-cert/)。

## 场景

在这个场景中，我们将配置两个配置为 Tier-2 的控制平面集群（`tsb-tier2gcp1` 和 `tsb-tier2gcp2`）。我们将在两个 Tier-2 集群中都部署 Bookinfo，`tsb-tier2gcp1` 中将安装 `productpage`，而 `tsb-tier2gcp2` 中将安装 reviews、details 和 ratings。

因此，Tier-2 集群的场景（一旦配置完成）应如下所示：

![](../../../assets/howto/bookinfo-tier2-tier2-diagram.png)

请确保两个集群都共享相同的信任根。在部署两个集群的控制平面之前，你必须填充正确的证书到 `cacerts` 中。有关更多详细信息，请参阅 Istio 文档中的 [Plugin CA 证书](https://istio.io/latest/docs/tasks/security/cert-management/plugin-ca-cert/)。

## 配置
### 配置 TSB 对象
在此示例中，假定你已经有一个名为 `tetrate` 的组织、一个名为 `test` 的租户，以及已经配置了 Tier-2 网关的两个控制平面集群。

首先，创建工作区和网关组：
```yaml
apiversion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: tetrate
  tenant: test
  name: bookinfo
spec:
  displayName: bookinfo app
  description: Workspace for the bookinfo app
  namespaceSelector:
    names:
      - "*/bookinfo-front"
      - "*/bookinfo-back"
---
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
  organization: tetrate
  tenant: test
  workspace: bookinfo
  name: bookinfo-gw
spec:
  configMode: BRIDGED
  namespaceSelector:
    names:
      - "*/bookinfo-front"
      - "*/bookinfo-back"
```

然后应用它：
```bash
tctl apply -f mgmt-bookinfo.yaml
```

在上面的示例中，使用通配符 ("*") 表示选择所有已登记集群中的 `bookinfo-front` 和 `bookinfo-back` 命名空间。如果你想要针对特定集群进行目标定位，可以将 "*" 替换为你希望使用的集群名称。

### 部署入口网关
现在，如果命名空间尚未创建，我们将在两者中创建它们并在两者中启用 Sidecar 注入。在 `tsb-tier2gcp1` 中，我们将创建 `bookinfo-front` 命名空间并部署 `productpage`，在 `tsb-tier2gcp2` 中，我们将创建 `bookinfo-back` 命名空间并部署 reviews、ratings 和 details。

在 `bookinfo-front` 中创建证书，以便命名空间中的服务可以使用 HTTPS 进行公开。

```bash
kubectl create secret tls bookinfo-cert -n bookinfo-front --cert cert.pem --key key.pem
```

完成后，在每个集群中创建一个 `IngressGateway` 部署：
```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: bookinfo-front-gw
  namespace: bookinfo-front
spec:
  kubeSpec:
    service:
      ports:
      - name: mtls
        port: 15443
        targetPort: 15443
      - name: https
        port: 443
        targetPort: 8443
      - name: http2
        port: 80
        targetPort: 8080
      type: LoadBalancer
---
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: bookinfo-back-gw
  namespace: bookinfo-back
spec:
  kubeSpec:
    service:
      ports:
      - name: mtls
        port: 15443
        targetPort: 15443
      - name: https
        port: 443
        targetPort: 8443
      - name: http2
        port: 80
        targetPort: 8080
      type: LoadBalancer
```

然后应用它们：
```bash
kubectl apply -f bookinfo-<front|back>-ingress.yaml
```

获取这两个服务的 IP 地址：
```bash
FRONT=$(kubectl get svc -n bookinfo-front bookinfo-front-gw -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
BACK=$(kubectl get svc -n bookinfo-back bookinfo-back-gw -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

并配置 DNS 以使用以下配置进行访问：
```text
FRONT → bookinfo.tetrate.com
BACK → bookinfo-back.tetrate.com（可以是你喜欢的名称）。
```

在这一点上，很重要的是在 `productpage` 部署规范中添加以下行

，以便部署能够知道 details 和 reviews 存储在哪里：
```yaml
        env:
        - name: DETAILS_HOSTNAME
          value: bookinfo-back.tetrate.com:80
        - name: REVIEWS_HOSTNAME
          value: bookinfo-back.tetrate.com:80
```
{{<callout note 注意>}}
对于默认的 `productpage` 映像，这不会起作用，因为默认端口硬编码为 9080，这只是一个示例，但你可以修改它以获取端口和主机名。
{{</callout>}}

### 配置 Ingress Gateway 路由
现在，我们可以通过创建 Tier-2 网关配置来配置已部署的入口网关。这可以通过创建 `IngressGateway` 网关资源来完成。

{{<callout note 注意>}}
请注意，`apiVersion` 与之前的不同，因为第一个是用于安装入口网关，第二个是用于配置使用 BRIDGED API 的网关和虚拟服务。
{{</callout>}}

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
  organization: tetrate
  tenant: test
  workspace: bookinfo
  group: bookinfo-gw
  name: bookinfo-front-gw
spec:
  workloadSelector:
    namespace: bookinfo-front
    labels:
      app: bookinfo-front-gw
  http:
  - name: bookinfo
    port: 443
    hostname: bookinfo.tetrate.com
    tls:
      mode: SIMPLE
      secretName: bookinfo-cert
    routing:
      rules:
      - route:
          host: bookinfo-front/productpage.bookinfo-front.svc.cluster.local
          port: 9080
---
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
  organization: tetrate
  tenant: test
  workspace: bookinfo
  group: bookinfo-gw
  name: bookinfo-back-gw
spec:
  workloadSelector:
    namespace: bookinfo-back
    labels:
      app: bookinfo-back-gw
  http:
  - name: bookinfo-back
    port: 80
    hostname: bookinfo-back.tetrate.com
    routing:
      rules:
      - match:
        - uri:
            prefix: /details
        route:
          host: bookinfo-back/details.bookinfo-back.svc.cluster.local
          port: 9080
      - match:
        - uri:
            prefix: /reviews
        route:
          host: bookinfo-back/reviews.bookinfo-back.svc.cluster.local
          port: 9080
```

### 验证

通过此配置，`bookinfo.tetrate.com` 使用 HTTPS 公开，而 `bookinfo-back.tetrate.com` 使用 HTTP。

在此时，你可以通过执行以下命令来测试它是否有效：

```bash
$ curl -I https://bookinfo.tetrate.com/productpage
```

{{<callout note 注意>}}
`productpage` 服务被配置为通过端口 80 发送流量到 details 和 reviews 服务。然而，在我们配置了 TSB 对象之后，将创建一个服务条目，该服务条目将重定向此端口 80 到 15443（已配置为 mTLS），还将创建一个使用 mTLS 的目标规则。
{{</callout>}}

你可以通过运行以下命令来查看这两者，并查看与 bookinfo 相关的服务条目和目标规则：

```bash
kubectl get dr,se -n xcp-multicluster
```
