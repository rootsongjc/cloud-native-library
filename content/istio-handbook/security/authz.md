---
weight: 30
title: 授权
date: '2022-05-18T00:00:00+08:00'
type: book
---

授权是对访问控制问题中访问控制部分的响应。一个（经过认证的）主体是否被允许对一个对象执行动作？用户 A 能否向服务 A 的路径 `/hello` 发送一个 GET 请求？

请注意，尽管主体可以被认证，但它可能不被允许执行一个动作。你的公司 ID 卡可能是有效的、真实的，但我不能用它来进入另一家公司的办公室。如果我们继续之前的海关官员的比喻，我们可以说授权类似于你护照上的签证章。

这就引出了下一个问题 —— 有认证而无授权（反之亦然）对我们没有什么好处。对于适当的访问控制，我们需要两者。让我给你举个例子：如果我们只认证主体而不授权他们，他们就可以做任何他们想做的事，对任何对象执行任何操作。相反，如果我们授权了一个请求，但我们没有认证它，我们就可以假装成其他人，再次对任何对象执行任何操作。

Istio 允许我们使用 `AuthorizationPolicy` 资源在网格、命名空间和工作负载层面定义访问控制。`AuthorizationPolicy` 支持 DENY、ALLOW、AUDIT 和 CUSTOM 操作。

每个 Envoy 代理实例都运行一个授权引擎，在运行时对请求进行授权。当请求到达代理时，引擎会根据授权策略评估请求的上下文，并返回 ALLOW 或 DENY。AUDIT 动作决定是否记录符合规则的请求。注意，AUDIT 策略并不影响请求被允许或拒绝。

没有必要明确地启用授权功能。为了执行访问控制，我们可以创建一个授权策略来应用于我们的工作负载。

`AuthorizationPolicy` 资源是我们可以利用 `PeerAuthentication` 策略和 `RequestAuthentication` 策略中的主体的地方。

在定义 `AuthorizationPolicy` 的时候，我们需要考虑三个部分。

1. 选择要应用该策略的工作负载
2. 要采取的行动（拒绝、允许或审计）
3. 采取该行动的规则

让我们看看下面这个例子如何与 `AuthorizationPolicy` 资源中的字段相对应。

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: customers-deny
 namespace: default
spec:
 selector:
   matchLabels:
     app: customers
     version: v2
 action: DENY
 rules:
 - from:
   - source:
       notNamespaces: ["default"]
```

使用`selector`和`matchLabels`，我们可以选择策略所适用的工作负载。在我们的案例中，我们选择的是所有设置了`app: customers`和`version: v2`标签的工作负载。action 字段被设置为`DENY`。

最后，我们在规则栏中定义所有规则。我们例子中的规则是说，当请求来自默认命名空间之外时，拒绝对 `customers v2` 工作负载的请求（action）。

除了规则中的 `from` 字段外，我们还可以使用 `to` 和 `when` 字段进一步定制规则。让我们看一个使用这些字段的例子。

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: customers-deny
 namespace: default
spec:
 selector:
   matchLabels:
     app: customers
     version: v2
 action: DENY
 rules:
 - from:
   - source:
       notNamespaces: ["default"]
 - to:
    - operation:
        methods: ["GET"]
 - when:
    - key: request.headers [User-Agent]
      values: ["Mozilla/*"]
```

我们在规则部分添加了`to`和`when`字段。如果我们翻译一下上面的规则，我们可以说，当客户的 GET 请求来自`default`命名空间之外，并且`User Agent`头的值与正则表达式`Mozilla/*` 相匹配时，我们会拒绝 customer v2 的工作负载。

总的来说，to 定义了策略所允许的行动，from 定义了谁可以采取这些行动，when 定义了每个请求必须具备的属性，以便被策略所允许，selector 定义了哪些工作负载将执行该策略。

如果一个工作负载有多个策略，则首先评估拒绝的策略。评估遵循这些规则：

1. 如果有与请求相匹配的 DENY 策略，则拒绝该请求
2. 如果没有适合该工作负载的 ALLOW 策略，则允许该请求。
3. 如果有任何 ALLOW 策略与该请求相匹配，则允许该请求。
4. 拒绝该请求

## 来源

我们在上述例子中使用的源是 `notNamespaces`。我们还可以使用以下任何一个字段来指定请求的来源，如表中所示。

| 来源                   | 示例                                     | 释义                                                     |
| ---------------------- | ---------------------------------------- | -------------------------------------------------------- |
| `principals`           | `principals: ["my-service-account"]`     | 任何是有 `my-service-account` 的工作负载                 |
| `notPrincipals`        | `notPrincipals: ["my-service-account"]`  | 除了 `my-service-account` 的任何工作负载                 |
| `requestPrincipals`    | `requestPrincipals: ["my-issuer/hello"]` | 任何具有有效 JWT 和请求主体 `my-issuer/hello` 的工作负载 |
| `notRequestPrincipals` | `notRequestPrincipals: ["*"]`            | 任何没有请求主体的工作负载（只有有效的 JWT 令牌）。        |
| `namespaces`           | `namespaces: ["default"]`                | 任何来自 `default` 命名空间的工作负载                    |
| `notNamespaces`        | `notNamespaces: ["prod"]`                | 任何不在 `prod` 命名空间的工作负载                       |
| `ipBlocks`             | `ipBlocks: ["1.2.3.4","9.8.7.6/15"]`    | 任何具有 `1.2.3.4` 的 IP 地址或来自 CIDR 块的 IP 地址的工作负载  |
| `notIpBlock`           | `ipBlocks: ["1.2.3.4/24"]`               | Any IP address that's outside of the CIDR block          |

## 操作

操作被定义在 `to` 字段下，如果多于一个，则使用 `AND` 语义。就像来源一样，操作是成对的，有正反两面的匹配。设置在操作字段的值是字符串：

- `hosts` 和 `notHosts`
- `ports` 和 `notPorts`
- `methods` 和 `notMethods`
- `paths` 和 `notPath`

所有这些操作都适用于请求属性。例如，要在一个特定的请求路径上进行匹配，我们可以使用路径。`["/api/*","/admin"]` 或特定的端口 `ports: ["8080"]`，以此类推。

## 条件

为了指定条件，我们必须提供一个 `key` 字段。`key` 字段是一个 Istio 属性的名称。例如，`request.headers`、`source.ip`、`destination.port` 等等。关于支持的属性的完整列表，请参考 [授权政策条件](https://istio.io/latest/docs/reference/config/security/conditions/)。

条件的第二部分是 `values` 或 `notValues` 的字符串列表。下面是一个 `when` 条件的片段：

```yaml
...
 - when:
    - key: source.ip
      notValues: ["10.0.1.1"]
```

{{< cta cta_text="下一章" cta_link="../../config-security/" >}}