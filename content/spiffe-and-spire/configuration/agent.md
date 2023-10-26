---
title: "SPIRE Agent 配置参考"
linkTitle: "SPIRE Agent"
weight: 4
---

本文描述 SPIRE Agent 的命令行选项、agent.conf 设置和内置插件。

本文档是 SPIRE Agent 的配置参考。它包括有关插件类型、内置插件、代理配置文件、插件配置和 `spire-agent` 命令的命令行选项的信息。

## 插件类型

| 类型             | 描述                                                         |
| ---------------- | ------------------------------------------------------------ |
| KeyManager       | 生成并存储代理的私钥。对于将密钥绑定到硬件等很有用。         |
| NodeAttestor     | 收集用于向服务器证明代理身份的信息。一般与同类型的服务器插件搭配使用。 |
| WorkloadAttestor | 内省工作负载以确定其属性，生成一组与其关联的选择器。         |
| SVIDStore        | 将 X509-SVID（私钥、叶证书和中间体（如果有））、捆绑包和联合捆绑包存储到信任存储中。 |

## 内置插件

| 类型             | 名称                                                         | 描述                                                         |
| ---------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| KeyManager       | [disk](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_keymanager_disk.md) | 将私钥写入磁盘的密钥管理器                                   |
| KeyManager       | [memory](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_keymanager_memory.md) | 不保留私钥的内存密钥管理器（必须在重新启动后重新证明）       |
| NodeAttestor     | [aws_iid](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_nodeattestor_aws_iid.md) | 使用 AWS 实例身份文档证明代理身份的节点证明者                |
| NodeAttestor     | [azure_msi](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_nodeattestor_azure_msi.md) | 使用 Azure MSI 令牌证明代理身份的节点证明者                  |
| NodeAttestor     | [gcp_iit](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_nodeattestor_gcp_iit.md) | 使用 GCP 实例身份令牌证明代理身份的节点证明者                |
| NodeAttestor     | [join_token](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_nodeattestor_jointoken.md) | 使用服务器生成的加入令牌的节点证明者                         |
| NodeAttestor     | [k8s_sat](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_nodeattestor_k8s_sat.md) | 使用 Kubernetes 服务帐户令牌证明代理身份的节点证明者         |
| NodeAttestor     | [k8s_psat](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_nodeattestor_k8s_psat.md) | 使用 Kubernetes 投影服务帐户令牌证明代理身份的节点证明者     |
| NodeAttestor     | [sshpop](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_nodeattestor_sshpop.md) | 使用现有 ssh 证书证明代理身份的节点证明者                    |
| NodeAttestor     | [ x509pop](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_nodeattestor_x509pop.md) | 使用现有 X.509 证书证明代理身份的节点证明者                  |
| WorkloadAttestor | [docker](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_workloadattestor_docker.md) | 工作负载证明器允许基于 docker 构造的选择器，例如 `label` 和 `image_id` |
| WorkloadAttestor | [k8s](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_workloadattestor_k8s.md) | 工作负载证明器允许基于 Kubernetes 的选择器构造 `ns` （命名空间）和 `sa` （服务帐户） |
| WorkloadAttestor | [unix](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_workloadattestor_unix.md) | 一个工作负载证明器，可生成基于 Unix 的选择器，例如 `uid` 和 `gid` |
| WorkloadAttestor | [systemd](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_workloadattestor_systemd.md) | 工作负载证明器，根据 systemd 单元属性（例如 `Id` 和 `FragmentPath` 生成选择器） |
| SVIDStore        | [aws_secretsmanager](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_svidstore_aws_secretsmanager.md) | SVIDstore 将机密存储在 AWS 机密管理器中，以及代理有权访问的条目的生成 X509-SVID。 |
| SVIDStore        | [gcp_secretmanager](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_svidstore_gcp_secretmanager.md) | SVIDStore 将机密存储在 Google Cloud Secret Manager 中，并包含代理有权访问的条目的结果 X509-SVID。 |

## 代理配置文件

下表概述了 SPIRE 代理的配置选项。这些可以在配置文件的顶级 `agent { ... }` 部分中设置。大多数选项都有一个相应的 CLI 标志，如果设置了该标志，则该标志优先于文件中定义的值。

SPIRE 配置文件可以用 HCL 或 JSON 表示。请参阅示例配置文件部分以获取完整示例。

如果 -expandEnv 标志传递给 SPIRE，则在解析之前扩展 `$VARIABLE` 或 `${VARIABLE}` 样式环境变量。这对于模板化配置文件可能很有用，例如跨不同的信任域，或者插入诸如加入令牌之类的秘密。

