---
draft: false
title: "环境变量"
weight: 18
---

以下环境变量可与 `argocd` CLI 一起使用：

| 环境变量            | 描述                                                         |
| :------------------ | :----------------------------------------------------------- |
| `ARGOCD_SERVER`     | 不带 `https://` 前缀的 ArgoCD 服务器地址（而不是为每个命令指定 `--server` ） 例如：`ARGOCD_SERVER=argocd.mycompany.com` 如果通过 DNS 入口提供服务 |
| `ARGOCD_AUTH_TOKEN` | ArgoCD `apiKey` 以便你的 ArgoCD 用户能够进行身份验证         |
| `ARGOCD_OPTS`       | 传递到 `argocd` CLI 的命令行选项，例如 `ARGOCD_OPTS="--grpc-web"` |
