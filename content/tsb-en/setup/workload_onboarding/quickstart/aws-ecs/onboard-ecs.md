---
title: Onboard AWS ECS task
---

## Overview

To onboard an AWS Elastic Container Service (ECS) task you need to follow
these steps:

1. Create an
   [AWS ECS cluster](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/clusters.html)
1. Create an
   [IAM role for the task](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html)
1. Create a
   [task execution IAM role](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html)
1. Create an
   [AWS ECS task definition](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html)
   with the Workload Onboarding Agent as a sidecar container
1. Create a subnet for the tasks
1. Create a security group
1. Create an
   [AWS ECS service](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html)
   with this task definition

## Create an AWS ECS cluster

Create an AWS ECS cluster called `bookinfo` using `FARGATE` as the capacity
provider.

```bash{promptUser: "alice"}
aws ecs create-cluster --cluster-name bookinfo --capacity-providers FARGATE
```

## Create an IAM role for the task

Create an IAM role for the task with the following trust policy.

```bash{promptUser: "alice"}
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

Configure this role with the following policy to allow
[ECS Exec](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-exec.html).
This is not required for the task to join the mesh, but is used later in the
guide to verify traffic from the task to Kubernetes services.

```bash{promptUser: "alice"}
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

## Create a task execution IAM role

Create a task execution IAM role with the following trust policy and configure
it to use the AWS managed `AmazonECSTaskExecutionRolePolicy` policy. This
policy gives the task permissions to access images in your Elastic Container
Registry (ECR) and to write logs.

```bash{promptUser: "alice"}
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

## Create an AWS ECS task definition

Set the onboarding configuration as JSON in a shell variable, with spaces
removed and quotes escaped so that it can be encoded in the ECS task container
definition. Replace `ONBOARDING_ENDPOINT_ADDRESS` with
[the value that you have obtained earlier](../aws-ec2/enable-workload-onboarding#verify-the-workload-onboarding-endpoint).

```bash{promptUser: "alice"}
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