| 配置                              | 描述                                                         | 默认                             |
| --------------------------------- | ------------------------------------------------------------ | -------------------------------- |
| `admin_socket_path`               | 绑定管理 API 套接字的位置（默认禁用）                        |                                  |
| `allow_unauthenticated_verifiers` | 允许代理向未经身份验证的验证者发布信任包                     | 错误的                           |
| `allowed_foreign_jwt_claims`      | 验证外部 JWTSVID 时要返回的可信声明列表                      |                                  |
| `authorized_delegates`            | 授权代表的 SPIFFE ID 列表。请参阅委托身份 API 了解更多信息   |                                  |
| `data_dir`                        | 代理可用于其运行时数据的目录                                 | $PWD                             |
| `experimental`                    | 可能会更改或删除的实验选项（见下文）                         |                                  |
| `insecure_bootstrap`              | 如果为 true，代理将在不验证服务器身份的情况下进行引导        | 错误的                           |
| `join_token`                      | 由 SPIRE 服务器生成的可选令牌                                |                                  |
| `log_file`                        | 将日志写入的文件                                             |                                  |
| `log_level`                       | 设置日志记录级别                                             | 信息                             |
| `log_format`                      | 日志格式，                                                   | 文本                             |
| `log_source_location`             | 如果为 true，日志将包含源文件、行号和方法名称字段（增加一点运行时成本） | 错误的                           |
| `profiling_enabled`               | 如果为 true，则启用 net/http/pprof 端点                      | 错误的                           |
| `profiling_freq`                  | 将分析数据转储到磁盘的频率。仅当 `profiling_enabled` 为 `true` 且 `profiling_freq` > 0 时启用。 |                                  |
| `profiling_names`                 | 将在每个分析标记上转储到磁盘的配置文件名称列表，请参阅分析名称 |                                  |
| `profiling_port`                  | net/http/pprof 端点的端口号。仅当 `profiling_enabled` 为 `true` 时使用。 |                                  |
| `server_address`                  | SPIRE 服务器的 DNS 名称或 IP 地址                            |                                  |
| `server_port`                     | SPIRE服务器的端口号                                          |                                  |
| `socket_path`                     | 绑定 SPIRE Agent API 套接字的位置（仅限 Unix）               | /tmp/spire-agent/public/api.sock |
| `sds`                             | 可选的 SDS 配置部分                                          |                                  |
| `trust_bundle_path`               | SPIRE 服务器 CA 捆绑包的路径                                 |                                  |
| `trust_bundle_url`                | 下载初始 SPIRE 服务器信任包的 URL                            |                                  |
| `trust_bundle_format`             | 初始信任包的格式，pem 或 spiffe                              | pem                              |
| `trust_domain`                    | 该代理所属的信任域（不得超过 255 个字符）                    |                                  |
| `workload_x509_svid_key_type`     | 工作负载 X509 SVID 密钥类型                                  | ec-p256                          |

| 实验性的          | 描述                                                        | 默认                    |
| ----------------- | ----------------------------------------------------------- | ----------------------- |
| `named_pipe_name` | 用于绑定 SPIRE Agent API 命名管道的管道名称（仅限 Windows） | \spire-agent\public\api |
| `sync_interval`   | 与指数退避的 SPIRE 服务器同步间隔                           | 5秒                     |

### 初始信任捆绑配置

代理需要初始信任捆绑才能安全连接到 SPIRE 服务器。有以下三种选择：

1. 如果使用 `trust_bundle_path` 选项，代理将从该路径的文件中读取初始信任包。你需要在启动 SPIRE 代理之前复制或共享该文件。
2. 如果使用 `trust_bundle_url` 选项，代理将从指定的 URL 读取初始信任包。为了安全起见，URL 必须以 `https://` 开头，并且服务器必须具有有效的证书（通过系统信任存储区进行验证）。这可用于快速部署 SPIRE 代理，而无需手动共享文件。请记住，URL 的内容需要保持最新。
3. 如果 `insecure_bootstrap` 选项设置为 `true` ，则代理将不会使用初始信任捆绑包。它将连接到 SPIRE 服务器而不进行身份验证。这不是一个安全配置，因为中间人攻击者可以控制 SPIRE 基础设施。包含它是因为它对于测试和开发来说是一个有用的选项。

一次只能设置这三个选项之一。

### SDS 配置

