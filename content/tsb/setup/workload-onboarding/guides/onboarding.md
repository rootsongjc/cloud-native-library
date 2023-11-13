---
title: Onboarding VMs
description: How to onboard VMs and VMs from auto-scaling groups
---

This document describes the steps to onboard VMs to TSB using the Workload Onboarding feature.

Before you proceed, make sure that you have completed the steps described in
[Setting Up Workload Onboarding document](./setup)

## Onboarding a VM

### Create the Workload Onboarding Agent Configuration

By default, the Workload Onboarding Agent expects its configuration to be
specified in a file called `/etc/onboarding-agent/onboarding.config.yaml`.

Create file `/etc/onboarding-agent/onboarding.config.yaml` with the following contents.
Replace `onboarding-endpoint-dns-name` with the Workload Onboarding Endpoint
to connect to, as well as `workload-group-namespace` and `workload-group-name`
with the namespace and name of the Istio [WorkloadGroup](https://istio.io/latest/docs/reference/config/networking/workload-group/) to join to.

```yaml
apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
kind: OnboardingConfiguration
onboardingEndpoint:
  host: <onboarding-endpoint-dns-name>
workloadGroup:
  namespace: <workload-group-namespace>
  name: <workload-group-name>
```

The Workload Onboarding Endpoint is assumed to be available at `https://<onboarding-endpoint-dns-name>:15443`,
and that it uses a TLS certificate issued for the appropriate DNS name. The certificate should be signed by the CA that the VM trusts. For more configuration options, please refer to [`OnboardingConfiguration`](../../../refs/onboarding/config/agent/v1alpha1/onboarding_configuration) documentation.

### Start the Workload Onboarding Agent

To start the `Workload Onboarding Agent`, run:

```bash
sudo systemctl enable onboarding-agent

sudo systemctl start onboarding-agent
```

If everything is configured correctly, your VM should now be onboarded into the mesh.

## Onboarding Workloads from Auto-scaling Group of VMs

Once the Workload Onboarding Agent has been installed on VMs in the auto-scaling
group, pass the following [user data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html) into the VM instances.
Replace `onboarding-endpoint-dns-name` with the Workload Onboarding Endpoint
to connect to, as well as `workload-group-namespace` and `workload-group-name`
with the namespace and name of the Istio [`WorkloadGroup`](https://istio.io/latest/docs/reference/config/networking/workload-group/) to join to.

```yaml
#cloud-config

# Provide `OnboardingConfiguration` to the `Workload Onboarding Agent`
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

# Start `Workload Onboarding Agent`
runcmd:
- sudo systemctl enable onboarding-agent
- sudo systemctl start onboarding-agent
```

The above [cloud-init] config provides the configuration file for Workload Onboarding Agent,
and starts the Workload Onboarding Agent as part of the VM launch flow.

If everything is configured correctly, your VMs should automatically be onboarded into the mesh.
