---
title: 加入 AWS ECS 任务
weight: 2
---

## 概述

要将 AWS 弹性容器服务（ECS）任务加入，你需要按照以下步骤操作：

1. 创建 [AWS ECS 集群](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/clusters.html)
1. 创建[任务的 IAM 角色](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html)
1. 创建[任务执行 IAM 角色](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html)
1. 创建一个包含 Workload Onboarding Agent 作为 sidecar 容器的 [AWS ECS 任务定义](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html)
1. 创建任务的子网
1. 创建安全组
1. 使用此任务定义创建 [AWS ECS 服务](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html)

## 创建 AWS ECS 集群

使用 `FARGATE` 作为容量提供程序创建名为 `bookinfo` 的 AWS ECS 集群。

```bash
aws ecs create-cluster --cluster-name bookinfo --capacity-providers FARGATE
```

## 为任务创建 IAM 角色

创建任务的 IAM 角色，并使用以下信任策略。

```bash
cat << EOF > task-role-trust-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role \
  --role-name bookinfoECSTaskRole \
  --assume-role-policy-document file://task-role-trust-policy.json
```

使用以下策略配置此角色，以允许
[ECS Exec](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-exec.html)。
这不是任务加入网格所必需的，但在后续的指南中用于验证任务到 Kubernetes 服务的流量。

```bash
cat << EOF > ecs-exec-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name bookinfoECSTaskRole \
  --policy-name bookinfoECSExecPolicy \
  --policy-document file://ecs-exec-policy.json
```

## 创建任务执行 IAM 角色

创建任务执行 IAM 角色，并使用以下信任策略，并配置使用 AWS 托管的 `AmazonECSTaskExecutionRolePolicy` 策略。此策略授予任务访问 Elastic Container Registry（ECR）中的镜像和写日志的权限。

```bash
cat << EOF > task-exec-role-trust-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role \
  --role-name bookinfoECSTaskExecRole \
  --assume-role-policy-document file://task-exec-role-trust-policy.json

aws iam attach-role-policy \
  --role-name bookinfoECSTaskExecRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
```

## 创建 AWS ECS 任务定义

将 Onboarding 配置设置为 JSON 形式的 shell 变量，去除空格并转义引号，以便可以编码在 ECS 任务容器定义中。将 `<ONBOARDING_ENDPOINT_ADDRESS>` 替换为你之前获取的值。

```bash
ONBOARDING_CONFIG=$(jq --compact-output . <<'EOF' | sed 's/"/\\"/g'
{
  "apiVersion": "config.agent.onboarding.tetrate.io/v1alpha1",
  "kind": "OnboardingConfiguration",
  "onboardingEndpoint": {
    "host": "<ONBOARDING_ENDPOINT_ADDRESS>",
    "transportSecurity": {
      "tls": {
        "sni": "onboarding-endpoint.example"
      }
    }
  },
  "workload": {
    "labels": {
      "version": "v5"
    }
  },
  "workloadGroup": {
    "name": "ratings",
    "namespace": "bookinfo"
  }
}
EOF


)
```

将用于签名 Onboarding 平面 TLS 证书的自签名根证书设置为 shell 变量，并转义换行符，以便可以编码在 ECS 任务容器定义中。`example-ca.crt.pem` 是在[启用工作负载加入](../../aws-ec2/enable-workload-onboarding)时创建的自签名证书。

```bash
ONBOARDING_AGENT_ROOT_CERTS=$(awk '{printf "%s\\n", $0}' example-ca.crt.pem)
```

现在，使用以下命令创建 ECS 任务定义：

```bash
AWS_REGION=$(aws configure get region)
TASK_ROLE_ARN=$(aws iam get-role --role-name bookinfoECSTaskRole --query 'Role.Arn' --output text)
TASK_EXECUTION_ROLE_ARN=$(aws iam get-role --role-name bookinfoECSTaskExecRole --query 'Role.Arn' --output text)
ONBOARDING_AGENT_IMAGE=$(kubectl get deploy onboarding-operator -n istio-system -ojsonpath='{.spec.template.spec.containers[?(@.name=="onboarding-operator")].image}' | sed 's|/onboarding-operator-server:|/onboarding-agent:|')

aws ecs register-task-definition \
  --task-role-arn="${TASK_ROLE_ARN}" \
  --execution-role-arn="${TASK_EXECUTION_ROLE_ARN}" \
  --family="bookinfo_ratings" \
  --network-mode="awsvpc" \
  --cpu=256 \
  --memory=512 \
  --requires-compatibilities FARGATE \
  --container-definitions='[
   {
       "name": "onboarding-agent",
       "image": "'"${ONBOARDING_AGENT_IMAGE}"'",
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
               "awslogs-group": "/ecs/bookinfo_ratings",
               "awslogs-region": "'"${AWS_REGION}"'",
               "awslogs-stream-prefix": "ecs"
           }
       }
   },
   {
       "name": "ratings",
       "image": "docker.io/tetrate/tetrate-examples-bookinfo-ratings-localhost-v1:1.16.4",
       "essential": true,
       "logConfiguration": {
           "logDriver": "awslogs",
           "options": {
               "awslogs-group": "/ecs/bookinfo_ratings",
               "awslogs-region": "'"${AWS_REGION}"'",
               "awslogs-stream-prefix": "ecs"
           }
       }
   }
]'
```

