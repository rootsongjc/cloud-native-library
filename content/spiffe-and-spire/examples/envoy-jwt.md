---
weight:  3
title: "使用 Envoy 和 JWT-SVID 进行安全的微服务通信"
linkTitle: "Envoy + JWT-SVID"
---

本教程在[SPIRE Envoy-X.509 教程](https://github.com/spiffe/spire-tutorials/blob/main/envoy-x509/)的基础上构建，演示如何使用 SPIRE 代替 X.509 SVID 进行工作负载的 JWT SVID 身份验证。在这个教程中展示了实现 JWT SVID 身份验证所需的更改，因此你应该首先运行或至少阅读 X.509 教程。

为了说明 JWT 身份验证，我们在 Envoy X.509 教程中使用的每个服务中添加了 sidecar。每个 sidecar 都充当 Envoy 的[外部授权过滤器](https://www.envoyproxy.io/docs/envoy/v1.25.1/intro/arch_overview/security/ext_authz_filter#arch-overview-ext-authz)。

![](../../images/SPIRE-Envoy_JWT-SVID_diagram.png)

如图所示，前端服务通过 Envoy 实例连接到后端服务，这些服务之间通过 Envoy 建立的 mTLS 连接进行通信。Envoy 通过携带的 JWT-SVID 进行身份验证的 HTTP 请求通过 mTLS 连接发送，并由 SPIRE Agent 提供和验证。

在本教程中，你将学习如何：

- 将 Envoy JWT Auth Helper gRPC 服务添加到 Envoy X.509 教程中现有的前端和后端服务中
- 将外部授权过滤器添加到 Envoy 配置中，将 Envoy 连接到 Envoy JWT Auth Helper
- 在 SPIRE Server 上为 Envoy JWT Auth Helper 实例创建注册条目
- 使用 SPIRE 测试成功的 JWT 身份验证

# 先决条件

## 支持外部 IP

此教程需要一个可以分配外部 IP（例如[metallb](https://metallb.universe.tf/)）的负载均衡器。

```bash
$ kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
```

等待 metallb 启动：

```bash
$ kubectl wait --namespace metallb-system \
                --for=condition=ready pod \
                --selector=app=metallb \
                --timeout=90s
```

应用 metallb 配置：

```bash
$ kubectl apply -f ../envoy-x509/metallb-config.yaml
```

## Auth helper 镜像

使用 Envoy-jwt-auth-helper 实现了一个外部授权过滤器，提供了一个脚本来方便地使用 `kind` 或 `minikube` 构建和导入。

```bash
$ bash ./scripts/build-helper.sh kind
```

## 之前的 SPIRE 安装

在继续之前，请查看以下内容：

- 你需要访问通过 SPIRE Envoy-X.509 教程*配置的 Kubernetes 环境。你也可以使用下面描述的 `pre-set-env.sh` 脚本创建 Kubernetes 环境。
- 本教程所需的 YAML 文件可以在 https://github.com/spiffe/spire-tutorials 的 `k8s/envoy-jwt` 目录中找到。如果你尚未克隆*SPIRE Envoy-X.509 教程*的存储库，请立即克隆它。

如果 Kubernetes 的*SPIRE Envoy-X.509 教程*环境不可用，你可以使用以下脚本创建它，并将其作为本教程的起点。从 `k8s/envoy-jwt` 目录中运行以下命令：

```bash
$ bash scripts/pre-set-env.sh
```

该脚本将创建集群中 SPIRE Server 和 SPIRE Agent 所需的所有资源，然后将为 SPIRE Envoy X.509 教程创建所有资源，这是本 SPIRE Envoy JWT 教程的基本场景。

# 第 1 部分：部署更新和新资源

假设 SPIRE Envoy X.509 教程是一个起点，需要更新一些资源并创建其他资源。目标是通过 JWT SVID 对工作负载进行身份验证。Envoy 实例之间已经建立了 mTLS 连接，可以在请求头中传输 JWT SVID。因此，缺失的部分是如何获取 JWT 并将其插入请求中，以及在另一侧进行验证。本教程中应用的解决方案包括在 Envoy 上配置外部授权过滤器，该过滤器根据配置模式注入或验证 JWT SVID。关于此示例服务器的详细信息，请参见[关于 Envoy JWT Auth Helper](https://spiffe.io/docs/latest/microservices/envoy-jwt/readme/#about-envoy-jwt-auth-helper)。

## 关于 Envoy JWT Auth Helper

Envoy JWT Auth Helper（`auth-helper` 服务）是一个简单的 gRPC 服务，实现了 Envoy 的 External Authorization Filter。它是为本教程开发的，以演示如何注入或验证 JWT SVID。

对于发送到 Envoy 转发代理的每个 HTTP 请求，Envoy JWT Auth Helper 从 SPIRE Agent 获取 JWT-SVID，并将其作为新的请求头注入，然后发送给 Envoy。另一方面，当 HTTP 请求到达反向代理时，Envoy External Authorization 模块将请求发送到 Envoy JWT Auth Helper，后者从标头中提取 JWT-SVID，然后连接到 SPIRE Agent 执行验证。验证成功后，请求将返回给 Envoy。如果验证失败，则拒绝请求。

在内部，Envoy JWT Auth Helper 利用[go-spiffe](https://github.com/spiffe/go-spiffe/)库，该库公开了获取和验证 JWT SVID 所需的所有功能。以下是代码的主要部分：

```go
// 使用 SPIRE 提供的 Unix 域套接字创建配置源的选项。
clientOptions := workloadapi.WithClientOptions(workloadapi.WithAddr(c.SocketPath))

...

// 创建 workloadapi.JWTSource 实例以从工作负载 API 中获取最新的 JWT 批。
jwtSource, err := workloadapi.NewJWTSource(context.Background(), clientOptions)
if err != nil {
   log.Fatalf("无法创建JWTSource：%v", err)
}
defer jwtSource.Close()

...

// 获取将添加到请求头中的 JWT-SVID。
jwtSVID, err := a.config.jwtSource.FetchJWTSVID(ctx, jwtsvid.Params{
   Audience: a.config.audience,
})
if err != nil {
   return forbiddenResponse("PERMISSION_DENIED"), nil
}

...

// 解析并验证令牌与 jwtSource 获取的批对比。
_, err := jwtsvid.ParseAndValidate(token, a.config.jwtSource, []string{a.config.audience})

if err != nil {
   return forbiddenResponse("PERMISSION_DENIED"), nil
}
```

注意：`workloadapi` 和 `jwtsvid` 是从 `go-spiffe` 库导入的。

## 更新部署

`auth-helper` 服务使得 Envoy 能够注入或验证携带 JWT-SVID 的身份验证头，如上所述。在这些部分中，`k8s/backend/config/envoy.yaml` 中的 YAML 文件片段说明了将 JWT 身份验证添加到在[SPIRE Envoy-X.509 教程](https://github.com/spiffe/spire-tutorials/blob/main/envoy-x509/)中定义的 `backend` 服务所需的更改。其他 YAML 文件也对其他两个服务（`frontend` 和 `frontend-2`）应用了相同的更改，但是本文档中不会详细描述这些更改，以避免不必要的重复。你无需手动对 YAML 文件进行这些更改。新文件已包含在 `k8s/envoy-jwt/k8s` 目录中。必须将此新的 `auth-helper` 服务作为 sidecar 添加，并且必须配置它与 SPIRE Agent 通信。通过挂载卷来共享 SPIRE Agent 提供的 Unix 域套接字来实现这一目标。通过新的第二个卷，可以访问使用服务配置定义的 configmap。下面是来自 `containers` 部分的代码片段，描述了这些更改：

```yaml
- name: auth-helper
  image: envoy-jwt-auth-helper:latest
  imagePullPolicy: IfNotPresent
  args:  ["-config", "/run/envoy-jwt-auth-helper/config/envoy-jwt-auth-helper.conf"]
  ports:
  - containerPort: 9010
  volumeMounts:
  - name: envoy-jwt-auth-helper-config
    mountPath: "/run/envoy-jwt-auth-helper/config"
    readOnly: true
  - name: spire-agent-socket
    mountPath: /run/spire/sockets
    readOnly: true
```

`spire-agent-socket` 卷已在部署中定义，无需再次添加。要将 configmap `envoy-jwt-auth-helper-config` 添加到 `volumes` 部分，可以使用以下代码：

```yaml
- name: envoy-jwt-auth-helper-config
  configMap:
     name: be-envoy-jwt-auth-helper-config
```

## 添加外部授权过滤器

接下来，在 Envoy 配置中需要一个外部授权过滤器，该过滤器连接到新的服务。这个新的 HTTP 过滤器调用了刚刚添加到部署中的 `auth-helper` 服务：

```yaml
http_filters:
- name: envoy.filters.http.ext_authz
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.filters.http.ext_authz.v3.ExtAuthz
    transport_api_version: V3
    grpc_service:
      envoy_grpc:
        cluster_name: ext-authz
      timeout: 0.5s
```

这是外部授权过滤器的相应集群配置：

```yaml
- name: ext-authz
  connect_timeout: 1s
  type: strict_dns
  http2_protocol_options: {}
  load_assignment:
    cluster_name: ext-authz
    endpoints:
    - lb_endpoints:
      - endpoint:
          address:
            socket_address:
              address: 127.0.0.1
              port_value: 9010
```

## 应用新资源

为了使新的配置生效，需要重新部署服务。让我们删除 `backend` 和 `frontend` 部署以便更新它们：

```bash
$ kubectl delete deployment backend
$ kubectl delete deployment frontend
```

确保当前工作目录是 `.../spire-tutorials/k8s/envoy-jwt`，然后使用以下命令部署新资源：

```bash
$ kubectl apply -k k8s/.

configmap/backend-envoy configured
configmap/be-envoy-jwt-auth-helper-config created
configmap/fe-envoy-jwt-auth-helper-config created
configmap/frontend-envoy configured
deployment.apps/backend configured
deployment.apps/frontend configured
```

## 创建注册条目

为了获取或验证由 SPIRE 发行的 JWT SVID，需要对 `auth-helper` 实例在 SPIRE 服务器上进行身份验证。可以使用以下 Bash 脚本为每个实例创建注册条目：

```bash
$ bash create-registration-entries.sh
```

脚本运行后，将显示新的注册条目列表。

```
...
Creating registration entry for the backend - auth-server...
Entry ID      : ecb140ab-50a7-4590-9fe0-d715ada67f29
SPIFFE ID     : spiffe://example.org/ns/default/sa/default/backend
Parent ID     : spiffe://example.org/ns/spire/sa/spire-agent
TTL           : 3600
Selector      : k8s:ns:default
Selector      : k8s:sa:default
Selector      : k8s:pod-label:app:backend
Selector      : k8s:container-name:auth-helper

Creating registration entry for the frontend - auth-server...
Entry ID      : 59a127fa-328c-4115-883e-5ee20b86714f
SPIFFE ID     : spiffe://example.org/ns/default/sa/default/frontend
Parent ID     : spiffe://example.org/ns/spire/sa/spire-agent
TTL           : 3600
Selector      : k8s:ns:default
Selector      : k8s:sa:default
Selector      : k8s:pod-label:app:frontend
Selector      : k8s:container-name:auth-helper
...
```

请注意，新服务的选择器指向 `auth-helper` 容器：`k8s:container-name:auth-helper`。这是为了对 `auth-helper` 服务进行身份验证，以便它可以获取或验证配置为每个请求的身份验证标头的 JWT SVID。

有意地，`frontend-2` 服务没有注册条目。稍后将添加它，以演示在请求标头中没有 JWT-SVID 时，外部授权过滤器将拒绝请求。

# 第二部分：测试连接

既然服务已经部署并在 SPIRE 中注册，让我们来测试我们配置的授权机制。

## 测试有效和无效的 JWT-SVID

第一组测试将演示如何通过有效的 JWT-SVID 来显示关联数据，以及如何通过无效的 JWT-SVID 阻止关联数据的显示。为了运行这些测试，我们需要找到组成用于访问数据的 URL 的 IP 地址和端口。

```bash
$ kubectl get services

NAME            TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)          AGE
backend-envoy   ClusterIP      None            <none>           9001/TCP         10m
frontend        LoadBalancer   10.96.226.176   172.18.255.200   3000:32314/TCP   10m
frontend-2      LoadBalancer   10.96.33.198    172.18.255.201   3002:31797/TCP   10m
kubernetes      ClusterIP      10.96.0.1       <none>           443/TCP          55m
```

`frontend` 服务将在 `EXTERNAL-IP` 值和端口 `3000` 上提供。在上面显示的示例输出中，要访问的 URL 是 `http://172.18.255.200:3000`。打开浏览器，并在你的环境中的 `frontend` 的 IP 地址后面添加端口 `:3000`。页面加载完成后，你将看到用户*Jacob Marley*的帐户详细信息。

![](../../images/frontend_view.png)

另一方面，当你连接到 `frontend-2` 服务的 URL（例如 `http://172.18.255.201:3002`）时，浏览器只显示标题而没有任何帐户详细信息。这是因为 `frontend-2` 服务没有在请求中包含 JWT 令牌。请求中缺少有效的令牌使得位于 `backend` 前面的 Envoy 实例拒绝该请求。

![](../../images/frontend-2_view_no_details.png)

让我们来看看 `auth-helper` 容器的日志，以了解幕后发生了什么。以下是与 `frontend` 服务并行运行的 `auth-helper` 实例的日志。在这种情况下，`auth-helper` 服务器配置为以注入模式运行。对于每个请求，它将 JWT-SVID 作为新的请求头注入并将其返回给将其转发给 `backend` 的 Envoy 实例。

```bash
$ kubectl logs -f --selector=app=frontend -c auth-helper
Envoy JWT Auth Helper running in jwt_injection mode
Starting gRPC Server at 9011
JWT-SVID injected. Sending response with 1 new headers
JWT-SVID injected. Sending response with 1 new headers
JWT-SVID injected. Sending response with 1 new headers
```

另一方面，位于 `backend` 服务前面的 `auth-helper` 实例配置为以验证模式运行，因此它将检查请求标头中的 JWT-SVID。它提取令牌并对其进行验证。在这种情况下，前三个请求的令牌是有效的，然后将其发送回 Envoy 实例。这些请求来自 `frontend` 服务。

```bash
$ kubectl logs -f --selector=app=backend -c auth-helper
Envoy JWT Auth Helper running in jwt_svid_validator mode
Starting gRPC Server at 9010
Token is valid
Token is valid
Token is valid
Invalid or unsupported authorization header: []
Invalid or unsupported authorization header: []
Invalid or unsupported authorization header: []
```

当请求来自 `frontend-2` 服务时（最后 3 条日志记录），`auth-helper` 无法从请求中获取 JWT-SVID 并将其拒绝。这就是为什么在 `frontend-2` 服务的浏览器中不显示帐户详细信息的原因。

## 使用有效的 JWT-SVID 重新测试 frontend-2

为了使 `frontend-2` 能够成功进行 JWT-SVID 身份验证，我们将更新 Kubernetes 环境，使 `frontend-2` 具有与 `frontend` 类似的设置。这包括为 `auth-helper` 服务创建一个新的容器，为 `auth-helper` 创建一个新的 configmap，以及使用外部授权过滤器更新 `frontend-2-envoy` 的 configmap。让我们先删除 `frontend-2` 的部署，以准备新的配置。

```bash
$ kubectl delete deployment frontend-2
```

要更新 `frontend-2` 的 Envoy 配置和服务部署，请使用 `k8s/frontend-2/kustomization.yaml` 文件：

```bash
$ kubectl apply -k k8s/frontend-2/.

configmap/fe-2-envoy-jwt-auth-helper-config created
configmap/frontend-2-envoy configured
deployment.apps/frontend-2 created
```

接下来，通过为 `auth-helper` 服务在 SPIRE Server 中创建一个新的注册条目来对其进行身份验证：

```bash
$ bash k8s/frontend-2/create-registration-entry.sh

Creating registration entry for the frontend-2 - auth-server...
Entry ID      : bd0acd51-0d36-42be-8999-fccdcf1f33da
SPIFFE ID     : spiffe://example.org/ns/default/sa/default/frontend-2
Parent ID     : spiffe://example.org/ns/spire/sa/spire-agent
TTL           : 3600
Selector      : k8s:ns:default
Selector      : k8s:sa:default
Selector      : k8s:pod-label:app:frontend-2
Selector      : k8s:container-name:auth-helper
```

等待一些时间，让部署传播后再次尝试在浏览器中查看 `frontend-2` 服务。一旦 Pod 准备好并且注册条目传播完毕，请使用 `frontend-2` 服务的正确 URL（例如 `http://35.222.190.182:3002`）刷新浏览器。结果，现在页面显示用户*Alex Fergus*的帐户详细信息。

![](../../images/frontend-2_view.png)

# 清理

完成本教程后，你可以使用以下命令删除用于配置 Envoy 代表工作负载执行 JWT SVID 身份验证的所有资源。此命令将删除：

- 为 SPIRE - Envoy JWT 集成教程创建的所有资源。
- 为 SPIRE - Envoy X.509 集成教程创建的所有资源。
- SPIRE 代理、SPIRE 服务器和命名空间的所有部署和配置。

```bash
$ bash scripts/clean-env.sh
```
