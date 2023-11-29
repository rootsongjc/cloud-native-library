---
title: 先决条件和下载
weight: 1
---

本页面提供了开始使用 Tetrate Service Bridge（TSB）安装所需的先决条件和下载说明的全面概述。

要有效地管理 TSB 服务网格，需要对 Kubernetes 和 Docker 仓库操作有深入的了解。我们建议咨询它们各自的支持文档以获取额外的指导。

## 先决条件

你可以安装用于生产的 TSB，也可以安装用于演示配置文件以快速了解 TSB。请查看以下表格中的每个要求：

| 项目 | 生产 TSB | 演示/快速入门TSB             |
| ------------------------------------------------------------ | ------- | ---------------------------- |
| **Kubernetes 集群：**<br />EKS 1.21 - 1.24<br />GKE 1.21 - 1.24<br />AKS 1.21 - 1.24（包括 Azure Stack HCI）<br />OpenShift 4.7 - 4.11<br />Docker UCP 3.2.5 或更高版本 | ✓       | ✓                            |
| Docker UCP 3.2.5 或更高版本                                   | ✓       | ✓                            |
| 私有 Docker 注册表（HTTPS）                                    | ✓       | ✓                            |
| Tetrate 存储库帐户和 API 密钥（如果你尚未拥有此内容，请联系 Tetrate） | ✓       | ✓                            |
| Docker 引擎 18.03.01 或更高版本，具有对私有 Docker 注册表的推送访问权限 | ✓       | ✓                            |
| PostgreSQL 11.1 或更高版本                                    | ✓       | 打包（v14.4）                |
| Elasticsearch 6.x 或 7.x                                       | ✓       | 打包（v7.8.1）               |
| Redis 6.2 或更高版本                                          | ✓       | 打包（v7.0.5）               |
| LDAP 服务器或 OIDC 提供程序                                     | ✓       | 打包（OpenLDAP v2.6）        |
| Cert-manager：</br>cert-manager v1.7.2 或更高版本             | ✓       | 打包（cert-manager v1.10.0） |

{{<callout note "cert-manager 用法">}}

