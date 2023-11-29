---
title: 配置本地虚拟机
weight: 2
---

## 安装 Bookinfo Ratings 应用程序

SSH 进入本地虚拟机并安装 `ratings` 应用程序。执行以下命令：

```bash
# 安装最新版本的可信 CA 证书
sudo apt-get update -y
sudo apt-get install -y ca-certificates

# 添加带有 Node.js 的 DEB 仓库
curl --fail --silent --location https://deb.nodesource.com/setup_14.x | sudo bash -

# 安装 Node.js
sudo apt-get install -y nodejs

# 下载 Bookinfo Ratings 应用程序的 DEB 包
curl -fLO https://dl.cloudsmith.io/public/tetrate/onboarding-examples/raw/files/bookinfo-ratings.deb

# 安装 DEB 包
sudo apt-get install -y ./bookinfo-ratings.deb

# 删除下载的文件
rm bookinfo-ratings.deb

# 启用 SystemD 单元
sudo systemctl enable bookinfo-ratings

# 启动 Bookinfo Ratings 应用程序
sudo systemctl start bookinfo-ratings
```

## 验证 `ratings` 应用程序

执行以下命令以验证 `ratings` 应用程序是否能够提供本地请求：

```bash
curl -fsS http://localhost:9080/ratings/1
```

你应该会得到类似于以下内容的输出：

```json
{"id":1,"ratings":{"Reviewer1":5,"Reviewer2":4}}
```

## 配置信任示例 CA

请记住，你之前已使用由自定义 CA 签名的 TLS 证书配置了 Workload Onboarding 终端点。因此，运行在本地虚拟机上并尝试连接到 Workload Onboarding 终端点的任何软件默认不会信任其证书。

在继续之前，你必须配置本地虚拟机以信任你的自定义 CA。

首先，更新 `apt` 软件包列表：

```bash
sudo apt-get update -y
```

然后安装 `ca-certificates` 软件包：

```bash
sudo apt-get install -y ca-certificates
```

将你在[设置证书时创建的文件](../../aws-ec2/enable-workload-onboarding) `example-ca.crt.pem` 的内容复制并放置在本地虚拟机的位置 `/usr/local/share/ca-certificates/example-ca.crt`。

使用你喜欢的工具来执行此操作。如果你没有安装任何编辑器或工具，你可以使用以下 `cat` 和 `dd` 的组合：

1. 执行 `cat <<EOF | sudo dd of=/usr/local/share/ca-certificates/example-ca.crt`
1. 复制 `example-ca.crt.pem` 的内容并粘贴到你执行上一步的终端中
1. 输入 `EOF` 并按 `Enter` 键完成第一个命令

在将自定义 CA 放置在正确位置后，执行以下命令：

```bash
sudo update-ca-certificates
```

这将重新加载受信任的 CA 列表，并包括你的自定义 CA。

## 安装 Istio Sidecar

通过执行以下命令安装 Istio sidecar。将 `ONBOARDING_ENDPOINT_ADDRESS` 替换为[之前获取的值](../../aws-ec2/enable-workload-onboarding)。

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

# 删除下载的文件
rm istio-sidecar.deb istio-sidecar.deb.sha256
```

## 安装 Workload Onboarding Agent

通过执行以下命令安装 Workload Onboarding Agent。将 `ONBOARDING_ENDPOINT_ADDRESS` 替换为[之前获取的值](../../aws-ec2/enable-workload-onboarding)。

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

# 删除下载的文件
rm onboarding-agent.deb onboarding-agent.deb.sha256
```

## 安装示例 JWT 凭据插件

为了本指南的目的，你将使用 `Sample JWT Credential Plugin` 为本地虚拟机上的工作负载提供 [JWT 令牌] 凭据。

执行以下命令以安装 `Sample JWT Credential Plugin`：

```bash
curl -fL "https://dl.cloudsmith.io/public/tetrate/onboarding-examples/raw/files/onboarding-agent-sample-jwt-credential-plugin_0.0.1_$(uname -s)_$(uname -m).tar.gz" \
 | tar -xz onboarding-agent-sample-jwt-credential-plugin
sudo mv onboarding-agent-sample-jwt-credential-plugin /usr/local/bin/
```

复制你之前[创建的文件](../configure-workload-onboarding) `sample-jwt-issuer.jwk` 的内容，并将其放置在本地虚拟机上的位置 `/var/run/secrets/onboarding-agent-sample-jwt-credential-plugin/jwt-issuer.jwk`。

使用你喜欢的工具来执行此操作。如果你没有安装任何编辑器或工具，你可以使用以下 `cat` 和 `dd` 的组合：

1. 执行
```bash
   sudo mkdir -p /var/run/secrets/onboarding-agent-sample-jwt-credential-plugin/
   cat <<EOF | sudo dd of=/

var/run/secrets/onboarding-agent-sample-jwt-credential-plugin/jwt-issuer.jwk
```
1. 复制 `sample-jwt-issuer.jwk` 的内容并粘贴到你执行上一步的终端中
1. 输入 `EOF` 并按 `Enter` 键完成第一个命令
1. 执行
```bash
   sudo chmod 400 /var/run/secrets/onboarding-agent-sample-jwt-credential-plugin/jwt-issuer.jwk
   sudo chown onboarding-agent: -R /var/run/secrets/onboarding-agent-sample-jwt-credential-plugin/
```

## 配置 Workload Onboarding Agent

执行以下命令将 [Agent Configuration](../../../../../refs/onboarding/config/agent/v1alpha1/agent-configuration) 保存到文件 `/etc/onboarding-agent/agent.config.yaml` 中：

```bash
cat << EOF | sudo tee /etc/onboarding-agent/agent.config.yaml
apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
kind: AgentConfiguration
host:
  custom:
    credential:
    - plugin:
        name: sample-jwt-credential
        path: /usr/local/bin/onboarding-agent-sample-jwt-credential-plugin
        env:
        - name: SAMPLE_JWT_ISSUER
          value: "https://sample-jwt-issuer.example"
        - name: SAMPLE_JWT_ISSUER_KEY
          value: "/var/run/secrets/onboarding-agent-sample-jwt-credential-plugin/jwt-issuer.jwk"
        - name: SAMPLE_JWT_SUBJECT
          value: "vm007-datacenter1-us-east.internal.corp"
        - name: SAMPLE_JWT_ATTRIBUTES_FIELD
          value: "custom_attributes"
        - name: SAMPLE_JWT_ATTRIBUTES
          value: "instance_name=vm007-datacenter1-us-east,instance_role=app-ratings,region=us-east"
EOF
```

通过支持的 `Sample JWT Credential Plugin` 环境变量，你已经配置了所需内容的 JWT 令牌。
