---
title: 使用 tctl 连接到 TSB
description: 配置 `tctl` 以连接到 TSB。
weight: 7
---

在这个页面中，你将学习如何使用 `tctl` CLI 连接到 TSB 以及使用 CLI 的一些基础知识。

在开始之前：
- [安装 TSB 管理平面](../../setup/self-managed/management-plane-installation) (仅自管理)
- [下载](../../setup/requirements-and-download#download) Tetrate Service Bridge CLI (`tctl`)
- 获取你的 TSB 的 `organization` 名称 - 你可以在 TSB UI 中找到，或在 TSB `ManagementPlane` CR 的安装时配置

TSB 提供了一个用户界面，但本站点中的大多数示例 - 以及大多数脚本和自动化 - 将使用 `tctl` CLI。本文档将涵盖如何登录，以便你可以使用 CLI，并提供更新凭据的步骤。

## 概述

有三种配置 `tctl` 的方法：使用 `tctl login`、从 UI 下载凭据包，或手动配置它。本文档的其余部分详细描述了每种方法。

1. 首选的方法是使用 `tctl login` 连接到 TSB，使用 `default` 配置文件：

```bash
tctl config clusters set default --bridge-address $TSB_ADDRESS
tctl login
Organization: tetrate
Tenant:
Username: admin
Password: *****
Login Successful!
# 现在可以开始使用:
tctl get tenants
NAME          DISPLAY NAME    DESCRIPTION
tetrate       Tetrate         Default tenant
```

2. 使用 `tctl` 连接的第二种简单方法是从 TSB UI 下载 bundle 并使用 `tctl config import` 导入：

```bash
tctl config profiles import ~/Downloads/tctl-<your username>.config.yaml
tctl config profiles set-current <your username>-tsb
# 现在可以开始使用:
tctl get tenants
NAME          DISPLAY NAME    DESCRIPTION
tetrate       Tetrate         Default tenant
```

3. 最后，你可以创建自己的 `user`、`cluster` 和 `profile`（对于 LDAP 与 OIDC 使用稍有不同的标志）来登录：

```bash
tctl config clusters set tsb-how-to-cluster --bridge-address $TSB_ADDRESS
# 对于 OIDC
tctl config users set tsb-how-to-user --org $TCTL_LOGIN_ORG --token $TSB_BEARER_TOKEN --refresh-token $TSB_REFRESH_TOKEN
# 或者对于 LDAP
# tctl config users set tsb-how-to-user --org $TCTL_LOGIN_ORG --username $TCTL_LOGIN_USERNAME --password $TCTL_LOGIN_PASSWORD
tctl config profiles set tsb-how-to --cluster tsb-how-to-cluster --username tsb-how-to-user
tctl config profiles set-current tsb-how-to
# 现在可以开始使用:
tctl get tenants
NAME          DISPLAY NAME    DESCRIPTION
tetrate       Tetrate         Default tenant
```

如果你使用用户名和密码登录，应该执行 `tctl login` 来交换密码以获取 OIDC 令牌。之后，你可以随时使用 `tctl`。例如，要在 TSB 中查找 `tenants`，只需执行 `tctl get tenants`。

## 使用 `tctl login` 登录

连接到 TSB 的最简单方法是使用 `tctl login` 命令，该命令将处理为你交换凭据以获取 OIDC 令牌，并确保不将明文密码持久保存到磁盘上。

要实现这一点，首先我们需要配置 `tctl` 使用 TSB 实例的地址。使用 `default` 配置文件最容易 - 如果你不想使用 `default` 配置文件，请跳到 [手动配置 `tctl`](#手动配置-tctl) 部分。

### 获取 TSB 的地址

如果你的 kubeconfig 指向管理平面集群，你可以从 Kubernetes 服务中获取地址：

```bash
export TSB_ADDRESS=$(kubectl get svc -n tsb envoy --output jsonpath='{.status.loadBalancer.ingress[0].ip}'):8443
```

许多组织将通过 DNS 公开 TSB 的 UI（因此也是 API）；你应该使用它而不是原始 IP 地址。

### 配置 `default` 配置文件

有了 TSB 的地址，我们将配置 `tctl` 连接到它：

```bash
tctl config clusters set default --bridge-address $TSB_ADDRESS
```

### 使用 OIDC 登录

要使用 OIDC 凭证登录 TSB，可以使用 OIDC 设备代码流，该流已集成到 `tctl` 中：

```bash
tctl login --use-device-code
```

```bash
Organization: tetrate
Tenant:
Code: GGBD-NJPR
Open browser page https://www.google.com/device and enter the code

Login Successful!
```

{{<callout note 在浏览器中进行 OIDC>}}
这将为你打开浏览器，以完成 OIDC 登录流程并生成令牌。
{{</callout>}}

### 使用用户名和密码登录

登录时提供用户名和密码：

```bash
tctl login
```

```bash
Organization: tetrate
Tenant:
Username: admin
Password: *****
Login Successful!
```

## 从 TSB 下载 `tctl` 配置

`tctl` 使用一个配置文件与 TSB 实例连接，类似于使用 kubeconfig 连接到 Kubernetes API 服务器。通过从 TSB UI 下载该配置文件，你可以使用 `tctl` 轻松连接。要访问这些凭据，请在浏览器中登录到 TSB UI，然后在右上角单击你的用户名，选择 `操作` > `显示令牌信息` > `下载 tctl 配置`。这将下载一个名为 `tctl-<your username>.config.yaml` 的文件。然后，你可以将其导入到 `tctl` 中，以永久保存：

```bash
tctl config profiles import /path/to/tctl-<your username>.config.yaml
tctl config profiles set-current <your username>-tsb
```

{{<callout note 提示>}}
`tctl` 将配置存储在你文件系统默认的配置目录中（由 Golang 确定）。在 Linux 上，这将是 `$HOME/.config/tetrate/tctl/tctl_config`，在 Darwin 上是 `$HOME/Library/Application\ Support/tetrate/tctl/tctl_config`，在 Windows 上是 `%AppData%/tetrate/tctl/tctl_config`。这是保存密码或令牌的位置。当导入配置文件时，`tctl` 将将该文件中的凭据添加到其配置目录中的现有凭据中。
{{</callout>}}

## 手动配置 `tctl`

{{<callout note "TSB 组织名称">}}
在下面的示例中，假定你已将组织名称保存在环境变量 `$TCTL_LOGIN_ORG` 中。如果你刚刚完成演示安装，演示组织名称是 `tetrate`。你可以执行以下操作将该值保存在环境变量中：`export TCTL_LOGIN_ORG=tetrate`。
{{</callout>}}

要使用 `tctl` 登录，首先必须配置 *cluster* (`tctl config clusters`)，然后是 *user* (`tctl config users`)，然后将两者结合到 *profile* 中，你将能够使用它来连接到 TSB 实例，就像使用 kubeconfig profile 一样 (`tctl config profiles set-current ...`)。有了这个 *profile*，你就可以使用 `tctl login` 命令配置凭据，并将这些凭据持久保存到磁盘上，以便将来连接到 TSB。

### 为你的 profile 选择一个名称

`tctl` 有一个 *default* profile，就像 `kubectl` 一样，你可以在下面的命令中使用它，或者你可以选择自己的 profile 名称。在此演示中，创建一个名为 *`tsb-how-to`* 的 profile（但任何名称都可以，包括 *default*）。

### 配置 `tctl` Cluster

UI 和 TSB 的 API 都在相同的地址和端口上暴露。为了配置 `tctl`，你将需要该地址以开始。

#### 获取 TSB 的地址

如果你的 kubeconfig 指向管理平面集群，你可以从 Kubernetes 服务中获取地址：

```bash
export TSB_ADDRESS=$(kubectl get svc -n tsb envoy --output jsonpath='{.status.loadBalancer.ingress[0].ip}'):8443
```

许多组织将通过 DNS 公开 TSB 的 UI（因此也是 API）；你应该使用它而不是原始 IP 地址。

#### 创建 `tctl` Cluster

一旦获得了地址（`$TSB_ADDRESS`），你可以在 `tctl` 的配置中创建一个 *cluster*。将集群命名为 `tsb-how-to-cluster`：

```bash
tctl config clusters set tsb-how-to-cluster --bridge-address $TSB_ADDRESS
```

{{<callout note "tctl  对象名称">}}
你可以使用与 profile 相同的名称作为 cluster 的名称（例如 `tctl config clusters set tsb-how-to --bridge-address $TSB_ADDRESS`）。此示例使用不同的名称，以便更容易跟踪。
{{</callout>}}

### 设置 `tctl` User

首先，你需要知道要使用的用户名。这将取决于 TSB 的安装方式：如果使用 OIDC，则将是你的企业电子邮件；如果使用 LDAP，则将是你通常的 LDAP 登录用户名；最后，你可以使用 TSB 的默认管理帐户登录，如果在安装中未禁用它。

#### OIDC 用户登录

要使用 OIDC 凭证登录 TSB，请在浏览器中登录到 TSB UI，然后在右上角单击你的用户名，选择 `操作` > `显示令牌信息`。从该页面中，复制下 Bearer Token 和 Refresh Token，并将其导出为 `TSB_BEARER_TOKEN` 和 `TSB_REFRESH_TOKEN`：

```bash
export TSB_BEARER_TOKEN=HHVMW2.qhf9jBL1fMCazBe1umanDr5sNEuFcKtClAUxeWA...redacted
export TSB_REFRESH_TOKEN=AJWXL6VmGUmvYfn43601RG.Bw+xr0IVQ43swidqAt1tHf...redacted
```
```bash
tctl config users set tsb-how-to-user \
  --org $TCTL_LOGIN_ORG \
  --token $TSB_BEARER_TOKEN \
  --refresh-token $TSB_REFRESH_TOKEN
```

#### LDAP（用户名 + 密码）用户登录

对于 LDAP 登录，你需要用户名和密码；你可以通过环境变量配置这些变量，或通过 CLI 传递它们：

```bash
export TCTL_LOGIN_USERNAME=demo-user@tetrate.io
export TCTL_LOGIN_PASSWORD=<your password>
```
```bash
tctl config users set tsb-how-to-user \
  --org $TCTL_LOGIN_ORG \
  --username $TCTL_LOGIN_USERNAME \
  --password $TCTL_LOGIN_PASSWORD
```

{{<callout warning "用户名 + 密码登录写密码到磁盘">}}
当你配置一个带有用户名和密码的用户时，该密码会写入磁盘。为确保凭据不保存到磁盘，你需要在设置完集群、用户和 profile 后执行 `tctl login`。
{{</callout>}}

#### 作为 Admin 用户登录

你可以使用与 LDAP 帐户相同的用户名和密码方案登录默认的管理员用户：

```bash
export TCTL_LOGIN_USERNAME=admin # 这是硬编码的
export TCTL_LOGIN_PASSWORD=<your password> # 你在管理平面安装期间创建的
```
```bash
tctl config users set tsb-how-to-user \
  --org $TCTL_LOGIN_ORG \
  --username $TCTL_LOGIN_USERNAME \
  --password $TCTL_LOGIN_PASSWORD
```

{{<callout warning 注意>}}
当你为用户配置用户名和密码时，该密码将被写入磁盘。为了确保凭证没有保存到磁盘，你需要在设置集群、用户和配置文件之后执行 ctl 登录。

{{</callout>}}

#### OIDC 用户登录

要使用 OIDC 凭证登录 TSB，请在浏览器中登录 TSB UI，然后在右上角点击你的用户名，在下拉菜单中选择 `Actions` > `Show token information`。从该页面复制 Bearer Token 和 Refresh Token，并将它们导出为 `TSB_BEARER_TOKEN` 和 `TSB_REFRESH_TOKEN`：

```bash
export TSB_BEARER_TOKEN=HHVMW2.qhf9jBL1fMCazBe1umanDr5sNEuFcKtClAUxeWA...redacted
export TSB_REFRESH_TOKEN=AJWXL6VmGUmvYfn43601RG.Bw+xr0IVQ43swidqAt1tHf...redacted
```
```bash
tctl config users set tsb-how-to-user \
  --org $TCTL_LOGIN_ORG \
  --token $TSB_BEARER_TOKEN \
  --refresh-token $TSB_REFRESH_TOKEN
```

#### LDAP（用户名 + 密码）用户登录

对于 LDAP 登录，你需要一个用户名和密码；你可以在环境变量中配置这些信息，或通过 CLI 传递：

```bash
export TCTL_LOGIN_USERNAME=demo-user@tetrate.io
export TCTL_LOGIN_PASSWORD=<your password>
```
```bash
tctl config users set tsb-how-to-user \
  --org $TCTL_LOGIN_ORG \
  --username $TCTL_LOGIN_USERNAME \
  --password $TCTL_LOGIN_PASSWORD
```

{{<callout warning "用户名 + 密码登录将密码写入磁盘">}}
当配置用户名和密码的用户时，密码会被写入磁盘。为了确保凭据不会保存到磁盘，你需要在设置好集群、用户和配置文件后运行 `tctl login`。
{{</callout>}}

#### 管理员用户登录

你可以使用与 LDAP 帐户相同的用户名和密码方案登录默认的管理员用户：

```bash
export TCTL_LOGIN_USERNAME=admin # 这是硬编码的
export TCTL_LOGIN_PASSWORD=<your password> # 在管理平面安装期间创建的
```
```bash
tctl config users set tsb-how-to-user \
  --org $TCTL_LOGIN_ORG \
  --username $TCTL_LOGIN_USERNAME \
  --password $TCTL_LOGIN_PASSWORD
```

{{<callout warning 注意>}}
建议在所有 TSB 部署中禁用管理员用户。管理员用户的主要用途是让平台所有者登录并配置其 IdP，以便组织中的其他人员可以使用 OIDC 或 LDAP 登录。

最后，由于这是用户名和密码登录，你需要运行 `tctl login` 以交换密码以获取将来的访问令牌，并确保密码不会保存到磁盘。
{{</callout>}}

### 创建你的 `tctl` 配置文件

*配置文件* 将 *集群* 和 *用户* 绑定在一起，以便它们可以用于连接到 TSB 实例。将刚刚创建的 *集群* 和 *用户* 连接在一起，形成一个 *配置文件*：

```bash
tctl config profiles set tsb-how-to --cluster tsb-how-to-cluster --username tsb-how-to-user
```

### 使用新配置文件

配置 `tctl` 使用你刚刚创建的配置文件连接到 TSB：

```bash
tctl config profiles set-current tsb-how-to
```

在这一点上，你已经准备好了：`tctl` 已经知道 TSB 的位置和你的凭证 - 你可以使用它与 TSB 交互！

### 验证配置

作为一个健全性检查，在完成以下步骤后，你可以列出你的 `tctl` 配置文件，你应该看到类似以下的内容：

```bash
tctl config profiles list
```
```bash
CURRENT   NAME         CLUSTER             ACCOUNT
          default      default             default
*         tsb-how-to   tsb-how-to-cluster  tsb-how-to-user
```

### 使用 `tctl` 查找你的租户

你可以通过 `tctl` 询问 TSB 哪些租户存在，以使你在 `tenant` 中更轻松地设置。对于大多数用户，将返回一个结果 - 这是你想要使用的租户。对于具有多个租户的用户，你需要与你的平台团队交流，确定哪个对你来说是正确的。

```bash
tctl get tenants
```
```bash
NAME          DISPLAY NAME    DESCRIPTION
tetrate       Tetrate         默认租户
```

有了你的租户，你可以将其保存到你的用户中：

```bash
tctl config users set tsb-how-to-user --tenant <your tenant>
```

### 使用 `tctl` 登录

当使用用户名和密码登录时，两者都会被保存到磁盘。这是不可取的，因为你的密码以明文形式存储。为了从 `tctl` 的配置文件中删除密码，你可以使用 [`tctl login`](../../reference/cli/reference/login)，它将交换你的凭据以获取一组 OAuth 令牌，并将这些令牌写入磁盘。

```bash
tctl login
```