这将配置任务使用 [awslogs 驱动程序](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using_awslogs.html)将日志写入 `/ecs/bookinfo_ratings` 日志组。使用以下命令创建此日志组：

```bash
aws logs create-log-group --log-group-name "/ecs/bookinfo_ratings"
```

## 创建子网

### 确保 VPC 中存在 NAT 网关

通过运行以下命令，确保 VPC 中存在 NAT 网关，将 `EKS_CLUSTER_NAME` 替换为你的 EKS 集群名称。

```bash
VPC_ID=$(aws eks describe-cluster --name <EKS_CLUSTER_NAME> --query 'cluster.resourcesVpcConfig.vpcId' --output text)

aws ec2 describe-nat-gateways --filter Name=vpc-id,Values=${VPC_ID}
```

如果返回的列表为空，请使用以下命令创建具有 NAT 网关的公共子网，并将 NAT 网关替换为上面找到或创建的 NAT 网关，使用以下命令，将 CIDR 块替换为用于子网的所需 CIDR 块，例如 `10.0.3.0/24`。

```bash
INTERNET_GATEWAY_ID=$(aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=${VPC_ID} --query 'InternetGateways[0].InternetGatewayId' --output text)

aws ec2 create-subnet \
  --vpc-id "${VPC_ID}" \
  --cidr-block <CIDR_BLOCK> \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=bookinfo-ecs-nat-gw-subnet}]'

NAT_GW_SUBNET_ID=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=bookinfo-ecs-nat-gw-subnet --query 'Subnets[0].SubnetId' --output text)

aws ec2 create-route-table \
  --vpc-id "${VPC_ID}" \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=bookinfo-ecs-nat-gw-rtb}]'

NAT_GW_ROUTE_TABLE_ID=$(aws ec2 describe-route-tables --filters Name=tag:Name,Values=bookinfo-ecs-nat-gw-rtb --query 'RouteTables[0].RouteTableId' --output text)

aws ec2 create-route \
  --route-table-id "${NAT_GW_ROUTE_TABLE_ID}" \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id "${INTERNET_GATEWAY_ID}"

aws ec2 associate-route-table \
  --route-table-id "${NAT_GW_ROUTE_TABLE_ID}" \
  --subnet-id "${NAT_GW_SUBNET_ID}"

aws ec2 allocate-address \
  --tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Name,Value=bookinfo-ecs-nat-gw-ip}]'

NAT_GW_EIP_ID=$(aws ec2 describe-addresses --filters Name=tag:Name,Values=bookinfo-ecs-nat-gw-ip --query 'Addresses[0].AllocationId' --output text)

aws ec2 create-nat-gateway \
  --subnet-id "${NAT_GW_SUBNET_ID}" \
  --allocation-id "${NAT_GW_EIP_ID}"
```

创建 ECS 任务的子网

如果你已经配置了一个带有 NAT 网关的私有子网，并希望将其用于部署任务，请将其 ID 设置为 shell 变量 `SUBNET_ID`，如下所示：

```bash
SUBNET_ID=<YOUR_SUBNET_ID>
```

否则，使用以下命令创建一个子网，使用上面找到或创建的 NAT 网关，替换 `CIDR_BLOCK` 为所需的子网 CIDR 块，例如 `10.0.4.0/24`。

```bash
NAT_GATEWAY_ID=$(aws ec2 describe-nat-gateways --filter Name=vpc-id,Values=${VPC_ID} --query 'NatGateways[0].NatGatewayId' --output text)

aws ec2 create-subnet \
  --vpc-id "${VPC_ID}" \
  --cidr-block <CIDR_BLOCK> \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=bookinfo-ecs-subnet}]'

SUBNET_ID=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=bookinfo-ecs-subnet --query 'Subnets[0].SubnetId' --output text)

aws ec2 create-route-table \
  --vpc-id "${VPC_ID}" \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=bookinfo-ecs-rtb}]'

ROUTE_TABLE_ID=$(aws ec2 describe-route-tables --filters Name=tag:Name,Values=bookinfo-ecs-rtb --query 'RouteTables[0].RouteTableId' --output text)

aws ec2 create-route \
  --route-table-id "${ROUTE_TABLE_ID}" \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id "${NAT_GATEWAY_ID}"

aws ec2 associate-route-table \
  --route-table-id "${ROUTE_TABLE_ID}" \
  --subnet-id "${SUBNET_ID}"
```

## 创建安全组

需要创建一个安全组，并设置一个允许入站流量到端口 9080 的规则，以供 Istio 使用。使用以下命令创建一个安全组：

