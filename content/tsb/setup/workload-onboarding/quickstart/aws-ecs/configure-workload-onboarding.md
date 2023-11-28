---
title: 配置 AWS ECS 工作负载的 WorkloadGroup 和 Sidecar
weight: 1
---

你将部署 `ratings` 应用程序作为 AWS ECS 任务，并将其加入服务网格。

## 创建 WorkloadGroup

执行以下命令创建一个 `WorkloadGroup`：

```shell
cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadGroup
metadata:
  name: ratings
  namespace: bookinfo
  labels:
    app: ratings
spec:
  template:
    labels:
      app: ratings
      class: ecs
      cloud: aws
    serviceAccount: bookinfo-ratings
EOF
```

字段 `spec.template.serviceAccount` 声明了工作负载将具有 Kubernetes 集群内的服务账号 `bookinfo-ratings` 的身份。服务账号 `bookinfo-ratings` 是在[之前部署 Istio bookinfo 示例](../../aws-ec2/bookinfo)时创建的。

## 创建 Sidecar 配置

执行以下命令创建一个新的 Sidecar 配置：

```shell
cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: bookinfo-ratings-no-iptables
  namespace: bookinfo
spec:
  workloadSelector:                  # (1)
    labels:
      app: ratings
      class: ecs
  ingress:
  - defaultEndpoint: 127.0.0.1:9080  # (2)
    port:
      name: http
      number: 9080                   # (3)
      protocol: HTTP
  egress:
  - bind: 127.0.0.2                  # (4)
    port:
      number: 9080                   # (5)
    hosts:
    - ./*                            # (6)
EOF
```

上述 Sidecar 配置仅适用于具有标签 `app=ratings` 和 `class=ecs`（1）的工作负载。你已经创建的 `WorkloadGroup` 具有这些标签。

Istio 代理将配置为侦听 `<主机 IP>:9080`（3），并将 *传入* 请求转发到侦听 `127.0.0.1:9080`（2）的应用程序。

最后，代理将配置为侦听 `127.0.0.2:9080`（4）（5），以将应用程序的 *传出* 请求代理到其他服务（6），这些服务使用端口 `9080`（5）。

## 允许工作负载加入 `WorkloadGroup`

你需要创建一个 [`OnboardingPolicy`](../../../guides/setup) 资源，以明确授权在 Kubernetes 外部部署的工作负载加入网格。

首先，获取你的 [AWS 帐户 ID](https://docs.aws.amazon.com/general/latest/gr/acct-identifiers.html)。如果不知道你的 AWS 帐户 ID，请参阅 [AWS 帐户文档](https://docs.aws.amazon.com/IAM/latest/UserGuide/console_account-alias.html) 以获取有关如何查找你的 ID 的更多详细信息。

如果已经设置了你的 [`aws` CLI](https://aws.amazon.com/cli/)，可以执行以下命令：

```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
```

然后，通过执行以下命令，创建一个 `OnboardingPolicy`，以允许你 AWS 帐户 ID 拥有的任何 AWS ECS 任务加入 `bookinfo` 命名空间中的任何 `WorkloadGroup`。将 `<AWS_ACCOUNT_ID>` 替换为适当的值。

```bash
cat <<EOF | kubectl apply -f -
apiVersion: authorization.onboarding.tetrate.io/v1alpha1
kind: OnboardingPolicy
metadata:
  name: allow-ecs
  namespace: bookinfo            # (1)
spec:
  allow:
  - workloads:
    - aws:
        accounts:
        - "<AWS_ACCOUNT_ID>"     # (2)
        ecs: {}                  # (3)
    onboardTo:
    - workloadGroupSelector: {}  # (4)
EOF
```

上述策略适用于由 (2) 中指定的帐户拥有的任何 AWS ECS 任务 (3)，并允许它们加入 `bookinfo` 命名空间 (1) 中的任何 `WorkloadGroup` (4)。