| 配置                             | 描述                                                         | 默认    |
| -------------------------------- | ------------------------------------------------------------ | ------- |
| `default_svid_name`              | 用于 Envoy SDS 的默认 X509-SVID 的 TLS 证书资源名称          | default |
| `default_bundle_name`            | 用于 Envoy SDS 的默认 X.509 捆绑包的验证上下文资源名称       | ROOTCA  |
| `default_all_bundles_name`       | 用于 Envoy SDS 的所有捆绑包（包括联合捆绑包）的验证上下文资源名称 | ALL     |
| `disable_spiffe_cert_validation` | 禁用 Envoy SDS 自定义验证                                    | false   |

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

代理配置文件还包含代理插件的配置。插件配置位于 `plugins { ... }` 部分，其格式如下：

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

| 配置            | 描述                                             |
| --------------- | ------------------------------------------------ |
| plugin_cmd      | 插件实现二进制文件的路径（可选，内置插件不需要） |
| plugin_checksum | 插件二进制文件的可选 sha256（可选，内置不需要）  |
| enabled         | 启用或禁用插件（默认启用）                       |
| plugin_data     | 插件特定数据                                     |

请参阅内置插件部分，了解有关开箱即用的插件的信息。

## 遥测配置

请参阅遥测配置指南，了解有关配置 SPIRE Agent 以发出遥测数据的更多信息。

## 健康检查配置

代理可以公开可用于健康检查的其他端点。它可以通过设置 `listener_enabled = true` 来启用。目前它公开了 2 条路径：一条用于活动（代理启动），一条用于准备（代理准备好服务请求）。默认情况下，健康检查端点将侦听 localhost:80，除非另有配置。

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

### `spire-agent run`

上述所有配置文件选项都有相同的命令行对应项。此外，还可以使用以下标志：

| 命令                             | 行动                                      | 默认                 |
| -------------------------------- | ----------------------------------------- | -------------------- |
| `-allowUnauthenticatedVerifiers` | 允许代理向未经身份验证的验证者发布信任包  |                      |
| `-config`                        | SPIRE 配置文件的路径                      | conf/代理/agent.conf |
| `-dataDir`                       | 代理可用于其运行时数据的目录              |                      |
| `-expandEnv`                     | 展开配置文件中的环境 $VARIABLES           |                      |
| `-joinToken`                     | 由 SPIRE 服务器生成的可选令牌             |                      |
| `-logFile`                       | 将日志写入的文件                          |                      |
| `-logFormat`                     | 日志格式，                                |                      |
| `-logLevel`                      | 调试、信息、警告或错误                    |                      |
| `-serverAddress`                 | SPIRE 服务器的 IP 地址或 DNS 名称         |                      |
| `-serverPort`                    | SPIRE服务器的端口号                       |                      |
| `-socketPath`                    | 绑定工作负载 API 套接字的位置             |                      |
| `-trustBundle`                   | SPIRE 服务器 CA 捆绑包的路径              |                      |
| `-trustBundleUrl`                | 下载 SPIRE 服务器 CA 捆绑包的 URL         |                      |
| `-trustDomain`                   | 该代理所属的信任域（不得超过 255 个字符） |                      |

#### 将 SPIRE Agent 作为 Windows 服务运行

在 Windows 平台上，SPIRE Agent 可以选择作为 Windows 服务运行。作为 Windows 服务运行时，唯一支持的命令是 `run` 命令。

*注意：SPIRE不会自动在系统中创建该服务，必须由用户创建。启动服务时，使用 `run` 命令执行 SPIRE Agent 的所有参数都必须作为服务参数传递。*

##### 创建 SPIRE Agent Windows 服务的示例

```bash
> sc.exe create spire-agent binpath=c:\spire\bin\spire-agent.exe
```

##### 运行 SPIRE Agent Windows 服务的示例

```bash
> sc.exe start spire-agent run -config c:\spire\conf\agent\agent.conf
```

### `spire-agent api fetch`

调用工作负载 API 以获取 X509-SVID。该命令的别名为 `spire-agent api fetch x509` 。

| 命令          | 行动                         | 默认                             |
| ------------- | ---------------------------- | -------------------------------- |
| `-silent`     | 抑制标准输出                 |                                  |
| `-socketPath` | SPIRE Agent API 套接字的路径 | /tmp/spire-agent/public/api.sock |
| `-timeout`    | 等待回复的时间               | 1s                               |
| `-write`      | 将SVID数据写入指定路径       |                                  |

### `spire-agent api fetch jwt`

调用工作负载 API 以获取 JWT-SVID。

| 命令          | 行动                                | 默认                             |
| ------------- | ----------------------------------- | -------------------------------- |
| `-audience`   | 以逗号分隔的受众群体值列表          |                                  |
| `-socketPath` | SPIRE Agent API 套接字的路径        | /tmp/spire-agent/public/api.sock |
| `-spiffeID`   | 正在请求的 JWT 的 SPIFFE ID（可选） |                                  |
| `-timeout`    | 等待回复的时间                      | 1s                               |

