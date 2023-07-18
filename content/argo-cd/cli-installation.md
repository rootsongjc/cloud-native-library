---
weight: 4
title: 安装
date: '2023-06-30T16:00:00+08:00'
type: book
---

你可以从此存储库的[最新发布页面](https://github.com/argoproj/argo-cd/releases/latest)下载最新的 Argo CD 版本，其中将包含`argocd` CLI。

## Linux 和 WSL

### ArchLinux

```bash
pacman -S argocd
```

### Homebrew

```bash
brew install argocd
```

### 使用 curl 下载

#### 下载最新版本

```bash
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

#### 下载具体版本

`VERSION`将以下命令中的替换设置`<TAG>`为你要下载的 Argo CD 版本：

```bash
VERSION=<TAG> # Select desired TAG from https://github.com/argoproj/argo-cd/releases
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

你现在应该能够运行`argocd`命令。

## Mac (M1)

### 使用 curl 下载

你可以在上面的链接查看最新版本的 Argo CD 或运行以下命令来获取版本：

```bash
VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
```

将以下命令替换`VERSION`为你要下载的 Argo CD 版本：

```bash
curl -sSL -o argocd-darwin-arm64 https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-darwin-arm64
```

安装 Argo CD CLI 二进制文件：

```bash
sudo install -m 555 argocd-darwin-arm64 /usr/local/bin/argocd
rm argocd-darwin-arm64
```

## Mac

### Homebrew

```
brew install argocd
```

### 使用 curl 下载

你可以在上面的链接查看最新版本的 Argo CD 或运行以下命令来获取版本：

```bash
VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
```

将以下命令替换`VERSION`为你要下载的 Argo CD 版本：

```bash
curl -sSL -o argocd-darwin-amd64 https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-darwin-amd64
```

安装 Argo CD CLI 二进制文件：

```bash
sudo install -m 555 argocd-darwin-amd64 /usr/local/bin/argocd
rm argocd-darwin-amd64
```

完成上述任一说明后，你现在应该能够运行`argocd`命令。

## Windows

### 使用 PowerShell 下载：Invoke-WebRequest

你可以在上面的链接查看最新版本的 Argo CD 或运行以下命令来获取版本：

```
$version = (Invoke-RestMethod https://api.github.com/repos/argoproj/argo-cd/releases/latest).tag_name
```

将以下命令替换`$version`为你要下载的 Argo CD 版本：

```bash
$url = "https://github.com/argoproj/argo-cd/releases/download/" + $version + "/argocd-windows-amd64.exe"
$output = "argocd.exe"

Invoke-WebRequest -Uri $url -OutFile $output
```

另请注意，你可能需要将该文件移至你的 PATH 中。

完成上述说明后，你现在应该能够运行`argocd`命令。
