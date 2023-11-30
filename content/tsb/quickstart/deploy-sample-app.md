---
title: 部署应用程序
description: 在 TSB 中部署示例应用程序。
weight: 2
---

在本部分中，你将在演示 TSB 环境中部署示例应用程序 (bookinfo)。将使用 TSB UI 和 `tctl` 命令验证部署。

## 先决条件

在继续阅读本指南之前，请确保你已完成以下步骤：

- 熟悉 TSB 概念，包括工作区和组
-  安装 TSB 演示

TSB 演示安装负责加入集群、安装所需的 Operator 并为你提供必要的访问凭据。

## 部署 Bookinfo 应用程序

你将使用经典的 Istio [bookinfo 应用程序](https://istio.io/latest/docs/examples/bookinfo/)来测试 TSB 的功能。

### 创建命名空间并部署应用程序

```bash
# Create namespace and label it for Istio injection
kubectl create namespace bookinfo
kubectl label namespace bookinfo istio-injection=enabled

# Deploy the bookinfo application
kubectl apply -n bookinfo -f https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/platform/kube/bookinfo.yaml
```

###  确认服务

要确认所有服务和 pod 都在运行，请执行以下命令：

```bash
kubectl get pods -n bookinfo
```

预期输出：

```
NAME                             READY   STATUS    RESTARTS   AGE
details-v1-5bc5dccd95-2qx8b      2/2     Running   0          38m
productpage-v1-f56bc8d5c-42kcg   2/2     Running   0          38m
ratings-v1-68f58946ff-vcrdh      2/2     Running   0          38m
reviews-v1-5976d456d4-nltg2      2/2     Running   0          38m
reviews-v2-57cf5b5488-rgq8l      2/2     Running   0          38m
reviews-v3-7745dbf976-4gnl9      2/2     Running   0          38m
```

## 访问 Bookinfo 应用程序

确认你可以访问 bookinfo 应用程序：

```bash
kubectl exec "$(kubectl get pod -n bookinfo -l app=ratings -o jsonpath='{.items[0].metadata.name}')"  \
    -n bookinfo -c ratings -- curl -s productpage:9080/productpage | \
    grep -o "<title>.*</title>"
```

你应该看到类似的输出：

```
<title>Simple Bookstore App</title>
```

这些步骤成功地将 bookinfo 应用程序部署到你的 TSB 环境中，确保它按预期启动并运行。