### `spire-agent api fetch x509`

调用工作负载 API 以获取 x.509-SVID。

| 命令          | 行动                         | 默认                             |
| ------------- | ---------------------------- | -------------------------------- |
| `-silent`     | 抑制标准输出                 |                                  |
| `-socketPath` | SPIRE Agent API 套接字的路径 | /tmp/spire-agent/public/api.sock |
| `-timeout`    | 等待回复的时间               | 1s                               |
| `-write`      | 将SVID数据写入指定路径       |                                  |

### `spire-agent api validate jwt`

调用工作负载 API 以验证提供的 JWT-SVID。

| 命令          | 行动                         | 默认                             |
| ------------- | ---------------------------- | -------------------------------- |
| `-audience`   | 以逗号分隔的受众群体值列表   |                                  |
| `-socketPath` | SPIRE Agent API 套接字的路径 | /tmp/spire-agent/public/api.sock |
| `-svid`       | 待验证的 JWT-SVID            |                                  |
| `-timeout`    | 等待回复的时间               | 1s                               |

### `spire-agent api watch`

连接到工作负载 API 并监视 X509-SVID 更新，并在收到更新时打印详细信息。

| 命令          | 行动                         | 默认                             |
| ------------- | ---------------------------- | -------------------------------- |
| `-socketPath` | SPIRE Agent API 套接字的路径 | /tmp/spire-agent/public/api.sock |

### `spire-agent healthcheck`

检查 SPIRE 代理的健康状况。

| 命令          | 行动                         | 默认                             |
| ------------- | ---------------------------- | -------------------------------- |
| `-shallow`    | 执行不太严格的健康检查       |                                  |
| `-socketPath` | SPIRE Agent API 套接字的路径 | /tmp/spire-agent/public/api.sock |
| `-verbose`    | 打印详细信息                 |                                  |

### `spire-agent validate`

验证 SPIRE 代理配置文件。

| 命令         | 行动                            | 默认         |
| ------------ | ------------------------------- | ------------ |
| `-config`    | SPIRE 代理配置文件的路径        | 代理配置文件 |
| `-expandEnv` | 展开配置文件中的环境 $VARIABLES | 错误的       |

## 配置文件示例

本节包括用于格式化和语法参考的示例配置文件

```hcl
agent {
    trust_domain = "example.org"
    trust_bundle_path = "/opt/spire/conf/initial_bundle.crt"

    data_dir = "/opt/spire/.data"
    log_level = "DEBUG"
    server_address = "spire-server"
    server_port = "8081"
    socket_path ="/tmp/spire-agent/public/api.sock"
}

telemetry {
    Prometheus {
        port = 1234
    }
}

plugins {
    NodeAttestor "join_token" {
        plugin_data {
        }
    }
    KeyManager "disk" {
        plugin_data {
            directory = "/opt/spire/.data"
        }
    }
    WorkloadAttestor "k8s" {
        plugin_data {
            kubelet_read_only_port = "10255"
        }
    }
    WorkloadAttestor "unix" {
        plugin_data {
        }
    }
}
```

## 委托身份API

委派身份 API 允许授权（即委派）工作负载代表无法由 SPIRE Agent 直接证明的工作负载获取 SVID 和捆绑包。授权工作负载通过向 SPIRE Agent 提供通常在工作负载证明期间获取的选择器来实现此目的。委派身份 API 通过管理 API 端点提供服务。

要启用委派身份 API，请配置管理 API 端点地址和授权委派的 SPIFFE ID 列表。例如：

 Unix系统：

```hcl
agent {
    trust_domain = "example.org"
    ...
    admin_socket_path = "/tmp/spire-agent/private/admin.sock"
    authorized_delegates = [
        "spiffe://example.org/authorized_client1",
        "spiffe://example.org/authorized_client2",
    ]
}
```

 Windows：

```hcl
agent {
    trust_domain = "example.org"
    ...
    experimental {
        admin_named_pipe_name = "\\spire-agent\\private\\admin"
    }
    authorized_delegates = [
        "spiffe://example.org/authorized_client1",
        "spiffe://example.org/authorized_client2",
    ]
}
```

## Envoy SDS 支持

SPIRE 代理支持 Envoy Secret Discovery Service (SDS)。 SDS 通过与工作负载 API 相同的 Unix 域套接字提供服务。连接到 SDS 的 Envoy 进程被证明为工作负载。

