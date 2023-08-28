---
title: Configuration Promotion
description: TSB Configuration Promotion between different instances.
---

:::danger Source of Truth
We do not recommend the deployment architecture outlined in this document: a
single instance of TSB is designed to be deployed across all of your
environments (test, qa, staging, and prod). The best practice is to deploy a
single TSB centrally and point all of your environments at that single TSB.
Tetrate Service Bridge's built-in controls keep your environment's configuration
isolated and safe.
:::

A few sites have deployed separate TSB instances for each environment. This
guide exists for those sites to ensure they can set up a process to control
configuration promotion across environments, outside TSB itself.

## Configuration Promotion Caveats and Advisory

TSB configuration mostly consists of a number of `Kubernetes Objects`, e.g. 
`Tenant` is an object of `api.tsb.tetrate.io/v2` `Kind` and so on.

As such, the main recommendation is to treat TSB configuration just like any
other k8s resource definition, i.e.

✓ define resources declaratively. <br />
✓ use GitOps for resource application. <br />
✓ use `kustomize` or similar tools for configuration templating and rendering.

The main caveat when it comes to applying resources from one TSB installation to
another is the way TSB stores configuration data when calculating and evaluating
NGAC access rules, cluster/service parameters, etc.

Service Bridge uses persistent storage (PostgreSQL) as the Source of Truth and
chooses the resource's fully-qualified name as its `primary key`. As such,
"promoting" a configuration between two independent *(not sharing the same
persistent state)* TSB installations MUST take into account the configuration
resource naming to avoid `primary key` conflicts.

In other words, to reliably promote configuration between independent instances,
one should:

- Name all TSB resources in both instances **exactly the same**, including the
  resource path (i.e. `Cluster`s of the same name in one instance must belong to
  the same `Tenant` as in the other and so on).
- Avoid imperative configuration changes (e.g. adding a `Cluster` via UI/CLI in
  one environment and not the other), rather using declarative definitions.
- Always have a fresh persistent storage backup to be able to quickly roll back
  in case of data model conflicts.
