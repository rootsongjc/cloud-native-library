---
title: 配置工作负载组和 Sidecar
weight: 3
---

你将在 AWS EC2 实例上部署 `ratings` 应用程序，并将其加入到服务网格中。

## 创建 `WorkloadGroup`

执行以下命令创建一个 `WorkloadGroup`：

```bash
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
      class: vm
      cloud: aws
    network: aws                      # (1)
    serviceAccount: bookinfo-ratings  # (2)
EOF
```

字段 `spec.template.network` 设置为非空值，以指示 Istio 控制平面，你稍后将创建的 VM 没有直接连接到 Kubernetes Pods。

字段 `spec.template.serviceAccount` 声明工作负载具有 Kubernetes 集群中的服务账号 `bookinfo-ratings` 的身份。服务账号 `bookinfo-ratings` 是在[之前部署 Istio bookinfo 示例时](../bookinfo)创建的。

## 创建 Sidecar 配置

执行以下命令创建一个新的 sidecar 配置：

```bash
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
      class: vm
  ingress:
  - defaultEndpoint: 127.0.0.1:9080  # (2)
    port:
      name: http
      number: 9080                   # (3)
      protocol: HTTP
  egress:
  - bind: 127.0.0.2                  # (4)
    port:
      name: http
      number: 9080                   # (5)
      protocol: HTTP
    hosts:
    - ./*                            # (6)
EOF
```

上述 sidecar 配置将仅应用于具有标签 `app=ratings` 和 `class=vm`（1）的工作负载。你已经创建的 `WorkloadGroup` 具有这些标签。

Istio 代理将配置为侦听 `<主机 IP>:9080`（3），并将 *传入* 请求转发到侦听 `127.0.0.1:9080`（2）的应用程序。

最后，代理将配置为侦听 `127.0.0.2:9080`（4）（5）以代理 *传出* 请求，将其发送到其他服务（6），这些服务的端口为 `9080`（5）。

## 允许工作负载加入 `WorkloadGroup`

你需要创建一个 [`OnboardingPolicy`](../../../guides/setup)
资源，以明确授权部署在 Kubernetes 之外的工作负载加入网格。

首先，获取你的 [AWS 账户 ID](https://docs.aws.amazon.com/general/latest/gr/acct-identifiers.html)。
如果不知道你的 AWS 账户 ID，请参阅 [AWS 账户文档](https://docs.aws.amazon.com/IAM/latest/UserGuide/console_account-alias.html) 以获取有关如何查找你的 ID 的更多详细信息。

如果你已经设置了 [`aws` CLI](https://aws.amazon.com/cli/)，可以执行以下命令：

```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
```

然后，通过执行以下命令创建一个 `OnboardingPolicy`，以允许你的 AWS EC2 实例的任何实例
通过执行以下命令加入 `bookinfo` 命名空间中的任何 `WorkloadGroup`。将 `<AWS_ACCOUNT_ID>` 替换为适当的值。

```bash
cat <<EOF | kubectl apply -f -
apiVersion: authorization.onboarding.tetrate.io/v1alpha1
kind: OnboardingPolicy
metadata:
  name: allow-aws-vms
  namespace: bookinfo            # (1)
spec:
  allow:
  - workloads:
    - aws:
        accounts:
        - <AWS_ACCOUNT_ID>       # (2)
        ec2: {}                  # (3)
    onboardTo:
    - workloadGroupSelector: {}  # (4)
EOF
```

上述策略适用于任何 AWS EC2 实例（3），由 (2) 中指定的账户拥有，允许它们加入命名空间 `bookinfo`（1）中的任何 `WorkloadGroup`（4）。