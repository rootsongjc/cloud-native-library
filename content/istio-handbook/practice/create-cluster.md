---
weight: 10
title: 创建集群
date: '2022-05-18T00:00:00+08:00'
type: book
---

我们将使用谷歌云平台来托管 Kubernetes 集群。打开并登录到你的 GCP 控制台账户，并按照以下步骤创建一个 Kubernetes 集群。

1. 从导航中，选择 Kubernetes Engine。
2. 点击创建集群。
3. 将集群命名为 `boutique-demo`。
4. 选择区域选项，选择最接近你的位置的区域。
5. 点击 default-pool，在节点数中输入 5。
6. 点击 Nodes（节点）。
7. 点击机器配置机器类型下拉，选择`e2-medium (2 vCPU, 4 GB memory)`。
8. 点击 "Create"来创建集群。

集群的创建将需要几分钟的时间。一旦安装完成，集群将显示在列表中，如下图所示。

![部署在 GCP 中的 Kubernetes 集群](../../images/008i3skNly1gteb2j2o53j30o206jdgb.jpg "部署在 GCP 中的 Kubernetes 集群")

>  你也可以将 Online Boutique 应用程序部署到托管在其他云平台上的 Kubernetes 集群，如 Azure 或 AWS。

## 访问集群

我们有两种方式来访问集群。我们可以从浏览器中使用 Cloud Shell。要做到这一点，点击集群旁边的 Connect，然后点击 Run in Cloud Shell 按钮。点击该按钮可以打开 Cloud Shell，并配置 Kubernetes CLI 来访问该集群。

第二个选择是在你的电脑上安装 `gcloud` CLI，然后从你的电脑上运行相同的命令。

## 安装 Istio

我们将使用 GetMesh CLI 在集群中安装 Istio 1.10.3。

**1. 下载 GetMesh CLI**

```bash
curl -sL https://istio.tetratelabs.io/getmesh/install.sh | bash
```

**2. 安装 Istio**

```bash
getmesh istioctl install --set profile=demo
```

安装完成后，给默认命名空间设置上 `istio-injection=enabled` 标签：

```bash
kubectl label namespace default istio-injection=enabled
```
