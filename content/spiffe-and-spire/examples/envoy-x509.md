---
weight: 2
linktitle: "Envoy + X.509"
title: "使用 Envoy 和 X.509-SVID"
---

本教程在[Kubernetes 快速入门教程](https://spiffe.io/docs/latest/try/getting-started-k8s/)的基础上，演示了如何配置 SPIRE 以提供动态的 X.509 证书形式的服务身份，并由 Envoy 秘密发现服务（SDS）进行使用。本教程中展示了实现 X.509 SVID 身份验证所需的更改，因此你应该首先运行或至少阅读 Kubernetes 快速入门教程。

为了演示 X.509 身份验证，我们创建了一个简单的场景，包含三个服务。其中一个服务是后端服务，是一个简单的 nginx 实例，用于提供静态数据。另一方面，我们运行两个`Symbank`演示银行应用作为前端服务。`Symbank`前端服务向 nginx 后端发送 HTTP 请求以获取用户账户详细信息。

![](../../images/SPIRE_Envoy_diagram.png)

如图所示，前端服务通过 Envoy 实例建立的 mTLS 连接与后端服务连接，并且 Envoy 实例会为每个工作负载执行 X.509 SVID 身份验证。

在本教程中，你将学习如何：

- 配置 SPIRE 以支持 SDS
- 配置 Envoy SDS 以使用 SPIRE 提供的 X.509 证书
- 在 SPIRE 服务器上为 Envoy 实例创建注册条目
- 使用 SPIRE 测试成功的 X.509 身份验证
- 可选地配置 Envoy RBAC HTTP 过滤器策略

## 先决条件

在继续之前，请先阅读以下内容：

- 你需要访问通过[Kubernetes 快速入门教程](https://spiffe.io/docs/latest/try/getting-started-k8s/)配置的 Kubernetes 环境。可选地，你可以使用下面描述的 `pre-set-env.sh` 脚本创建 Kubernetes 环境。Kubernetes 环境必须能够将 Ingress 公开到公共互联网上。**注意：对于本地 Kubernetes 环境（例如 Minikube），通常不适用此条件**。
- 本教程所需的 YAML 文件可在 https://github.com/spiffe/spire-tutorials 的 `k8s/envoy-x509` 目录中找到。如果你尚未克隆*Kubernetes 快速入门教程*的存储库，请现在进行克隆。

如果*Kubernetes 快速入门教程*环境不可用，你可以使用以下脚本创建该环境，并将其用作本教程的起点。从`k8s/envoy-x509`目录中运行以下命令：

```
$ bash scripts/pre-set-env.sh
```

该脚本将创建所需的 SPIRE 服务器和 SPIRE 代理资源。

### 外部 IP 支持

本教程需要一个可以分配外部 IP 的负载均衡器（例如[metallb](https://metallb.universe.tf/)）。

```bash
$ kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
```

等待 metallb 启动

```bash
$ kubectl wait --namespace metallb-system \
                --for=condition=ready pod \
                --selector=app=metallb \
                --timeout=90s
```

应用 metallb 配置

```bash
$ kubectl apply -f metallb-config.yaml
```

## Envoy SDS 支持

SPIRE 代理原生支持 Envoy Secret Discovery Service（SDS）。SDS 通过与工作负载 API 和连接到 SDS 的 Envoy 进程使用相同的 Unix 域套接字提供服务，并对工作负载进行验证。

## 第 1 部分：运行工作负载

现在，让我们部署本教程中将使用的工作负载。它由三个工作负载组成：如前所述，两个*Symbank*演示应用程序的实例将充当前端服务，另一个提供静态文件的 nginx 实例将充当后端服务。

为了区分两个*Symbank*应用程序的实例，让我们将其称为*frontend*和*frontend-2*。前者配置为显示与用户*Jacob Marley*相关的数据，而后者将显示用户*Alex Fergus*的帐户详细信息。

## 部署所有工作负载

确保当前的工作目录是 `.../spire-tutorials/k8s/envoy-x509`，然后使用以下命令部署新的资源：

```
$ kubectl apply -k k8s/.
configmap/backend-balance-json-data created
configmap/backend-envoy created
configmap/backend-profile-json-data created
configmap/backend-transactions-json-data created
configmap/frontend-2-envoy created
configmap/frontend-envoy created
configmap/symbank-webapp-2-config created
configmap/symbank-webapp-config created
service/backend-envoy created
service/frontend-2 created
service/frontend created
deployment.apps/backend created
deployment.apps/frontend-2 created
deployment.apps/frontend created
```

`kubectl apply` 命令将创建以下资源：

- 每个工作负载的部署。它包含一个用于我们的服务和 Envoy Sidecar 的容器。
- 每个工作负载的服务。用于它们之间的通信。
- 多个 Configmap：
  - *json-data* 用于向作为后端服务运行的 Nginx 实例提供静态文件。
  - *envoy* 包含每个工作负载的 Envoy 配置。
  - *symbank-webapp-* 包含供每个前端服务实例使用的配置。

接下来的两个部分将重点介绍配置 Envoy 所需的设置。

#### SPIRE Agent 集群

为了让 Envoy SDS 使用 SPIRE Agent 提供的 X.509 证书，我们配置一个集群，指向 SPIRE Agent 提供的 Unix 域套接字。后端服务的 Envoy 配置位于 `k8s/backend/config/envoy.yaml`。

```yaml
clusters:
- name: spire_agent
  connect_timeout: 0.25s
  http2_protocol_options: {}
  load_assignment:
    cluster_name: spire_agent
    endpoints:
    - lb_endpoints:
      - endpoint:
          address:
            pipe:
              path: /run/spire/sockets/agent.sock
```

#### TLS 证书

要从 SPIRE 获取 TLS 证书和私钥，你需要在 TLS 上下文中设置一个 SDS 配置。TLS 证书的名称是 Envoy 充当代理的服务的 SPIFFE ID。此外，SPIRE 为每个信任域提供一个验证上下文，Envoy 使用它来验证对等证书。

```yaml
transport_socket:
  name: envoy.transport_sockets.tls
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.DownstreamTlsContext
    common_tls_context:
      tls_certificate_sds_secret_configs:
      - name: "spiffe://example.org/ns/default/sa/default/backend"
        sds_config:
          resource_api_version: V3
          api_config_source:
            api_type: GRPC
            transport_api_version: V3
            grpc_services:
              envoy_grpc:
                cluster_name: spire_agent
      combined_validation_context:
        # validate the SPIFFE ID of incoming clients (optionally)
        default_validation_context:
          match_typed_subject_alt_names:
          - san_type: URI
            matcher:
              exact: "spiffe://example.org/ns/default/sa/default/frontend"
          - san_type: URI
            matcher:
              exact: "spiffe://example.org/ns/default/sa/default/frontend-2"
        # obtain the trust bundle from SDS
        validation_context_sds_secret_config:
          name: "spiffe://example.org"
          sds_config:
            resource_api_version: V3
            api_config_source:
              api_type: GRPC
              transport_api_version: V3
              grpc_services:
                envoy_grpc:
                  cluster_name: spire_agent
```

类似的配置也适用于前端服务，以建立一个 mTLS 通信。检查名为 `backend` 的集群在 `k8s/frontend/config/envoy.yaml` 和 `k8s/frontend-2/config/envoy.yaml` 中的配置。

### 创建注册条目

为了获得 SPIRE 颁发的 X.509 证书，必须先注册服务。我们通过在 SPIRE Server 上为每个工作负载创建注册条目来实现这一点。让我们使用以下 Bash 脚本：

```bash
$ bash create-registration-entries.sh
```

运行脚本后，将显示所创建的注册条目列表。输出将显示 [Kubernetes Quickstart Tutorial](https://spiffe.io/docs/latest/try/getting-started-k8s/) 创建的其他注册条目。这里重要的是每个工作负载的三个新条目：

```
...
Entry ID      : 0d02d63f-712e-47ad-a06e-853c8b062835
SPIFFE ID     : spiffe://example.org/ns/default/sa/default/backend
Parent ID     : spiffe://example.org/ns/spire/sa/spire-agent
TTL           : 3600
Selector      : k8s:container-name:envoy
Selector      : k8s:ns:default
Selector      : k8s:pod-label:app:backend
Selector      : k8s:sa:default

Entry ID      : 3858ec9b-f924-4f69-b812-5134aa33eaee
SPIFFE ID     : spiffe://example.org/ns/default/sa/default/frontend
Parent ID     : spiffe://example.org/ns/spire/sa/spire-agent
TTL           : 3600
Selector      : k8s:container-name:envoy
Selector      : k8s:ns:default
Selector      : k8s:pod-label:app:frontend
Selector      : k8s:sa:default

Entry ID      : 4e37f863-302a-4b3c-a942-dc2a86459f37
SPIFFE ID     : spiffe://example.org/ns/default/sa/default/frontend-2
Parent ID     : spiffe://example.org/ns/spire/sa/spire-agent
TTL           : 3600
Selector      : k8s:container-name:envoy
Selector      : k8s:ns:default
Selector      : k8s:pod-label:app:frontend-2
Selector      : k8s:sa:default
...
```

请注意，我们工作负载的选择器指向了 Envoy 容器：k8s:container-name:envoy。这是我们配置 Envoy 代表工作负载执行 X.509 SVID 身份验证的方式。

## 第二部分：测试连接

现在，服务已经部署并在 SPIRE 中注册，让我们测试我们配置的授权。

### 使用有效的 X.509 SVID 进行身份验证的测试

第一组测试将演示如何使用有效的 X.509 SVID 显示相关数据。为此，我们将展示前端服务 (`frontend`和`frontend-2`) 如何通过获取每个服务的正确 IP 地址和端口与`backend`服务进行通信。要运行这些测试，我们需要找到用于访问数据的 URL 所组成的 IP 地址和端口。

```bash
$ kubectl get services

NAME            TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)          AGE
backend-envoy   ClusterIP      None          <none>           9001/TCP         6m53s
frontend        LoadBalancer   10.8.14.117   35.222.164.221   3000:32586/TCP   6m52s
frontend-2      LoadBalancer   10.8.7.57     35.222.190.182   3002:32056/TCP   6m53s
kubernetes      ClusterIP      10.8.0.1      <none>           443/TCP          59m
```

`frontend`服务将在`EXTERNAL-IP`值和端口`3000`处可用，这是我们容器配置的端口。在上面显示的示例输出中，导航的 URL 为`http://35.222.164.221:3000`。打开浏览器并导航到环境中显示的`frontend`的 IP 地址，添加端口`:3000`。页面加载完成后，你将看到用户*Jacob Marley*的账户详细信息。

![](../../images/frontend_view.png)

按照相同的步骤，当你连接到`frontend-2`服务的 URL 时（例如`http://35.222.190.182:3002`），浏览器将显示用户*Alex Fergus*的账户详细信息。

![](../../images/frontend-2_view.png)

### 更新 TLS 配置以便只有一个前端可以访问后端

`backend`服务的 Envoy 配置使用 TLS 配置来通过验证 TLS 连接上呈现的证书的主题备用名称 (SAN) 来过滤传入的连接。对于 SVIDs，证书的 SAN 字段设置为与服务关联的 SPIFFE ID。因此，通过在`combined_validation_context`部分的[Envoy 配置](https://github.com/spiffe/spire-tutorials/blob/main/k8s/envoy-x509/k8s/backend/config/envoy.yaml#L49)中删除`frontend-2`服务的 SPIFFE ID，可以使`backend`服务的 Envoy 配置允许仅来自`frontend`服务的请求。更新后的配置如下所示：

```
combined_validation_context:
  # validate the SPIFFE ID of incoming clients (optionally)
  default_validation_context:
    match_typed_subject_alt_names:
    - san_type: URI
      matcher:
        exact: "spiffe://example.org/ns/default/sa/default/frontend"
```

### 应用 Envoy 的新配置

使用文件`backend-envoy-configmap-update.yaml`更新`backend`工作负载的 Envoy 配置：

```bash
$ kubectl apply -f backend-envoy-configmap-update.yaml
```

接下来，需要重新启动`backend` Pod 以应用新配置：

```bash
$ kubectl scale deployment backend --replicas=0
$ kubectl scale deployment backend --replicas=1
```

在尝试再次在浏览器中查看`frontend-2`服务之前，请等待几秒钟以使部署生效。一旦 Pod 准备就绪，请使用`frontend-2`服务的正确 URL（例如`http://35.222.190.182:3002`）刷新浏览器。结果，现在 Envoy 不允许请求到达`backend`服务，并且浏览器中不显示账户详细信息。

![](../../images/frontend-2_view_no_details.png)

另一方面，你可以检查`frontend`服务仍然能够从`backend`获得响应。刷新浏览器以正确的 URL（例如`http://35.222.164.221:3000`），并确认对*Jacob Marley*的账户显示账户详细信息。

## 通过基于角色的访问控制过滤器扩展场景

Envoy 提供了一种基于角色的访问控制（RBAC）HTTP 过滤器，它根据一组策略检查请求。策略由权限和主体组成，其中主体指的是请求的下游客户端身份，例如下游客户端证书的 URI SAN。因此，我们可以使用为服务分配的 SPIFFE ID 创建策略，以实现更细粒度的访问控制。

“Symbank”演示应用程序使用三个不同的端点来获取有关银行账户的所有信息。`/profiles`端点提供账户所有者的姓名和地址。另外两个端点，`/balances`和`/transactions`，提供账户的余额和交易信息。

为了演示 Envoy 的 RBAC 过滤器，我们可以创建一个策略，允许“frontend”服务仅获取`/profiles`端点的数据，并拒绝发送到其他端点的请求。这可以通过定义一个主体与服务的 SPIFFE ID 匹配以及只允许对`/profiles`资源进行 GET 请求的权限来实现。

可以将以下代码片段添加到`backend`服务的 Envoy 配置中作为新的 HTTP 过滤器来测试该策略。*注意：为了使 Envoy 配置正常工作，必须在现有的`envoy.router`过滤器之前添加此代码片段*。

```yaml
- name: envoy.filters.http.rbac
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.filters.http.rbac.v3.RBAC
    rules:
      action: ALLOW
      policies:
        "general-rules":
          permissions:
              - and_rules:
                  rules:
                    - header: { name: ":method", exact_match: "GET" }
                    - url_path:
                        path: { prefix: "/profiles" }
          principals:
          - authenticated:
              principal_name:
                exact: "spiffe://example.org/ns/default/sa/default/frontend"
```

该示例演示了如何在已由 SPIRE 获得其身份的 Envoy 实例建立了 TLS 连接时，根据请求参数执行更精细的访问控制。

## 清理

完成本教程后，你可以使用以下脚本删除用于配置 Envoy 以代表工作负载执行 X.509 身份验证的所有资源。此命令将删除：

- 用于 SPIRE - Envoy X.509 集成教程的所有资源。
- SPIRE 代理、SPIRE 服务器和命名空间的所有部署和配置。

```bash
$ bash scripts/clean-env.sh
```