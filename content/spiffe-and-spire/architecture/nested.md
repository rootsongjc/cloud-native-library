---
weight: 2
title: "SPIRE 嵌套架构：将 SPIRE 服务器链接为同一信任域"
linkTitle: "SPIRE 嵌套架构"
---

嵌套 SPIRE 允许将 SPIRE 服务器“链接”在一起，并且所有 SPIRE 服务器都可以在同一信任域中发放身份，这意味着在同一信任域中标识的所有工作负载都可以使用根密钥验证其身份文档。

嵌套拓扑结构通过将一个 SPIRE 代理与每个下游 SPIRE 服务器“链接”在一起来实现。下游 SPIRE 服务器通过 Workload API 获得凭证，然后直接与上游 SPIRE 服务器进行身份验证，以获取一个中间 CA。

为了演示嵌套拓扑中的 SPIRE 部署，我们使用 Docker Compose 创建了一个场景，其中包括一个根 SPIRE 部署和两个嵌套的 SPIRE 部署。

![](../../images/Nested_SPIRE_Diagram.png)

嵌套拓扑结构非常适合多云部署。由于可以混合匹配节点验证者，下游 SPIRE 服务器可以位于不同的云提供商环境中，并为工作负载和 SPIRE 代理提供身份。

在本教程中，你将学习以下内容：

- 在嵌套拓扑中配置 SPIRE
- 配置 UpstreamAuthority 插件
- 为嵌套 SPIRE 服务器创建注册条目
- 测试在整个信任域中创建的 SVID 是否有效

## 先决条件

本教程的所需文件可以在 https://github.com/spiffe/spire-tutorials 的 `docker-compose/nested-spire` 目录中找到。如果尚未克隆存储库，请现在进行克隆。

在继续之前，请查看以下系统要求：

