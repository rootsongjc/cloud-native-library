---
title: 故障排除指南
weight: 5
---

## 工作负载无法加入 mesh

如果新的工作负载未出现在已载入的工作负载列表中，请按照以下步骤操作。

### 检查 `Workload Onboarding Agent` 的状态

#### 虚拟机 (VM) 工作负载

在工作负载的主机上，例如在 VM 上运行：

```bash
systemctl status onboarding-agent
```

你应该会得到类似于以下的输出：

```bash
● onboarding-agent.service - Workload Onboarding Agent
   Loaded: loaded (/usr/lib/systemd/system/onboarding-agent.service; enabled; vendor preset: disabled)
   Active: active (running) since Thu 2021-10-07 14:57:23 UTC; 1 minute ago  # (1)
     Docs: https://tetrate.io/
 Main PID: 3519 (bash)
   CGroup: /system.slice/onboarding-agent.service
           ├─3520 onboarding-agent --agent-config /etc/onboarding-agent/agent.config.yaml --onboarding-config /etc/onboarding-agent/onboarding.config.yaml
```

如果 `onboarding-agent.service` 单元的状态不是 `Active`（1），请再次检查是否按照工作负载载入说明进行操作。

例如，返回到：
* [从 VM 载入工作负载](../onboarding)
* [从 VM 自动扩展组载入工作负载](../onboarding)

#### AWS ECS 工作负载

检查任务是否已创建，并且 `onboarding-agent` 容器和应用程序容器都处于健康状态。例如，通过运行以下命令描述 ECS 服务并检查是否有任何错误：

```bash
aws ecs describe-services --cluster <ECS cluster name> --services <ECS service name>
```

如果存在任何问题，请仔细检查是否按照 [载入 AWS ECS 工作负载](../ecs-workloads) 说明进行操作。

有关进一步的 ECS 故障排除，请参阅 [AWS 故障排除指南](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/troubleshooting.html)。

### 检查 `Workload Onboarding Agent` 的日志

#### 虚拟机 (VM) 工作负载

在工作负载的主机上，例如在 VM 上运行：

```bash
journalctl -u onboarding-agent -o cat
```

#### AWS ECS 工作负载

如果启用了 [`awslogs` 日志驱动程序](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using_awslogs.html)，则可以在 AWS Console 和 `ecs-cli` 命令行工具中查看日志。

要在 AWS Console 中访问日志，导航到 ECS 任务，打开 Logs 选项卡，并选择 `onboarding-agent` 容器。

要使用可在[此处下载和安装](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_installation.html)的 `ecs-cli` 工具访问日志，请运行以下命令：

```bash
ecs-cli logs --cluster <ECS cluster name> --task-id <ECS task ID> --container-name onboarding-agent --follow
```

#### 无法连接到 `Workload Onboarding Endpoint`

如果你看到类似于以下行的重复行：

```text
info    agent   obtaining discovery information from the Workload Onboarding Plane ...
error   agent   RPC failed: rpc error: code = Unavailable desc = connection error: desc = "transport: Error while dialing dial tcp: lookup <onboarding-endpoint-dns-name> on 172.31.0.2:53: no such host"
```

那么你的工作负载无法连接到 `Workload Onboarding Endpoint`。

确保：
* [`OnboardingConfiguration`](../../../../refs/onboarding/config/agent/v1alpha1/onboarding_configuration)（文件 `/etc/onboarding-agent/onboarding.config.yaml`）包含正确的 `Workload Onboarding Endpoint` 的 DNS 名称
* DNS 名称可解析

你可能需要返回到：
* [启用 Workload 载入](../setup)

#### 工作负载未被授权加入 mesh

如果你看到类似于以下行的重复行：

```text
info    agent   using platform-specific credential procured by "aws-ec2-credential" plugin to request authorization for onboarding ...
error   agent   RPC failed: rpc error: code = PermissionDenied desc = Not authorized by OnboardingPolicy
error   agent   failed to obtain authorization for onboarding using platform-specific credential procured by "aws-ec2-credential" plugin: rpc error: code = PermissionDenied desc = Not authorized by OnboardingPolicy
error   agent   failed to obtain authorization to onboard using platform-specific credential procured by any of the plugins
```

（请注意 `failed to obtain authorization for onboarding ... Not authorized by OnboardingPolicy`）

那么你的工作负载未被授权加入 mesh。

请仔细检查是否已创建正确的 [`OnboardingPolicy`](../../../../refs/onboarding/config/authorization/v1alpha1/policy) 资源。

你可能需要返回到：
* [允许工作负载加入 WorkloadGroup](../setup)