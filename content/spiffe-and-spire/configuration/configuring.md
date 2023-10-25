---
weight: 1
title: "配置 SPIRE"
---

要根据你的应用程序需求自定义 SPIRE 服务器和 SPIRE 代理的行为，你需要编辑服务器和代理的配置文件。

## 如何配置 SPIRE

SPIRE 服务器和代理的配置文件分别为 `server.conf` 和 `agent.conf`。

默认情况下，服务器期望配置文件位于 `conf/server/server.conf`，但是服务器可以通过 `--config` 标志配置为使用不同位置的配置文件。有关更多信息，请参阅 [SPIRE 服务器参考](https://spiffe.io/docs/latest/deploying/spire_server/)。

同样，代理期望配置文件位于 `conf/agent/agent.conf`，但是代理可以通过 `--config` 标志配置为使用不同位置的配置文件。有关更多信息，请参阅 [SPIRE 代理参考](https://spiffe.io/docs/latest/deploying/spire_agent/)。

配置文件在启动服务器或代理时加载一次。如果更改了服务器或代理的配置文件，则必须重新启动服务器或代理以使配置生效。

在 Kubernetes 中运行 SPIRE 时，通常将配置文件存储在 `ConfigMap` 对象中，然后将其作为文件挂载到运行代理或服务器进程的容器中。

SPIRE 代理支持使用 [HCL](https://github.com/hashicorp/hcl) 或 [JSON](http://www.json.org/) 作为配置文件结构语法。下面的示例将假定使用 HCL。

## 配置信任域

*此配置适用于 SPIRE 服务器和 SPIRE 代理*

信任域对应于 SPIFFE 身份提供者的信任根。信任域可以表示运行其自己独立的 SPIFFE 基础设施的个人、组织、环境或部门。在同一信任域中标识的所有工作负载都将获得可以与信任域的根密钥进行验证的身份文件。

每个 SPIRE 服务器关联一个必须在该组织内唯一的信任域。信任域采用与 DNS 名称相同的形式（例如，`prod.acme.com`），但不需要与任何 DNS 基础设施对应。

在首次启动服务器之前，需要在 SPIRE 服务器中配置信任域。通过在配置文件的 `server` 部分的 `trust_domain` 参数中配置。例如，如果服务器的信任域应配置为 `prod.acme.com`，则应设置为：

```
trust_domain = "prod.acme.com"
```

同样，代理必须通过在代理配置文件的 `agent` 部分的 `trust_domain` 参数中配置来为相同的信任域颁发身份。

SPIRE 服务器和代理只能为单个信任域*颁发*身份，代理配置的信任域必须与其连接的服务器的信任域匹配。

## 配置服务器监听代理的端口

*此配置适用于 SPIRE 服务器*

默认情况下，SPIRE 服务器在端口 8081 上监听来自 SPIRE 代理的传入连接；要选择不同的值，请编辑 `server.conf` 文件中的 `bind_port` 参数。例如，要将监听端口更改为 9090：

```
bind_port = "9090"
```

如果从服务器的默认配置更改了此配置，则还必须在代理上更改服务端口的配置。

## 配置节点认证

*此配置适用于 SPIRE 服务器和 SPIRE 代理*

SPIFFE 服务器通过节点认证和解析的过程来识别和验证代理。这是通过节点验证器和节点解析器插件来完成的，你需要在服务器中配置和启用它们。

你选择的节点认证方法将确定你在 SPIRE 配置文件的服务器插件和代理插件部分中配置 SPIRE 使用哪些节点验证器插件。服务器上必须配置*至少一个*节点验证器，每个代理上只能配置*一个*节点验证器。

### 对运行在 Kubernetes 上的节点进行认证

为了向在 Kubernetes 集群中运行的工作负载发放身份，需要在每个运行负载的集群节点上部署一个 SPIRE 代理。（[在 Kubernetes 上安装 SPIRE 代理](https://spiffe.io/docs/latest/spire/installing/install-agents/#installing-spire-agents-on-kubernetes)了解如何在 Kubernetes 上安装 SPIRE 代理）。

可以使用 Kubernetes 的 [Token Review API](https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/token-review-v1/) 对服务帐户令牌进行验证。因此，SPIRE 服务器本身不需要在 Kubernetes 上运行，并且单个 SPIRE 服务器可以支持在启用了 PSAT 认证的多个 Kubernetes 集群上运行的代理。

#### Projected Service Account Tokens

在撰写本文时，预投影的服务帐户是 Kubernetes 的一个相对较新的功能，不是所有部署都支持它们。你的 Kubernetes 平台文档将告诉你是否支持此功能。如果你的 Kubernetes 部署不支持预投影的服务帐户令牌，则应启用服务帐户令牌。

使用 Kubernetes 的 [Projected Service Account Tokens](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#service-account-token-volume-projection) (PSATs) 对节点进行认证允许 SPIRE 服务器验证在 Kubernetes 集群上运行的 SPIRE 代理的身份。预投影的服务帐户令牌相对于传统的 Kubernetes 服务帐户令牌提供了额外的安全保证，因此，如果 Kubernetes 集群支持，PSAT 是推荐的认证策略。

要使用 PSAT 节点认证，请在 [SPIRE Server](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_nodeattestor_k8s_psat.md) 和 [SPIRE Agent](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_nodeattestor_k8s_psat.md) 上配置启用 PSAT 节点认证器插件。

#### 服务帐户令牌

在 Kubernetes 上运行工作负载时，如果集群上没有 Projected Service Account Token 功能，则 SPIRE 可以使用 Service Account Tokens 在 Server 和 Agent 之间建立信任。与使用 Projected Service Account Tokens 不同，此方法要求 SPIRE Server 和 SPIRE Agent 都部署在同一个 Kubernetes 集群上。

由于服务帐户令牌不包含可用于强力识别运行 Agent 的节点/守护程序/Pod 的声明，因此任何在允许的服务帐户下运行的容器都可以冒充 Agent。因此，强烈建议在使用此认证方法时，Agent 应在专用的服务帐户下运行。

要使用 SAT 节点认证，请在 [SPIRE Server](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_nodeattestor_k8s_sat.md) 和 [SPIRE Agent](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_nodeattestor_k8s_sat.md) 上配置和启用 SAT 节点认证器插件。

### 对运行 Linux 的节点进行认证

SPIRE 能够对运行 Linux 的物理或虚拟机（节点）上的工作负载的身份进行认证。作为认证过程的一部分，SPIRE Server 需要建立与运行 Linux 节点上的 SPIRE Agent 的信任关系。根据节点运行的位置，SPIRE 支持各种节点认证器，这些节点认证器允许在创建注册项时使用不同的选择器来标识特定的工作负载。

#### 加入令牌（Join Token）

加入令牌是一种使用单次使用的令牌来对服务器进行认证的简单方法，该令牌在服务器上生成并在启动代理时提供给代理。它适用于在 Linux 上运行的任何节点。

SPIRE 服务器可以通过在 `server.conf` 配置文件中启用内置的`join-token` NodeAttestor 插件来支持加入令牌认证，如下所示：

```
NodeAttestor "join_token" {
    plugin_data {
    }
}
```

配置了加入令牌节点认证之后，可以使用`spire-server token generate`命令在服务器上生成加入令牌。可以使用`-spiffeID`标志将特定的 SPIFFE ID 与加入令牌关联起来。[在此处阅读更多](https://spiffe.io/docs/latest/deploying/spire_server/#spire-server-token-generate)有关使用此命令的更多信息。

当第一次启动启用加入令牌证明的 SPIRE 代理时，可以使用 `spire-agent run` 命令启动代理，并使用 `-joinToken` 标志指定服务器生成的加入令牌。有关此命令的详细信息，请阅读[更多](https://spiffe.io/docs/latest/deploying/spire_agent/#spire-agent-run)。

服务器将验证加入令牌并向代理颁发 SVID（SPIFFE 身份验证信息文档）。只要代理与服务器保持连接，SVID 将自动轮换。在以后的启动中，除非 SVID 已过期且未续订，否则代理将使用该 SVID 对服务器进行身份验证。

要使用加入令牌节点证明，请在 [SPIRE 服务器](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_nodeattestor_jointoken.md)和 [SPIRE 代理](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_nodeattestor_jointoken.md)上配置和启用加入令牌节点证明插件。

要在服务器上禁用加入令牌证明，请在启动之前从配置文件中注释或删除此部分。

#### X.509 证书

在许多情况下，特别是在手动配置节点的情况下（例如在数据中心），可以通过验证先前安装在节点上的现有 X.509 叶子证书来识别节点并唯一标识它。

通常，这些叶子证书是从单个公共密钥和证书（在本指南中称为*根证书包*）生成的。服务器必须配置根密钥和任何中间证书，以便能够验证特定机器呈现的叶子证书。只有找到可以通过证书链验证到服务器的证书时，节点证明才会成功，并且可以向该节点上的工作负载发布 SPIFFE ID。

此外，证明者公开了 `subject:cn ` 选择器，该选择器将匹配满足以下条件的证书：（a）有效，如上所述，（b）其通用名称（CN）与选择器中描述的通用名称匹配。

要使用 X.509 证书节点证明，请在 [SPIRE 服务器](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_nodeattestor_x509pop.md)和 [SPIRE 代理](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_nodeattestor_x509pop.md)上配置和启用 x509pop 节点证明插件。

#### SSH 证书

在某些环境中，每个节点都会自动配备一个有效且唯一的 SSH 证书，用于标识该节点。SPIRE 可以使用此证书来引导其身份验证。

通过这种方法进行验证的节点会自动获得形式为的 SPIFFE ID：

```
spiffe://<trust-domain>/spire/agent/sshpop/<fingerprint>
```

其中 `<fingerprint>` 是证书本身的哈希值。然后，可以使用此 SPIFFE ID 作为其他工作负载注册条目的基础。

要使用 SSH 证书节点验证，请在 SPIRE 服务器和 SPIRE 代理上配置并启用 sshpop 节点验证插件。

### 云供应商上的 Linux 节点验证

许多云供应商提供特权 API，允许在由该供应商托管的特定节点上运行的进程能够证明其所在的节点。SPIRE 可以配置为利用这些 API 进行节点验证。这对于自动化来说特别方便，因为在新实例上首次启动代理时，代理可以自动向 SPIRE 服务器证明其身份，而无需为其发行预先存在的证书或加入令牌。

#### Google Compute Engine 实例

Google Compute Engine（GCE）节点验证和解析允许 SPIRE 服务器自动识别和验证在 GCP GCE 实例上运行的 SPIRE 代理。简而言之，通过以下步骤完成：

1. SPIRE 代理 gcp_iit 节点验证插件检索 GCP 实例的实例标识令牌，并向 SPIRE 服务器 gcp_iit 节点验证插件标识自身。
2. 如果 `use_instance_metadata` 配置值设置为 `true`，SPIRE 服务器 gcp_iit 节点验证插件调用 GCP API 验证令牌的有效性。
3. 验证完成后，SPIRE 代理被视为经过验证，并分配其自己的 SPIFFE ID。
4. 最后，如果工作负载与注册条目匹配，SPIRE 会向节点上的工作负载发放 SVID。注册条目可以包括节点验证插件或解析器公开的选择器，或者将 SPIRE 代理的 SPIFFE ID 作为父级。

要使用 GCP IIT 节点验证，请在 SPIRE 服务器和 SPIRE 代理上配置并启用 gcp_iit 节点验证插件。

#### Amazon EC2 实例

EC2 节点认证和解析允许 SPIRE 服务器自动识别和验证在 AWS EC2 实例上运行的 SPIRE Agent。简而言之，通过以下方式实现：

1. SPIRE Agent 的 aws_iid 节点证明插件检索 AWS 实例的实例身份文档，并向 SPIRE Server 的 aws_iid 节点证明插件进行身份验证。
2. SPIRE Server 的 aws_iid 节点证明插件使用具有有限权限的 AWS IAM 角色调用 AWS API 来验证文档的有效性。
3. 如果配置了 aws_iid 节点解析器插件，则 SPIRE 将使用节点的已验证身份查找有关节点的其他信息。此元数据可以用作注册条目中的选择器。
4. 验证完成后，SPIRE Agent 被视为经过验证的，并被分配其自己的 SPIFFE ID。
5. 最后，如果工作负载与注册条目匹配，SPIRE 为节点上的工作负载发放 SVID。注册条目可以包含节点证明者或解析器提供的选择器，或者将 SPIRE Agent 的 SPIFFE ID 作为父级。

有关配置 AWS EC2 节点证明者或解析器插件的更多信息，请参阅 SPIRE 服务器的相应 SPIRE 文档，其中包括 [SPIRE 服务器节点证明者](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_nodeattestor_aws_iid.md) 和 [SPIRE 服务器节点解析器](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_noderesolver_aws_iid.md)，以及代理上的 [SPIRE Agent 节点证明者](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_nodeattestor_aws_iid.md)。

#### Azure 虚拟机

Azure MSI 节点认证和解析允许 SPIRE 服务器自动识别和验证在 Azure VM 上运行的 SPIRE Agent。SPIRE 使用 MSI 令牌来验证代理。如果拦截，MSI 令牌必须进行范围限制以防止滥用。简而言之，通过以下方式实现：

1. SPIRE Agent 的 azure_msi 节点证明插件检索 Azure VM 的 MSI 令牌，并向 SPIRE Server 的 azure_msi 节点证明插件进行身份验证。
2. SPIRE Server 的 azure_msi 节点证明插件通过 API 调用从 Azure 检索 JSON Web Key Set (JWKS) 文档，并使用 JWKS 信息验证 MSI 令牌。
3. SPIRE Server 的 azure_msi 节点解析器插件与 Azure 交互，获取有关代理 VM 的信息，例如订阅 ID、VM 名称、网络安全组、虚拟网络和虚拟网络子网，以构建有关代理 VM 的属性集，然后可以将其用作 Azure 节点集的节点选择器。
4. 一旦验证完成，SPIRE 代理将被视为已验证，并发放其自己的 SPIFFE ID。
5. 最后，如果工作负载与注册条目匹配，SPIRE 将向节点上的工作负载发放 SVID。注册条目可以包括节点验证器或解析器公开的选择器，或者将 SPIRE 代理的 SPIFFE ID 作为父级。

默认情况下，代理插件分配的资源范围相对较大，它使用 Azure 资源管理器 (`https://management.azure.com` 端点) 的资源 ID。出于安全考虑，考虑使用自定义资源 ID 来进行更精细的范围设置。

如果在代理配置文件中配置自定义资源 ID，则必须在 `server.conf` 配置文件的 `NodeAttestor` 部分中为每个租户指定自定义资源 ID。

有关配置 Azure MSI 节点验证器或解析器插件的更多信息，请参阅对应的 SPIRE 文档，包括 Azure MSI [SPIRE Server 节点验证器](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_nodeattestor_azure_msi.md)，[SPIRE Server 节点解析器](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_noderesolver_azure_msi.md)，以及代理上的 [SPIRE 代理节点验证器](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_nodeattestor_azure_msi.md)。

## 配置工作负载验证

*此配置适用于 SPIRE 代理*

与节点验证器关注的是 SPIRE Server 如何在特定物理或虚拟机上识别 SPIRE 代理不同，工作负载验证关注的是 SPIRE 代理如何识别特定进程。通常，两者结合使用以识别特定的工作负载。

与节点验证类似，工作负载验证通过启用相关插件来完成。不同的插件提供了不同的选择器，可在注册条目中使用这些选择器来识别特定的工作负载。与节点验证不同，对于单个工作负载，工作负载验证可以使用多种策略。例如，对于给定的 Unix 组，可能要求单个工作负载运行，并从特定的 Docker 镜像启动。

### 为由 Kubernetes 调度的工作负载进行工作负载证明

当工作负载在 Kubernetes 中运行时，能够用 Kubernetes 构造描述它们是非常有价值的，比如与工作负载运行的 Pod 相关联的命名空间、服务账户或标签。

Kubernetes 工作负载证明插件通过与本地的 Kubelet 进行交互来检索有关特定进程的 Kubernetes 特定元数据，当它调用工作负载 API 时，使用这些元数据来识别与注册条目匹配的工作负载。

有关更多信息，包括暴露的选择器的详细信息，请参阅 [Kubernetes 工作负载证明插件的相应 SPIRE 文档](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_workloadattestor_k8s.md)。

### 为 Docker 容器进行工作负载证明

当工作负载在 Docker 容器中运行时，能够用该容器的属性来描述它们是很有帮助的，比如容器启动的 Docker 镜像或特定环境变量的值。

Docker 工作负载证明插件通过与本地的 Docker 守护程序进行交互来检索有关特定进程的 Docker 特定元数据，当它调用工作负载 API 时。

有关更多信息，包括暴露的选择器的详细信息，请参阅 [Docker 工作负载证明插件的相应 SPIRE 文档](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_workloadattestor_docker.md)。

### 为 Unix 进程进行工作负载证明

当工作负载在 Unix 上运行时，能够用进程在 Unix 中的管理方式来描述它们是很有帮助的，比如它正在运行的 Unix 组的名称。

Unix 工作负载证明通过检查 Unix 域套接字的调用者来确定调用 Workload API 的工作负载的内核元数据。

有关更多信息，包括暴露的选择器的详细信息，请参阅 [Unix 工作负载证明插件的相应 SPIRE 文档](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_workloadattestor_unix.md)。

## 配置代理和服务器数据存储位置

*此配置适用于 SPIRE 服务器和 SPIRE 代理*

`agent.conf` 和 `server.conf` 配置文件中的 `data_dir` 选项设置了 SPIRE 运行时数据的目录。

如果你为 `data_dir` 指定了相对路径，即以 `./` 开头的路径，则 `data_dir` 将基于你执行 `spire-agent` 或 `spire-server` 命令时的当前工作目录进行评估。使用相对路径的 `data_dir` 对于对 SPIRE 进行初始评估可能很有用，但对于生产部署，你可能希望将 `data_dir` 设置为绝对路径。按照惯例，如果你已在 `/opt/spire` 安装了 SPIRE，则将 `data_dir` 指定为 `"/opt/spire/data"`。

确保你为 `data_dir` 指定的路径及其所有子目录对运行 SPIRE 代理或服务器可执行文件的 Linux 用户可读取。你可能需要使用 [chown](http://man7.org/linux/man-pages/man1/chown.1.html) 来更改这些数据目录的所有权，以便其归属于将运行可执行文件的 Linux 用户。

如果你为 `data_dir` 指定的路径不存在，则 SPIRE 代理或服务器可执行文件将在具有执行权限的情况下创建该路径。

通常，你应该将 `data_dir` 的值用作在 `agent.conf` 和 `server.conf` 配置文件中配置的其他数据路径的基目录。例如，如果你在 `agent.conf` 中将 `data_dir` 设置为 `"/opt/spire/data"`，则将 `KeyManager“disk”plugin_data directory` 设置为 `"/opt/spire/data/agent"`。或者，如果你在 `server.conf` 中将 `data_dir` 设置为 `/opt/spire/data`，则将 `connection_string` 设置为 `"/opt/spire/data/server/datastore.sqlite3"`，如果你使用 SQLite 作为 SPIRE Server 数据存储，则如下所述。

## 配置服务器数据存储方式

*此配置适用于 SPIRE 服务器*

数据存储是 SPIRE 服务器用于持久化动态配置的地方，例如从 SPIRE 服务器检索的注册条目和标识映射策略。默认情况下，SPIRE 使用 SQLite 捆绑并将其设置为默认的服务器数据存储方式。SPIRE 还支持其他兼容的数据存储。对于生产用途，你应该仔细考虑使用哪个数据库，特别是在将 SPIRE 部署在高可用配置时。

可以通过配置默认的 SQL 数据存储插件来将 SPIRE 服务器配置为使用不同的 SQL 兼容存储后端，如下所述。有关如何配置此块的完整参考，请参阅[SPIRE 文档](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_datastore_sql.md)。

#### 将 SQLite 配置为 SPIRE 数据存储

默认情况下，SPIRE 服务器会创建并使用本地 SQLite 数据库来备份和存储配置数据。虽然对于测试来说很方便，但是在生产部署中通常不推荐使用，因为很难在多台机器上共享 SQLite 数据存储，这会使备份、HA 部署和升级变得复杂。

要配置服务器使用 SQLite 数据库，请在配置文件中启用以下类似的部分：

```
    DataStore "sql" {
        plugin_data {
            database_type = "sqlite3"
            connection_string = "/opt/spire/data/server/datastore.sqlite3"
        }
    }
```

配置文件中不应该有其他（取消注释的）`DataStore` 部分。

数据库将在 `connection_string` 中指定的路径中创建。有关选择 SPIRE 相关数据位置的更多信息，请参见[配置代理和服务器数据存储位置](https://spiffe.io/docs/latest/deploying/configuring/#configuring-where-to-store-agent-and-server-data)。

#### 将 MySQL 配置为数据存储

在生产环境中，建议使用专用数据库来备份和存储配置数据。尽管安装和配置 MySQL 数据库不在本指南的范围内，但值得注意的是 SPIRE 服务器需要：

- 用于 SPIRE 服务器配置的 MySQL 服务器上的专用数据库。
- 具有能力连接到运行 SPIRE 服务器的任何 EC2 实例，并能向该数据库中的表、列和行插入和删除的 MySQL 用户。

要配置 SPIRE 服务器使用 MySQL 数据库，请在配置文件中启用以下类似的部分：

```
    DataStore "sql" {
        plugin_data {
            database_type = "mysql"
            connection_string = "username:password@tcp(localhost:3306)/dbname?parseTime=true"
        }
    }
```

在上述连接字符串中，用以下内容替换：

- `username`：要用于访问数据库的 MySQL 用户的用户名
- `password`：MySQL 用户的密码
- `localhost:3306`：MySQL 服务器的 IP 地址或主机名和端口号
- `dbname`：数据库的名称

#### 将 Postgres 配置为数据存储

在生产环境中，建议使用专用数据库来备份和存储配置数据。尽管安装和配置 Postgres 数据库不在本指南的范围内，但值得注意的是 SPIRE 服务器需要：

- 用于 SPIRE 服务器配置的 Postgres 服务器上的专用数据库。
- 具有能力连接到运行 SPIRE 服务器的任何实例，并能向该数据库中的表、列和行插入和删除的 Postgres 用户。

要配置 SPIRE 服务器使用 Postgres 数据库，请在服务器配置文件中启用以下部分：

```
    DataStore "sql" {
        plugin_data {
            database_type = "postgres"
            connection_string = "dbname=[database_name] user=[username]
                                 password=[password] host=[hostname] port=[port]"
        }
    }
```

`connection_string` 的值采用键=值格式，但也可以使用连接 URI（参见 Postgres 文档中支持的连接字符串格式的 [34.1.1. 连接字符串](https://www.postgresql.org/docs/11/libpq-connect.html#LIBPQ-CONNSTRING)）。

以下是你设置的连接字符串值的摘要：

- [database-name]：数据库的名称
- [username]：访问数据库的 Postgres 用户的用户名
- [password]：用户的密码
- [hostname]：Postgres 服务器的 IP 地址或主机名
- [port]：Postgres 服务器的端口号

#### 配置代理和服务器上存储生成的密钥的方式

*此配置适用于 SPIRE 服务器和 SPIRE 代理*

SPIRE 代理和 SPIRE 服务器在正常运行过程中会生成私钥和证书。保持这些密钥和证书的完整性非常重要，以确保维护所发行的 SPIFFE 身份的完整性。

目前，SPIRE 在代理和服务器上支持两种密钥管理策略。

- 存储于内存中。在此策略中，密钥和证书仅存储在内存中。这意味着，如果服务器或代理崩溃或重新启动，则必须重新生成密钥。对于 SPIRE 代理来说，这通常需要代理在重新启动时重新对服务器进行验证。通过启用和配置内存密钥管理器插件来管理此策略，可用于 [SPIRE 服务器](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_keymanager_memory.md)和/或 [SPIRE 代理](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_keymanager_memory.md)。
- 存储在磁盘上。在此策略中，密钥和证书存储在指定的磁盘文件中。使用此方法的一个优点是它们在 SPIRE 服务器或代理重新启动后仍然存在。缺点是，由于密钥存储在磁盘文件中，必须采取其他预防措施，以防止恶意进程读取这些文件。通过启用和配置磁盘密钥管理器插件来管理此策略，可用于 [SPIRE 服务器](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_keymanager_disk.md)和/或 [SPIRE 代理](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_keymanager_disk.md)。

另外，SPIRE 可以配置为通过第三方密钥管理器插件集成自定义后端，例如秘密存储。[扩展 SPIRE](https://spiffe.io/docs/latest/spire/developing/extending/) 指南对此进行了更详细的介绍。

## 配置应用程序将使用的信任根/“上游授权机构”

*此配置适用于 SPIRE 服务器*

每个 SPIRE 服务器使用特定的根签名密钥，用于执行几个重要操作：

- 通过 SPIRE 代理对 SPIRE 服务器建立信任，因为代理持有由该密钥签名的证书（但请注意，服务器对代理的信任是通过验证建立的）。
- 生成发放给工作负载的 X.509 或 JWT SVID。
- 生成用于与其他 SPIRE 服务器建立信任的 SPIFFE 信任捆绑。

应将此签名密钥视为非常敏感的，因为获取它将允许恶意行为者冒充 SPIRE 服务器并代表其发放身份。

为了确保签名密钥的完整性，SPIRE 服务器可以自行对材料进行签名，使用存储在磁盘上的签名密钥，或委托签名给独立的证书颁发机构（CA），例如 AWS Secrets Manager。此行为通过 `server.conf` 文件中的 `UpstreamAuthority` 部分进行配置。

有关完整的服务器配置参考，请参阅 [SPIRE 服务器配置参考](https://spiffe.io/docs/latest/deploying/spire_server/)。

#### 配置磁盘上的签名密钥

SPIRE 服务器可以配置为从磁盘加载 CA 凭据，使用它们为服务器的签名机构生成中间签名证书。

SPIRE 服务器附带了一个“虚拟”密钥和证书，可用于简化测试，但由于该密钥分发给所有 SPIRE 用户，因此不应将其用于除测试目的之外的任何用途。相反，应生成一个在磁盘上的签名密钥。

如果已安装`openssl`工具，则可以使用类似以下命令生成有效的根密钥和证书：

```bash
sudo openssl req \\\\
       -subj "/C=/ST=/L=/O=/CN=acme.com" \\\\
       -newkey rsa:2048 -nodes -keyout /opt/spire/conf/root.key \\\\
       -x509 -days 365 -out /opt/spire/conf/root.crt
```

通过启用和配置磁盘 `UpstreamAuthority` 插件，可以管理此策略，用于 [SPIRE 服务器](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_upstreamauthority_disk.md)。

#### 配置 AWS 证书管理器

可以配置 SPIRE 服务器从亚马逊网络服务的证书管理器（[Private Certificate Authority](https://aws.amazon.com/certificate-manager/private-certificate-authority/)）加载 CA 凭据，并使用它们生成服务器签名授权的中间签名证书。

可以通过启用和配置 `aws_pca` UpstreamAuthority 插件来管理此策略，有关详细信息，请参阅 [SPIRE 服务器](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_upstreamauthority_aws_pca.md)。

#### 配置另一个 SPIRE 安装

可以配置 SPIRE 服务器从另一个 SPIFFE 实现（例如 SPIRE）的 Workload API 加载 CA 凭据。这使得可以使用一种称为“嵌套 SPIRE”的技术，作为 HA 部署的补充，允许独立的 SPIRE 服务器针对单个信任域发出标识。

关于嵌套 SPIRE 的完整处理超出了本指南的范围。但是，可以通过启用和配置 `spire` UpstreamAuthority 插件来管理此策略，有关详细信息，请参阅 [SPIRE 服务器](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_upstreamauthority_spire.md)。

## 导出用于监控的指标

*此配置适用于 SPIRE 服务器和 SPIRE Agent*

要将 SPIRE 服务器或 Agent 配置为将数据输出到指标收集器，请编辑 `server.conf` 或 `agent.conf` 中的遥测部分。SPIRE 可以将指标导出到 [Datadog](https://docs.datadoghq.com/developers/dogstatsd/) （DogStatsD 格式）、[M3](https://github.com/m3db/m3)、[Prometheus](https://prometheus.io/) 和 [StatsD](https://github.com/statsd/statsd)。

可以同时配置多个收集器。在要将指标发送到多个收集器的情况下，DogStatsD、M3 和 StatsD 支持多个声明。

如果要使用 Amazon CloudWatch 进行指标收集，请查阅 [此文档](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-custom-metrics-statsd.html) 以了解使用 CloudWatch 代理程序和 StatsD 检索自定义指标的方法。

以下是将遥测导出到 Datadog、M3、Prometheus 和 StatsD 并禁用内存收集器的 `agent.conf` 或 `server.conf` 的配置块示例：

```
telemetry {
        Prometheus {
                port = 9988
        }

        DogStatsd = [
            { address = "localhost:8125" },
        ]

        Statsd = [
            { address = "localhost:1337" },
            { address = "collector.example.org:8125" },
        ]

        M3 = [
            { address = "localhost:9000" env = "prod" },
        ]

        InMem {
            enabled = false
        }
}
```

有关更多信息，请参阅 [遥测配置](https://spiffe.io/docs/latest/deploying/telemetry_config/) 指南。

## 日志记录

*此配置适用于 SPIRE 服务器和 SPIRE Agent*

可以在各自的配置文件中设置 SPIRE 服务器和 SPIRE Agent 的日志文件位置和日志级别。编辑 `log_file` 值以设置日志文件位置，编辑 `log_level` 值以设置日志级别。此值可以是 DEBUG、INFO、WARN 或 ERROR 中的一个。

默认情况下，SPIRE 日志将输出到 STDOUT。但是，可以通过在 `log_file` 属性中指定文件路径，将 SPIRE Agent 和 Server 配置为直接将日志写入文件。