[cert-manager](https://cert-manager.io/) 用于为 TSB webhook、TSB 内部通信和 Istio 控制平面与外部 CA 集成等颁发和管理证书。

{{</callout>}}

{{<callout note "cert-manager 版本">}}

cert-manager 1.4.0 是使用 TSB 1.5 所需的最低版本。它具有特性标志，用于签署 K8S CSR 请求，支持 Kubernetes 1.16-1.21。前往[cert-manager 受支持的版本](https://cert-manager.io/docs/installation/supported-releases/)以获取有关受支持的 Kubernetes 和 OpenShift 版本的更多信息。

{{</callout>}}

{{<callout note "生产安装注意事项">}}

你的 Kubernetes 集群的大小取决于平台部署要求。基本的 TSB 安装不会消耗太多额外的资源。存储的大小非常取决于应用程序集群的大小、工作负载的数量（及其请求率）以及可观测性配置（采样率、数据保留期等）。有关更多信息，请参见我们的容量规划指南。 

{{</callout>}}

当运行自托管时，你的组织可能会对上述环境和应用程序施加额外的（安全）限制、可用性和灾难恢复要求。有关如何调整 TSB 安装和配置的详细信息，请参阅操作员参考指南以及我们的文档中的[操作任务](../../howto/)部分，在其中可以找到有关配置选项、常见部署方案和解决方案的描述。

### 身份标识提供者

TSB 需要标识提供程序（IdP）作为用户来源。此标识提供程序用于用户身份验证以及定期将现有用户和组的信息同步到平台中。TSB 可以与 LDAP 或任何符合 OIDC 的标识提供程序集成。

要使用 LDAP，你必须弄清楚如何查询 LDAP，以便 TSB 可以将其用于身份验证和用户和组的同步。有关 LDAP 配置的更多详细信息，请参见 [LDAP 作为标识提供程序](../../operations/users/configuring-ldap/)。

要使用 OIDC，请在你的 IdP 中创建 OIDC 客户端。启用授权代码流以使用 UI 登录，并启用设备授权以使用设备代码使用 tctl 登录。有关更多信息和示例，请参见如何设置 Azure AD 作为 TSB 标识提供程序。

{{<callout note "OIDC IdP 同步">}}

TSB 支持 Azure AD 用于同步用户和组。如果你使用其他 IdP，则必须创建同步作业，将从你的 IdP 获取用户和团队并使用同步 API 将它们同步到 TSB 中。有关更多详细信息，请参见用户同步。 

{{</callout>}}

### 数据和遥测存储

TSB 需要外部数据和遥测存储。TSB 使用 PostgreSQL 作为数据存储和 Elasticsearch 作为遥测存储。

{{<callout warnning "Demo 存储">}}

演示安装将部署 PostgreSQL、Elasticsearch 和 LDAP 服务器作为标识提供程序，其中填充了模拟用户和团队。演示存储不适用于生产使用。请确保为你的生产环境提供适当的 PostgreSQL、Elasticsearch 和标识提供程序。 

{{</callout>}}

### 证书提供者

TSB 1.5 需要证书提供者来支持内部 TSB 组件的证书颁发，例如 Webhook 证书和其他用途。此证书提供者必须在管理平面集群和所有控制平面集群中都可用。

TSB 支持`cert-manager`作为其中一个受支持的提供者。它可以为你管理`cert-manager`安装的生命周期。要在集群中配置`cert-manager`的安装，请将以下部分作为`ManagementPlane`或`ControlPlane` CR 的一部分添加：

```
   components:
     internalCertProvider:
       certManager:
         managed: INTERNAL
```

你还可以使用任何支持`kube-CSR` API 的证书提供者。要使用自定义提供者，请参阅以下部分 Internal Cert Provider

{{<callout note "现有的 cert-manager 安装">}}

如果你已经使用 cert-manager 作为集群的一部分，则可以将`ManagementPlane`或`ControlPlane` CR 中的`managed`字段设置为`EXTERNAL`，使 TSB 利用现有的 cert-manager 安装。如果将`managed`字段设置为`INTERNAL`，则 TSB 操作员会在找到已安装的 cert-manager 时失败，以确保它不覆盖现有的 cert-manager 安装。

{{</callout>}}

{{<callout note "cert-manager Kube-CSR">}}

TSB 使用 kubernetes CSR 资源为各种 Webhook 颁发证书。如果你的配置使用外部 cert-manager 安装，请确保 cert-manager 可以签署 Kubernetes CSR 请求。例如，在 cert-manager 1.7.2 中，通过设置此特性标志 `ExperimentalCertificateSigningRequestControllers=true`启用此功能。对于使用内部托管的 cert-manager 的 TSB 管理安装，此配置已作为安装的一部分设置。 

{{</callout>}}

## 下载 tctl

设置 TSB 的初始步骤是安装我们的 TSB CLI 工具，称为`tctl`。使用`tctl`，你可以执行 TSB 安装（或升级），使用 YAML 对象与 TSB API 进行交互，并将 TSB 无缝集成到 GitOps 工作流程中。

请按照 CLI 参考页面中概述的说明下载和安装`tctl`。

## 同步 Tetrate Service Bridge 镜像

安装了`tctl`之后，你可以检索必要的容器镜像并将它们上传到你的私有 Docker 注册表。`tctl`工具通过`image-sync`命令简化了此过程，该命令下载与当前`tctl`版本对应的 镜像版本，并将其推送到你的 Docker 注册表。使用你的 Tetrate 存储库帐户凭据和指定你的私有 Docker 注册表的`registry`参数使用`username`和`apikey`参数。

```bash
tctl install image-sync --username <user-name> \    --apikey <api-key> --registry <registry-location>
```

在初始执行期间，你需要接受最终用户许可协议（EULA）。如果你在没有交互式终端访问权限的环境中运行 TSB 安装，例如 CI / CD 流程，请将`--accept-eula`标志附加到上述命令中。

### 在 Kind 集群中加载演示镜像

对于本地[kind](https://kind.sigs.k8s.io/)集群中的`demo`配置文件安装，请使用以下命令直接将镜像加载到 kind 节点中：

```bash
#使用我们的“用户名”和“apikey”登录到Docker注册表
docker login containers.dl.tetrate.io

#拉取所有docker镜像
for i in `tctl install image-sync --just-print --raw` ; do docker pull $i ; done

#将镜像加载到kind节点中
for i in `tctl install image-sync --just-print --raw` ; do kind load docker-image $i ; done
```

## 安装

{{<callout note "集群配置文件">}}

在操作多集群 TSB 环境时，与多个 Kubernetes 集群的交互变得普遍。虽然文档没有明确引用`kubectl`配置上下文和`tctl` config 配置文件，但这些选择是特定于环境的。确保选择了正确的`kubectl`上下文和`tctl`配置文件作为默认值，或在使用这些工具执行命令时使用显式参数。

{{</callout>}}

要使用 Helm Chart 继续进行安装，请参阅 Helm 安装指南。

要使用`tctl`进行安装，请继续查看 tctl 安装指南。

有关演示安装过程的详细说明，请转到演示安装指南。
