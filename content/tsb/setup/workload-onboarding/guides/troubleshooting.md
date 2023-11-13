---
title: Troubleshooting Guide
description: How to debug common problems related to Workload Onboarding
---

## Workload fails to join the mesh

If a new workload does not appear on the list of onboarded workloads, follow these steps.

### Check status of the `Workload Onboarding Agent`

#### Virtual Machine (VM) workloads

On the host of the workload, e.g. on the VM, run:

```bash
systemctl status onboarding-agent
```

You should get output similar to:

```bash
● onboarding-agent.service - Workload Onboarding Agent
   Loaded: loaded (/usr/lib/systemd/system/onboarding-agent.service; enabled; vendor preset: disabled)
   Active: active (running) since Thu 2021-10-07 14:57:23 UTC; 1 minute ago  # (1)
     Docs: https://tetrate.io/
 Main PID: 3519 (bash)
   CGroup: /system.slice/onboarding-agent.service
           ├─3520 onboarding-agent --agent-config /etc/onboarding-agent/agent.config.yaml --onboarding-config /etc/onboarding-agent/onboarding.config.yaml
```

If status of the `onboarding-agent.service` unit is not `Active` (1),
double-check whether you followed onboarding instructions closely.

E.g., go back to:
* [Onboarding workload from a VM](./onboarding#onboarding-a-vm)
* [Onboarding workload from an auto-scaling group of VMs](./onboarding#onboarding-workloads-from-auto-scaling-group-of-vms)

#### AWS ECS workloads

Check that the task(s) have been created and that both the `onboarding-agent`
container and application container are healthy. For example describe the ECS
service and check for any errors by running:

```bash
aws ecs describe-services --cluster <ECS cluster name> --services <ECS service name>
```

If there are any problems, double-check that you followed the
[onboard AWS ECS workloads](ecs-workloads) instructions closely.

For further ECS troubleshooting, see also the
[AWS troubleshooting guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/troubleshooting.html).

### Check logs of the `Workload Onboarding Agent`

#### Virtual Machine (VM) workloads

On the host of the workload, e.g. on the VM, run:

```bash
journalctl -u onboarding-agent -o cat
```

#### AWS ECS workloads

Logs can be viewed in both the AWS Console and via the `ecs-cli` command line
tool if you have enabled the
[`awslogs` log driver](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using_awslogs.html).

To access the logs in the AWS Console navigate to the ECS task, open the Logs
tab and select the `onboarding-agent` container.

To access the logs using the `ecs-cli` tool that can be
[downloaded and installed here](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_installation.html),
run the following commands:

```bash
ecs-cli logs --cluster <ECS cluster name> --task-id <ECS task ID> --container-name onboarding-agent --follow
```

#### No connectivity to the `Workload Onboarding Endpoint`

If you see repeatedly lines similar to:

```text
info    agent   obtaining discovery information from the Workload Onboarding Plane ...
error   agent   RPC failed: rpc error: code = Unavailable desc = connection error: desc = "transport: Error while dialing dial tcp: lookup <onboarding-endpoint-dns-name> on 172.31.0.2:53: no such host"
```

then your workload has no connectivity to the `Workload Onboarding Endpoint`.

Make sure
* [`OnboardingConfiguration`](../../../refs/onboarding/config/agent/v1alpha1/onboarding_configuration) (file `/etc/onboarding-agent/onboarding.config.yaml`)
  contains correct DNS name of the `Workload Onboarding Endpoint`
* DNS name is resolvable

You might need to go back to:
* [Enable Workload Onboarding](./setup#enable-workload-onboarding)

#### Workload is not authorized to join the mesh

If you see repeatedly lines similar to:

```text
info    agent   using platform-specific credential procured by "aws-ec2-credential" plugin to request authorization for onboarding ...
error   agent   RPC failed: rpc error: code = PermissionDenied desc = Not authorized by OnboardingPolicy
error   agent   failed to obtain authorization for onboarding using platform-specific credential procured by "aws-ec2-credential" plugin: rpc error: code = PermissionDenied desc = Not authorized by OnboardingPolicy
error   agent   failed to obtain authorization to onboard using platform-specific credential procured by any of the plugins
```

(notice `failed to obtain authorization for onboarding ... Not authorized by OnboardingPolicy`)

then your workload is not authorized to join the mesh.

Double-check whether you've created the correct [`OnboardingPolicy`](../../../refs/onboarding/config/authorization/v1alpha1/policy) resource.

You might need to go back to:
* [Allow workloads to join WorkloadGroup](./setup#allow-workloads-to-join-workloadgroup)
