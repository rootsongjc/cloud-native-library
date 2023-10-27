---
weight: 5
title: "SPIRE Server 配置参考"
linkTitle: "SPIRE Server"
---

本文描述了 SPIRE Server 的命令行选项、server.conf 设置和内置插件。

本文档是 SPIRE Server 的配置参考。它包括有关插件类型、内置插件、服务器配置文件、插件配置和 `spire-server` 命令的命令行选项的信息。

## 插件类型

| 类型              | 描述                                                         |
| ----------------- | ------------------------------------------------------------ |
| DataStore         | 提供持久存储和 HA 功能。注意：不再支持数据存储的可插入性。只能使用内置的 SQL 插件。 |
| KeyManager        | 为服务器的签名操作实现签名和密钥存储逻辑。对于利用基于硬件的关键操作很有用。 |
| NodeAttestor      | 为尝试断言其身份的节点实现验证逻辑。一般与同类型的代理插件搭配使用。 |
| UpstreamAuthority | 允许 SPIRE 服务器与现有 PKI 系统集成。                       |
| Notifier          | 由 SPIRE 服务器通知正在发生或已经发生的某些事件。对于正在发生的事件，通知者可以将结果告知 SPIRE 服务器。 |

## 内置插件

| 类型              | 名称                                                         | 描述                                                         |
| ----------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| DataStore         | [sql](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_datastore_sql.md) | 用于 SPIRE 数据存储的 SQLite、PostgreSQL 和 MySQL 数据库的 SQL 数据库存储 |
| KeyManager        | [aws_kms](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_keymanager_aws_kms.md) | 管理 AWS KMS 中密钥的密钥管理器                              |
| KeyManager        | [disk](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_keymanager_disk.md) | 管理保存在磁盘上的密钥的密钥管理器                           |
| KeyManager        | [memory](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_keymanager_memory.md) | 管理内存中非持久密钥的密钥管理器                             |
| NodeAttestor      | [aws_iid](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_nodeattestor_aws_iid.md) | 使用 AWS 实例身份文档证明代理身份的节点证明者                |
| NodeAttestor      | [azure_msi](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_nodeattestor_azure_msi.md) | 使用 Azure MSI 令牌证明代理身份的节点证明者                  |
| NodeAttestor      | [gcp_iit](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_nodeattestor_gcp_iit.md) | 使用 GCP 实例身份令牌证明代理身份的节点证明者                |
| NodeAttestor      | [join_token](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_nodeattestor_jointoken.md) | 节点证明器，用于验证使用服务器生成的加入令牌进行证明的代理   |
| NodeAttestor      | [k8s_sat](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_nodeattestor_k8s_sat.md) | 使用 Kubernetes 服务帐户令牌证明代理身份的节点证明者         |
| NodeAttestor      | [k8s_psat](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_nodeattestor_k8s_psat.md) | 使用 Kubernetes 投影服务帐户令牌证明代理身份的节点证明者     |
| NodeAttestor      | [sshpop](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_nodeattestor_sshpop.md) | 使用现有 ssh 证书证明代理身份的节点证明者                    |
| NodeAttestor      | [tpm_devid](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_nodeattestor_tpm_devid.md) | 节点证明者，使用已配置 DevID 证书的 TPM 证明代理身份         |
| NodeAttestor      | [x509pop](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_nodeattestor_x509pop.md) | 使用现有 X.509 证书证明代理身份的节点证明者                  |
| Notifier          | [gcs_bundle](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_notifier_gcs_bundle.md) | 将最新信任包内容推送到 Google Cloud Storage 中的对象的通知程序。 |
| Notifier          | [k8sbundle](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_notifier_k8sbundle.md) | 将最新信任包内容推送到 Kubernetes ConfigMap 的通知程序。     |
| UpstreamAuthority | [disk](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_upstreamauthority_disk.md) | 使用从磁盘加载的 CA 来签署 SPIRE 服务器中间证书。            |
| UpstreamAuthority | [aws_pca](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_upstreamauthority_aws_pca.md) | 使用 AWS Certificate Manager 中的私有证书颁发机构来签署 SPIRE 服务器中间证书。 |
| UpstreamAuthority | [awssecret](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_upstreamauthority_awssecret.md) | 使用从 AWS SecretsManager 加载的 CA 来签署 SPIRE 服务器中间证书。 |
| UpstreamAuthority | [gcp_cas](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_upstreamauthority_gcp_cas.md) | 使用 GCP 证书颁发机构服务中的私有证书颁发机构来签署 SPIRE 服务器中间证书。 |
| UpstreamAuthority | [vault](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_upstreamauthority_vault.md) | 使用 HashiCorp Vault 中的 PKI 秘密引擎来签署 SPIRE 服务器中间证书。 |
| UpstreamAuthority | [spire](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_upstreamauthority_spire.md) | 使用同一信任域中的上游 SPIRE 服务器来获取 SPIRE 服务器的中间签名证书。 |
| UpstreamAuthority | [cert-manager](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_upstreamauthority_cert_manager.md) | 使用引用的证书管理器颁发者来请求中间签名证书。               |

