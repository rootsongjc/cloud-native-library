---
weight: 3
title: "SPIRE 联邦：验证来自不同 SPIRE 服务器的工作负载"
linkTitle: "SPIRE 联邦架构"
---

本教程展示了如何对由两个不同 SPIRE 服务器识别的两个 SPIFFE 标识的工作负载进行身份验证。

本文的第一部分演示了如何通过显示 SPIRE 配置文件更改和 `spire-server` 命令来配置 SPIFFE 联邦，以设置股票报价 web 应用的前端和服务后端。本文的第二部分列出了您可以在此教程目录中包含的 Docker Compose 文件中运行的步骤，以显示场景的实际操作。

在本教程中，您将学到如何：

- 配置每个 SPIRE 服务器以使用 SPIFFE 身份验证和 Web PKI 身份验证公开其 SPIFFE 联邦捆绑点。
- 配置 SPIRE 服务器以从彼此检索信任捆绑点。
- 使用不同的信任域引导两个 SPIRE 服务器之间的联合。
- 为工作负载创建注册条目，以便它们可以与其他信任域进行联合。

## 先决条件

SPIFFE 联邦的基线组件包括：

- 运行版本为 1.5.1 的两个 SPIRE 服务器实例。
- 运行版本为 1.5.1 的两个 SPIRE 代理。一个连接到一个 SPIRE 服务器，另一个连接到另一个 SPIRE 服务器。
- 两个需要通过 mTLS 进行通信的工作负载，并使用工作负载 API 获取 SVID 和信任捆绑点。

## 场景

假设我们有一个股票经纪人的 web 应用程序，它希望从股票市场 web 服务提供商那里获取股票报价并显示它们。情景如下：

1. 用户在浏览器中输入经纪人 web 应用的股票报价 URL。
2. Web 应用的工作负载接收到请求并使用 mTLS 向股票市场服务发出获取报价的 HTTP 请求。
3. 股票市场服务收到请求并在响应中发送报价。
4. Web 应用呈现使用返回的报价的股票报价页面并将其发送到浏览器。
5. 浏览器向用户显示报价。Web 应用包括一些 JavaScript 以便每隔 1 秒刷新页面，因此每秒都会执行这些步骤。

