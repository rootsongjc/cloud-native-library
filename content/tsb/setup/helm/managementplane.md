---
title: 管理平面安装
description: 如何使用 Helm 安装管理平面元素。
weight: 2
---

此 Chart 安装 TSB 管理平面 Operator，还允许你使用 [TSB `ManagementPlane` CR](../../../refs/install/managementplane/v1alpha1/spec) 安装 TSB 管理平面组件以及使其完全运行所需的所有秘密。

在开始之前，请确保你已经查看了 [Helm 安装过程](../helm#installation-process)。

## 安装概述

1. 创建一个 `values.yaml` 文件并使用所需的配置进行编辑。你可以在下面的 [配置](#configuration) 部分中找到有关可用 Helm 配置的更多详细信息。有关 `spec` 部分的完整参考，请参阅 [TSB `ManagementPlane` CR](../../../refs/install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-managementplanespec)。

2. 使用 `helm install` 命令安装 TSB 管理平面。确保将 `image.registry` 和 `version` 设置为正确的注册表位置和 TSB 版本。

3. 等待所有 TSB 管理平面组件成功部署。你可以尝试登录 TSB UI 或使用 [tctl](../../tctl-connect) 来验证你的安装。

## 安装

要安装 TSB 管理平面，请创建一个 `values.yaml` 文件，包含以下内容，并根据你的需求进行编辑。

```yaml
spec:
  # 设置组织名称。组织名称必须小写以符合 RFC 标准。
  organization: <organization-name>

  dataStore:
    postgres:
      host: <postgres-hostname-or-ip>
      port: <postgres-port>
      name: <database-name>
  telemetryStore:
    elastic:
      host: <elastic-hostname-or-ip>
      port: <elastic-port>
      version: <elastic-version>
      selfSigned: <is-elastic-use-self-signed-certificate>

  # TSB 支持 OIDC 和 LDAP 作为身份提供者。
  # 根据你的环境进行设置。
  identityProvider:
    ...

  # 启用自动证书管理。
  # 如果要使用其他方法管理证书，可以删除此字段。
  # 请注意，在这种情况下，你将需要提供证书作为机密。
  certIssuer:
    selfSigned: {}
    tsbCerts: {}
    clusterIntermediateCAs: {}

  # TSB 管理平面的默认端口是 8443。你可以在此处更改它。
  components:
    frontEnvoy:
      port: 443
    # 启用 oap 流式日志功能
    oap:
      streamingLogEnabled: true

secrets:
  tsb:
    adminPassword: <tsb-admin-password>

  postgres:
    username: <postgres-username>
    password: <postgres-password>

  # 根据你的 IdP，你需要在此处设置所需的秘密。
  ...
```

然后，使用以下 `helm install` 命令安装 TSB 管理平面。此安装可能需要最多 10 分钟才能完成。确保用正确的值替换 `<tsb-version>` 和 `<registry-location>`。

```shell
helm install mp tetrate-tsb-helm/managementplane \
  --version <tsb-version> \
  --namespace tsb  --create-namespace \
  --values values.yaml \
  --timeout 10m \
  --set image.registry=<registry-location>
```

### 非生产外部依赖

如果在 `values.yaml` 文件中省略了 `dataStore`、`telemetryStore` 和 `identityProvider` 字段，TSB 将安装非生产 Postgres、Elasticsearch 和 LDAP。请注意，你仍然需要设置正确的秘密和凭据以使用存储。

{{<callout warning 注意>}}
请勿在生产环境中使用非生产存储和身份提供者。
{{</callout>}}

以下是演示安装的 `values.yaml` 文件的示例完成内容：

```yaml
spec:
  organization: <organization-name>

  # 启用自动证书管理。
  certIssuer:
    selfSigned: {}
    tsbCerts: {}
    clusterIntermediateCAs: {}

secrets:
  tsb:
    adminPassword: <tsb-admin-password>

  postgres:
    username: tsb
    password: tsb-postgres-password

  ldap:
    binddn: cn=admin,dc=tetrate,dc=io
    bindpassword: admin
```

## 访问 TSB 管理平面

完成安装后，你可以通过登录到 TSB UI 或使用 [tctl](../../tctl-connect) 来访问 TSB 管理平面。

## 故障排除

如果在安装过程中遇到任何问题，请检查以下几点：

- 确保你在 `values.yaml` 文件中输入了正确的值。
- 验证你在 `helm install` 命令中使用的注册表位置和 TSB 版本是否正确。
- 如果你使用自定义身份提供者，请确保你在 `values.yaml` 文件的 secrets 部分设置了所有所需的 `secrets`。
- 如果无法连接到 TSB，请确保所有 TSB 组件都已成功部署，日志中没有错误。
- 如果你使用私有注册表来托管 TSB 控制平面 Operator 镜像，请确保已对注册表进行身份验证，并且 `image.registry` 值正确。

## 配置

### 镜像配置

这是一个 **必填** 字段。将 `image.registry` 设置为你的私有注册表位置，你已经同步了 TSB 镜像，将 `image.tag` 设置为要部署的 TSB 版本。仅指定此字段将安装 TSB 控制平面 Operator，而不安装其他 TSB 组件。

| 名称             | 描述                             | 默认值                     |
| ---------------- | -------------------------------- | -------------------------- |
| `image.registry` | 用于下载 Operator 镜像的注册表。必填 | `containers.dl.tetrate.io` |
| `image.tag`      | Operator 镜像的标签。必填             | *与 Chart 版本相同*                  |

### 管理平面资源配置

这是一个 **可选** 字段。你可以在 Helm 值文件中设置 [TSB `ManagementPlane` CR `spec`](../../../refs/install/managementplane/v1alpha1/spec##tetrateio-api-install-managementplane-v1alpha1-managementplanespec)，以使 TSB 管理平面完全运行。

| 名称   | 描述                                           | 默认值 |
| ------ | ---------------------------------------------- | ------ |
| `spec` | 包含 `ManagementPlane` CR 的 `spec` 部分。可选 |        |

### 秘密配置

这是一个 **可选** 字段。你可以在安装 TSB 管理平面之前将秘密应用到你的集群中，或者你可以使用 Helm 值来指定所需的秘密。请注意，如果要将秘密与管理平面规范分开，则可以使用不同的 Helm 值文件。

{{<callout note 注意>}}
请记住，这些选项只是帮助创建秘密的选项，它们必须遵守 TSB `ManagementPlane` CR 中提供的配置，否则安装将配置不正确。
{{</callout>}}

| 名称                              | 描述                                                         | 默认值  |
| --------------------------------- | ------------------------------------------------------------ | ------- |
| `secrets.keep`                    | 启用此选项将使生成的秘密在卸载 Chart 后持续存在于集群中，如果它们在将来的更新中未提供，则不会删除它们。 (参见 [Helm 文档](https://helm.sh/docs/howto/charts_tips_and_tricks/#tell-helm-not-to-uninstall-a-resource)) | `false` |
| `secrets.tsb.adminPassword`       | 为 `admin` 用户配置的密码。                                  |         |
| `secrets.tsb.cert`                | 管理平面 (front envoy) 暴露的 TLS 证书。                     |         |
| `secrets.tsb.key`                 | 管理平面 (front envoy) 暴露的 TLS 证书的密钥。               |         |
| `secrets.postgres.username`       | 访问 Postgres 数据库的用户名。                               |         |
| `secrets.postgres.password`       | 访问 Postgres 数据库的密码。                                 |         |
| `secrets.postgres.cacert`         | 用于验证 Postgres 数据库提供的 TLS 证书的 CA 证书。          |         |
| `secrets.postgres.clientcert`     | 访问 Postgres 数据库所需的客户端证书。                       |         |
| `secrets.postgres.clientkey`      | 访问 Postgres 数据库所需的客户端证书的密钥。                 |         |
| `secrets.elasticsearch.username`  | 访问 Elasticsearch 所需的用户名。                            |         |
| `secrets.elasticsearch.password`  | 访问 Elasticsearch 所需的密码。                              |         |
| `secrets.elasticsearch.cacert`    | 用于验证 Elasticsearch 提供的 TLS 证书的 CA 证书。           |         |
| `secrets.ldap.binddn`             | 用于从 LDAP IDP 中读取的绑定 DN。                            |         |
| `secrets.ldap.bindpassword`       | 用于从 LDAP IDP 中读取的绑定 DN 的提供密码。                 |         |
| `secrets.ldap.cacert`             | 用于验证 LDAP IDP 提供的 TLS 证书的 CA 证书。                |         |
| `secrets.oidc.clientSecret`       | 用于连接到配置的 OIDC 的客户端密钥。                         |         |
| `secrets.oidc.deviceClientSecret` | 用于连接到配置的 OIDC 的设备客户端密钥。                     |         |
| `secrets.azure.clientSecret`      | 用于连接到 Azure OIDC 的客户端密钥。                         |         |

#### XCP 秘密配置

XCP 使用 TLS 和 JWT 在 Edge 和 Central 之间进行身份验证。

如果 `secrets.xcp.autoGenerateCerts` 已 **禁用**，则用户必须提供 XCP Central 的证书和密钥，使用 `secrets.xcp.central.cert` 和 `secrets.xcp.central.key`。

此外，用户可以选择提供 CA，使用 `secrets.xcp.rootca` 允许 MPC 组件使用它来验证 XCP Central 提供的证书。

如果 `secrets.xcp.autoGenerateCerts` 已 **启用**，则需要 Cert Manager 来提供 XCP Central 证书。

然后，`secrets.xcp.rootca` 和 `secrets.xcp.rootcakey` 将用于创建正确的 Issuer 并生成 XCP Central 的证书，并与 MPC 共享 CA，以允许其验证 XCP Central 生成的证书。

以下属性允许用于配置 XCP 身份验证模式：

| 名称                            | 描述                                                         | 默认值  |
| ------------------------------- | ------------------------------------------------------------ | ------- |
| `secrets.xcp.autoGenerateCerts` | 启用此选项将自动生成 XCP Central 的 TLS 证书。需要 cert-manager | `false` |
| `secrets.xcp.rootca`            | XCP 组件的 CA 证书。                                         |         |