## 服务器配置文件

下表概述了 SPIRE 服务器的配置选项。这些可以在配置文件的顶级 `server { ... }` 部分中设置。大多数选项都有一个相应的 CLI 标志，如果设置了该标志，则该标志优先于文件中定义的值。

SPIRE 配置文件可以用 HCL 或 JSON 表示。请参阅示例配置文件部分以获取完整示例。

如果 -expandEnv 标志传递给 SPIRE，则在解析之前扩展 `$VARIABLE` 或 `${VARIABLE}` 样式环境变量。这对于模板化配置文件（例如跨不同信任域）或插入数据库连接密码等机密可能很有用。

| 配置                    | 描述                                                         | 默认                                              |
| ----------------------- | ------------------------------------------------------------ | ------------------------------------------------- |
| `admin_ids`             | SPIFFE ID，当出现在呼叫者的 X509-SVID 中时，会授予该呼叫者管理员权限。管理 ID 必须驻留在服务器信任域或联合域中，并且不需要在服务器上有相应的管理注册条目。 |                                                   |
| `agent_ttl`             | 用于代理 SVID 的 TTL                                         | `default_x509_svid_ttl` 的值                      |
| `audit_log_enabled`     | 如果为 true，则启用审核日志记录                              | 错误的                                            |
| `bind_address`          | SPIRE 服务器的 IP 地址或 DNS 名称                            | 0.0.0.0                                           |
| `bind_port`             | SPIRE 服务器的 HTTP 端口号                                   | 8081                                              |
| `ca_key_type`           | 用于服务器 CA 的密钥类型（X509 和 JWT），`<rsa-2048\|rsa-4096\|ec-p256\|ec-p384>` | ec-p256（JWT 密钥类型可以被 `jwt_key_type` 覆盖） |
| `ca_subject`            | CA 证书应使用的主题（见下文）                                |                                                   |
| `ca_ttl`                | 默认 CA/签名密钥 TTL                                         | 24h                                               |
| `data_dir`              | 服务器运行时可以使用的目录                                   |                                                   |
| `default_x509_svid_ttl` | 默认 X509-SVID TTL                                           | 1h                                                |
| `default_jwt_svid_ttl`  | 默认 JWT-SVID TTL                                            | 5m                                                |
| `experimental`          | 可能会更改或删除的实验选项（见下文）                         |                                                   |
| `federation`            | 用于联合的捆绑端点配置部分                                   |                                                   |
| `jwt_key_type`          | 用于服务器 CA (JWT) 的密钥类型，                             | 如果未定义，则为 `ca_key_type` 或 ec-p256 的值    |
| `jwt_issuer`            | 发行 JWT-SVID 时使用的发行者声明                               |                                                   |
| `log_file`              | 将日志写入的文件                                             |                                                   |
| `log_level`             | 设置日志记录级别                                             | 信息                                              |
| `log_format`            | 日志格式，text 或 json                                                   | 文本                                              |
| `log_source_location`   | 如果为 true，日志将包含源文件、行号和方法名称字段（增加一点运行时成本） | 错误的                                            |
| `profiling_enabled`     | 如果为 true，则启用 net/http/pprof 端点                      | 错误的                                            |
| `profiling_freq`        | 将分析数据转储到磁盘的频率。仅当 `profiling_enabled` 为 `true` 且 `profiling_freq` > 0 时启用。 |                                                   |
| `profiling_names`       | 将在每个分析标记上转储到磁盘的配置文件名称列表，请参阅分析名称 |                                                   |
| `profiling_port`        | net/http/pprof 端点的端口号。仅当 `profiling_enabled` 为 `true` 时使用。 |                                                   |
| `ratelimit`             | 速率限制配置，通常在服务器位于负载均衡器后面时使用（见下文） |                                                   |
| `socket_path`           | 将 SPIRE 服务器 API 套接字绑定到的路径（仅限 Unix）          | /tmp/spire-server/private/api.sock                |
| `trust_domain`          | 该服务器所属的信任域（不应超过 255 个字符）                    |                                                   |

| ca_subject     | 描述                  | 默认 |
| -------------- | --------------------- | ---- |
| `country`      | `Country` 值数组      |      |
| `organization` | `Organization` 值数组 |      |
| `common_name`  | `CommonName` 值       |      |

| 实验性的                 | 描述                                                         | 默认                      |
| ------------------------ | ------------------------------------------------------------ | ------------------------- |
| `cache_reload_interval`  | 两次重新加载内存条目缓存之间的时间量。增加此值将减轻超大型部署的高数据库负载，但也会减慢新条目或更新条目向代理的传播速度。 | 5s                        |
| `auth_opa_policy_engine` | 用于授权决策的 auth opa_policy 引擎                          | 默认 SPIRE 授权策略       |
| `named_pipe_name`        | SPIRE Server API 命名管道的管道名称（仅限 Windows）          | \spire-server\private\api |

