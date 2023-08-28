---
title: Onboarding AWS ECS workloads
description: How to onboard AWS Elastic Container Service (ECS) workloads
---

This document describes the steps to onboard AWS Elastic Container Service
(ECS) tasks to TSB using the Workload Onboarding feature.

Before you proceed, make sure that you have completed the steps described in
[Setting Up Workload Onboarding document](./setup). You may skip the steps
around configuring the local repository and installing packages if you do not
plan to onboard VMs, as the process for ECS tasks is slightly different.

## Context

Every workload that gets onboarded into the mesh by Workload Onboarding must
have a verifiable identity. For AWS ECS tasks, the
[task IAM role](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html)
is used to identify which task is trying to join the mesh.

The Onboarding Agent container runs as a sidecar next to the workload container
in the AWS ECS task. On start up, Onboarding Agent interacts with the AWS ECS
environment to procure a credential associated with the IAM role of the task
and uses it to authenticate with the Workload Onboarding Plane.

## Overview

The setup for Workload Onboarding of AWS ECS workloads consists of the
following extra steps compared with VM workloads:

1. Allow AWS ECS tasks to join WorkloadGroup
2. Configure the AWS ECS task definition to have an IAM role and to run the
   Workload Onboarding Agent as a sidecar

## Allow AWS ECS tasks to join WorkloadGroup

To allow on-premise workloads to join certain WorkloadGroups, create an
[OnboardingPolicy](../../../refs/onboarding/config/authorization/v1alpha1/policy)
with the `ecs` field set.

### Examples

The example below allows any workloads running as AWS ECS tasks
associated with the given AWS account, and can join any of the
available WorkloadGroups in the given Kubernetes namespace:

```yaml
apiVersion: authorization.onboarding.tetrate.io/v1alpha1
kind: OnboardingPolicy
metadata:
  name: allow-any-aws-ecs-task-from-given-accounts
  namespace: <namespace>
spec:
  allow:
  - workloads:
    - aws:
        accounts:
        - '123456789012'
        - '234567890123'
        ecs: {}                 # any AWS ECS tasks from the above account(s)
    onboardTo:
    - workloadGroupSelector: {} # any WorkloadGroup from that namespace
```

While the previous example may have been a rather "permissive" policy, a more
restrictive onboarding policy might only allow onboarding workloads running as
AWS ECS tasks in a particular AWS region and/or zone, in a particular AWS
ECS cluster, with a particular AWS IAM Role, etc. It might also only allow
workloads to join a specific subset of WorkloadGroups.

The following shows an example of a more restrictive policy:

```yaml
apiVersion: authorization.onboarding.tetrate.io/v1alpha1
kind: OnboardingPolicy
metadata:
  name: allow-narrow-subset-of-aws-ecs-tasks
  namespace: <namespace>
spec:
  allow:
  - workloads:
    - aws:
        partitions:
        - aws
        accounts:
        - '123456789012'
        regions:
        - us-east-2
        zones:
        - us-east-2b
        ecs:
          clusters:
          - <ECS cluster name>
          iamRoleNames:
          - <IAM role name>     # any AWS ECS task from the above partitions/accounts/regions/zones
                                # in the specified cluster(s) that is associated with one of IAM
                                # Roles on that list
    onboardTo:
    - workloadGroupSelector:
        matchLabels:
          app: ratings
```

## Creating the Task Definition

1. Configure a
[task IAM role](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html).
This is the identity that the task will use for joining the mesh.
2. Set the Network mode to `awsvpc`. Other network modes are not supported.
3. Configure a
[task execution IAM role](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html).
If the image registry is an Elastic Container Registry (ECR) this role should
have permissions to pull images from it.

### Configuring the Workload Onboarding Agent sidecar

Add the Workload Onboarding Agent container to your Task Definition
alongside your application container with the following steps.

