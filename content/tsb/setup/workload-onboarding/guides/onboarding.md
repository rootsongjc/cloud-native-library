---
title: "载入虚拟机"
description: 本文档描述了使用工作负载载入功能将 VM 载入到 TSB 的步骤。
weight: 3
---

在继续之前，请确保你已经完成了 [设置工作负载载入文档](../setup) 中描述的步骤。

## 载入 VM

### 创建工作负载载入代理配置

默认情况下，工作负载载入代理期望将其配置指定在一个名为 `/etc/onboarding-agent/onboarding.config.yaml` 的文件中。

创建文件 `/etc/onboarding-agent/onboarding.config.yaml`，并使用以下内容替换。
将 `onboarding-endpoint-dns-name` 替换为要连接的工作负载载入端点，以及将 `workload-group-namespace` 和 `workload-group-name` 替换为要加入的 Istio [WorkloadGroup](https://istio.io/latest/docs/reference/config/networking/workload-group/) 的命名空间和名称。

```yaml
apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
kind: OnboardingConfiguration
onboardingEndpoint:
  host: <onboarding-endpoint-dns-name>
workloadGroup:
  namespace: <workload-group-namespace>
  name: <workload-group-name>
```

工作负载载入端点假定在 `https://<onboarding-endpoint-dns-name>:15443` 处可用，并且它使用为适当的 DNS 名称颁发的 TLS 证书。证书应由 VM 信任的 CA 签名。有关更多配置选项，请参阅 [`OnboardingConfiguration`](../../../refs/onboarding/config/agent/v1alpha1/onboarding_configuration) 文档。

### 启动工作负载载入代理

要启动 `工作负载载入代理`，运行：

```bash
sudo systemctl enable onboarding-agent

sudo systemctl start onboarding-agent
```

如果一切配置正确，你的 VM 现在应该已经成功加入到 mesh 中。

## 从 VM 自动扩展组载入工作负载

一旦在自动扩展组的 VM 上安装了 Workload 载入代理，将以下 [用户数据](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html) 传递到 VM 实例。
将 `onboarding-endpoint-dns-name` 替换为要连接的工作负载载入端点，以及将 `workload-group-namespace` 和 `workload-group-name` 替换为要加入的 Istio [`WorkloadGroup`](https://istio.io/latest/docs/reference/config/networking/workload-group/) 的命名空间和名称。

```yaml
#cloud-config

# 为 `Workload 载入代理` 提供 `OnboardingConfiguration`
write_files:
- content: |
    apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
    kind: OnboardingConfiguration
    onboardingEndpoint:
      host: <onboarding-endpoint-dns-name> 
    workloadGroup:
      namespace: <workload-group-namespace>
      name: <workload-group-name>
  path: /etc/onboarding-agent/onboarding.config.yaml
  owner: root:root
  permissions: '0644'

# 启动 `Workload 载入代理`
runcmd:
- sudo systemctl enable onboarding-agent
- sudo systemctl start onboarding-agent
```

上述 cloud-init 配置提供了 Workload 载入代理的配置文件，并在 VM 启动流程的一部分启动了 Workload 载入代理。

如果一切配置正确，你的 VM 应该会自动加入到 mesh 中。