| 速率限制      | 描述                                                         | 默认 |
| ------------- | ------------------------------------------------------------ | ---- |
| `attestation` | 是否对节点证明进行速率限制。如果为 true，则节点证明的速率限制为每个 IP 地址每秒一次尝试。 | 真的 |
| `signing`     | 是否对 JWT 和 X509 签名进行速率限制。如果为 true，JWT 和 X509 签名的速率限制为每个 IP 地址每秒 500 个请求（单独）。 | 真的 |

| auth_opa_policy_engine | 描述                      | 默认 |
| ---------------------- | ------------------------- | ---- |
| `local`                | 授权策略的本地 OPA 配置。 |      |

| auth_opa_policy_engine.local | 描述                                     | 默认 |
| ---------------------------- | ---------------------------------------- | ---- |
| `rego_path`                  | 用于检索 OPA rego 策略以进行授权的文件。 |      |
| `policy_data_path`           | 用于检索数据绑定以进行策略评估的文件。   |      |

### 分析名称

这些是可以在 `profiling_freq` 配置值中设置的可用配置文件：

- `goroutine`
- `threadcreate`
- `heap`
- `block`
- `mutex`
- `trace`
- `cpu`

## 插件配置

服务器配置文件还包含各种 SPIRE 服务器插件的配置部分。插件配置位于顶级 `plugins { ... }` 部分，其格式如下：

```hcl
plugins {
    pluginType "pluginName" {
        ...
        plugin configuration options here
        ...
    }
}
```

以下配置选项可用于配置插件：

| 配置       | 描述                                             |
| ---------- | ------------------------------------------------ |
| 插件命令   | 插件实现二进制文件的路径（可选，内置插件不需要） |
| 插件校验和 | 插件二进制文件的可选 sha256（可选，内置不需要）  |
| 已启用     | 启用或禁用插件（默认启用）                       |
| 插件数据   | 插件特定数据                                     |

请参阅下面的内置插件部分，了解有关开箱即用的插件的信息。

## 联邦配置

SPIRE 服务器可以配置为与位于不同信任域中的其他 SPIRE 服务器联合。SPIRE 支持在 SPIRE 服务器配置文件中（静态关系）和通过信任域 API（动态关系）配置联合关系。本节介绍如何在配置文件中配置静态定义的关系。

*注意：静态关系优先于动态关系。如果需要配置动态关系，请参见 `federation` 命令。静态关系不会反映在 `federation` 命令中。*

配置联合信任域允许信任域对其他 SPIFFE 机构颁发的身份进行身份验证，从而允许一个信任域中的工作负载安全地对外部信任域中的工作负载进行身份验证。实现联合的一个关键要素是使用 SPIFFE 捆绑端点，这些资源（由 URL 表示）为信任域提供信任捆绑的副本。使用 `federation` 部分，你将能够将 SPIRE 设置为 SPIFFE 捆绑包端点服务器，并配置此 SPIRE 服务器将从中获取捆绑包的联合信任域。

```hcl
server {
    .
    .
    .
    federation {
        bundle_endpoint {
            address = "0.0.0.0"
            port = 8443
            refresh_hint = "10m"
            profile "https_web" {
                acme {
                    domain_name = "example.org"
                    email = "mail@example.org"
                }
            }
        }
        federates_with "domain1.test" {
            bundle_endpoint_url = "https://1.2.3.4:8443"
            bundle_endpoint_profile "https_web" {}
        }
        federates_with "domain2.test" {
            bundle_endpoint_url = "https://5.6.7.8:8443"
            bundle_endpoint_profile "https_spiffe" {
                endpoint_spiffe_id = "spiffe://domain2.test/beserver"
            }
        }
    }
}
```

`federation.bundle_endpoint` 部分是可选的，用于在 SPIRE 服务器中设置 SPIFFE 捆绑端点服务器。 `federation.federates_with` 部分也是可选的，用于配置与外部信任域的联合关系。此部分用于 SPIRE 服务器将定期获取捆绑包的每个联合信任域。

### `federation.bundle_endpoint` 的配置选项

此可选部分包含 SPIRE 服务器用于公开捆绑端点的配置。

| 配置         | 描述                                                         |
| ------------ | ------------------------------------------------------------ |
| address      | 该服务器将侦听 HTTP 请求的 IP 地址                           |
| port         | 该服务器将侦听 HTTP 请求的 TCP 端口号                        |
| refresh_hint | 允许手动指定刷新提示。如果未设置，则根据捆绑包中密钥的生命周期确定。小值允许及时检索信任包更新 |
| profile "<https_web\|https_spiffe>" | 允许配置捆绑配置文件                                         |

### `federation.bundle_endpoint.profile` 的配置选项

