---
title: 应用程序入口
weight: 14
---

应用程序入口是一个 L7 入口，允许应用程序开发人员直接利用可用的 Envoy 功能。
与 TSB 中其他类型的 Ingress 不同，配置它不需要管理员权限，
并以一种使应用程序开发人员更容易定义意图的方式公开 Envoy 代理的功能。

应用程序入口是 Istio 的一个简化版本，使用 Istiod 作为控制平面组件和 Istio IngressGateway（即 Envoy 代理）作为数据平面组件。应用程序入口在由应用程序拥有的命名空间中为每个应用程序部署，并只能使用来自其部署的命名空间的 Istio 配置。

应用程序入口还具有一个 OpenAPI 翻译器附加组件，允许用户使用 OpenAPI 规范配置入口。

此功能需要 tctl 版本 1.4.5 或更高版本。

## 使用 Istio 进行配置

在此示例中，你将在一个命名空间中安装 `httpbin`，并在相同命名空间中创建一个应用程序入口，以路由访问 `httpbin` 工作负载。

创建名为 `httpbin-appingress` 的命名空间。

```bash
kubectl create namespace httpbin-appingress
```

你将在同一个命名空间中安装工作负载和应用程序入口。

在此示例中，工作负载将是 `httpbin` 服务。[按照这些说明安装 `httpbin`](../../../reference/samples/httpbin)。

使用以下命令安装应用程序入口。

```bash
tctl experimental app-ingress kubernetes generate -n httpbin-appingress | \
  kubectl apply -f -
```

{{<callout note 注意>}}
你可能会看到错误消息 `unable to recognize "STDIN": no matches for kind "IstioOperator" in version "install.istio.io/v1alpha1"`。如果遇到此错误，请重新运行上面的命令。这是因为尚未部署 `IstioOperator` CRD，通常在重试后会消失。
{{</callout>}}

验证命名空间 `httpbin-appingress` 中的 `httpbin`、`istio-ingressgateway` 和 `istiod` pod 是否正常运行：

```bash
kubectl get pod -n httpbin-appingress

NAME                                    READY   STATUS    RESTARTS   AGE
httpbin-74fb669cc6-lc4qm                1/1     Running   0          10m
istio-ingressgateway-6f9c469bd5-r7z4t   1/1     Running   0          8m8s
istio-operator-1-11-3-f88d885b5-8wb9k   1/1     Running   0          8m42s
istiod-1-11-3-597999c56f-5f2xr          1/1     Running   0          8m19s
```

你需要通过主机名 `httpbin-appingress.example.com` 访问 `httpbin` 服务。为此，
在 `httpbin-appingress` 命名空间中部署一个 Istio Gateway 和 Virtual Service，以路由 HTTP 流量到
`httpbin` pod。

创建一个名为 `httpbin-appingress-virtualservice.yaml` 的文件，内容如下：

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  selector:
    istio: ingressgateway # 使用 Istio 默认网关实现
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "httpbin-appingress.example.com"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "httpbin-appingress.example.com"
  gateways:
  - httpbin-gateway
  http:
  - match:
    - uri:
        prefix: /status
    - uri:
        prefix: /delay
    route:
    - destination:
        port:
          number: 8000
        host: httpbin
```

使用 `kubectl` 应用这些配置：

```bash
kubectl -n

 httpbin-appingress -f httpbin-appingress-virtualservice.yaml
```

由于尚未为 `httpbin-appingress.example.com` 设置 DNS，你需要设置你的环境或更改发出 HTTP 请求的方式，以访问你创建的服务。在此示例中，你将使用 `kubectl port-forward` 来建立端口转发。

在不同的终端中，使用本地端口 4040 设置到 `httpbin-appingress` 命名空间中的 `istio-ingressgateway` 服务的端口转发：

```bash
kubectl -n httpbin-appingress port-forward svc/istio-ingressgateway 4040:80 
```

现在，你应该能够通过 `istio-ingressgateway` 服务访问 `httpbin` 应用程序，该服务在 `httpbin-appingress` 命名空间中运行，
使用以下命令：

```bash
curl -s -I \
  -H "Host: httpbin-appingress.example.com" \
  http://localhost:4040/status/200
```

## 使用 OpenAPI 翻译器

如果你的应用程序提供 OpenAPI 规范（3.0.0 或更高版本），你可以使用它来生成路由规则到你的应用程序。OpenAPI 翻译器插件将应用程序的 OpenAPI 规范，并将其翻译为 Istio 配置，并将其应用于应用程序入口。

在此示例中，你将使用 `bookinfo` 示例应用程序，并使用其 OpenAPI 规范。

创建一个新的命名空间 `bookinfo-openapi`：

```bash
kubectl create namespace bookinfo-openapi
```

将 `bookinfo` 示例部署到 `bookinfo-openapi` 命名空间中：

```bash
kubectl apply -n bookinfo-openapi \
   -f https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/platform/kube/bookinfo.yaml 