可以使用工作负载的 SPIFFE ID 作为资源名称（例如 `spiffe://example.org/database` ）来获取包含 X509-SVID 的 `tlsv3.TlsCertificate` 资源。或者，如果使用默认名称“default”，则会获取包含工作负载（即 Envoy）的默认 X509-SVID 的 `tlsv3.TlsCertificate` 。默认名称是可配置的（请参阅 SDS 配置下的 `default_svid_name` ）。

可以使用所需信任域的 SPIFFE ID 作为资源名称（例如 `spiffe://example.org` ）来获取包含受信任 CA 证书的 `tlsv3.CertificateValidationContext` 资源。此外，还有另外两个特殊资源名称可用。第一个默认为“ROOTCA”，为代理所属的信任域提供 CA 证书。第二个默认为“ALL”，返回代理所属信任域以及适用于 Envoy 工作负载的任何联合信任域的可信 CA 证书。这些资源名称的默认名称可分别通过 `default_bundle_name` 和 `default_all_bundles_name` 进行配置。 “ALL”资源名称需要支持 SPIFFE 证书验证器扩展，该扩展仅从 Envoy 1.18 开始可用。默认名称是可配置的（请参阅 SDS 配置下的 `default_all_bundles_name` 。

SPIFFE 证书验证器将 Envoy 配置为执行 SPIFFE 身份验证。 SPIRE Agent 返回的验证上下文默认包含此扩展。然而，如果需要标准 X.509 链验证，SPIRE Agent 可以配置为省略扩展。可以通过在 SDS 配置中配置 `disable_spiffe_cert_validation` 来更改默认行为。各个 Envoy 实例还可以通过在 Envoy 节点元数据中配置设置 `disable_spiffe_cert_validation` 键来覆盖默认行为。

## OpenShift 支持

OpenShift 的默认安全配置文件禁止访问主机级资源。可以应用一组自定义策略来启用 Spire 在 OpenShift 中运行所需的访问级别。

*注意：需要具有 `cluster-admin` 权限的用户才能应用这些策略。*

### 安全上下文约束

Pod 执行的操作由安全上下文约束 (SCC) 控制，并且根据条件范围为每个被接纳的 Pod 分配一个特定的 SCC。以下名为 `spire` 的自定义 SCC 可用于启用 Spire Agent 所需的必要主机级访问

```yaml
allowHostDirVolumePlugin: true
allowHostIPC: true
allowHostNetwork: true
allowHostPID: true
allowHostPorts: true
allowPrivilegeEscalation: true
allowPrivilegedContainer: false
allowedCapabilities: null
apiVersion: security.openshift.io/v1
defaultAddCapabilities: null
fsGroup:
  type: MustRunAs
groups: []
kind: SecurityContextConstraints
metadata:
  annotations:
    include.release.openshift.io/self-managed-high-availability: "true"
    kubernetes.io/description: Customized policy for Spire to enable host level access.
    release.openshift.io/create-only: "true"
  name: spire
priority: null
readOnlyRootFilesystem: false
requiredDropCapabilities:
  - KILL
  - MKNOD
  - SETUID
  - SETGID
runAsUser:
  type: RunAsAny
seLinuxContext:
  type: MustRunAs
supplementalGroups:
  type: RunAsAny
users: []
volumes:
  - hostPath
  - configMap
  - downwardAPI
  - emptyDir
  - persistentVolumeClaim
  - projected
  - secret
```

### 将安全约束与工作负载关联

通过将 SCC 与 pod 引用的服务帐户相关联，可以通过基于角色的访问控制策略授予工作负载对安全上下文约束的访问权限。

为了利用 `spire` SCC，必须创建一个利用引用 SCC 的 `use` 动词的 ClusterRole：

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    include.release.openshift.io/self-managed-high-availability: "true"
    rbac.authorization.kubernetes.io/autoupdate: "true"
  name: system:openshift:scc:spire
rules:
- apiGroups:
  - security.openshift.io
  resourceNames:
  - spire
  resources:
  - securitycontextconstraints
  verbs:
  - use
```

最后，通过在 `spire` 命名空间中创建 RoleBinding，将 `system:openshift:scc:spire` ClusterRole 关联到 `spire-agent` 服务帐户

注意：如果在应用以下策略之前存在 `spire` 命名空间，则创建该命名空间。

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: system:openshift:scc:spire
  namespace: spire
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:openshift:scc:spire
subjects:
  - kind: ServiceAccount
    name: spire-agent
    namespace: spire
```

由于 SCC 在 Pod 准入时应用，因此请删除任何现有的 Spire Agent Pod。所有新接纳的 pod 将利用 `spire` SCC，以便在 OpenShift 中使用。