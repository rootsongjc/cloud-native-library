---
title: "在 AWS 安装 TSB"
weight: 1
---

本文档描述了如何在 AWS 单一 VPC 中安装 TSB。

在开始之前，请确保你已经：

- 熟悉 [TSB 概念](../../../concepts/)
- 安装 [tctl](../../../setup/requirements-and-download) 并 [同步你的 tctl 镜像](../../../reference/cli/reference/install#tctl-install-image-sync)
- 安装 [EKS CLI](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html)
- 安装 [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

# 使用单一 VPC 安装 TSB

在这种情况下，你将需要在你的 AWS 帐户中运行 3 个 EKS 集群，以及运行 Elasticsearch 和 Postgres。

请按照相应的 AWS 指南进行更详细的设置：

* [创建 EKS 集群](https://docs.aws.amazon.com/cli/latest/reference/eks/create-cluster.html)
* [开始使用 Amazon OpenSearch 服务](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/gsgcreate-domain.html)（[CLI 参考](https://docs.aws.amazon.com/cli/latest/reference/es/create-elasticsearch-domain.html)）
* [创建 PostgreSQL DB 实例](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_GettingStarted.CreatingConnecting.PostgreSQL.html)（[CLI 参考](https://docs.aws.amazon.com/cli/latest/reference/rds/create-db-instance.html)）

首先，使用以下命令模板创建管理平面集群。
由于命令中没有明确定义 VPC，将为你创建一个新的 VPC。

```bash
$ eksctl create cluster \
  --name <NAME> \
  --version <VERSION> \
  --region <REGION> \
  --nodegroup-name <POOLNAME> \
  --nodes <NUM> \
  --node-type <TYPE> \
  --managed
```

一旦管理平面集群、节点和 VPC 准备就绪，请记录下子 VPC 名称，并继续进行 Tier 1 和控制平面集群的设置。

对于 Tier 1 和控制平面集群，你需要在前面的命令模板之上指定 VPC 网络信息。使用以下命令模板创建两个集群，一个用于 Tier 1，另一个用于控制平面。

```bash
$ eksctl create cluster \
  --name <NAME> \
  --version <VERSION>\
  --region <REGION> \
  --nodegroup-name <POOLNAME> \
  --nodes <NUM> \
  --node-type <TYPE> \
  --managed \
  --vpc-private-subnets <VPCNAMES> \
  --vpc-public-subnets <VPCNAMES>
```

一旦 EKS 集群准备就绪，请确保根据提供的链接设置 OpenSearch 和 PostgreSQL。

## 部署管理平面

指向为管理平面安装创建的集群，并按照 [管理平面安装](../../../setup/self-managed/management-plane-installation) 中的说明操作。

但是，请确保在创建管理平面密钥时指定 Elasticsearch 和 PostgreSQL 的额外信息：

```
$ tctl install manifest management-plane-secrets  \
  --elastic-username <USER> \
  --elastic-password <PASS> \
  --postgres-username <USER> \
  --postgres-password <PASS> \
  ... other options ...
```

此外，[ManagementPlane](../../../refs/install/managementplane/v1alpha1/spec) 自定义资源应该指向正确的 PostgreSQL 和 OpenSearch 端点：

```yaml
# <snip>
 dataStore:
   postgres:
     address: <postgres-endpoint>
     name: <database-name>
 telemetryStore:
   elastic:
     host: <elastic-endpoint>
     port: <elastic-port>
     version: <elastic-version>
# <snip>
```

安装管理平面后，你应该能够使用以下命令获取外部主机名（确保你的 Kubernetes 上下文指向适当的集群）：

```bash
$ kubectl get svc -n tsb
```

从上述命令的输出中，你应该能够找到一个主机名，类似于 `ab940458d752c4e0c80830e9eb89a99d-1487971349.<Region>.elb.amazonaws.com`。这是在配置 Tier 1 和控制平面配置 YAML 文件时要使用的端点。

## 部署 Tier 1 和控制平面（Tier2）集群

对于 Tier 1 和 CP 集群，请按照以下说明进行操作：

查看以下链接以获取有关 [Tier1 网关](../../../refs/tsb/gateway/v2/tier1-gateway) 和 [控制平面](../../../concepts/operators/control-plane) 的更多信息。

* [部署控制平面 Operator](../../../setup/self-managed/onboarding-clusters)
* [安装控制平面密钥](../../../setup/self-managed/onboarding-clusters)
* 应用 `ControlPlane` CR 来 [安装 TSB 控制平面组件](../../../setup/self-managed/onboarding-clusters)

设置这些集群后，在 Tier 1 和 Tier 2 中的 Edge XCP 中添加以下注释以启用 [多集群路由](../../../concepts/traffic-management) 并应用这些设置。

```yaml
# <snip>
components:
  xcp:
    kubeSpec:
      overlays:
      - apiVersion: install.xcp.tetrate.io/v1alpha1
        kind: EdgeXcp
        name: edge-xcp
        patches:
        - path: spec.components.edgeServer.kubeSpec.overlays
          value:
          - apiVersion: v1
            kind: Service
            name: xcp-edge
            patches:
            - path: spec.type
              value: NodePort
            - path: metadata.annotations
              value:
                traffic.istio.io/nodeSelector: '{"beta.kubernetes.io/arch":"amd64"}'
```

集群设置完成后，你可以按照 [部署 bookinfo 应用程序的说明](../../../quickstart/deploy-sample-app) 继续进行演示工作负载。

# 使用多个 VPC 安装 TSB

对于此安装，你应该已经在

单个 VPC 中运行了 TSB。

![](../../../assets/setup/aws/multiple-vpc2.png)

此情景中的基础架构与使用单个 VPC 的情况类似，但托管控制平面（Tier2）的集群位于与管理平面和 Tier 1 网关的集群不同的 VPC 中。这些 VPC 需要配置以能够相互通信。请阅读 AWS 中有关 [VPC 对等连接](https://docs.aws.amazon.com/vpc/latest/peering/what-is-vpc-peering.html) 的指南以及 CLI 参考中的相关部分，以获取更多详细信息。

首先创建一个集群和控制平面的新 VPC。你可以使用与为单个 VPC 案例创建第一个 EKS 集群时相同的命令模板。

```bash
$ eksctl create cluster \
  --name <NAME> \
  --version <VERSION> \
  --region <REGION> \
  --nodegroup-name <POOLNAME> \
  --nodes <NUM \
  --node-type <TYPE> \
  --managed 
```

## 配置 VPC

你需要检索 VPC 信息以继续配置。使用以下命令获取必要信息：

```bash
$ aws ec2 --output text \
          --query 'Vpcs[*].{VpcId:VpcId,Name:Tags[?Key==`Name`].Value|[0],CidrBlock:CidrBlock}' describe-vpcs
```

找到将要参与的每个 VPC 的 ID，并使用 [`aws ec2 create-vpc-peering-connection`](https://docs.aws.amazon.com/cli/latest/reference/ec2/create-vpc-peering-connection.html) 命令创建 VPC 对等连接，以允许这些 VPC 互相通信：

```bash
$ aws ec2 create-vpc-peering-connection \
          --vpc-id <VPC-ID1> \
          --peer-vpc-id <VPC-ID2>
```

请注意从上述命令的输出中获取 `VpcPeeringConnectionId` 字段的值。你将需要此值来接受对等连接请求。

使用此 ID，使用 [`aws ec2 accept-vpc-peering-connection`](https://docs.aws.amazon.com/cli/latest/reference/ec2/accept-vpc-peering-connection.html) 命令接受对等连接：

```bash
$ aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id <PEERID>
```

当上述命令成功执行时，这些 VPC 应该能够相互通信。

## 配置控制平面集群

为了连接到控制平面集群，你需要更新你的 `kubeconfig`。使用适当的值运行以下命令：

```bash
$ aws eks --region <REGION> update-kubeconfig --name <NAME>
```

启动控制平面。一般的设置与 [Onboarding Clusters 指南](../../../setup/self-managed/onboarding-clusters) 中的相同。

你的控制平面的集群定义应如下所示。注意 `spec` 组件中的额外字段。

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Cluster
metadata:
  name: cp-remote
  organization: tetrate
spec:
  displayName: "Control Plane Remote"
  network: tier2
```

当你准备好 [安装控制平面自定义资源](../../../setup/self-managed/onboarding-clusters) 时，从指南中修改定义，并使用以下 YAML 作为指南设置适当的值：

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  name: controlplane
  namespace: istio-system
spec:
  hub: <repository>
dataStore:
  postgres:
    address: <postgres-endpoint>
    name: <database-name>
  telemetryStore:
    elastic:
      host: <elastic-endpoint>
      port: <elastic-port>
      version: <elastic-version>
  managementPlane:
    host: <management-plane-endpoint>
    port: 8443
    clusterName: <management-plane-cluster>
  components:
    internalCertProvider:
      certManager:
        managed: INTERNAL
    xcp:
      kubeSpec:
        overlays:
        - apiVersion: install.xcp.tetrate.io/v1alpha1
          kind: EdgeXcp
          name: edge-xcp
          patches:
          - path: spec.components.edgeServer.kubeSpec.overlays
            value:
            - apiVersion: v1
              kind: Service
              name: xcp-edge
              patches:
              - path: spec.type
                value: NodePort
              - path: metadata.annotations
                value:
                  traffic.istio.io/nodeSelector: '{"beta.kubernetes.io/arch":"amd64"}'
```

如果一切配置正确，你应该能够在新集群上部署工作负载。
