---
title: Azure AD 作为身份提供者
description: 如何配置 Azure AD 作为 TSB 的身份提供者。
weight: 3
---

本文描述了创建 Azure 中的应用程序以允许 TSB 使用云帐户进行 OIDC 以及从 Azure AD 同步用户和组的步骤。

## 创建应用程序

登录到 Azure 门户，然后转到*Active Directory > 应用程序注册 > 新应用程序注册*。

![](../../../assets/operations/oidc-azure-1.png)

将应用程序类型设置为 Web，并将重定向 URI 配置为指向 TSB 地址以及**`/iam/v2/oidc/callback`**端点。

![](../../../assets/operations/oidc-azure-2.png)

## 配置应用程序秘密

一旦应用程序创建完毕，转到*证书和密码*以创建一个用于在 TSB 中使用的客户端秘密：

![](../../../assets/operations/oidc-azure-3.png)

配置名称和到期时间，然后单击添加。

![](../../../assets/operations/oidc-azure-4.png)

一旦添加完成，你将能够看到秘密的**Value**。复制它，因为稍后将使用它，并且将不再显示。

![](../../../assets/operations/oidc-azure-5.png)

## 配置 OIDC 令牌

一旦创建了秘密，转到*身份验证*菜单项，然后单击*添加平台*以配置 OIDC 令牌。

![](../../../assets/operations/oidc-azure-6.png)

选择*Web*

![](../../../assets/operations/oidc-azure-7.png)

在接下来的屏幕中，将重定向 URI 配置为指向 TSB 地址以及**`/iam/v2/oidc/callback`**端点，选择两个令牌（访问令牌和 ID 令牌），可以选择启用 tctl 设备代码流的移动和桌面流程：

![](../../../assets/operations/oidc-azure-8.png)

## 配置应用程序权限

一旦为 OIDC 配置了应用程序，就需要授予应用程序权限，以允许 TSB 从 Azure AD 同步有关用户和组的信息。为此，请转到*API 权限*，然后单击*添加权限*：

![](../../../assets/operations/oidc-azure-9.png)

在接下来的屏幕上，向下滚动到底部，从*常用的 Microsoft API*中选择*Microsoft Graph*：

![](../../../assets/operations/oidc-azure-10.png)

在接下来的屏幕上，将权限类型设置为*应用程序权限*，从权限列表中选择**_Directory.Read.All 权限_**，然后单击*添加权限*按钮。

![](../../../assets/operations/oidc-azure-11.png)

一旦添加了权限，请单击**授予管理员同意**按钮以授予应用程序请求的权限。

![](../../../assets/operations/oidc-azure-12.png)

一旦授予了权限，状态应该反映出来：

![](../../../assets/operations/oidc-azure-13.png)

## 启用公共工作流

你需要启用公共工作流以允许`tctl`命令登录。
登录到 Azure 门户，然后转到前面步骤中创建的平台的“身份验证”部分。

在“高级设置”部分，启用选项“是”，然后单击保存。

![](../../../assets/operations/oidc-azure-18.png)

## 配置 TSB

此时，你已完成 Azure 端的配置。现在，你需要创建 Kubernetes 秘密以存储应用程序的客户端秘密，并配置 ManagementPlane。

需要从 Azure 应用程序获取以下数据：
* 客户端 ID
* 客户端秘密
* 租户 ID
* 配置 URL

*客户端 ID*和*租户 ID*可以在 Azure 应用程序的*概述*中获取。

![](../../../assets/operations/oidc-azure-14.png)

*客户端秘密*是你在前面步骤中配置应用程序秘密时复制的“密码”。

*配置 URI*可以从应用程序端点中复制：

![](../../../assets/operations/oidc-azure-15.png)

## 创建 Kubernetes 秘密

使用以下命令创建名为`secret.yaml`的文件中的秘密。适当替换`TSB_Admin_Pass`和`Client_Secret`。

```bash
tctl install manifest management-plane-secrets --allow-defaults --tsb-admin-password <TSB_Admin_Pass>   \
    --oidc-client-secret=<Client_Secret> \
    --teamsync-azure-client-secret=<Client_Secret> > secret.yaml
```

在生成的`secret.yaml`文件中，我们只关心`iam-oidc-client-secret`和`azure-credentials`的值。

编辑`secret.yaml`文件，删除所有其他秘密，然后使用`kubectl`应用 YAML 文件。重要的是要删除所有其他秘密，因为你不希望为此过程覆盖它们。

```bash
kubectl apply -f secret.yaml
```

## 配置 ManagementPlane CR

一旦创建了秘密，使用以下命令来配置`ManagementPlane` CR 的 identityProvider 部分，以开始编辑 CR：

```bash
kubectl edit managementplane managementplane -n tsb
```

以与下面的示例类似的方式编辑 CR 的内容（仅显示示例中的相关部分）。你需要在`ManagementPlane` CR 清单中的适当位置插入`identityProvider`子句。

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ManagementPlane
metadata:
  name: managementplane
  namespace: tsb
spec:
  ( … )
  identityProvider:
    oidc:
      clientId: <应用程序客户端 ID>
      providerConfig:
        dynamic:
          configurationUri: <应用程序配置 URI>
      redirectUri: https://<tsb地址>:8443/iam/v2/oidc/callback
      scopes:
      - email
      - profile
      - offline_access
    sync:
      azure:
        clientId: <应用程序客户端 ID>
        tenantId: <应用程序租户 ID>
```

:::note Helm 安装
本文档提供的所有有关更新`ManagementPlane` CR 的示例也适用于 Helm 安装。你可以编辑管理平面 Helm 值文件中的`identityProvider.oidc`。
:::

## 最终用户 TCTL 配置

使用 Azure OIDC 有两种配置 tctl 的方法

1. 使用服务主体的基于用户的设备代码身份验证。
2. 无服务主体的基于用户的设备代码身份验证。

### 使用服务主体的基于用户的设备代码身份验证

使用以下命令`kubectl edit managementplane managementplane -n tsb`配置`ManagementPlane` CR 的 identityProvider 部分，并将离线部分更新如下：

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ManagementPlane
metadata:
  name: managementplane
  namespace: tsb
spec:
  ...
  identityProvider:
    oidc:
      ...
      offlineAccessConfig:
        deviceCodeAuth:
          clientId: <应用程序客户端 ID>
```

使用当前配置文件登录：

```bash
tctl login --use-device-code
```

### 无服务主体的基于用户的设备代码身份验证

一旦 OIDC 集成到集群中，最终用户就可以通过使用带有`--use-device-code`参数的登录命令配置 tctl 以与 OIDC 一起使用。该命令将要求组织和租户，并提供一个可以用于验证提供的 URL 上的代码。一旦验证了该代码，tctl 将准备好使用。

```bash
tctl login --use-device-code

组织：tetrate
租户：mp
代码：CXKF-TDKP
打开浏览器页面 https://aka.ms/devicelogin 并输入代码
```

或者，tctl 配置可以从 UI 中下载。要这样做，请登录到 TSB，单击右上角的用户信息图标。然后单击“显示令牌信息”，按照 UI 显示的步骤下载并使用文件。

![](../../../assets/operations/oidc-azure-16.png)

![](../../../assets/operations/oidc-azure-17.png)
