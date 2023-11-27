---
title: 使用 Keycloak 进行终端用户身份验证
description: 在 Ingress Gateway 中使用 Keycloak 作为身份提供者进行终端用户身份验证和授权。
weight: 9
---

在这个操作指南中，你将使用 Keycloak 作为身份提供者，在 Ingress Gateway 中添加用户身份验证和授权。

在开始之前，请确保你已经：

- 安装了 [TSB 管理平面](../../../setup/self-managed/management-plane-installation)
- 接入了一个 [集群](../../../setup/self-managed/onboarding-clusters)
- 安装了启用了 HTTPS 的 [Keycloak](https://www.keycloak.org/)

{{<callout note 注意>}}
本示例将使用经过 GKE 测试的 [httpbin](https://httpbin.org/) 应用程序的演示。如果你打算用于生产环境，请确保在相关字段中更新应用程序信息以适应你的情况。
{{</callout>}}

在本指南中，你将：

- 为演示的 httpbin 应用程序的 Ingress Gateway 添加身份验证和授权。
- 定义两个角色和两个用户：一个 *admin* 用户（称为 Jack），可以执行所有操作，以及一个 *normal* 用户（Sally），只能执行 `GET /status` 操作。
- 配置你的 Ingress Gateway，允许 *admin* 角色的用户访问所有内容，只允许 *normal* 角色的用户访问 `GET /status`。

## 什么是 OpenID 提供者？

OpenID 提供者是一个 OAuth 2.0 授权服务器，提供身份验证作为一项服务。它确保终端用户已经进行了身份验证，并提供了关于终端用户和身份验证事件的 [claims](https://openid.net/specs/draft-jones-json-web-token-07.html#anchor4) 给客户端应用程序。在本示例中，你将使用 Keycloak 作为 OpenID 提供者。你可以使用其他 OpenID 提供者（如 Auth0 或 Okta）采用类似的步骤。

{{<callout note 注意>}}
在本操作指南中，我们将使用 https://keycloak.example.com 作为 Keycloak 的 URL。你应该将其更改为你自己的 Keycloak URL。
{{</callout>}}

## 配置 Keycloak 作为 OpenID 提供者

登录到 Keycloak 管理界面。

{{<callout note 注意>}}
如果你已经创建了 Realm、Roles 和 Users，请直接转到 Client 部分。
{{</callout>}}

### Realm

首先创建 Realm。如果这是你第一次登录 Keycloak，你将拥有一个默认的主 Realm。该 Realm 用于管理对 Keycloak 界面的访问，不应该用于配置你的 OpenID 提供者。因此，你需要创建一个新的 Realm。

1. 单击 **Add Realm** 按钮。
2. 设置 Realm 名称，本示例中为 `tetrate`。
3. 单击 **Create**。

### Role

在创建的 Realm 中，添加两个新角色：admin 和 normal。

1. 在左侧菜单中点击 **Roles**。
2. 选择 **Add Role** 按钮。
3. 将名称设置为 **admin**。
4. 单击 **Save**。
5. 再次按上述步骤添加一个名称为 **normal** 的角色。

### Users

添加两个用户——Jack 和 Sally——并将它们映射到其新的角色：

1. 在左侧菜单中点击 **Users**。
2. 选择 **Add user** 按钮。
3. 填写 `Jack` 的详细信息。
4. 单击 **Save**。
5. 选择 **Credentials** 选项卡。
6. 为 `Jack` 设置密码。
7. 单击 **Role Mappings** 选项卡。
8. 添加 **admin** 角色。
9. 添加另一个用户名为 `Sally` 的用户，然后按照上述步骤，在 **Role Mappings** 选项卡中添加一个 `normal` 角色。

### Client

客户端是可以请求 Keycloak 对用户进行身份验证的实体。在这种情况下，Keycloak 将提供单点登录，用户将登录到该单点登录，获取一个 JWT 令牌，然后使用该令牌进行对 TSB 管理的 Ingress Gateway 的身份验证。

添加一个新的客户端。

1. 在左侧菜单中点击 **Clients**。
2. 选择客户端 **Create** 按钮。
3. 客户端 ID: `tetrateapp`。
4. 客户端 Protocol: openid-connect。
5. 根 URL: <https://www.keycloak.org/app/> 是 Keycloak 网站上可用的一个 SPA 测试应用程序。
6. 单击 **Save**。

接下来，在客户端中进行一些更新。

首先，增加令牌寿命，以确保令牌不会在测试过程中过快过期。

1. 在设置选项卡中，滚动到底部，选择 **Advanced Settings**。
2. 将 **Access Token Lifespan** 设置为 2 小时。
3. 单击 **Save**。

然后，你需要添加两个映射器，以便 Keycloak 可以生成一个带有你在 TSB Ingress Gateway 中使用的数据的 JWT。

你需要添加两种类型的映射器：一个 Audience 映射器和一个 Role 映射器：

| 映射器 | 目的 |
| --- | --- |
| Audience 映射器 | 将客户端 ID 添加到 JWT 令牌中的 audience 字段。这可以确保你可以将 JWT 令牌限制为特定客户端。 |
| Role 映射器 | 将 JWT 令牌中的角色从嵌套结构更改为数组。当前，TSB 无法处理 JWT 申明中的嵌套字段。这在 Istio 1.8 中已修复，并将在未来版本中添加到 TSB 中。 |

1. 选择 **Mappers** 选项卡。

2. 单击 **Create** 按钮，然后输入以下信息：
   - 名称：Audience 映射器。
   - 映射器类型：Audience。
   - 包含客户端受众：`tetrateapp`。
3. 单击 **Save**。

1. 返回到 **Mappers** 选项卡。
2. 单击 **Create** 按钮，然后输入以下信息：
   - 名称：Role 映射器。
   - 映射器类型：User Realm Role。
   - 令牌声明名称：roles。
   - 申明 JSON 类型：String。
   不要修改 multi-valued，添加到 ID token，添加到访问令牌和添加用户信息到 'on'。
3. 单击 **Save**。

### 测试用户登录

现在，你已经配置了客户端，请使用 Keycloak 示例应用程序或之前解释的 `curl` 来获取并检查你的 JWT 令牌。

1. 前往 https://www.keycloak.org/app/，并输入以下信息：
    - Keycloak URL: https://keycloak.example.com/auth
    - Realm: `tetrate`
    - Client: `tetrateapp`
2. 单击 **Save**。

要检查 JWT 令牌，请执行以下操作：

1. 打开浏览器控制台。
2. 单击 **Network** 选项卡。
3. 使用 Jack 的凭证登录。
4. 查找一个请求 `token`。在响应中，获取 `access_token`。
5. 将你的令牌粘贴到 https://jwt.io/。

你将从 JWT 令牌中看到以下信息。你只需要注意三个字段，这些字段将在你的 Ingress Gateway 配置中使用：`iss`、`aud` 和 `roles`。

```json
{
  "exp": 1606908135,
  "iat": 1606900935,
  "auth_time": 1606900917,
  "jti": "c1e45982-38c6-4d0d-b201-9d823eed4c0a",
  "iss": "https://keycloak.example.com/auth/realms/tetrate",
  "aud": [
    "tetrateapp",
    "account"
  ],
  "sub": "06765a3f-b09f-4c46-a0f9-0285c3924409",
  "typ": "Bearer",
  "azp": "tetrateapp",
  "nonce": "f96cd9eb-af9e-4e41-8591-ffc01fd94dd0",
  ...
  "scope": "openid email profile",
  "email_verified": true,
  "roles": [
    "offline_access",
    "admin",
    "uma_authorization"
  ],
  "name": "Jack White",
  "preferred_username": "jack",
  "given_name": "Jack",
  "family_name": "White",
  "email": "jack@tetrate.com"
}
```

你还可以使用 OAuth 的 Resource Owner Password Flow 获取用户 JWT 令牌。当你创建一个 Keycloak 客户端时，默认情况下会启用此流程。

```bash
curl --request POST \
    --url https://keycloak.example.com/auth/realms/tetrate/protocol/openid-connect/token \
    --header 'Content-Type: application/x-www-form-urlencoded' \
     --data client_id=tetrateapp \
     --data password=<user_password> \
     --data username=jack \
     --data grant_type=password \
     --data 'scope=openid email profile'
```

## 使用 Ingress Gateway 部署 Httpbin 应用程序

与 Ingress Gateway 一起部署 `httpbin` 应用程序。

创建以下 [`httpbin.yaml`](../../../assets/howto/httpbin.yaml)。

使用 kubectl 命令将 `httpbin` 部署到你的接入集群中：

```bash
kubectl create namespace httpbin
kubectl label namespace httpbin istio-injection=enabled --overwrite=true
kubectl apply -n httpbin -f httpbin.yaml
```

确认所有服务和 Pod 都在运行：

```bash
kubectl get pods -n httpbin
```

创建 Ingress Gateway [`ingress.yaml`](../../../assets/howto/ingress.yaml)。

应用更改：

```bash
kubectl apply -n httpbin -f ingress.yaml
```

确保所有服务和 Pod 都在运行。请等待，直到 Ingress Gateway 分配了其外部 IP。

```bash
kubectl get pods -n httpbin
kubectl get svc -n httpbin
```

获取 Ingress Gateway 的 IP：

```bash
export GATEWAY_HTTPBIN_IP=$(kubectl -n httpbin get service tsb-gateway-httpbin -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

## 配置工作区和 Ingress Gateway

现在，你的应用程序正在运行，你需要创建工作区并配置 Ingress Gateway。为此，你需要 TSB 运行和 tctl。

{{<callout note 注意>}}
如果你运行 TSB 演示安装，你将拥有一个名为 `tetrate` 的默认租户和一个名为 `demo` 的默认集群，我们在以下配置 YAML 中使用了它们。如果你在生产环境中使用，请将其更改为你自己的租户和集群。
{{</callout>}}

### 工作区

创建一个 [`workspace.yaml`](../../../assets/howto/workspace.yaml)。

应用更改：

```bash
tctl apply -f workspace.yaml
```

确保工作区已创建：

```bash
tctl get workspaces httpbin-ws
```

预期输出：

```text
  NAME
  httpbin-ws
```

接下来，创建一个 Ingress Gateway，允许从网格外部访问 httpbin。你将从一个没有身份验证的不安全 Gateway 开始。

### IngressGateway

创建以下 [`gateway-no-auth.yaml`](../../../assets/howto/gateway-no-auth.yaml)。在此示例中，已经为 HTTPS 连接设置了 `httpbin-certs`。

使用 `tctl` 应用：

```bash
tctl apply -f gateway-no-auth.yaml
```

验证你在 httpbin 命名空间中创建了一个网关：

```bash
kubectl get gateway -n httpbin httpbin-gw-ingress -o yaml
```

示例输出：

```yaml

apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  annotations:
    tsb.tetrate.io/fqn: tenants/tetrate/workspaces/httpbin-ws/gatewaygroups/httpbin-gw/ingressgateways/httpbin-gw-ingress
    xcp.tetrate.io/contentHash: ea6e317d90873ee3
  creationTimestamp: "2020-12-03T00:52:32Z"
  generation: 2
  labels:
    xcp.tetrate.io/gatewayGroup: httpbin-gw
    xcp.tetrate.io/workspace: httpbin-ws
  name: httpbin-gw-ingress
  namespace: httpbin
  resourceVersion: "6006430"
  selfLink: /apis/networking.istio.io/v1beta1/namespaces/httpbin/gateways/httpbin-gw-ingress
  uid: ab0ad2d9-b3db-40ac-9926-0e440d7d8c85
spec:
  selector:
    app: tsb-gateway-httpbin
  servers:
  - hosts:
    - httpbin/httpbin.tetrate.com
    port:
      name: http-httpbin
      number: 8443
      protocol: HTTP
  - hosts:
    - httpbin/httpbin.tetrate.com
    port:
      name: mtls-httpbin
      number: 15443
      protocol: HTTPS
    tls:
      mode: ISTIO_MUTUAL
```

尝试通过发送请求来访问 httpbin：

```bash
export GATEWAY_HTTPBIN_IP=$(kubectl -n httpbin get service tsb-gateway-httpbin -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -k -v "https://httpbin.tetrate.com/get" \
    --resolve "httpbin.tetrate.com:443:${GATEWAY_HTTPBIN_IP}" 
```

## 在 Ingress 启用身份验证和授权

现在，通过创建以下 [`gateway-with-auth.yaml`](../../../assets/howto/gateway-with-auth.yaml) 将身份验证和授权添加到你的 Ingress Gateway。

请注意，在身份验证块中，**audiences** 设置为 `tetrateapp`，这是之前在 JWT 令牌中设置的。

授权块设置了两个规则：一个是 *admin* 角色可以访问所有内容，另一个是 *normal* 角色只能访问 `GET /status`。

现在，应用这些更改。由于与之前的 `gateway-no-auth.yaml` 具有相同的名称，它将更新之前的网关。

```bash
tctl apply -f gateway-with-auth.yaml
```

如果尝试在没有 JWT 令牌的情况下访问 `httpbin`，将会收到 `403` 错误。

```bash
curl -k -o /dev/null -s \
    -w "%{http_code}\n" "https://httpbin.tetrate.com/get" \
    --resolve "httpbin.tetrate.com:443:${GATEWAY_HTTPBIN_IP}"
403
```

使用 JWT 令牌尝试访问网关。使用 Keycloak 示例应用程序或之前解释的 `curl` 获取令牌，并将令牌用于使用 `curl` 进行 HTTP 请求，分别为 Jack 和 Sally 的用户。在以下 `curl` 命令中，将 `<jack_access_token>` 和 `<sally_access_token>` 替换为用户的 JWT 令牌。

尝试使用 Jack 的令牌访问 `GET /get`（我们的管理员用户）：

```bash
curl -k -o /dev/null -s \
    -w "%{http_code}\n" "https://httpbin.tetrate.com/get" \
    --resolve "httpbin.tetrate.com:443:${GATEWAY_HTTPBIN_IP}" \
    --header "Authorization: Bearer <jack_access_token>"
200
```

尝试使用 Sally 的令牌访问 `GET /get`（我们的普通用户）。由于只允许 *normal* 角色的用户访问 `GET /status/*`，因此请求将失败：

```bash
curl -k -o /dev/null -s \
    -w "%{http_code}\n" "https://httpbin.tetrate.com/get" \
    --resolve "httpbin.tetrate.com:443:${GATEWAY_HTTPBIN_IP}" \
    --header "Authorization: Bearer <sally_access_token>"
403
```

尝试使用 Sally 的令牌访问 `GET /status/200`。请求应成功，因为 *normal* 角色的用户被允许访问 `GET /status/*`：

```bash
curl -k -o /dev/null -s \
    -w "%{http_code}\n" "https://httpbin.tetrate.com/status/200" \
    --resolve "httpbin.tetrate.com:443:${GATEWAY_HTTPBIN_IP}" \
    --header "Authorization: Bearer <sally_access_token>"
200
```