除了上述内容，本教程的其余部分中，我们将假设以下 [信任域](https://spiffe.io/docs/latest/spiffe/concepts/#trust-domain) 名称用于这些示例 SPIRE 安装：`broker.example` 和 `stockmarket.example`。请注意，信任域不需要对应实际的 DNS 域名。此外，应用程序直接访问 WorkloadAPI 以获取 SVID 和信任捆绑点，这意味着在所描述的情景中没有代理。

## 配置 SPIFFE 联邦捆绑点

为了使联邦工作，并且因为 web 应用程序和报价服务将使用 `mTLS`，两个 SPIRE 服务器都需要彼此的信任捆绑点。在某种程度上，这是通过在每个 SPIRE 服务器上配置所谓的联邦捆绑点来完成的，该捆绑点提供了由其他信任域中的 SPIRE 服务器使用的 API，以获取他们要与之联合的信任域的信任捆绑点。

由 SPIRE 服务器公开的联邦捆绑点可以配置为使用两种身份验证方法之一：SPIFFE 身份验证或 Web PKI 身份验证。

### 使用 SPIFFE 身份验证配置联邦捆绑点

要配置经纪人的 SPIRE 服务器捆绑点端点，我们在经纪人的 SPIRE 服务器配置文件中使用了 `federation` 部分（默认为 `server.conf`）：

```
 server {
     .
     .
     trust_domain = "broker.example"
     .
     .
 
     federation {
         bundle_endpoint {
             address = "0.0.0.0"
             port = 8443
         }
     }
 }
```

这将在运行 SPIRE 服务器的主机中的任何 IP 地址上的端口 8443 上发布联邦捆绑点。

另一方面，股票市场服务提供商的 SPIRE 服务器配置类似：

```ini
 server {
     .
     .
     trust_domain = "stockmarket.example"
     .
     .
 
     federation {
         bundle_endpoint {
             address = "0.0.0.0"
             port = 8443
         }
     }
 }
```

此时，两个 SPIRE 服务器都暴露了它们的联邦捆绑点以提供它们的信任捆绑点，但它们都不知道如何到达彼此的联邦捆绑点。

### 使用 Web PKI 身份验证配置联邦捆绑点

我们将假设仅经纪人的 SPIRE 服务器将使用 Web PKI 身份验证来配置其联邦捆绑点。股票市场 SPIRE 服务器仍将使用 SPIFFE 身份验证。因此，股票市场 SPIRE 服务器配置与前一节中所见相同。

然后，要配置经纪人的 SPIRE 服务器捆绑点端点，我们将 `federation` 部分配置如下：

```ini
 server {
     .
     .
     trust_domain = "broker.example"
     .
     .
 
     federation {
         bundle_endpoint {
             address = "0.0.0.0"
             port = 443
             acme {
                 domain_name = "broker.example"
                 email = "some@email.com"
                 tos_accepted = true
             }
         }
     }
 }
```

这将在任何 IP 地址上的端口 443 上发布联邦捆绑点。我们使用端口 443，因为我们演示了使用 Let's Encrypt 作为我们的 ACME 提供商（如果您要使用其他提供商，则必须设置 `directory_url` 可配置）。请注意，`tos_accepted` 设置为 `true`，这意味着我们接受了我们的 ACME 提供商的服务条款，这在使用 Let's Encrypt 时是必要的。

要使使用 Web PKI 的 SPIFFE 联邦正常工作，您必须拥有为 `domain_name`（在我们的示例中为 `broker.example`）指定的 DNS 域名，并且该域名必须解析到公开联邦捆绑点的 SPIRE 服务器 IP 地址。

## 配置 SPIRE 服务器以从彼此检索信任捆绑点

在配置联邦端点后，启用 SPIFFE 联邦的下一步是配置 SPIRE 服务器以查找其他信任域的信任捆绑点。在 `server.conf` 中的 `federates_with` 配置选项是您指定另一个信任域的端点的地方。在使用不同的身份验证方法时，该部分的配置有一些细微的差异，根据每个端点配置文件的要求。

### 使用 SPIFFE 身份验证配置信任捆绑点位置（https_spiffe）

如前所述，股票市场服务提供商的 SPIRE 服务器将其联邦端点监听在任何 IP 地址的端口 `8443` 上。我们还假设 `spire-server-stock` 是一个解析为股票市场服务的 SPIRE 服务器 IP 地址的 DNS 名称。 （这里的 Docker Compose 演示使用主机名 `spire-server-stock`，但在典型的使用中，您会指定一个 FQDN。）然后，经纪人的 SPIRE 服务器必须配置以下 `federates_with` 部分：

```ini
 server {
     .
     .
     trust_domain = "broker.example"
     .
     .
 
     federation {
         bundle_endpoint {
             address = "0.0.0.0"
             port = 8443
         }
         federates_with "stockmarket.example" {
             bundle_endpoint_url = "https://spire-server-stock:8443"
             bundle_endpoint_profile "https_spiffe" {
                 endpoint_spiffe_id = "spiffe://stockmarket.example/spire/server"
             }
         }
     }
 }
```

现在，经纪人的 SPIRE 服务器知道在哪里找到可以用于验证包含来自 `stockmarket.example` 信任域的身份的信任捆绑点。

另一方面，股票市场服务提供商的 SPIRE 服务器必须以类似的方式进行配置：

```ini
 server {
     .
     .
     trust_domain = "stockmarket.example"
     .
     .
 
     federation {
         bundle_endpoint {
             address = "0.0.0.0"
             port = 8443
         }
         federates_with "broker.example" {
             bundle_endpoint_url = "https://spire-server-broker:8443"
             bundle_endpoint_profile "https_spiffe" {
                 endpoint_spiffe_id = "spiffe://broker.example/spire/server"
             }
         }
     }
 }
```

请注意，指定了 "https_spiffe" 配置文件，指示了联邦捆绑点的预期 SPIFFE ID。指定 `server.conf` 的 `federation` 部分和 `federates_with` 子部分是配置 SPIFFE 联邦所需的全部内容。要完成启用 SPIFFE 联邦，我们需要使用下面描述的 `spire-server` 命令来引导信任捆绑点和注册工作负载。

### 使用 Web PKI 身份验证配置信任捆绑点位置（https_web）

如前所述，在这种备选方案中，我们假设只有经纪人的 SPIRE 服务器将使用 Web PKI 身份验证来配置其联邦端点，因此经纪人服务器的 `federates_with` 配置与前一节中所见相同。然而，股票市场服务提供商的 SPIRE 服务器需要一个不同的配置，它使用 "https_web" 配置文件而不是 "https_spiffe"：

```ini
 server {
     .
     .
     trust_domain = "stockmarket.example"
     .
     .
 
     federation {
         bundle_endpoint {
             address = "0.0.0.0"
             port = 8443
         }
         federates_with "broker.example" {
             bundle_endpoint_url = "https://spire-server-broker:8443"
             bundle_endpoint_profile "https_web" {}
         }
     }
 }
```

可以注意到 "https_web" 配置文件不需要额外的配置设置。端点使用安装在操作系统中的相同公共 CA 证书进行身份验证。

## 引导联邦

我们已经配置了 SPIRE 服务器的联邦端点地址，但这并不足以使联邦正常工作。为了使 SPIRE 服务器能够从彼此获取信任捆绑点，它们首先需要彼此的信任捆绑点，因为它们必须对试图访问联邦端点的联合服务器的 SPIFFE 身份进行身份验证。一旦联邦被引导，就可以使用当前信任捆绑点通过联邦端点 API 获取信任捆绑点更新。

引导工作是通过使用 SPIRE Server 命令 `bundle show` 和 `bundle set` 来完成的。

### 获取引导信任捆绑点

假设我们想要获取经纪人的 SPIRE 服务器信任捆绑点。在运行经纪人的 SPIRE 服务器的节点上运行：

```
broker> spire-server bundle show -format spiffe > broker.example.bundle
```

这会将信任捆绑点保存在 `broker.example.bundle` 文件中。然后，经纪人必须将此文件的副本提供给股票市场服务人员，以便他们可以将此信任

捆绑点存储在他们的 SPIRE 服务器上，并将其与 `broker.example` 信任域关联起来。要做到这一点，股票市场服务人员必须在他们运行 SPIRE 服务器的节点上运行以下命令：

```
stock-market> spire-server bundle set -format spiffe -id spiffe://broker.example -path /some/path/broker.example.bundle
```

此时，股票市场服务的 SPIRE 服务器可以验证具有 `broker.example` 信任域的 SPIFFE ID 的 SVID。但是，经纪人的 SPIRE 服务器尚无法验证具有 `stockmarket.example` 信任域的 SPIFFE ID 的 SVID。要使此成为可能，股票市场人员必须在他们运行 SPIRE 服务器的节点上运行以下命令：

```
stock-market> spire-server bundle show -format spiffe > stockmarket.example.bundle
```

然后，股票市场人员必须将此文件的副本提供给经纪人，以便他们可以将此信任捆绑点存储在他们的 SPIRE 服务器上，并将其与 `stockmarket.example` 信任域关联起来。要做到这一点，经纪人必须在他们运行 SPIRE 服务器的节点上运行以下命令：

```
broker> spire-server bundle set -format spiffe -id spiffe://stockmarket.example -path /some/path/stockmarket.example.bundle
```

现在，两台 SPIRE 服务器都可以验证具有彼此信任域的 SPIFFE ID 的 SVID，因此两者可以开始从彼此的联邦端点获取信任捆绑点更新。此外，从现在起，他们可以创建用于联合的注册条目，如下一节所示。

请注意，在经纪人的 SPIRE 服务器为其联邦捆绑点使用 Web PKI 身份验证时，不需要创建 `broker.example.bundle` 文件（后来由股票市场服务导入）。

## 为联合创建注册条目

现在，SPIRE 服务器具有了彼此的信任捆绑点，让我们看看它们如何创建用于联合的注册条目。

为简化起见，我们假设股票市场 Web 应用程序和行情服务都在运行 Linux 箱子上，一个属于股票市场组织，另一个属于经纪人。由于它们使用 SPIRE，每个 Linux 箱子上还安装了一个 SPIRE 代理。除此之外，Web 应用程序是使用 `webapp` 用户运行的，行情服务是使用 `quotes-service` 用户运行的。

在经纪人的 SPIRE Server 节点上，经纪人必须创建一个注册条目。`-federatesWith` 标志是必需的，以启用 SPIFFE 联邦：

```
broker> spire-server entry create \
   -parentID <SPIRE 代理的 SPIFFE ID> \
   -spiffeID spiffe://broker.example/webapp \
   -selector unix:user:webapp \
   -federatesWith "spiffe://stockmarket.example"
```

通过指定 `-federatesWith` 标志，创建了此注册条目后，当 Web 应用程序的 SPIRE 服务器请求 SVID 时，它将从经纪人的 SPIRE 服务器获取一个具有 `spiffe://broker.example/webapp` 身份的 SVID，并附带与 `stockmarket.example` 信任域关联的信任捆绑点。

在股票市场服务的一侧，他们必须创建一个注册条目，如下所示：

```
stock-market> spire-server entry create \
   -parentID <SPIRE 代理的 SPIFFE ID> \
   -spiffeID spiffe://stockmarket.example/quotes-service \
   -selector unix:user:quotes-service \
   -federatesWith "spiffe://broker.example"
```

类似地，创建了此注册条目后，当行情服务请求 SVID 时，它将获得一个具有 `spiffe://stockmarket.example/quotes-service` 身份的 SVID，并附带与 `broker.example` 信任域关联的信任捆绑点。

以上就是全部内容。现在，所有的组件都已就绪，可以使联邦正常工作，并演示 Web 应用程序如何在具有不同信任域的身份的情况下与行情服务通信。

# 使用 SPIFFE 身份验证的联邦示例

本节将解释如何使用 Docker Compose 尝试此教程中描述的 SPIFFE 身份验证场景的示例实现。

尽管此处没有显示出来，但您可以对 Web PKI 身份验证部分中显示的更改进行更改以尝试 Web PKI 场景。请记住，要配置 Web PKI，`domain_name` 指定的 FQDN 必须由您拥有，并且可以通过 DNS 通过互联网进行解析。

## 要求

本教程的所需文件可以在 [https://github.com/spiffe/spire-tutorials](https://github.com/spiffe/spire-tutorials) 的 `docker-compose/federation` 目录中找到。如果您尚未克隆该存储库，请立即执行此操作。

在继续之前，请查看以下系统要求：

- 64 位 Linux 或 macOS 环境
- 安装了 [Docker](https://docs.docker.com/get-docker/) 和 [Docker Compose](https://docs.docker.com/compose/install/)（Docker Compose 包含在 macOS Docker Desktop 中）
- 安装了 [Go](https://golang.org/dl/) 1.14.4 或更高版本

## 构建

确保当前工作目录是 `.../spire-tutorials/docker-compose/federation`，并运行以下命令以创建 Docker Compose 所需的文件：

```bash
$ ./build.sh
```

## 运行

运行以下命令以启动 SPIRE 服务器和应用程序：

```bash
$ docker-compose up -d
```

## 启动 SPIRE 代理

运行以下命

令以启动 SPIRE 代理：

```bash
$ ./agent.sh
```

## 启动 Web 应用程序

运行以下命令以启动 Web 应用程序：

```bash
$ ./webapp.sh
```

## 启动行情服务

运行以下命令以启动行情服务：

```bash
$ ./quotes.sh
```

## 测试

现在，您可以在浏览器中访问 `http://localhost:8080` 来查看股票报价。

## 清理

要清理所有 Docker 容器和卷，请运行以下命令：

```bash
$ docker-compose down -v
```

这将关闭并删除所有正在运行的容器，并删除由 `docker-compose up` 创建的卷。