```bash
aws ec2 create-security-group \
  --group-name BookinfoECSSecurityGroup \
  --description "Security group for ECS onboarding quickstart bookinfo tasks" \
  --vpc-id "${VPC_ID}"

SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=${VPC_ID} Name=group-name,Values=BookinfoECSSecurityGroup --query "SecurityGroups[0].GroupId" --output text)

aws ec2 authorize-security-group-ingress \
    --group-id "${SECURITY_GROUP_ID}" \
    --protocol tcp \
    --port 9080 \
    --cidr 0.0.0.0/0
```

## 创建 AWS ECS 服务

在集群中创建一个 AWS ECS 服务，该服务使用任务定义、子网和安全组，使用以下命令。如果创建了多个任务定义版本，请在 `--task-definition` 标志中传递所需的版本。

```bash
aws ecs create-service \
  --cluster bookinfo \
  --service-name ratings \
  --task-definition bookinfo_ratings:1 \
  --desired-count 1 \
  --launch-type FARGATE \
  --platform-version LATEST \
  --network-configuration "awsvpcConfiguration={subnets=[${SUBNET_ID}],securityGroups=[${SECURITY_GROUP_ID}]}" \
  --enable-execute-command
```

创建此服务后，将创建一个 ECS 任务，该任务将加入网格。

## 验证工作负载

通过执行以下命令验证工作负载是否已正确加入：

```bash
kubectl get war -n bookinfo
```

如果工作负载已正确加入，你应该会得到类似以下的输出：

```bash
NAME                                                                                    AGENT CONNECTED   AGE
ratings-aws-aws-123456789012-us-east-1a-ecs-bookinfo-3a151358f03a4e32bf8cd401c1c74653   True              1m
```

### 验证从 Kubernetes 到任务的流量

要验证从 Kubernetes Pod 到 AWS ECS 任务的流量，请对 Kubernetes 上部署的 Bookinfo 应用程序创建一些负载，并确认请求被路由到 AWS ECS 任务上部署的 `ratings` 应用程序。

[如果尚未完成，请设置端口转发](../../aws-ec2/bookinfo)。

然后运行以下命令：

```bash
for i in `seq 1 9`; do
    curl -s "http://localhost:9080/productpage?u=normal" | grep -c "glyphicon-star" | awk '{print $1" stars on the page"}'
done
```

其中的两次之中，你应该会得到消息 `10 stars on the page`。

此外，你可以通过检查 Istio sidecar 代理代理的入站 HTTP 请求的
[访问日志](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage)来验证任务是否正在接收流量。

使用可以在[此处下载和安装的 ecs-cli 工具](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_installation.html)执行以下命令：

```bash
# 从 WorkloadAutoRegistration 资源获取任务 ID
TASK_ID=$(kubectl get war -n bookinfo -o jsonpath="{.items[0].spec.identity.aws.ecs.taskId}")

ecs-cli logs --cluster bookinfo --task-id ${TASK_ID} --container-name onboarding-agent --follow
```

你应该会看到类似以下的输出：

```text
[2021-10-25T11:06:13.553Z] "GET /ratings/0 HTTP/1.1" 200 - via_upstream - "-" 0 48 3 2 "-" "curl/7.68.0" "1928e798-dfe7-45a6-9020-d0f3a8641d03" "172.31.7.211:9080" "127.0.0.1:9080" inbound|9080|| 127.0.0.1:40992 172.31.7.211:9080 172.31.7.211:35470 - default
```

### 验证从任务到 Kubernetes 的流量

通过运行以下命令，在任务中启动一个 shell：

```bash
# 从 WorkloadAutoRegistration 资源获取任务 ID
TASK_ID=$(kubectl get war -n bookinfo -o jsonpath="{.items[

0].spec.identity.aws.ecs.taskId}")

# 启动一个 shell
aws ecs execute-command --cluster bookinfo --task ${TASK_ID} --container onboarding-agent --interactive --command bash
```

然后执行以下命令：

```bash
for i in `seq 1 5`; do
  curl -i \
    --resolve details.bookinfo:9080:127.0.0.2 \
    details.bookinfo:9080/details/0
done
```

上述命令将发出 `5` 个 HTTP 请求到 Bookinfo `details` 应用程序。
`curl` 将 Kubernetes 集群本地 DNS 名称 `details.bookinfo`
解析为 Istio 代理的 `egress` 监听器的 IP 地址（根据你之前创建的
 [Sidecar 配置](../configure-workload-onboarding)为 `127.0.0.2`）。

你应该会得到类似以下的输出：

```bash
HTTP/1.1 200 OK
content-type: application/json
server: envoy

{"id":0,"author":"William Shakespeare","year":1595,"type":"paperback",   "pages":200,"publisher":"PublisherA","language":"English",   "ISBN-10":"1234567890","ISBN-13":"123-1234567890"}
```

如果返回 HTTP 503 错误，请确保你的 EKS 集群的安全组设置允许来自这里创建的 ECS 任务使用的 `BookinfoECSSecurityGroup` 的端口 9080 的流量。