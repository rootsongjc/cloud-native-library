---
title: Backup and restore PostgreSQL
description: Backup and restore PostgreSQL
---

This document describes how to create a backup, and restore using a backup, when using PostgreSQL as TSB's  datastore.
It is recommended to create a backup of your TSB datastore every 24 hours, so in case it gets corrupted, you can easily recover all the information.

Before you get started make sure:

✓ You have [installed and configured TSB.](../setup/self_managed/management-plane-installation)<br />
✓ You have installed and configured `kubectl` to access the management cluster.<br />
✓ You have full access to the PostgreSQL system where TSB is storing the data.

## Create a backup of TSB configuration

TSB requires PostgreSQL 11.1 or up. We will be using this 11.1 version for the example. You can create a backup of the database by running:

```bash{promptUSer: "alice"}
pg_dump tsb > tsb_backup.sql
```
:::note
make sure that the backup file has complete information. At the end of the file there is the completion message such as 

```pre
--
-- PostgreSQL database dump complete
--
```

The size of the backup logs can be decreased by removing the audit logs (please make sure that you have a snapshot to comply with your organization compliance rules). 
For audit logs truncation you can use the following command (please adjust the delta of logs to be kept - it's `2day` in the example below):

```bash
DELETE FROM audit_log WHERE time <= ROUND(EXTRACT(epoch FROM now() - INTERVAL '2day'));
```

:::

## Restore a backup

To restore a backup, it is recommended to scale down the `tsb` and `iam` deployments to 0, as these deployments will be doing queries to the database continuously:
```bash{promptUSer: "alice"}
kubectl scale deployment tsb iam -n tsb --replicas 0
```

:::note
Scaling `tsb` deployment to 0 only interrupts the ability to change configuration in a running TSB installation while restoration is in progress, but does not interfere with the data plane / running services.
:::

At this point, you have to login into your PostgreSQL system, and execute the following actions with a privileged user.
Usually, the database will have few active connections. You can check them by running this query:

```sql
SELECT *
FROM pg_stat_activity
WHERE datname = 'tsb';
```

The next step is to terminate these connections with this query:

```sql
SELECT	pg_terminate_backend (pid)
FROM	pg_stat_activity
WHERE	pg_stat_activity.datname = 'tsb';
```

And immediately remove `tsb` database:

```sql
DROP DATABASE tsb;
```

At this point, all the TSB configurations will be removed. Now you will need to create `tsb` database again:

```sql
CREATE DATABASE tsb;
```

And grant all permissions for this database to the user called `tsb`:

```sql
GRANT ALL PRIVILEGES ON DATABASE tsb TO tsb;
```

Once this is done, login with the user `tsb` and restore the dump created previously:

```sql
psql tsb < tsb_backup.sql
```

Now all data from the backup is restored and you can scale up `tsb` and `iam` deployments to 1:

```bash{promptUSer: "alice"}
kubectl scale deployment tsb iam -n tsb --replicas 1
```