当设置 `bundle_endpoint` 时，它是 `required` 来指定捆绑配置文件。

 允许的配置文件：

- `https_web` 允许配置自动证书管理环境部分。
- `https_spiffe`

### `federation.bundle_endpoint.profile "https_web".acme` 的配置选项

| 配置          | 描述                                                         | 默认                                           |
| ------------- | ------------------------------------------------------------ | ---------------------------------------------- |
| directory_url | 目录端点 URL                                                 | https://acme-v02.api.letsencrypt.org/directory |
| domain_name   | 证书管理器尝试检索新证书的域                                 |                                                |
| email         | 联系电子邮件地址。Let's Encrypt 等 CA 使用它来通知已颁发证书的问题 |                                                |
| tos_acceptted | 接受 ACME 服务条款。如果没有设置为 true，并且提供商要求接受，则证书检索将失败 | false                                          |

### `federation.bundle_endpoint.profile "https_spiffe"` 的配置选项

默认捆绑配置文件配置。

### `federation.federates_with["<trust domain>"].bundle_endpoint` 的配置选项

可选的 `federates_with` 部分是捆绑端点配置文件配置的映射，以该服务器想要联合的 `"<trust domain>"` 的名称为键。此部分具有以下可配置项：

| 配置                                | 描述                                                         | 默认 |
| ----------------------------------- | ------------------------------------------------------------ | ---- |
| bundle_endpoint_url                 | 提供要联合的信任捆绑包的 SPIFFE 捆绑包端点的 URL。必须使用 HTTPS 协议。 |      |
| bundle_endpoint_profile "<https_web \| https_spiffe>" | SPIFFE 端点配置文件类型的配置。                | |

SPIRE 支持 `https_web` 和 `https_spiffe` 捆绑端点配置文件。

`https_web` 配置文件不需要额外的设置。

使用 `https_spiffe` 捆绑端点配置文件配置的信任域必须使用 `endpoint_spiffe_id` 设置作为配置的一部分来指定远程 SPIFFE 捆绑端点服务器的预期 SPIFFE ID。

有关 SPIFFE 中定义的不同配置文件的更多信息，以及设置 SPIFFE 联合的安全注意事项，请参阅 [SPIFFE 联邦标准](../../standard/spiffe-federation/)。

## 遥测配置

请参阅遥测配置指南，了解有关配置 SPIRE 服务器以发出遥测数据的更多信息。

## 健康检查配置

服务器可以公开可用于健康检查的附加端点。它可以通过设置 `listener_enabled = true` 来启用。目前它公开了 2 条路径：一条用于活动（服务器是否已启动？），另一条用于准备（服务器是否准备好服务请求？）。默认情况下，健康检查端点将侦听 localhost:80，除非另有配置。

```hcl
health_checks {
        listener_enabled = true
        bind_address = "localhost"
        bind_port = "8080"
        live_path = "/live"
        ready_path = "/ready"
}
```

## 命令行选项

### `spire-server run`

上面的大多数配置文件选项都有相同的命令行对应项。此外，还可以使用以下标志。

| 命令           | 行动                                      | 默认                    |
| -------------- | ----------------------------------------- | ----------------------- |
| `-bindAddress` | SPIRE 服务器的 IP 地址或 DNS 名称         |                         |
| `-config`      | SPIRE 配置文件的路径                      | conf/服务器/服务器.conf |
| `-dataDir`     | 存储运行时数据的目录                      |                         |
| `-expandEnv`   | 展开配置文件中的环境 $VARIABLES           |                         |
| `-logFile`     | 将日志写入的文件                          |                         |
| `-logFormat`   | 日志格式，                                |                         |
| `-logLevel`    | 调试、信息、警告或错误                    |                         |
| `-serverPort`  | SPIRE 服务器的端口号                       |                         |
| `-socketPath`  | 将 SPIRE 服务器 API 套接字绑定到的路径    |                         |
| `-trustDomain` | 该服务器所属的信任域（不应超过 255 个字符） |                         |

#### 将 SPIRE Server 作为 Windows 服务运行

在 Windows 平台上，SPIRE Server 可以选择作为 Windows 服务运行。作为 Windows 服务运行时，唯一支持的命令是 `run` 命令。

*注意：SPIRE 不会自动在系统中创建该服务，必须由用户创建。启动服务时，使用 `run` 命令执行 SPIRE Server 的所有参数都必须作为服务参数传递。*

##### 创建 SPIRE Server Windows 服务的示例

```bash
> sc.exe create spire-server binpath=c:\spire\bin\spire-server.exe
```

##### 运行 SPIRE Server Windows 服务的示例

```bash
> sc.exe start spire-server run -config c:\spire\conf\server\server.conf
```

### `spire-server token generate`

生成一个节点加入令牌并为其创建一个注册条目。该令牌可用于引导一个 spire-agent 安装。除了基于令牌的 ID 之外，可选的 `-spiffeID` 可用于为令牌提供人类可读的注册条目名称。

