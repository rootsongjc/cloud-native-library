---
title: 先决条件和下载
weight: 1
---

本页面提供了开始使用Tetrate Service Bridge（TSB）安装所需的先决条件和下载说明的全面概述。

要有效地管理TSB服务网格，需要对Kubernetes和Docker仓库操作有深入的了解。我们建议咨询它们各自的支持文档以获取额外的指导。

## 先决条件

你可以安装用于生产的TSB，也可以安装用于演示配置文件以快速了解TSB。请查看以下表格中的每个要求：

|                                                              | 生产TSB | 演示/快速入门TSB             |
| ------------------------------------------------------------ | ------- | ---------------------------- |
| **Kubernetes 集群：**<br />EKS 1.21 - 1.24<br />GKE 1.21 - 1.24<br />AKS 1.21 - 1.24（包括 Azure Stack HCI）<br />OpenShift 4.7 - 4.11<br />Docker UCP 3.2.5 或更高版本 | ✓       | ✓                            |
| Docker UCP 3.2.5或更高版本                                   | ✓       | ✓                            |
| 私有Docker注册表（HTTPS）                                    | ✓       | ✓                            |
| Tetrate存储库帐户和API密钥（如果你尚未拥有此内容，请联系Tetrate） | ✓       | ✓                            |
| Docker引擎18.03.01或更高版本，具有对私有Docker注册表的推送访问权限 | ✓       | ✓                            |
| PostgreSQL 11.1或更高版本                                    | ✓       | 打包（v14.4）                |
| Elasticsearch 6.x或7.x                                       | ✓       | 打包（v7.8.1）               |
| Redis 6.2或更高版本                                          | ✓       | 打包（v7.0.5）               |
| LDAP服务器或OIDC提供程序                                     | ✓       | 打包（OpenLDAP v2.6）        |
| Cert-manager：</br>cert-manager v1.7.2或更高版本             | ✓       | 打包（cert-manager v1.10.0） |

{{<callout note "cert-manager用法">}}

