---
title: 配置虚拟机
weight: 4
---

## 启动 AWS EC2 实例

使用以下配置启动 AWS EC2 实例：

1. 选择带有 `Ubuntu Server`（DEB）的 `64 位 (x86)` AMI 镜像。
1. 选择最小的 `实例类型`，例如 `t2.micro`（1 个 vCPU，1 GiB RAM）
   或 `t2.nano`（1 个 vCPU，0.5 GiB RAM）
1. 选择默认 VPC（以使你的实例具有公共 IP）
1. 将 `自动分配公共 IP` 设置为 `启用`
1. 配置 `安全组`，允许从 `0.0.0.0/0` 的端口 `9080` 接收流量

为了本指南的目的，你将创建一个具有公共 IP 的 EC2 实例，以便进行配置。

{{<callout warning 注意>}}
这不建议用于生产场景。对于生产场景，你应该做相反的操作，将 Kubernetes 集群和 EC2 实例放在同一网络上，或进行网络对等连接，并不为你的虚拟机分配公共 IP。
{{</callout>}}

## 安装 Bookinfo Ratings 应用程序

SSH 进入你创建的 AWS EC2 实例，并安装 `ratings` 应用程序。执行以下命令：

```bash
# 安装最新版本的受信任 CA 证书
sudo apt-get update -y
sudo apt-get install -y ca-certificates

# 添加具有 Node.js 的 DEB 仓库
curl --fail --silent --location https://deb.nodesource.com/setup_14.x | sudo bash -

# 安装 Node.js
sudo apt-get install -y nodejs

# 下载 Bookinfo Ratings 应用程序的 DEB 包
curl -fLO https://dl.cloudsmith.io/public/tetrate/onboarding-examples/raw/files/bookinfo-ratings.deb

# 安装 DEB 包
sudo apt-get install -y ./bookinfo-ratings.deb

# 删除已下载的文件
rm bookinfo-ratings.deb

# 启用 SystemD 单元
sudo systemctl enable bookinfo-ratings

# 启动 Bookinfo Ratings 应用程序
sudo systemctl start bookinfo-ratings
```

## 验证 `ratings` 应用程序

执行以下命令验证 `ratings` 应用程序现在可以提供本地请求：

```bash
curl -fsS http://localhost:9080/ratings/1
```

你应该会得到类似以下的输出：

```json
{"id":1,"ratings":{"Reviewer1":5,"Reviewer2":4}}
```

## 配置信任示例 CA

请记住，你之前使用自定义 CA 签名的 TLS 证书配置了 Workload Onboarding Endpoint。因此，运行在 AWS EC2 实例上并尝试连接到 Workload Onboarding Endpoint 的任何软件默认不信任其证书。

在继续之前，你必须配置 EC2 实例以信任你的自定义 CA。

首先，更新 `apt` 包列表：

```bash
sudo apt-get update -y
```

然后安装 `ca-certificates` 包：

```bash
sudo apt-get install -y ca-certificates
```

将你在[设置证书时创建的文件](../enable-workload-onboarding)中的 `example-ca.crt.pem` 文件的内容复制并放置在 EC2 实例上的路径 `/usr/local/share/ca-certificates/example-ca.crt` 下。

可以使用你喜欢的工具来执行此操作。如果你尚未安装任何编辑器或工具，你可以使用以下步骤组合 `cat` 和 `dd`：

1. 执行 `cat <<EOF | sudo dd of=/usr/local/share/ca-certificates/example-ca.crt`
1. 复制 `example-ca.crt.pem` 的内容，并粘贴到执行上一步的终端中
1. 输入 `EOF` 并按 `Enter` 完成第一个命令

将自定义 CA 放在正确位置后，执行以下命令：

```bash
sudo update-ca-certificates
```

这将重新加载可信 CA 的列表，并包括你的自定义 CA。

## 安装 Istio Sidecar

通过执行以下命令安装 Istio sidecar。将 `ONBOARDING_ENDPOINT_ADDRESS` 替换为 [你之前获取

的值](../enable-workload-onboarding#verify-the-workload-onboarding-endpoint)。

```bash
# 下载 DEB 包
curl -fLO \
  --connect-to "onboarding-endpoint.example:443:${ONBOARDING_ENDPOINT_ADDRESS}:443" \
  "https://onboarding-endpoint.example/install/deb/amd64/istio-sidecar.deb"

# 下载校验和
curl -fLO \
  --connect-to "onboarding-endpoint.example:443:${ONBOARDING_ENDPOINT_ADDRESS}:443" \
  "https://onboarding-endpoint.example/install/deb/amd64/istio-sidecar.deb.sha256"

# 验证校验和
sha256sum --check istio-sidecar.deb.sha256

# 安装 DEB 包
sudo apt-get install -y ./istio-sidecar.deb

# 删除已下载的文件
rm istio-sidecar.deb istio-sidecar.deb.sha256
```

## 安装 Workload Onboarding Agent

通过执行以下命令安装 Workload Onboarding Agent。将 `ONBOARDING_ENDPOINT_ADDRESS` 替换为 [你之前获取的值](../../enable-workload-onboarding)。

```bash
# 下载 DEB 包
curl -fLO \
  --connect-to "onboarding-endpoint.example:443:${ONBOARDING_ENDPOINT_ADDRESS}:443" \
  "https://onboarding-endpoint.example/install/deb/amd64/onboarding-agent.deb"

# 下载校验和
curl -fLO \
  --connect-to "onboarding-endpoint.example:443:${ONBOARDING_ENDPOINT_ADDRESS}:443" \
  "https://onboarding-endpoint.example/install/deb/amd64/onboarding-agent.deb.sha256"

# 验证校验和
sha256sum --check onboarding-agent.deb.sha256

# 安装 DEB 包
sudo apt-get install -y ./onboarding-agent.deb

# 删除已下载的文件
rm onboarding-agent.deb onboarding-agent.deb.sha256
```