| 命令          | 行动                                       | 默认                               |
| ------------- | ------------------------------------------ | ---------------------------------- |
| `-socketPath` | SPIRE 服务器 API 套接字的路径              | /tmp/spire-server/private/api.sock |
| `-spiffeID`   | 用于分配令牌所有者的附加 SPIFFE ID（可选） |                                    |
| `-ttl`        | 令牌 TTL（以秒为单位）                     | 600                                |

### `spire-server entry create`

创建注册条目。

| 命令             | 行动                                                         | 默认                                   |
| ---------------- | ------------------------------------------------------------ | -------------------------------------- |
| `-admin`         | 如果设置，此条目中的 SPIFFE ID 将被授予对服务器 API 的访问权限 |                                        |
| `-data`          | 包含 JSON 格式的注册数据的文件的路径（可选，如果指定，则必须省略与条目信息相关的其他标志）。如果设置为“-”，则从 stdin 读取 JSON。 |                                        |
| `-dns`           | DNS 名称将包含在基于此条目发布的 SVID 中（如果适用）。可以多次使用 |                                        |
| `-downstream`    | 布尔值，设置后表示该条目描述下游 SPIRE 服务器                |                                        |
| `-entryExpiry`   | 从数据存储中删除生成的注册条目的到期时间（以秒为单位）。请注意，这是一项数据管理功能，而不是安全功能（可选）。 |                                        |
| `-entryID`       | 新创建的注册条目的用户指定 ID（可选）。如果没有提供条目 ID，则会在创建时生成一个 |                                        |
| `-federatesWith` | 代表与此注册条目联合的信任域的信任域 SPIFFE ID 列表。该信任域的捆绑包必须已存在 |                                        |
| `-node`          | 如果设置，此条目将应用于匹配节点而不是工作负载               |                                        |
| `-parentID`      | 该记录父记录的 SPIFFE ID。                                   |                                        |
| `-selector`      | 用于证明的冒号分隔的类型：值选择器。该参数可以多次使用，以指定必须满足的多个选择器。 |                                        |
| `-socketPath`    | SPIRE 服务器 API 套接字的路径                                | /tmp/spire-server/private/api.sock     |
| `-spiffeID`      | 该记录代表的 SPIFFE ID 并将被设置为颁发的 SVID。             |                                        |
| `-x509SVIDTTL`   | 作为此记录的结果而发出的任何 X509-SVID 的 TTL（以秒为单位）。覆盖 `-ttl` 值。 | 使用 `default_x509_svid_ttl` 配置的 TTL |
| `-jwtSVIDTTL`    | 作为此记录的结果而发出的任何 JWT-SVID 的 TTL（以秒为单位）。覆盖 `-ttl` 值。 | 使用 `default_jwt_svid_ttl` 配置的 TTL  |
| `-storeSVID`     | 一个布尔值，设置后表示必须通过 SVIDStore 插件存储从此条目生成的 SVID |                                        |

### `spire-server entry update`

更新注册条目。

| 命令             | 行动                                                         | 默认                                   |
| ---------------- | ------------------------------------------------------------ | -------------------------------------- |
| `-admin`         | 如果为 true，则此条目中的 SPIFFE ID 将被授予对服务器 API 的访问权限 |                                        |
| `-data`          | 包含 JSON 格式的注册数据的文件的路径（可选，如果指定，则必须省略与条目信息相关的其他标志）。如果设置为“-”，则从 stdin 读取 JSON。 |                                        |
| `-dns`           | DNS 名称将包含在基于此条目发布的 SVID 中（如果适用）。可以多次使用 |                                        |
| `-downstream`    | 布尔值，设置后表示该条目描述下游 SPIRE 服务器                |                                        |
| `-entryExpiry`   | 到期时间（以秒为单位），用于修剪生成的注册条目               |                                        |
| `-entryID`       | 要更新的记录的注册条目 ID                                    |                                        |
| `-federatesWith` | 代表与此注册条目联合的信任域的信任域 SPIFFE ID 列表。该信任域的捆绑包必须已存在 |                                        |
| `-parentID`      | 该记录父记录的 SPIFFE ID。                                   |                                        |
| `-selector`      | 用于证明的冒号分隔的类型：值选择器。该参数可以多次使用，以指定必须满足的多个选择器。 |                                        |
| `-socketPath`    | SPIRE 服务器 API 套接字的路径                                | /tmp/spire-server/private/api.sock     |
| `-spiffeID`      | 该记录代表的 SPIFFE ID 并将被设置为颁发的 SVID。             |                                        |
| `-x509SVIDTTL`   | 作为此记录的结果而发出的任何 X509-SVID 的 TTL（以秒为单位）。覆盖 `-ttl` 值。 | 使用 `default_x509_svid_ttl` 配置的 TTL |
| `-jwtSVIDTTL`    | 作为此记录的结果而发出的任何 JWT-SVID 的 TTL（以秒为单位）。覆盖 `-ttl` 值。 | 使用 `default_jwt_svid_ttl` 配置的 TTL  |
| `storeSVID`      | 一个布尔值，设置后表示必须通过 SVIDStore 插件存储从此条目生成的 SVID |                                        |

