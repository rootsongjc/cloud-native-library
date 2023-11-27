---
title: 备份和恢复 PostgreSQL
description: 备份和恢复 PostgreSQL。
weight: 9
---

本文描述了在将 PostgreSQL 用作 TSB 数据存储时如何创建备份以及如何使用备份进行恢复。
建议每 24 小时创建一次 TSB 数据存储的备份，以便在发生损坏时可以轻松恢复所有信息。

在开始之前，请确保：

- 你已经[安装和配置了 TSB](../../setup/self-managed/management-plane-installation)。
- 你已经安装并配置了 `kubectl` 以访问管理集群。
- 你对存储 TSB 数据的 PostgreSQL 系统具有完全访问权限。

## 创建 TSB 配置的备份

TSB 需要 PostgreSQL 11.1 或更高版本。我们将在示例中使用 11.1 版本。你可以通过运行以下命令创建数据库备份：

```bash
pg_dump tsb > tsb_backup.sql
```
{{<callout note 注意>}}
确保备份文件包含完整的信息。在文件的末尾，应该有如下的完成消息：

```pre
--
-- PostgreSQL database dump complete
--
```

备份日志的大小可以通过删除审计日志来减小（请确保你有一个快照以符合你组织的合规性规则）。要进行审计日志截断，你可以使用以下命令（请根据要保留的日志的时间间隔进行调整，以下示例中为`2day`）：

```bash
DELETE FROM audit_log WHERE time <= ROUND(EXTRACT(epoch FROM now() - INTERVAL '2day'));
```

{{</callout>}}

## 恢复备份

要恢复备份，建议将 `tsb` 和 `iam` 部署的副本数缩减为 0，因为这些部署将不断对数据库进行查询：

```bash
kubectl scale deployment tsb iam -n tsb --replicas 0
```

{{<callout note 注意>}}
将 `tsb` 部署的副本数缩减为 0 仅会在还原进行中时中断在运行中的 TSB 安装中更改配置的能力，但不会干扰数据平面/正在运行的服务。
{{</callout>}}

此时，你需要登录到你的 PostgreSQL 系统，并以特权用户的身份执行以下操作。
通常，数据库将具有少量活动连接。你可以通过运行以下查询来检查它们：

```sql
SELECT *
FROM pg_stat_activity
WHERE datname = 'tsb';
```

接下来的步骤是使用以下查询终止这些连接：

```sql
SELECT	pg_terminate_backend (pid)
FROM	pg_stat_activity
WHERE	pg_stat_activity.datname = 'tsb';
```

然后立即删除 `tsb` 数据库：

```sql
DROP DATABASE tsb;
```

此时，所有 TSB 配置都将被删除。现在，你需要重新创建 `tsb` 数据库：

```sql
CREATE DATABASE tsb;
```

并将该数据库的所有权限授予名为 `tsb` 的用户：

```sql
GRANT ALL PRIVILEGES ON DATABASE tsb TO tsb;
```

完成后，使用用户 `tsb` 登录并恢复之前创建的转储：

```sql
psql tsb < tsb_backup.sql
```

现在，备份中的所有数据都已恢复，你可以将 `tsb` 和 `iam` 部署的副本数增加到 1：

```bash
kubectl scale deployment tsb iam -n tsb --replicas 1
```