```

一旦验证应用程序已正确部署，就在 `bookinfo-openapi` 命名空间中部署应用程序入口。你需要指定 OpenAPI 规范描述的 "backend" 服务（应用程序）。

```bash
tctl experimental app-ingress kubernetes generate \
  -n bookinfo-openapi \
  --openapi-translator \
  --openapi-backend-service http://productpage.bookinfo-openapi.svc.cluster.local:9080 \
  | kubectl apply -f - 
```

上面的命令创建一个应用程序入口，该入口期望在名为 `openapi-translator` 的 `ConfigMap` 中提供 OpenAPI 规范。由于你尚未提供规范，因此无法正确配置应用程序入口。

你需要获取 `bookinfo` 的 OpenAPI 规范，但 [Istio 提供的示例仅以 OpenAPI 2.0 格式提供](https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/swagger.yaml)。已将 `bookinfo` OpenAPI 规范转换为 OpenAPI 3.0.0 的版本可通过 [此链接](../../../assets/howto/bookinfo-openapi.yaml) 获取。将文件下载为 `bookinfo-openapi.yaml`。

使用以下命令使用此文件创建 `ConfigMap`：

```bash
kubectl -n bookinfo-openapi create configmap openapi-translator \
  --from-file=bookinfo-openapi.yaml
```

当 OpenAPI 翻译器捕获配置时，将在命名空间中提供 Istio 资源，可以通过执行 `kubectl get gateway` 和 `kubectl get virtualservice` 命令来验证这一点：

```bash
kubectl -n bookinfo-openapi get gateway

NAME                                    AGE
istio-ingressgateway-f6fb54b17b9120eb   64s
```

```bash
kubectl -n bookinfo-openapi get virtualservice

NAME                                                     GATEWAYS                                                     HOSTS                  AGE
istio-ingressgateway-f6fb54b17b9120eb-www-bookinfo-com   ["bookinfo-openapi/istio-ingressgateway-f6fb54b17b9120eb"]   ["www.bookinfo.com"]   5m13s
```

还可以通过添加注解来利用更多 TSB 功能，如速率限制、身份验证和授权，[通过添加注释](../../../refs/tsb/application/v2/openapi-extensions) 到你的 OpenAPI 规范中。

## 使用 IstioOperator 扩展应用程序入口

可以使用 [Istio Operator](https://istio.io/latest/docs/reference/config/istio.operator.v1alpha1/) 进一步配置应用程序入口中的 Istio 组件。

例如，如果要在应用程序入口中配置自定义 CA 证书（在 Kubernetes 版本高于 1.22 的情况下特别有用，因为 Kubernetes 的 `pilotCertProvider` 已弃用），创建一个名为 `configure-plug-in-certs.yaml` 的文件：

```yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: bookinfo-appingress
  name: bookinfo-appingress 
spec:
  values:
    global:
      pilotCertProvider: istiod
```

创建包含证书和密钥的 `cacerts` 密钥。有关更多信息，请单击[此处](https://istio.io/latest/docs/tasks/security/cert-management/plugin-ca-cert/)。
你可以通过使用 Istio 发行包提供的示例证书运行以下命令来进行测试。

```bash
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.11.3 sh -
```

运行以下命令创建 `cacerts` 密钥。

```bash
kubectl create secret generic cacerts -n bookinfo-appingress --from-file=ca-cert.pem=istio-1.11.3/samples/certs/ca-cert.pem --from-file=ca-key.pem=istio-1.11.3/samples/certs/ca-key.pem --from-file=root-cert.pem=istio-1.11.3/samples/certs/root-cert.pem --from-file=cert-chain.pem=istio-1.11.3/samples/certs/cert-chain.pem
```

然后，通过指定 `-f`（`--filename`）标志来提供此文件，以生成应用程序入口的清单：

```bash
tctl experimental app-ingress kubernetes generate \
  -n bookinfo-appingress \
  -f configure-plug-in-certs.yaml \
  | kubectl apply -f -
```

{{<callout note 注意>}}
如果在单个集群中运行多个 App Ingress 并且使用自定义 `cacerts`，请确保在运行 App Ingress 的每个命名空间中使用相同的 `cacerts` 密钥。
{{</callout>}}

## 在 Docker 中运行 App Ingress

如果你在主要的 Kubernetes 环境中有部署限制，可以通过 `docker-compose` 将 App Ingress 部署到 Docker 中。如果你想在 Kubernetes 之外的环境中运行 App Ingress，或者想在本地测试应用程序和/或 OpenAPI 规范，这可能是一个要求。

在本示例中，你将在 Docker 中启动一个服务，流量将通过使用 `docker-compose` 创建的 App Ingress 接收，并使用服务的 OpenAPI 文档进行配置。

在继续之前，请确保已安装 [docker](https://docs.docker.com/engine/install/) 和 [docker-compose](https://docs.docker.com/compose/install/)。

### 生成 docker-compose 文件

创建一个名为 `appingress-compose` 的目录。后续的说明将依赖于存在该目录。

使用以下命令生成并保存生成的 docker-compose 文件，该文件定义了所有使用以下命令创建的 App Ingress 容器。注意启用了 `--openapi-translator` 选项，并且通过 `--openapi-backend-service` 指定了后端服务 `http://httpbin.tetrate.com`。

