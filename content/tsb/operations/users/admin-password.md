---
title: 更改管理员密码
description: 更改 TSB 管理员的密码。
weight: 1
---

本文描述如何更改 TSB 管理员的密码。

TSB 管理员在每个 TSB 实例中都是本地配置的，不属于企业身份提供者（IdP）。这允许超级用户在连接到身份提供者出现问题以进行故障排除和平台修复时能够登录 TSB。

## 更新密钥

管理员凭据存储在管理平面命名空间中的 `admin-credentials` Kubernetes 密钥中（默认为 `tsb`）。它以 SHA-256 哈希的形式安全存储，因此无法被反向解析，可以通过直接更新带有所需密码的密钥来修改。

以下示例显示了如何生成一个稍后可以应用的更新密钥：

```bash
new_password="Tetrate1"
new_password_shasum=$(echo -n $new_password | shasum -a 256 | awk '{print $1}')
kubectl -n tsb create secret generic admin-credentials --from-literal=admin=$new_password_shasum --dry-run=client -o yaml
```

这将输出包含更新密码的密钥的 YAML，并可以使用 `kubectl` 正常应用。

一旦密钥已更新，需要重新启动 `iam` 部署的 pods 以加载更改：

```bash
kubectl -n tsb rollout restart deployment/iam
```
