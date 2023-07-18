---
draft: false
weight: 1
title: "工具"
date: '2023-06-30T16:00:00+08:00'
---

## 生产

Argo CD 支持多种不同的 Kubernetes 清单定义方式：

- [Kustomize](https://argo-cd.readthedocs.io/en/stable/user-guide/kustomize/)应用程序
- [Helm](https://argo-cd.readthedocs.io/en/stable/user-guide/helm/) Chart
- YAML/JSON/Jsonnet 清单的目录，包括[Jsonnet](https://argo-cd.readthedocs.io/en/stable/user-guide/jsonnet/)。
- 任何配置为配置管理插件的[自定义配置管理工具](https://argo-cd.readthedocs.io/en/stable/operator-manual/config-management-plugins/)

## 开发

Argo CD 还支持直接上传本地清单。由于这是 GitOps 范式的反模式，因此只能出于开发目的而这样做。`override`需要具有权限的用户（通常是管理员）才能在本地上传清单。支持上述所有不同的 Kubernetes 部署工具。上传本地应用程序：

```bash
$ argocd app sync APPNAME --local /path/to/dir/
```