```bash
tctl x app-ingress docker-compose generate \
  --openapi-translator \
  --output-dir appingress-compose \
  --openapi-backend-service http://httpbin.tetrate.com \
```

### 运行 docker-compose
使用 `docker-compose` 运行容器：

```bash
$ cd appingress-compose
$ docker-compose up -d
```

你应该看到 App Ingress 容器启动，以及一个名为 `appingress-compose_app-ingress` 的新 Docker 网络被创建。

```bash
$ docker ps --filter="name=appingress"
CONTAINER ID   IMAGE                                                                                          COMMAND                  CREATED       STATUS       PORTS                                            NAMES
aeae400dcdc3   istio/proxyv2:1.11.3                                                                           "/usr/local/bin/pilo…"   2 hours ago   Up 2 hours   0.0.0.0:8080->8080/tcp, 0.0.0.0:8443->8443/tcp   appingress-compose_istio-ingressgateway_1
e7d988a02384   gcr.io/tetrate-internal-containers/genistio-watcher:7c8c123e620c261e45b925de22b345f4d2b37387   "/usr/local/bin/geni…"   2 hours ago   Up 2 hours                                                    appingress-compose_openapi-translator_1
19539c0a28d3   istio/pilot:1.11.3                                                                             "/usr/local/bin/pilo…"   2 hours ago   Up 2 hours                                                    appingress-compose_pilot-discovery_1
```

```bash
$ docker network ls
NETWORK ID     NAME                             DRIVER    SCOPE
d5b159e5b631   appingress-compose_app-ingress   bridge    local
51364ba39b1b   bridge                           bridge    local
7135f2f769e4   host                             host      local
c955a05b02d1   none                             null      local
```

### 运行应用程序容器
启动一个容器，其名称与 `--openapi-backend-service` 参数中提到的名称相同，本例中应为 `httpbin.tetrate.com`。当前的实现要求名称与后端服务名称匹配。你还需要将其部署在最近由 `docker-compose` 创建的 `appingress-compose_app-ingress` 网络中：

```bash
docker run --net appingress-compose_app-ingress --name httpbin.tetrate.com -d kennethreitz/httpbin
```

### 安装 OpenAPI 规范

下载文件 [`httpbin-openapi.json`](../../../assets/howto/httpbin-openapi.json_) 并将其保存到 `.app-ingress/config-sources` 目录下，命名为 `.app-ingress/config-sources/httpbin-openapi.json`。App Ingress 将消耗并将其翻译成 Istio 资源。

你应该立即看到生成的 Istio 资源作为一个 YAML 文件被创建：

```bash
$ ls .app-ingress/config-sources/app-ingress.yaml
.app-ingress/config-sources/app-ingress.yaml
```

你可以在此目录 `.app-ingress/config-sources/` 中包含其他 Istio 资源，例如目标规则、Envoy 过滤器，以实现你的用例。

### 测试

如果一切正常，你应该能够访问在 Docker 中运行的应用程序。

```bash
$ curl -vvv -H "Host: httpbin.tetrate.com" http://localhost:8080/get
*   Trying ::1...
* TCP_NODELAY set
* Connected to localhost (::1) port 8080 (#0)
> GET /get HTTP/1.1
> Host: httpbin.tetrate.com
> User-Agent: curl/7.64.1
> Accept: */*
> 
< HTTP/1.1 200 OK
< server: istio-envoy
< date: Wed, 08 Dec 2021 03:50:43 GMT
< content-type: application/json
< content-length: 432
< access-control-allow-origin: *
< access-control-allow-credentials: true
< x-envoy-upstream-service-time: 1
< 
{
  "args": {}, 
  "headers": {
    "Accept": "*/*", 
    "Host": "httpbin.tetrate.com", 
    "User-Agent": "curl/7.64.1", 
    "X-B3-Sampled": "0", 
    "X-B3-Spanid": "e5ab7bfbd817196b", 
    "X-B3-Traceid": "2729efd79fd5e2e9e5ab7bfbd817196b", 
    "X-Envoy-Attempt-Count": "1", 
    "X-Envoy-Decorator-Operation": "httpbin.tetrate.com:80/get", 
    "X-Envoy-Internal": "true"
  }, 
  "origin": "172.18.0.1", 
  "url": "http://httpbin.tetrate.com/get"
}
* Connection #0 to

 host localhost left intact
* Closing connection 0
```

请注意，这是一个示例，你需要根据你的实际应用程序和环境进行适当的配置。
