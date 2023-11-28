---
title: 从 AWS Auto Scaling Group 上加入工作负载
weight: 6
---

要将部署在 AWS Auto Scaling Group（ASG）上的工作负载加入，你需要在[实例启动脚本](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)中执行所有设置操作，而不是在 EC2 实例上执行命令。

简而言之，你需要将先前步骤中的设置命令移到与 Auto Scaling Group 中的实例关联的 [cloud-init](https://cloudinit.readthedocs.io/en/latest/) 配置中。

具体来说，

1. 将来自 [安装 Bookinfo Ratings 应用程序](../configure-vm) 步骤的设置命令移到云初始化配置中。
1. 将来自 [安装 Istio Sidecar](../configure-vm) 步骤的设置命令移到云初始化配置中。
1. 将来自 [在 AWS EC2 实例上安装工作负载 Onboarding Agent](../configure-vm) 步骤的设置命令移到云初始化配置中。
1. 将来自 [从 AWS EC2 实例上加入工作负载](../onboard-vm) 步骤的设置命令移到云初始化配置中。

以下配置是将所有步骤合并在一起的示例。将 `<example-ca-certificate>` 替换为 [example-ca.crt.pem 的值](../enable-workload-onboarding)，将 `<ONBOARDING_ENDPOINT_ADDRESS>` 替换为 [你之前获取的值](../enable-workload-onboarding)。

```yaml
#cloud-config

write_files:
# 自定义 CA 的证书
- content: |
    <example-ca-certificate>
  path: /usr/local/share/ca-certificates/example-ca.crt
  owner: root:root
  permissions: '0644'
# Onboarding 配置
- content: |
    apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
    kind: OnboardingConfiguration
    onboardingEndpoint:
      host: <ONBOARDING_ENDPOINT_ADDRESS>
      transportSecurity:
        tls:
          sni: onboarding-endpoint.example
    workloadGroup:
      namespace: bookinfo
      name: ratings
    workload:
      labels:
        version: v5
    settings:
      connectedOver: INTERNET
  path: /etc/onboarding-agent/onboarding.config.yaml
  owner: root:root
  permissions: '0644'

runcmd:
- |
  #!/usr/bin/env bash

  set -ex

  # 安装最新版本的受信任 CA 证书
  sudo apt-get update -y
  sudo apt-get install -y ca-certificates
  # 信任自定义 CA 的证书
  sudo update-ca-certificates

  # 安装 Bookinfo ratings 应用程序
  curl --fail --silent --location https://deb.nodesource.com/setup_14.x | sudo bash -
  sudo apt-get install -y nodejs
  curl -fLO https://dl.cloudsmith.io/public/tetrate/onboarding-examples/raw/files/bookinfo-ratings.deb
  sudo apt-get install -y ./bookinfo-ratings.deb
  rm bookinfo-ratings.deb
  sudo systemctl enable bookinfo-ratings
  sudo systemctl start bookinfo-ratings

  ONBOARDING_ENDPOINT_ADDRESS=<ONBOARDING_ENDPOINT_ADDRESS>

  # 安装 Istio Sidecar
  curl -fLO \
    --connect-to "onboarding-endpoint.example:443:${ONBOARDING_ENDPOINT_ADDRESS}:443" \
    "https://onboarding-endpoint.example/install/deb/amd64/istio-sidecar.deb"
  curl -fLO \
    --connect-to "onboarding-endpoint.example:443:${ONBOARDING_ENDPOINT_ADDRESS}:443" \
    "https://onboarding-endpoint.example/install/deb/amd64/istio-sidecar.deb.sha256"
  sha256sum --check istio-sidecar.deb.sha256
  sudo apt-get install -y ./istio-sidecar.deb
  rm istio-sidecar.deb istio-sidecar.deb.sha256

  # 安装工作负载 Onboarding Agent
  curl -fLO \
    --connect-to "onboarding-endpoint.example:443:${ONBOARDING_ENDPOINT_ADDRESS}:443" \
   "https://onboarding-endpoint.example/install/deb/amd64/onboarding-agent.deb"
  curl -fLO \
    --connect-to "onboarding-endpoint.example:443:${ONBOARDING_ENDPOINT_ADDRESS}:443" \
    "https://onboarding-endpoint.example/install/deb/amd64/onboarding-agent.deb.sha256"
  sha256sum --check onboarding-agent.deb.sha256
  sudo apt-get install -y ./onboarding-agent.deb
  rm onboarding-agent.deb onboarding-agent.deb.sha256
  sudo systemctl enable onboarding-agent
  sudo systemctl start onboarding-agent
```

一旦将数据与 Auto Scaling Group 的用户数据相关联，请尝试扩展和缩小 Auto Scaling Group，并验证[工作负载是否已正确加入](../onboard-vm)。