### `spire-server entry count`

显示注册条目总数。

| 命令          | 行动                          | 默认                               |
| ------------- | ----------------------------- | ---------------------------------- |
| `-socketPath` | SPIRE 服务器 API 套接字的路径 | /tmp/spire-server/private/api.sock |

### `spire-server entry delete`

删除指定的注册条目。

| 命令          | 行动                          | 默认                               |
| ------------- | ----------------------------- | ---------------------------------- |
| `-entryID`    | 要删除的记录的注册条目 ID     |                                    |
| `-socketPath` | SPIRE 服务器 API 套接字的路径 | /tmp/spire-server/private/api.sock |

### `spire-server entry show`

显示配置的注册条目。

| 命令             | 行动                                                       | 默认                               |
| ---------------- | ---------------------------------------------------------- | ---------------------------------- |
| `-downstream`    | 布尔值，设置后表示该条目描述下游 SPIRE 服务器              |                                    |
| `-entryID`       | 要显示的记录的条目 ID。                                    |                                    |
| `-federatesWith` | 与条目联合的信任域的 SPIFFE ID。可以多次使用               |                                    |
| `-parentID`      | 要显示的记录的父 ID。                                      |                                    |
| `-selector`      | 以冒号分隔的类型：值选择器。可以多次使用来指定多个选择器。 |                                    |
| `-socketPath`    | SPIRE 服务器 API 套接字的路径                              | /tmp/spire-server/private/api.sock |
| `-spiffeID`      | 要显示的记录的 SPIFFE ID。                                 |                                    |

### `spire-server bundle count`

显示捆绑包的总数。

| 命令          | 行动                          | 默认                               |
| ------------- | ----------------------------- | ---------------------------------- |
| `-socketPath` | SPIRE 服务器 API 套接字的路径 | /tmp/spire-server/private/api.sock |

### `spire-server bundle show`

显示服务器信任域的捆绑包。

| 命令          | 行动                                 | 默认                               |
| ------------- | ------------------------------------ | ---------------------------------- |
| `-format`     | 显示捆绑包的格式。 `pem` 或 `spiffe` | pem                                |
| `-socketPath` | SPIRE 服务器 API 套接字的路径        | /tmp/spire-server/private/api.sock |

### `spire-server bundle list`

显示联合捆绑包。

| 命令          | 行动                                                         | 默认                               |
| ------------- | ------------------------------------------------------------ | ---------------------------------- |
| `-id`         | 要显示的捆绑包的信任域 SPIFFE ID。如果未设置，则显示所有信任包 |                                    |
| `-format`     | 显示联合捆绑包的格式。 `pem` 或 `spiffe`                     | pem                                |
| `-socketPath` | SPIRE 服务器 API 套接字的路径                                | /tmp/spire-server/private/api.sock |

### `spire-server bundle set`

创建或更新信任域的捆绑数据。此命令不能用于更改服务器信任域捆绑，只能用于其他信任域的捆绑。

| 命令          | 行动                                                         | 默认                               |
| ------------- | ------------------------------------------------------------ | ---------------------------------- |
| `-id`         | 要设置的捆绑包的信任域 SPIFFE ID。                           |                                    |
| `-path`       | 包含捆绑数据的文件在磁盘上的路径。如果未设置，则从标准输入读取数据。 |                                    |
| `-socketPath` | SPIRE 服务器 API 套接字的路径                                | /tmp/spire-server/private/api.sock |
| `-format`     | 要设置的捆绑包的格式。 `pem` 或 `spiffe`                     | pem                                |

### `spire-server bundle delete`

删除信任域的捆绑数据。该命令不能用于删除服务器信任域捆绑，只能删除其他信任域的捆绑。

| 命令          | 行动                                                         | 默认                               |
| ------------- | ------------------------------------------------------------ | ---------------------------------- |
| `-id`         | 要删除的捆绑包的信任域 SPIFFE ID。                           |                                    |
| `-mode`       | 以下之一： `restrict` 、 `dissociate` 、 `delete` 。 `restrict` 如果捆绑包与注册条目关联（即联合），则防止该捆绑包被删除。 `dissociate` 允许删除捆绑包并从注册条目中删除关联。 `delete` 删除捆绑包以及关联的注册条目。 | `restrict`                         |
| `-socketPath` | SPIRE 服务器 API 套接字的路径                                | /tmp/spire-server/private/api.sock |

### `spire-server federation create`

创建与外部信任域的动态联合关系。