- 64 位 Linux 或 macOS 环境
- 已安装 [Docker](https://docs.docker.com/get-docker/) 和 [Docker Compose](https://docs.docker.com/compose/install/)（macOS Docker Desktop 包含 Docker Compose）
- 已安装 [Go](https://golang.org/dl/) 1.14.4 或更高版本

## 第一部分：运行服务

本教程的“nested-spire”主目录包含三个子目录，分别用于存放 SPIRE 部署的配置文件：`root`、`nestedA`和`nestedB`。这些目录包含用于验证 Agents 在 Servers 上的身份的私钥和证书。这些私钥和证书是在场景初始化时使用 Go 应用程序创建的，其详细信息超出了本教程的范围。

### 创建共享目录

首先，需要一个本地目录，在服务上进行卷挂载，以在根 SPIRE Agent 和嵌套 SPIRE Servers 之间共享工作负载 API。本教程使用`.../spire-tutorials/docker-compose/nested-spire/sharedRootSocket`作为共享目录。

### 配置根 SPIRE 部署

根 SPIRE 服务器和代理的配置文件与默认的`server.conf`和`agent.conf`文件没有改动，但值得注意的是 SPIRE 代理定义绑定工作负载 API socket 的位置：`socket_path ="/opt/spire/sockets/workload_api.sock"`。稍后将使用此路径来配置卷，以便与嵌套 SPIRE Servers 共享工作负载 API。

我们在[docker-compose.yaml](https://github.com/spiffe/spire-tutorials/blob/main/docker-compose/nested-spire/docker-compose.yaml)文件中定义了本教程中的所有服务。在`root-agent`服务定义中，我们将 SPIRE Agent 容器中的`/opt/spire/sockets`目录挂载到新的本地目录`sharedRootSocket`上。在下一节中，当定义嵌套 SPIRE Server 服务时，我们将使用此目录将`root-agent`套接字挂载到 SPIRE Server 容器上。

```yaml
services:
  # Root
  root-server:
    image: ghcr.io/spiffe/spire-server:1.5.1
    hostname: root-server
    volumes:
      - ./root/server:/opt/spire/conf/server
    command: ["-config", "/opt/spire/conf/server/server.conf"]
  root-agent:
    # Share the host pid namespace so this agent can attest the nested servers
    pid: "host"
    image: ghcr.io/spiffe/spire-agent:1.5.1
    depends_on: ["root-server"]
    hostname: root-agent
    volumes:
      # Share root agent socket to be accessed by nestedA and nestedB servers
      - ./sharedRootSocket:/opt/spire/sockets
      - ./root/agent:/opt/spire/conf/agent
      - /var/run/:/var/run/
    command: ["-config", "/opt/spire/conf/agent/agent.conf"]
```

### 配置嵌套 A SPIRE 部署

`nestedB` SPIRE 部署需要相同的一组配置，但本文不描述这些更改，以避免重复。

SPIRE Agent 和 Server 可以通过各种[插件](https://spiffe.io/spire/docs/extending/)进行扩展。[UpstreamAuthority 插件](https://github.com/spiffe/spire/blob/v1.8.2/doc/spire_server.md#built-in-plugins)类型允许 SPIRE Server 与现有 PKI 系统集成。UpstreamAuthority 插件可以使用从磁盘加载的 CA 进行证书签名，第三方工具如 AWS 和 Vault 等。嵌套 SPIRE 部署需要使用[spire UpstreamAuthority 插件](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_upstreamauthority_spire.md)，该插件使用同一信任域中的上游 SPIRE Server 获取 SPIRE Server 的中间签名证书。

- *[nestedA-server 的配置文件](https://github.com/spiffe/spire-tutorials/blob/main/docker-compose/nested-spire/nestedA/server/server.conf)*包括`spire` UpstreamAuthority 插件定义，其中`root-server`被定义为其上游 SPIRE Server。

```ini
   UpstreamAuthority "spire" {
 	   plugin_data = {
 	       server_address      = "root-server"
 	       server_port         = 8081
 	       workload_api_socket = "/opt/spire/sockets/workload_api.sock"
 	   }
    }
```

在[docker-compose.yaml](https://github.com/spiffe/spire-tutorials/blob/main/docker-compose/nested-spire/docker-compose.yaml)文件中，`nestedA-server`服务的 Docker Compose 定义将新的本地目录`sharedRootSocket`作为卷进行挂载。请记住，前一节中将`root-agent`套接字挂载在该目录上。这样，`nestedA-server`就可以访问`root-agent`的工作负载 API 并获取其 SVID。

```yaml
nestedA-server:
  # Share the host pid namespace so this server can be attested by the root agent
  pid: "host"
  image: ghcr.io/spiffe/spire-server:1.5.1
  hostname: nestedA-server
  labels:
    # label to attest nestedA-server against root-agent
    - org.example.name=nestedA
  volumes:
    # Add root agent socket
    - ./shared/rootSocket:/opt/spire/sockets
    - ./nestedA/server:/opt/spire/conf/server
  command: ["-config", "/opt/spire/conf/server/server.conf"]
```

### 创建下游注册项

`nestedA-server`必须在`root-server`中注册，以获取其身份，该身份将用于生成 SVID。我们通过在根 SPIRE Server 中创建一个注册项来实现为`nestedA-server`。

```bash
docker-compose exec -T root-server \
    /opt/spire/bin/spire-server entry create \
    -parentID "spiffe://example.org/spire/agent/x509pop/$(fingerprint root/agent/agent.crt.pem)" \
    -spiffeID "spiffe://example.org/nestedA" \
    -selector "docker:label:org.example.name:nestedA-server" \
    -downstream
```

- `parentID`标志包含`root-agent`的 SPIFFE ID。`root-agent`的 SPIFFE ID 是由[x509pop Node Attestor 插件](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_nodeattestor_x509pop.md)创建的，该插件将 SPIFFE ID 定义为`spiffe://<trust domain>/spire/agent/x509pop/<fingerprint>`。shell 脚本中的`fingerprint()`函数计算证书的 SHA1 指纹。另一个要注意的是`downstream`选项。设置此选项时，表示该条目描述的是下游 SPIRE Server。

### 运行场景

使用`set-env.sh`脚本来运行构成场景的所有服务。该脚本使用之前描述的配置选项启动`root`、`nestedA`和`nestedB`服务。

确保当前工作目录是`.../spire-tutorials/docker-compose/nested-spire`，然后运行以下命令：

```bash
bash scripts/set-env.sh
```

脚本完成后，在另一个终端中运行以下命令以查看所有服务的日志：

```bash
docker-compose logs -f -t
```

## 第二部分：测试部署

现在 SPIRE 部署已准备就绪，让我们测试所配置的场景。

### 创建工作负载注册项

为了测试场景，我们创建两个工作负载注册项，一个用于每个嵌套 SPIRE Server（`nestedA`和`nestedB`）。测试的目标是演示在嵌套配置中创建的 SVID 在整个信任域中都有效，而不仅仅在生成 SVID 的 SPIRE Server 的范围内。以下命令演示了我们将用于创建这两个工作负载注册项的命令行选项，但你可以使用下面显示的`create-workload-registration-entries.sh`脚本运行这些命令。

```bash
# nestedA部署的工作负载
docker-compose exec -T nestedA-server \
    /opt/spire/bin/spire-server entry create \
    -parentID "spiffe://example.org/spire/agent/x509pop/$(fingerprint nestedA/agent/agent.crt.pem)" \
    -spiffeID "spiffe://example.org/nestedA/workload" \
    -selector "unix:uid:1001" \

# nestedB部署的工作负载
docker-compose exec -T nestedB-server \
    /opt/spire/bin/spire-server entry create \
    -parentID "spiffe://example.org/spire/agent/x509pop/$(fingerprint nestedB/agent/agent.crt.pem)" \
    -spiffeID "spiffe://example.org/nestedB/workload" \
    -selector "unix:uid:1001"
```

示例再次使用`fingerprint path/to/nested-agent-cert`的形式，以显示`-parentID`标志指定了嵌套 SPIRE Agent 的 SPIFFE ID。最后，在两种情况下，Unix 选择器将 SPIFFE ID 分配给 uid 为 1001 的任何进程。

使用以下 Bash 脚本使用刚才描述的选项创建注册条目：

```
bash scripts/create-workload-registration-entries.sh
```

### 运行测试

一旦两个工作负载注册条目被传播，我们可以测试在嵌套配置中创建的 SVID 是否在整个信任域中有效，而不仅仅在生成 SVID 的 SPIRE Server 的范围内。

该测试包括从`nestedA-agent` SPIRE Agent 获取 JWT-SVID，并使用`nestedB-agent`对其进行验证。在两种情况下，Docker Compose 使用 uid 1001 运行进程，以匹配在上一节中创建的工作负载注册条目。

输入以下命令从`nestedA` SPIRE Agent 获取 JWT-SVID，并从 JWT-SVID 中提取令牌：

```bash
token=$(docker-compose exec -u 1001 -T nestedA-agent \
    /opt/spire/bin/spire-agent api fetch jwt -audience nested-test -socketPath /opt/spire/sockets/workload_api.sock | sed -n '2p')
```

运行以下命令在`nestedB` SPIRE Agent 上验证`nestedA`的令牌：

```bash
docker-compose exec -u 1001 -T nestedB-agent \
    /opt/spire/bin/spire-agent api validate jwt -audience nested-test  -svid "${token}" \
      -socketPath /opt/spire/sockets/workload_api.sock
```

`nestedB` SPIRE Agent 输出如下：

```
    SVID is valid.
    SPIFFE ID : spiffe://example.org/nestedA/workload
    Claims    : {"aud":["nested-test"],"exp":1595814190,"iat":1595813890,"sub":"spiffe://example.org/nestedA/workload"}
```

输出表示 JWT-SVID 是有效的。此外，尽管 SPIFFE ID 注册在`nestedA`而不是`nestedB`上，但该 SPIFFE ID 在`nestedB` SPIRE Agent 上仍然有效，因为 SPIRE Agents 在嵌套 SPIRE 拓扑中处于相同的信任域。

在 SPIRE 中，这是通过将每个 JWT-SVID 公共签名密钥传播到整个拓扑来实现的。在 X509-SVID 的情况下，由于 X.509 的链式语义，这很容易实现。

## 清理

完成本教程后，你可以使用以下 Bash 脚本停止所有容器：

```bash
bash scripts/clean-env.sh
```
