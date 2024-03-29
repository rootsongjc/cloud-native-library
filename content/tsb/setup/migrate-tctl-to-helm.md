---
title: 从 tctl 迁移到 Helm
weight: 14
---

这份文档将覆盖如何迁移使用 tctl 的 TSB 的实时安装，并迁移到 Helm。文档假设 [Helm 已经安装](https://helm.sh/docs/intro/install/) 在系统中。

在开始之前，请确保你：

- 熟悉 [TSB 概念](../../concepts/)
- 安装了 TSB 环境。你可以使用 [TSB 演示](../self-managed/demo-installation) 进行快速安装。
- 完成了 [TSB 使用快速入门](../../quickstart)。

## 准备 Helm Chart

在进行之前，你必须熟悉 Helm。请按照我们的指南中的 [先决条件](../helm/helm) 安装 TSB 与 Helm。  

## 迁移管理平面

迁移当前的安装只需要标记和注释平面安装的资源。所有其他组件将由 tsb-operator 升级和管理。以下是标记每个将由 Helm 管理的资源的命令列表。

```shell
kubectl -n tsb label deployment tsb-operator-management-plane "app.kubernetes.io/managed-by=Helm"
kubectl -n tsb annotate deployment tsb-operator-management-plane "meta.helm.sh/release-name=mp" "meta.helm.sh/release-namespace=tsb"

kubectl -n tsb annotate service tsb-operator-management-plane "meta.helm.sh/release-name=mp" "meta.helm.sh/release-namespace=tsb"

kubectl -n tsb annotate sa tsb-operator-management-plane "meta.helm.sh/release-name=mp" "meta.helm.sh/release-namespace=tsb"

kubectl -n tsb label secret elastic-credentials "app.kubernetes.io/managed-by=Helm"
kubectl -n tsb annotate secret elastic-credentials "meta.helm.sh/release-name=mp" "meta.helm.sh/release-namespace=tsb"

kubectl -n tsb label secret es-certs "app.kubernetes.io/managed-by=Helm"
kubectl -n tsb annotate secret es-certs "meta.helm.sh/release-name=mp" "meta.helm.sh/release-namespace=tsb"

kubectl -n tsb label secret ldap-credentials "app.kubernetes.io/managed-by=Helm"
kubectl -n tsb annotate secret ldap-credentials "meta.helm.sh/release-name=mp" "meta.helm.sh/release-namespace=tsb"

kubectl -n tsb label secret postgres-credentials "app.kubernetes.io/managed-by=Helm"
kubectl -n tsb annotate secret postgres-credentials "meta.helm.sh/release-name=mp" "meta.helm.sh/release-namespace=tsb"

kubectl -n tsb label secret admin-credentials "app.kubernetes.io/managed-by=Helm"
kubectl -n tsb annotate secret admin-credentials "meta.helm.sh/release-name=mp" "meta.helm.sh/release-namespace=tsb"

kubectl annotate clusterrole tsb-operator-management-plane-tsb "meta.helm.sh/release-name=mp" "meta.helm.sh/release-namespace=tsb"

kubectl annotate clusterrolebinding tsb-operator-management-plane-tsb "meta.helm.sh/release-name=mp" "meta.helm.sh/release-namespace=tsb"

kubectl -n tsb label managementplane managementplane "app.kubernetes.io/managed-by=Helm"
kubectl -n tsb annotate managementplane managementplane "meta.helm.sh/release-name=mp" "meta.helm.sh/release-namespace=tsb"
```

{{<callout note 注意>}}
release-name 和 release-namespace 应该与 Helm 安装命令中使用的发行名称和命名空间匹配。
{{</callout>}}

在所有资源都正确标记后，然后继续安装发布：

```shell
### 示例
helm upgrade mp tetrate-tsb-helm/managementplane --install --namespace tsb -f upgrade-mpt1/helm/values-mp.yaml --set image.registry=${HUB} --set image.tag=${TSB_VERSION} --set spec.hub=${HUB} 

### 输出：
Release "mp" does not exist. Installing it now.

NAME: mp
LAST DEPLOYED: Thu May 25 11:03:18 2023
NAMESPACE: tsb
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for installing the TSB Management plane 1.5.11.
Chart: managementplane
Version: 1.5.11

Your Management Plane is ready to be used.
Next step might be to onboard the cluster from the control plane.
You could choose between:
 - install `controlplane` chart
 - manually following # TODO url to docs.

# Discover the TSB entrypoint

Check the IP for the envoy loadbalancer service.

This is one example. Consider a time for the service to be ready:
kubectl get svc -n "tsb" envoy --output jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Configure the TCTL admin profile, using the IP in the previous step.

# Setup the TSB address as follows. If specific settings are needed to trust the certificate configured in TSB,
# refer to the `tctl config clusters set --help` command to see all the available options.
tctl config clusters set helm --bridge-address <IP>:8443

tctl config users set helm --username admin --password "NotAPassword" --org "tetrate"
tctl config profiles set helm --cluster helm --username helm
tctl config profiles set-current helm 
```

## 迁移控制平面

该过程相同，只有一些资源和机密发生了变化。

```shell
kubectl -n istio-system label deployment tsb-operator-control-plane "app.kubernetes.io/managed-by=Helm"
kubectl -n istio-system annotate deployment tsb-operator-control-plane "meta.helm.sh/release-name=cp" "meta.helm.sh/release-namespace=istio-system"

kubectl -n istio-system annotate service tsb-operator-control-plane "meta.helm.sh/release-name=cp" "meta.helm.sh/release-namespace=istio-system"

kubectl -n istio-system annotate sa tsb-operator-control-plane "meta.helm.sh/release-name=cp" "meta.helm.sh/release-namespace=istio-system"

kubectl -n istio-system annotate secret elastic-credentials "app.kubernetes.io/managed-by=Helm"
kubectl -n istio-system annotate secret elastic-credentials "meta.helm.sh/release-name=cp" "meta.helm.sh/release-namespace=istio-system"

kubectl -n istio-system label secret cluster-service-account "app.kubernetes.io/managed-by=Helm"
kubectl -n istio-system annotate secret cluster-service-account "meta.helm.sh/release-name=cp" "meta.helm.sh/release-namespace=istio-system"

kubectl -n istio-system

 label secret mp-certs "app.kubernetes.io/managed-by=Helm"
kubectl -n istio-system annotate secret mp-certs "meta.helm.sh/release-name=cp" "meta.helm.sh/release-namespace=istio-system"

kubectl -n istio-system label secret xcp-central-ca-bundle "app.kubernetes.io/managed-by=Helm"
kubectl -n istio-system annotate secret xcp-central-ca-bundle "meta.helm.sh/release-name=cp" "meta.helm.sh/release-namespace=istio-system"

kubectl annotate clusterrole tsb-operator-control-plane-istio-system "meta.helm.sh/release-name=cp" "meta.helm.sh/release-namespace=istio-system"

kubectl annotate clusterrolebinding tsb-operator-control-plane-istio-system "meta.helm.sh/release-name=cp" "meta.helm.sh/release-namespace=istio-system"

kubectl -n istio-system label controlplane  controlplane "app.kubernetes.io/managed-by=Helm"
kubectl -n istio-system annotate controlplane controlplane "meta.helm.sh/release-name=cp" "meta.helm.sh/release-namespace=istio-system"
```

验证并检查 release-name 和 release-namespace 是否指向发布安装中使用的值：

```shell
### 示例
helm upgrade cp tetrate-tsb-helm/controlplane --install --namespace istio-system -f upgrade-mpt1/helm/values-cp.yaml  --set image.registry=${HUB} --set image.tag=${TSB_VERSION} --set spec.hub=${HUB} --set spec.managementPlane.host=${TSB_HOST} --set-file secrets.clusterServiceAccount.JWK=/tmp/upgrade-mpt1.jwk

### 输出
Release "cp" does not exist. Installing it now.
NAME: cp
LAST DEPLOYED: Thu May 25 11:21:18 2023
NAMESPACE: istio-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for installing the TSB Control Plane 1.5.11.
Chart: controlplane
Version: 1.5.11
```

## 迁移数据平面

这是最后一个平面，需要注释的资源较少：

```shell
kubectl -n istio-gateway label deployment tsb-operator-data-plane "app.kubernetes.io/managed-by=Helm"
kubectl -n istio-gateway annotate deployment tsb-operator-data-plane "meta.helm.sh/release-name=dp" "meta.helm.sh/release-namespace=istio-gateway"

kubectl -n istio-gateway annotate service tsb-operator-data-plane "meta.helm.sh/release-name=dp" "meta.helm.sh/release-namespace=istio-gateway"

kubectl -n istio-gateway annotate sa tsb-operator-data-plane "meta.helm.sh/release-name=dp" "meta.helm.sh/release-namespace=istio-gateway"

kubectl annotate clusterrole tsb-operator-data-plane-istio-gateway "meta.helm.sh/release-name=dp" "meta.helm.sh/release-namespace=istio-gateway"

kubectl annotate clusterrolebinding tsb-operator-data-plane-istio-gateway "meta.helm.sh/release-name=dp" "meta.helm.sh/release-namespace=istio-gateway"
```

继续安装发布：

```shell
### 示例
helm upgrade dp tetrate-tsb-helm/dataplane --install --namespace istio-gateway --create-namespace --set image.registry=${HUB} --set image.tag=${TSB_VERSION}

### 输出
Release "dp" does not exist. Installing it now.
NAME: dp
LAST DEPLOYED: Thu May 25 11:29:11 2023
NAMESPACE: istio-gateway
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for installing the TSB Data Plane 1.5.11.
Chart: dataplane
Version: 1.5.11
```
