---
title: 载入 AWS ECS 工作负载
weight: 7
---

该文档描述了如何使用工作负载载入功能将 AWS Elastic Container Service (ECS) 任务载入到 TSB。

在继续之前，请确保你已完成 [设置工作负载载入文档](./setup) 中描述的步骤。如果你不计划载入虚拟机，可以跳过配置本地仓库和安装软件包的步骤，因为 ECS 任务的流程略有不同。

## 背景

通过工作负载载入将工作负载引入 mesh 的每个工作负载都必须具有可验证的身份。对于 AWS ECS 任务，使用 [任务 IAM 角色](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html) 来标识尝试加入 mesh 的任务。

Onboarding Agent 容器作为 AWS ECS 任务中的边车与工作负载容器一起运行。在启动时，Onboarding Agent 与 AWS ECS 环境交互，获取与任务的 IAM 角色关联的凭据，并使用这些凭据与 Workload Onboarding Plane 进行身份验证。

## 概述

与虚拟机工作负载相比，AWS ECS 工作负载的工作负载载入设置包括以下额外步骤：

1. 允许 AWS ECS 任务加入 WorkloadGroup
2. 配置 AWS ECS 任务定义，包括 IAM 角色和运行 Workload Onboarding Agent 作为边车

## 允许 AWS ECS 任务加入 WorkloadGroup

要允许本地工作负载加入特定的 WorkloadGroup，请创建一个 [OnboardingPolicy](../../../refs/onboarding/config/authorization/v1alpha1/policy)，并设置 `ecs` 字段。

### 示例

以下示例允许与给定 AWS 帐户关联的任何以 AWS ECS 任务形式运行的工作负载，可以加入给定 Kubernetes 命名空间中的任何可用 WorkloadGroup：

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
        ecs: {}                 # 以上述帐户的任何 AWS ECS 任务
    onboardTo:
    - workloadGroupSelector: {} # 该命名空间中的任何 WorkloadGroup
```

虽然前面的示例可能是一个相对“宽松”的策略，但更严格的载入策略可能只允许以特定 AWS 区域和/或区域、特定 AWS ECS 集群、特定 AWS IAM 角色等运行的 AWS ECS 任务。它还可能只允许工作负载加入特定的 WorkloadGroup 子集。

以下是更为严格策略的示例：

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
          - <IAM role name>     # 上述分区/帐户/区域/区域中特定 ECS 集群中与 IAM 角色列表中的一个关联的任何 AWS ECS 任务
    onboardTo:
    - workloadGroupSelector:
        matchLabels:
          app: ratings
```

## 创建任务定义

1. 配置 [任务 IAM 角色](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html)。这是任务将用于加入 mesh 的身份。
2. 将网络模式设置为 `awsvpc`。不支持其他网络模式。
3. 配置 [任务执行 IAM 角色](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html)。如果镜像仓库是 Elastic Container Registry (ECR)，则此角色应具有从中拉取图像的权限。

### 配置 Workload Onboarding Agent Sidecar

按照以下步骤将 Workload Onboarding Agent 容器添加到任务定义中，与应用程序容器一起。

