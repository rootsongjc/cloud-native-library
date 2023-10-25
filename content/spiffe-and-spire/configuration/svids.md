---
weight: 3
title: "使用 SVID"
---

本文指导你如何编写与 SPIFFE SVID 相关的代码。

SPIRE 等符合 SPIFFE 的身份提供者将通过 SPIFFE Workload API 公开 SPIFFE 可验证身份文档（SVID）。工作负载可以使用从此 API 检索到的 SVID 来验证消息的来源或在两个工作负载之间建立相互 TLS 安全通道。

## 与 Workload API 交互

开发需要与 SPIFFE 进行交互的新工作负载的开发人员可以直接与 SPIFFE Workload API 进行交互，以便：

- 检索工作负载的身份，描述为 SPIFFE ID，例如 `spiffe://prod.acme.com/billing/api`
- 代表工作负载生成短期密钥和证书，具体包括：
  - 与该 SPIFFE ID 相关联的私钥，可用于代表工作负载签署数据。
  - 对应的短期 X.509 证书 - 一种称为 X509-SVID 的证书。该证书可用于建立 TLS 或以其他方式对其他工作负载进行身份验证。
- 一组证书 - 称为信任捆绑包（trust bundle） - 工作负载可以使用它来验证同一信任域或联合信任域中的另一个工作负载呈现的 X.509-SVID。
- 生成或验证代表工作负载或同一信任域或联合信任域中另一个工作负载的 JSON Web Token（JWT-SVID）。

Workload API 不需要任何显式的身份验证（如密钥）。相反，SPIFFE 规范将身份验证工作留给 SPIFFE Workload API 的实现来确定。在 SPIRE 的情况下，这是通过检查 SPIRE 代理在工作负载调用 API 时收集的 Unix 内核元数据来实现的。

该 API 是基于 gRPC 的 API，派生自 [protobuf](https://github.com/spiffe/go-spiffe/blob/main/v2/proto/spiffe/workload/workload.proto)。[gRPC 项目](https://grpc.io/) 提供了从 protobuf 生成各种语言的客户端库的工具。

### 在 Go 中使用 SVID

如果你在使用 Go 进行开发，SPIFFE 项目维护了一个 Go 客户端库，提供以下功能：

- 一个命令行实用程序，用于解析和验证 X.509 证书中编码的 SPIFFE 身份，如 SPIFFE 标准中所述。
- 一个客户端库，提供与 SPIFFE Workload API 的交互界面。

你可以在 [GitHub](https://github.com/spiffe/go-spiffe) 上找到该库以及 GoDoc 的链接。

## 使用 SPIFFE Helper 实用程序

SPIFFE Helper 实用程序是一个通用实用程序，用于构建或与无法直接写入 Workload API 的应用程序集成时非常有用。大体上，该实用程序能够：

- 获取用于验证 X.509-SVID 的 X.509-SVID、密钥和信任捆绑包（证书链），并将它们写入磁盘上的特定位置。
- 启动一个子进程，该子进程可以使用这些密钥和证书。
- 主动监视其过期时间，并根据需要从 Workload API 请求刷新的证书和密钥。
- 一旦获取到更换的证书，向任何已启动的子进程发送信号。

## 使用 SPIRE Agent

SPIRE Agent 二进制文件可用作作为 SPIFFE Workload API 的实现时的 SPIRE 部署的一部分，但它也可以作为 Workload API 的客户端运行，并提供一些简单的实用程序与其进行交互以检索 SPIFFE 凭据。

例如，运行以下命令：

```bash
sudo -u webapp ./spire-agent api fetch x509 -socketPath /run/spire/sockets/agent.sock -write /tmp/
```

将会：

1. 连接到 Unix 域套接字 `/run/spire/sockets/agent.sock` 上的 Workload API（即使 SPIRE 不提供 API）。
2. 检索与该进程所运行的用户相关联的任何身份（在此示例中为 `webapp`）。
3. 将每个身份关联的 X.509-SVID、私钥写入 `/tmp/`。
4. 将用于验证在该信任域下颁发的 X.509-SVID 的信任捆绑包（证书链）写入 `/tmp/`。

有关相关命令的完整列表，请参阅 [SPIRE Agent 文档](https://spiffe.io/docs/latest/deploying/spire_agent/#command-line-options)。