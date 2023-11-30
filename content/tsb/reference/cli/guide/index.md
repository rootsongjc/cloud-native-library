---
title: 入门指南
description: 使用 Tetrate Service Bridge CLI 入门。
weight: 1
---

Tetrate Service Bridge 的命令行界面（CLI）允许你与 TSB API 交互，以便以编程或交互的方式轻松操作对象和配置。CLI 通过提交 TSB 或 Istio 对象的 YAML 表示来工作。

## 安装

请参阅 [TSB 文档]( https://docs.tetrate.io/service-bridge/reference/cli/guide/index)。

## 配置

CLI 配置支持多个配置文件，用于轻松管理来自同一 CLI 的不同环境。CLI 中的配置由集群和凭据的一对一配对定义。

### 凭据

CLI 中的凭据被称为 `user`。有关 `user` 子命令的完整参考信息可以在 [CLI 参考](../reference/config#tctl-config-users) 页面中找到。下面是创建名为 `admin-user` 用户的示例：

```bash
tctl config users set admin-user --username admin --password 'MySuperSecret!' --org tetrate --tenant tenant1
```

每当在配置文件中使用 `admin-user` 时，CLI 将提交 `admin` 用户和 `MySuperSecret!` 密码，以及 `tetrate` 组织和 `tenant1` 租户。

{{<callout note 密码中的特殊字符>}}
在终端中使用可能被视为特殊字符的字符时要小心。例如，如果包含 `$`（美元符号）并使用双引号引用它们，可能会以意想不到的方式解释它们。

由于每个终端的行为可能略有不同，请始终查阅手册以获取确切的语法，以避免这些特殊字符以意外的方式被解释。在大多数情况下，使用单引号应该是安全的。

这个警告适用于在终端上键入的几乎所有内容，但密码有更高的风险，因为鼓励使用特殊字符。
{{</callout>}}

### 集群

CLI 中的集群映射到给定的 TSB API 终点。有关 `clusters` 子命令的完整参考信息可以在 [CLI 参考](../reference/config#tctl-config-clusters) 页面中找到。下面是创建名为 `my-tsb` 集群的示例：

```bash
tctl config clusters set my-tsb --bridge-address my.tsb.corp:8443
```

每当在配置文件中使用 `my-tsb` 时，CLI 将发送请求到 `https://my.tsb.corp:8443/` 终点。

### 配置文件

配置文件是 `cluster` 和 `username` 的给定组合。其结果是 CLI 发送请求到由 `cluster` 指定的终点，并使用 `username` 凭据进行身份验证。有关 `profiles` 子命令的完整参考信息可以在 [CLI 参考](../reference/config#tctl-config-profiles) 页面中找到。下面是创建名为 `demo-tsb` 配置文件的示例：

```bash
tctl config profiles set demo-tsb --cluster my-tsb --username admin-user
```

CLI 可以使用不同的集群和用户组合拥有多个 `profiles`。在未指定 `--profile` 选项时，其中一个配置文件将被用作默认配置文件。你可以随时更改当前配置文件，如下所示。

```bash
tctl config profiles list
  CURRENT  NAME      CLUSTER      ACCOUNT
  *        default
           demo-tsb  my-tsb       admin-user

tctl config profiles set-current demo-tsb

tctl config profiles list
  CURRENT  NAME      CLUSTER      ACCOUNT
           default
  *        demo-tsb  my-tsb       admin-user
```

## 命令完成

`tctl` 为 `bash` shell 提供了命令完成，允许轻松查找命令及其标志。假设已启用 `bash` 完成，你可以在 [completion](../reference/completion) 命令的输出上执行源代码，以使 `bash` 中的 `tctl` 命令的自动完成工作。

```bash
source <(tctl completion bash)
```