The container image will have been added to the container registry used when
installing Tetrate Service Bridge into your Kubernetes cluster(s). To use a
different container registry, sync the images to it by
[following these instructions](../../requirements-and-download#sync-tetrate-service-bridge-images).

1. Container name: `onboarding-agent`
2. Image: `<your docker registry>/onboarding-agent:<tag>`

   This should match the image registry and tag used by the other TSB images in
   your cluster, you can find the correct image by first extracting the image
   using `kubectl`:

   ```bash{promptUser: "alice"}
   kubectl get deploy -n istio-system onboarding-plane -o jsonpath="{.spec.template.spec.containers[0].image}"
   ```

   This will return an image such as:
   ```
   123456789012.dkr.ecr.us-east-1.amazonaws.com/registry/onboarding-plane-server:1.5.0
   ```

   The corresponding Workload Onboarding Agent image will be:
   ```
   123456789012.dkr.ecr.us-east-1.amazonaws.com/registry/onboarding-agent:1.5.0
   ```
3. The user must be set to the root user by using a UID of `0`.
4. Provide the
   [onboarding configuration](../../../refs/onboarding/config/agent/v1alpha1/onboarding_configuration).

   Set an environment variable `ONBOARDING_CONFIG` with the following contents.
   Replace `onboarding-endpoint-dns-name` with the Workload Onboarding Endpoint
   to connect to, as well as `workload-group-namespace` and `workload-group-name`
   with the namespace and name of the Istio
   [WorkloadGroup](https://istio.io/latest/docs/reference/config/networking/workload-group/)
   to join to.

   ```yaml
   apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
   kind: OnboardingConfiguration
   onboardingEndpoint:
     host: <onboarding-endpoint-dns-name>
   workloadGroup:
     namespace: <workload-group-namespace>
     name: <workload-group-name>
   ```

   The Workload Onboarding Endpoint is assumed to be available at
   `https://<onboarding-endpoint-dns-name>:15443`, and that it uses a TLS
   certificate issued for the appropriate DNS name. For more configuration
   options, please refer to
   [onboarding configuration](../../../refs/onboarding/config/agent/v1alpha1/onboarding_configuration)
   documentation.

   It may be easier to specify the configuration as JSON instead of YAML so
   that it does not need to include line breaks. In that case the above
   configuration will take the form:

   ```json
   {
     "apiVersion": "config.agent.onboarding.tetrate.io/v1alpha1",
     "kind": "OnboardingConfiguration",
     "onboardingEndpoint": {
       "host": "<onboarding-endpoint-dns-name>"
     },
     "workloadGroup": {
       "namespace": "<workload-group-namespace>",
       "name": "<workload-group-name>"
     }
   }
   ```
5. If the certificate authority (CA) used to sign the Workload Onboarding
   Endpoint TLS certificate is self-signed, i.e. is not issued by a public
   root CA such as Let's Encrypt or Digicert, the public root certificate must
   be provided.

   Set an environment variable `ONBOARDING_AGENT_ROOT_CERTS` with the content
   of the root certificate authority PEM file. This should be of the form:

   ```
   -----BEGIN CERTIFICATE-----
   MIIC...
   -----END CERTIFICATE-----
      ```

   Note that this environment variable cannot be configured via the AWS
   console as it replaces the newlines. Instead, it should be configured by the
   AWS CLI tool or an infrastructure as code tool such as Terraform or
   CloudFormation.
6. Provide the
   [agent configuration](../../../refs/onboarding/config/agent/v1alpha1/agent_configuration)
   if required. This step is optional as the default values will work in most
   cases.

   This step is required if TSB is installed with
   [Istio Isolation Boundaries](../../../setup/isolation-boundaries)
   enabled, and the workload should connect to a non-default revision. As an
   example, to configure a workload to connect to the `canary` revision, set
   an environment variable `AGENT_CONFIG` with the following content:

   ```yaml
   apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
   kind: AgentConfiguration
   sidecar:
     istio:
       revision: canary
   ```

   It may be easier to specify the configuration as JSON instead of YAML so
   that it does not need to include line breaks. In that case the above
   configuration will take the form:

   ```json
   {
     "apiVersion": "config.agent.onboarding.tetrate.io/v1alpha1",
     "kind": "AgentConfiguration",
     "sidecar": {
       "istio": {
         "revision": "canary"
       }
     }
   }
   ```

### Example task definition

An example command for creating a task definition is as follows:

```bash{promptUser: "alice"}
# Compact and escape quotes in the onboarding config for encoding in the JSON container definition
ONBOARDING_CONFIG=$(jq --compact-output . <<'EOF' | sed 's/"/\\"/g'
{
  "apiVersion": "config.agent.onboarding.tetrate.io/v1alpha1",
  "kind": "OnboardingConfiguration",
  "onboardingEndpoint": {
    "host": "abcdef-123456789.us-east-1.elb.amazonaws.com",
  },
  "workload": {
    "labels": {
      "version": "v5"
    }
  },
  "workloadGroup": {
    "name": "app",
    "namespace": "app-namespace"
  }
}
EOF
)

# Replace line breaks in the root cert PEM with \n for encoding in the JSON container definition
ONBOARDING_AGENT_ROOT_CERTS=$(awk '{printf "%s\\n", $0}' root-ca-cert.pem)

aws ecs register-task-definition \
  --task-role-arn="arn:aws:iam::123456789012:role/app-task" \
  --execution-role-arn="arn:aws:iam::123456789012:role/ecsTaskExecutionRole" \
  --family="app" \
  --network-mode="awsvpc" \
  --cpu=256 \
  --memory=512 \
  --requires-compatibilities FARGATE EC2 \
  --container-definitions='[
  {
    "name": "onboarding-agent",
    "image": "123456789012.dkr.ecr.us-east-1.amazonaws.com/registry/onboarding-agent:1.5.0",
    "user": "0",
    "environment": [
      {
        "name": "ONBOARDING_CONFIG",
        "value": "'"${ONBOARDING_CONFIG}"'"
      },
      {
        "name": "ONBOARDING_AGENT_ROOT_CERTS",
        "value": "'"${ONBOARDING_AGENT_ROOT_CERTS}"'"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/app",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "ecs"
      }
    }
  },
  {
    "name": "app",
    "image": "123456789012.dkr.ecr.us-east-1.amazonaws.com/registry/app:1.2.3",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/app",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]'
```

## Using an internal load balancer

In the default configuration, the Workload Onboarding Plane in your EKS
cluster uses an internet-facing load balancer. This means that traffic from
the Onboarding Agent and Istio will not stay within your VPC.

If all your onboarded workloads are within the same VPC or peered VPCs, it is
recommended to use an internal load balancer by setting the
[`service.beta.kubernetes.io/aws-load-balancer-scheme` annotation](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/guide/service/annotations/#lb-scheme).
This means that all traffic will stay internal to your VPC(s). You can do this
by adding an overlay in the `ControlPlane` CR or Helm values of the form:

```yaml
spec:
  components:
    istio:
      kubeSpec:
        overlays:
        - apiVersion: install.istio.io/v1alpha1
          kind: IstioOperator
          name: tsb-istiocontrolplane
          patches:
          - path: spec.components.ingressGateways.[name:vmgateway].k8s.serviceAnnotations
            value:
              service.beta.kubernetes.io/aws-load-balancer-scheme: "internal"
```

If there are no other overlays, this can be applied using the following command:

```bash{promptUser: "alice"}
kubectl patch -n istio-system controlplane/controlplane --type json --patch '
- op: add
  path: "/spec/components/istio/kubeSpec/overlays"
  value:
    - apiVersion: install.istio.io/v1alpha1
      kind: IstioOperator
      name: tsb-istiocontrolplane
      patches:
      - path: spec.components.ingressGateways.[name:vmgateway].k8s.serviceAnnotations
        value:
          service.beta.kubernetes.io/aws-load-balancer-scheme: "internal"
'
```

After making this change, you should see the Workload Onboarding Endpoint
address update to be of the form
`internal-abcxyz.us-east-1.elb.amazonaws.com`. You can query this address
using the following command:

```bash{promptUser: "alice"}
kubectl get svc vmgateway \
  -n istio-system \
  -ojsonpath="{.status.loadBalancer.ingress[0]['hostname', 'ip']}"
```

Once the internal load balancer address has been assigned, ensure the
`onboardingEndpoint` field in your
[onboarding configuration](../../../refs/onboarding/config/agent/v1alpha1/onboarding_configuration)
uses the new value.