Set the self-signed root certificate used for signing the onboarding plane TLS
certificate in a shell variable, with the line breaks escaped so that it can
be encoded in the ECS task container definition. `example-ca.crt.pem` is the
self-signed cert created earlier when
[enabling workload onboarding](../aws-ec2/enable-workload-onboarding#prepare-the-certificates).

```bash{promptUser: "alice"}
ONBOARDING_AGENT_ROOT_CERTS=$(awk '{printf "%s\\n", $0}' example-ca.crt.pem)
```

Now create the ECS task definition with the following command:

```bash{promptUser: "alice"}
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

This configures the task to write logs using the
[awslogs driver](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using_awslogs.html)
to the `/ecs/bookinfo_ratings` log group. Create this group with the following
command:

```bash{promptUser: "alice"}
aws logs create-log-group --log-group-name "/ecs/bookinfo_ratings"
```

## Create a subnet

### Ensure that there is a NAT gateway in your VPC

Ensure that there is a NAT gateway in your VPC by running commands below,
replacing `EKS_CLUSTER_NAME` with the name of your EKS cluster.

```bash{promptUser: "alice"}
VPC_ID=$(aws eks describe-cluster --name <EKS_CLUSTER_NAME> --query 'cluster.resourcesVpcConfig.vpcId' --output text)

aws ec2 describe-nat-gateways --filter Name=vpc-id,Values=${VPC_ID}
```

If the returned list is empty, create a public subnet and NAT gateway using
the commands below, replacing `CIDR_BLOCK` with the desired CIDR block to use
for the subnet, e.g. `10.0.3.0/24`.

```bash{promptUser: "alice"}
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

### Create a subnet for the ECS tasks

If you already have a private subnet configured with a NAT gateway that you
want to use for deploying tasks, set its ID in the shell variable `SUBNET_ID`,
i.e.

```bash{promptUser: "alice"}
SUBNET_ID=<YOUR_SUBNET_ID>
```

Otherwise, create a subnet using the NAT gateway found or created above using
the commands below, replacing `CIDR_BLOCK` with the desired CIDR block to use
for the subnet, e.g. `10.0.4.0/24`.

```bash{promptUser: "alice"}
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

## Create a security group

A security group is needed with a rule allowing ingress traffic to port 9080
for Istio to use. Create one using the commands below:

```bash{promptUser: "alice"}
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

## Create an AWS ECS service

Create an AWS ECS service in your cluster that uses the task definition,
subnet and security group using the following command. If you created
multiple task definition versions, update the version passed in the
`--task-definition` flag.

```bash{promptUser: "alice"}
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

Once you create this service, it will create an ECS task that will join the
mesh.

## Verify the Workload

Verify that the workload has been properly onboarded by executing the
following command:

```bash{promptUser: "alice"}
kubectl get war -n bookinfo
```

If the workload was properly onboarded, you should get an output similar to:

```bash{promptUser: "alice"}
NAME                                                                                    AGENT CONNECTED   AGE
ratings-aws-aws-123456789012-us-east-1a-ecs-bookinfo-3a151358f03a4e32bf8cd401c1c74653   True              1m
```

### Verify Traffic from Kubernetes to the task

To verify traffic from Kubernetes Pod(s) to the AWS ECS task, create
some load on the bookinfo application deployed on Kubernetes and confirm
that requests get routed into the `ratings` application deployed on the
AWS ECS task.

[Set up port forwarding](../aws-ec2/bookinfo) if you have not already done so.

Then run the following commands:

```bash{promptUser: "alice"}
for i in `seq 1 9`; do
    curl -s "http://localhost:9080/productpage?u=normal" | grep -c "glyphicon-star" | awk '{print $1" stars on the page"}'
done
```

Two out of three times you should get a message `10 stars on the page`.

Furthermore, you can verify that the task is receiving the traffic by
inspecting the
[access logs](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage)
for the incoming HTTP requests proxied by the Istio sidecar.

Execute the following command using the `ecs-cli` tool that can be
[downloaded and installed here](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_installation.html):

```bash{promptUser: "alice"}
# Get the task ID from the WorkloadAutoRegistration resource
TASK_ID=$(kubectl get war -n bookinfo -o jsonpath="{.items[0].spec.identity.aws.ecs.taskId}")

ecs-cli logs --cluster bookinfo --task-id ${TASK_ID} --container-name onboarding-agent --follow
```

You should see an output similar to:

```text
[2021-10-25T11:06:13.553Z] "GET /ratings/0 HTTP/1.1" 200 - via_upstream - "-" 0 48 3 2 "-" "curl/7.68.0" "1928e798-dfe7-45a6-9020-d0f3a8641d03" "172.31.7.211:9080" "127.0.0.1:9080" inbound|9080|| 127.0.0.1:40992 172.31.7.211:9080 172.31.7.211:35470 - default
```

### Verify Traffic from the task to Kubernetes

Start a shell in the task by running the following commands:

```bash{promptUser: "alice"}
# Get the task ID from the WorkloadAutoRegistration resource
TASK_ID=$(kubectl get war -n bookinfo -o jsonpath="{.items[0].spec.identity.aws.ecs.taskId}")

# Start a shell
aws ecs execute-command --cluster bookinfo --task ${TASK_ID} --container onboarding-agent --interactive --command bash
```

Then execute the following commands:

```bash{promptUser: "alice"}
for i in `seq 1 5`; do
  curl -i \
    --resolve details.bookinfo:9080:127.0.0.2 \
    details.bookinfo:9080/details/0
done
```

The above command will make `5` HTTP requests to Bookinfo `details` application.
`curl` will resolve Kubernetes cluster-local DNS name `details.bookinfo`
into the IP address of the `egress` listener of Istio proxy (`127.0.0.2` according
to [the sidecar configuration you created earlier](./configure-workload-onboarding#create-the-sidecar-configuration)).

You should get an output similar to:

```bash{promptUser: "alice"}
HTTP/1.1 200 OK
content-type: application/json
server: envoy

{"id":0,"author":"William Shakespeare","year":1595,"type":"paperback",   "pages":200,"publisher":"PublisherA","language":"English",   "ISBN-10":"1234567890","ISBN-13":"123-1234567890"}
```

If this returns an HTTP 503 error, ensure the security group for your EKS
cluster is set to allow traffic on port 9080 from the
`BookinfoECSSecurityGroup` that the ECS tasks created here use.