| 命令                       | 行动                                                         | 默认                               |
| -------------------------- | ------------------------------------------------------------ | ---------------------------------- |
| `-bundleEndpointProfile`   | 端点配置文件类型。 `https_web` 或 `https_spiffe` 。          |                                    |
| `-bundleEndpointURL`       | 提供信任捆绑包的 SPIFFE 捆绑包端点的 URL（必须使用 HTTPS 协议）。 |                                    |
| `-data`                    | 包含 JSON 格式的联合关系的文件的路径（可选，如果指定，则必须省略与联合关系信息相关的其他标志）。如果设置为“-”，则从 stdin 读取 JSON。 |                                    |
| `-endpointSpiffeID`        | SPIFFE 捆绑端点服务器的 SPIFFE ID。仅用于 `https_spiffe` 配置文件。 |                                    |
| `-socketPath`              | SPIRE 服务器 API 套接字的路径。                              | /tmp/spire-server/private/api.sock |
| `-trustDomain`             | 要联合的信任域的名称（例如 example.org）                     |                                    |
| `-trustDomainBundleFormat` | 捆绑数据的格式（可选）。 `pem` 或 `spiffe` 。                | pem                                |
| `-trustDomainBundlePath`   | 信任域捆绑数据的路径（可选）。                               |                                    |

### `spire-server federation delete`

删除动态联合关系。

| 命令          | 行动                            | 默认                               |
| ------------- | ------------------------------- | ---------------------------------- |
| `-id`         | 关系的信任域的 SPIFFE ID。      |                                    |
| `-socketPath` | SPIRE 服务器 API 套接字的路径。 | /tmp/spire-server/private/api.sock |

### `spire-server federation list`

列出所有动态联合关系。

| 命令          | 行动                            | 默认                               |
| ------------- | ------------------------------- | ---------------------------------- |
| `-id`         | 关系信任域的 SPIFFE ID          |                                    |
| `-socketPath` | SPIRE 服务器 API 套接字的路径。 | /tmp/spire-server/private/api.sock |

### `spire-server federation refresh`

从指定的联合信任域刷新捆绑包。

| 命令          | 行动                            | 默认                               |
| ------------- | ------------------------------- | ---------------------------------- |
| `-id`         | 关系信任域的 SPIFFE ID          |                                    |
| `-socketPath` | SPIRE 服务器 API 套接字的路径。 | /tmp/spire-server/private/api.sock |

### `spire-server federation show`

显示动态的联邦关系。

| 命令           | 行动                                           | 默认                               |
| -------------- | ---------------------------------------------- | ---------------------------------- |
| `-socketPath`  | SPIRE 服务器 API 套接字的路径。                | /tmp/spire-server/private/api.sock |
| `-trustDomain` | 要显示的联合关系的信任域名（例如 example.org） |                                    |

### `spire-server federation update`

更新与外部信任域的动态联合关系。

| 命令                       | 行动                                                         | 默认                               |
| -------------------------- | ------------------------------------------------------------ | ---------------------------------- |
| `-bundleEndpointProfile`   | 端点配置文件类型。 `https_web` 或 `https_spiffe` 。          |                                    |
| `-bundleEndpointURL`       | 提供信任捆绑包的 SPIFFE 捆绑包端点的 URL（必须使用 HTTPS 协议）。 |                                    |
| `-data`                    | 包含 JSON 格式的联合关系的文件的路径（可选，如果指定，则必须省略与联合关系信息相关的其他标志）。如果设置为“-”，则从 stdin 读取 JSON。 |                                    |
| `-endpointSpiffeID`        | SPIFFE 捆绑端点服务器的 SPIFFE ID。仅用于 `https_spiffe` 配置文件。 |                                    |
| `-socketPath`              | SPIRE 服务器 API 套接字的路径。                              | /tmp/spire-server/private/api.sock |
| `-trustDomain`             | 要联合的信任域的名称（例如 example.org）                     |                                    |
| `-trustDomainBundleFormat` | 捆绑数据的格式（可选）。 `pem` 或 `spiffe` 。                | pem                                |
| `-trustDomainBundlePath`   | 信任域捆绑数据的路径（可选）。                               |                                    |

### `spire-server agent ban`

根据 spiffeID 禁止已证明的节点。被禁止的证明节点无法重新证明。

| 命令          | 行动                                 | 默认                               |
| ------------- | ------------------------------------ | ---------------------------------- |
| `-socketPath` | SPIRE 服务器 API 套接字的路径        | /tmp/spire-server/private/api.sock |
| `-spiffeID`   | 要禁止的代理的 SPIFFE ID（代理身份） |                                    |

### `spire-server agent count`

显示已证明的节点总数。

| 命令          | 行动                          | 默认                               |
| ------------- | ----------------------------- | ---------------------------------- |
| `-socketPath` | SPIRE 服务器 API 套接字的路径 | /tmp/spire-server/private/api.sock |

### `spire-server agent evict`

在给定 spiffeID 的情况下取消对已认证节点的认证。