[cert-manager](https://cert-manager.io/) 用于为TSB webhook、TSB内部通信和Istio控制平面与外部CA集成等颁发和管理证书。

{{</callout>}}

{{<callout note "cert-manager 版本">}}

cert-manager 1.4.0是使用TSB 1.5所需的最低版本。它具有特性标志，用于签署K8S CSR请求，支持Kubernetes 1.16-1.21。前往[cert-manager受支持的版本](https://cert-manager.io/docs/installation/supported-releases/)以获取有关受支持的Kubernetes和OpenShift版本的更多信息。

{{</callout>}}

{{<callout note "生产安装注意事项">}}

你的Kubernetes集群的大小取决于平台部署要求。基本的TSB安装不会消耗太多额外的资源。存储的大小非常取决于应用程序集群的大小、工作负载的数量（及其请求率）以及可观察性配置（采样率、数据保留期等）。有关更多信息，请参见我们的容量规划指南。 

{{</callout>}}

当运行自托管时，你的组织可能会对上述环境和应用程序施加额外的（安全）限制、可用性和灾难恢复要求。有关如何调整TSB安装和配置的详细信息，请参阅操作员参考指南以及我们的文档中的how to部分，在其中可以找到有关配置选项、常见部署方案和解决方案的描述。

### 身份标识提供者

TSB需要标识提供程序（IdP）作为用户来源。此标识提供程序用于用户身份验证以及定期将现有用户和组的信息同步到平台中。TSB可以与LDAP或任何符合OIDC的标识提供程序集成。

要使用LDAP，你必须弄清楚如何查询LDAP，以便TSB可以将其用于身份验证和用户和组的同步。有关LDAP配置的更多详细信息，请参见LDAP作为标识提供程序。

要使用OIDC，请在你的IdP中创建OIDC客户端。启用授权代码流以使用UI登录，并启用设备授权以使用设备代码使用tctl登录。有关更多信息和示例，请参见如何设置Azure AD作为TSB标识提供程序。

{{<callout note "OIDC IdP同步">}}

TSB支持Azure AD用于同步用户和组。如果你使用其他IdP，则必须创建同步作业， 将从你的IdP获取用户和团队并使用同步API将它们同步到TSB中。有关更多详细信息，请参见用户同步。 

{{</callout>}}

### 数据和遥测存储

TSB需要外部数据和遥测存储。TSB使用PostgreSQL作为数据存储和Elasticsearch作为遥测存储。

{{<callout warnning "Demo存储">}}

演示安装将部署PostgreSQL、Elasticsearch和LDAP服务器作为标识提供程序，其中填充了模拟用户和团队。演示存储不适用于生产使用。请确保为你的生产环境提供适当的PostgreSQL、Elasticsearch和标识提供程序。 

{{</callout>}}

### 证书提供者

TSB 1.5需要证书提供者来支持内部TSB组件的证书颁发，例如Webhook证书和其他用途。此证书提供者必须在管理平面集群和所有控制平面集群中都可用。

TSB支持`cert-manager`作为其中一个受支持的提供者。它可以为你管理`cert-manager`安装的生命周期。要在集群中配置`cert-manager`的安装，请将以下部分作为`ManagementPlane`或`ControlPlane` CR的一部分添加：

```
   components:
     internalCertProvider:
       certManager:
         managed: INTERNAL
```

你还可以使用任何支持`kube-CSR` API的证书提供者。要使用自定义提供者，请参阅以下部分Internal Cert Provider

{{<callout note "现有的cert-manager安装">}}

如果你已经使用cert-manager作为集群的一部分，则可以将`ManagementPlane`或`ControlPlane` CR中的`managed`字段设置为`EXTERNAL`，使TSB利用现有的cert-manager安装。如果将`managed`字段设置为`INTERNAL`，则TSB操作员会在找到已安装的cert-manager时失败，以确保它不覆盖现有的cert-manager安装。

{{</callout>}}

{{<callout note "cert-manager Kube-CSR">}}

TSB使用kubernetes CSR资源为各种Webhook颁发证书。如果你的配置使用外部cert-manager安装，请确保cert-manager可以签署Kubernetes CSR请求。例如，在cert-manager 1.7.2中，通过设置此特性标志 `ExperimentalCertificateSigningRequestControllers=true`启用此功能。对于使用内部托管的cert-manager的TSB管理安装，此配置已作为安装的一部分设置。 

{{</callout>}}

## 下载tctl

设置TSB的初始步骤是安装我们的TSB CLI工具，称为`tctl`。使用`tctl`，你可以执行TSB安装（或升级），使用YAML对象与TSB API进行交互，并将TSB无缝集成到GitOps工作流程中。

请按照CLI参考页面中概述的说明下载和安装`tctl`。

## 同步Tetrate Service Bridge镜像

安装了`tctl`之后，你可以检索必要的容器镜像并将它们上传到你的私有Docker注册表。`tctl`工具通过`image-sync`命令简化了此过程，该命令下载与当前`tctl`版本对应的图像版本，并将其推送到你的Docker注册表。使用你的Tetrate存储库帐户凭据和指定你的私有Docker注册表的`registry`参数使用`username`和`apikey`参数。

```bash
tctl install image-sync --username <user-name> \    --apikey <api-key> --registry <registry-location>
```

在初始执行期间，你需要接受最终用户许可协议（EULA）。如果你在没有交互式终端访问权限的环境中运行TSB安装，例如CI / CD流程，请将`--accept-eula`标志附加到上述命令中。

### 在Kind集群中加载演示镜像

对于本地[kind](https://kind.sigs.k8s.io/)集群中的`demo`配置文件安装，请使用以下命令直接将镜像加载到kind节点中：

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

在操作多集群TSB环境时，与多个Kubernetes集群的交互变得普遍。虽然文档没有明确引用`kubectl`配置上下文和`tctl` config配置文件，但这些选择是特定于环境的。确保选择了正确的`kubectl`上下文和`tctl`配置文件作为默认值，或在使用这些工具执行命令时使用显式参数。

{{</callout>}}

要使用Helm Chart继续进行安装，请参阅Helm安装指南。

要使用`tctl`进行安装，请继续查看tctl安装指南。

有关演示安装过程的详细说明，请转到演示安装指南。