该容器映像将添加到安装 Tetrate Service Bridge 到你的 Kubernetes 集群时使用的容器仓库中。要使用不同的容器仓库，请通过 [按照这些说明同步 Tetrate Service Bridge 镜像](../../../requirements-and-download#sync-tetrate-service-bridge-images)。

1. 容器名称：`onboarding-agent`
2. 映像：`<your docker registry>/onboarding-agent:<tag>`

   这应该与集群中其他 TSB 映像使用的映像仓库和标签匹配，你可以通过首先使用 `kubectl` 提取映像来找到正确的映像：

```bash
   kubectl get deploy -n istio-system onboarding-plane -o jsonpath="{.spec.template.spec.containers[0].image}"
```

   这将返回一个映像，例如：
   ```
   123456789012.dkr.ecr.us-east-1.amazonaws.com/registry/onboarding-plane-server:1.5.0
   ```

   相应的 Workload Onboarding Agent 映像将是：
   ```
   123456789012.dkr.ecr.us-east-1.amazonaws.com/registry/onboarding-agent:1.5.0
   ```
3. 用户必须设置为 root 用户，使用 UID 为 `0`。
4. 提供 [载入配置](../../../../refs/onboarding/config/agent/v1alpha1/onboarding_configuration)。

   使用以下内容设置一个名为 `ONBOARDING_CONFIG` 的环境变量。将其中的 `onboarding-endpoint-d

ns-name` 替换为要连接的 Workload Onboarding Endpoint，`workload-group-namespace` 和 `workload-group-name` 替换为 Istio [WorkloadGroup](https://istio.io/latest/docs/reference/config/networking/workload-group/) 的命名空间和名称。

   ```yaml
   apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
   kind: OnboardingConfiguration
   onboardingEndpoint:
     host: <onboarding-endpoint-dns-name>
   workloadGroup:
     namespace: <workload-group-namespace>
     name: <workload-group-name>
   ```

   假定 Workload Onboarding Endpoint 可以在 `https://<onboarding-endpoint-dns-name>:15443` 上访问，并且使用为适当的 DNS 名称颁发的 TLS 证书。有关更多配置选项，请参考 [载入配置](../../../../refs/onboarding/config/agent/v1alpha1/onboarding_configuration) 文档。

   为了不包含换行符，可能更容易将配置指定为 JSON 而不是 YAML。在这种情况下，上述配置将采用以下形式：

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
5. 如果用于签署 Workload Onboarding Endpoint TLS 证书的证书颁发机构 (CA) 是自签名的，即未由公共根 CA（如 Let's Encrypt 或 Digicert）颁发，则必须提供公共根证书。

   使用根证书颁发机构 PEM 文件的内容设置一个名为 `ONBOARDING_AGENT_ROOT_CERTS` 的环境变量。这应该是以下形式：

   ```
   -----BEGIN CERTIFICATE-----
   MIIC...
   -----END CERTIFICATE-----
   ```

   请注意，此环境变量不能通过 AWS 控制台配置，因为它会替换换行符。相反，应使用 AWS CLI 工具或基础架构即代码工具（例如 Terraform 或 CloudFormation）进行配置。
6. 如果需要，提供 [代理配置](../../../../refs/onboarding/config/agent/v1alpha1/agent_configuration)。在大多数情况下，默认值将起作用，此步骤是可选的。

   如果使用 [Istio 隔离边界](../../../../setup/isolation-boundaries) 安装 TSB，并且工作负载应连接到非默认修订版本，则需要此步骤。例如，要配置工作负载连接到 `canary` 修订版，设置一个名为 `AGENT_CONFIG` 的环境变量，其内容如下：

   ```yaml
   apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
   kind: AgentConfiguration
   sidecar:
     istio:
       revision: canary
   ```

   为了不包含换行符，可能更容易将配置指定为 JSON 而不是 YAML。在这种情况下，上述配置将采用以下形式：

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
### 示例任务定义

创建任务定义的示例命令如下：

```bash
# 在 JSON 容器定义中压缩并转义 onboarding 配置中的引号
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

# 在 JSON 容器定义中替换根证书 PEM 中的换行符，以进行编码
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

## 使用内部负载均衡器

在默认配置中，你的 EKS 集群中的工作负载载入平面使用的是面向互联网的负载均衡器。这意味着来自载入代理和 Istio 的流量不会保留在你的 VPC 内。

如果所有已载入的工作负载都在同一个 VPC 或对等 VPC 中，建议通过设置 [`service.beta.kubernetes.io/aws-load-balancer-scheme` 注解](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/guide/service/annotations/#lb-scheme)来使用内部负载均衡器。这意味着所有流量都将保留在你的 VPC 内。你可以通过在 `ControlPlane` CR 或 Helm values 中添加以下形式的叠加来实现：

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

如果没有其他叠加，可以使用以下命令应用此更改：

```bash
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

进行此更改后，你应该看到工作负载载入终端地址更新为类似于 `internal-abcxyz.us-east-1.elb.amazonaws.com` 的形式。你可以使用以下命令查询此地址：

```bash
kubectl get svc vmgateway \
  -n istio-system \
  -ojsonpath="{.status.loadBalancer.ingress[0]['hostname', 'ip']}"
```

在分配了内部负载均衡器地址后，请确保你的[载入配置](../../../../refs/onboarding/config/agent/v1alpha1/onboarding-configuration)中的 `onboardingEndpoint` 字段使用新值。