| 命令          | 行动                                 | 默认                               |
| ------------- | ------------------------------------ | ---------------------------------- |
| `-socketPath` | SPIRE 服务器 API 套接字的路径        | /tmp/spire-server/private/api.sock |
| `-spiffeID`   | 要驱逐的代理的 SPIFFE ID（代理身份） |                                    |

### `spire-server agent list`

显示已证明的节点。

| 命令          | 行动                          | 默认                               |
| ------------- | ----------------------------- | ---------------------------------- |
| `-socketPath` | SPIRE 服务器 API 套接字的路径 | /tmp/spire-server/private/api.sock |

### `spire-server agent show`

显示给定 spiffeID 的已证明节点的详细信息（包括节点选择器）。

| 命令          | 行动                                 | 默认                               |
| ------------- | ------------------------------------ | ---------------------------------- |
| `-socketPath` | SPIRE 服务器 API 套接字的路径        | /tmp/spire-server/private/api.sock |
| `-spiffeID`   | 要显示的代理的 SPIFFE ID（代理身份） |                                    |

### `spire-server healthcheck`

检查 SPIRE 服务器的健康状况。

| 命令          | 行动                          | 默认                               |
| ------------- | ----------------------------- | ---------------------------------- |
| `-shallow`    | 执行不太严格的健康检查        |                                    |
| `-socketPath` | SPIRE 服务器 API 套接字的路径 | /tmp/spire-server/private/api.sock |
| `-verbose`    | 打印详细信息                  |                                    |

### `spire-server validate`

验证 SPIRE 服务器配置文件。参数与 `spire-server run` 相同。通常，你可能至少需要：

| 命令         | 行动                            | 默认           |
| ------------ | ------------------------------- | -------------- |
| `-config`    | SPIRE 服务器配置文件的路径      | 服务器配置文件 |
| `-expandEnv` | 展开配置文件中的环境 $VARIABLES | 错误的         |

### `spire-server x509 mint`

 铸造 X509-SVID。

| 命令          | 行动                                      | 默认                                                         |
| ------------- | ----------------------------------------- | ------------------------------------------------------------ |
| `-dns`        | 将包含在 SVID 中的 DNS 名称。可以多次使用 |                                                              |
| `-socketPath` | SPIRE 服务器 API 套接字的路径             | /tmp/spire-server/private/api.sock                           |
| `-spiffeID`   | X509-SVID 的 SPIFFE ID                    |                                                              |
| `-ttl`        | X509-SVID 的 TTL                          | `Entry.x509_svid_ttl` 、 `Entry.ttl` 、 `default_x509_svid_ttl` 、 `1h` 中的第一个非零值 |
| `-write`      | 将输出写入而不是 stdout 的目录            |                                                              |

### `spire-server jwt mint`

 铸造 JWT-SVID。

| 命令          | 行动                                   | 默认                                                         |
| ------------- | -------------------------------------- | ------------------------------------------------------------ |
| `-audience`   | 观众声称将包含在 SVID 中。可以多次使用 |                                                              |
| `-socketPath` | SPIRE 服务器 API 套接字的路径          | /tmp/spire-server/private/api.sock                           |
| `-spiffeID`   | JWT-SVID 的 SPIFFE ID                  |                                                              |
| `-ttl`        | JWT-SVID 的 TTL                        | `Entry.jwt_svid_ttl` 、 `Entry.ttl` 、 `default_jwt_svid_ttl` 、 `5m` 中的第一个非零值 |
| `-write`      | 要写入令牌而不是标准输出的文件         |                                                              |

## `-data` 的 JSON 对象

传递给 `entry create/update` 的 `-data` 的 JSON 对象需要以下形式：

```json
{
    "entries":[]
}
```

入口对象在公共 protobuf 文件中由 `RegistrationEntry` 描述。

*注意：要创建节点条目，请将 `parent_id` 设置为特殊值 `spiffe://<your-trust-domain>/spire/server` 。这就是在 cli 上传递 `-node` 标志时代码所做的事情。*

## 配置文件示例

本节包括用于格式化和语法参考的示例配置文件

```hcl
server {
    trust_domain = "example.org"

    bind_address = "0.0.0.0"
    bind_port = "8081"
    log_level = "INFO"
    data_dir = "/opt/spire/.data/"
    default_x509_svid_ttl = "6h"
    default_jwt_svid_ttl = "5m"
    ca_ttl = "72h"
    ca_subject {
        country = ["US"]
        organization = ["SPIRE"]
        common_name = ""
    }
}

telemetry {
    Prometheus {
        port = 1234
    }
}

plugins {
    DataStore "sql" {
        plugin_data {
            database_type = "sqlite3"
            connection_string = "/opt/spire/.data/datastore.sqlite3"
        }
    }
    NodeAttestor "join_token" {
        plugin_data {}
    }
    KeyManager "disk" {
        plugin_data {
            keys_path = "/opt/spire/.data/keys.json"
        }
    }
}
```