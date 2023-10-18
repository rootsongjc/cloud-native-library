---
title: 安全
weight: 10
---

在此场景中，你将了解如何使用 TSB 安全设置来限制来自工作区外部的访问。这有助于通过控制服务之间的通信来增强环境的安全性。

## 先决条件

在继续之前，请确保你已完成以下任务：

- 熟悉 TSB 概念。
- 安装 TSB 演示环境。
- 部署 Istio Bookinfo 示例应用程序。
- 创建租户、工作区和配置组。
- 为团队和用户配置权限。
- 设置入口网关。
- 使用可观察性工具检查服务拓扑和指标。
- 配置流量转移。

## 部署 sleep 服务

首先，让我们在不属于 bookinfo 应用程序工作区的另一个命名空间中部署“睡眠”服务。这将用于测试安全设置。

创建以下 `sleep.yaml` 文件：

<details>
  <summary>sleep.yaml</summary>

```yaml
# Copyright Istio Authors
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

##################################################################################################
# Sleep service
##################################################################################################
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sleep
---
apiVersion: v1
kind: Service
metadata:
  name: sleep
  labels:
    app: sleep
spec:
  ports:
  - port: 80
    name: http
  selector:
    app: sleep
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sleep
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sleep
  template:
    metadata:
      labels:
        app: sleep
    spec:
      serviceAccountName: sleep
      containers:
      - name: sleep
        image: governmentpaas/curl-ssl
        command: ["/bin/sleep", "3650d"]
        imagePullPolicy: IfNotPresent
        volumeMounts:
        - mountPath: /etc/sleep/tls
          name: secret-volume
      volumes:
      - name: secret-volume
        secret:
          secretName: sleep-secret
          optional: true
---
```

</details>

根据你的环境（标准 Kubernetes 或 OpenShift），使用适当的命令部署 `sleep` 服务：

<details>
<summary>标准 Kubernetes</summary>
```bash
kubectl create namespace sleep
kubectl label namespace sleep istio-injection=enabled --overwrite=true
kubectl apply -n sleep -f sleep.yaml
```

等待配置传播后，你可以从 `sleep` 服务 pod 调用 bookinfo 产品页面：

```bash
kubectl exec "$(kubectl get pod -l app=sleep -n sleep -o jsonpath={.items..metadata.name})" -c sleep -n sleep -- curl -s http://productpage.bookinfo:9080/productpage | grep -o "<title>.*</title>"
```

</details>

<details>
<summary>OpenShift</summary>

```bash
oc create namespace sleep
oc label namespace sleep istio-injection=enabled

cat <<EOF | oc -n sleep create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: istio-cni
EOF

oc adm policy add-scc-to-group anyuid \
    system:serviceaccounts:sleep

oc apply -n sleep -f sleep.yaml
```

等待配置传播后，你可以从 `sleep` 服务 pod 调用 bookinfo 产品页面：

```bash{promptUser: Alice}
oc exec "$(oc get pod -l app=sleep -n sleep -o jsonpath={.items..metadata.name})" -c sleep -n sleep -- curl -s http://productpage.bookinfo:9080/productpage | grep -o "<title>.*</title>"
```

</details>

你应该看到输出：

```text
<title>Simple Bookstore App</title>
```

这表明工作区外部的服务与 bookinfo 应用程序工作区之间的通信是允许的。

## 创建安全设置

你可以配置安全设置以限制来自不同工作区或集群的服务之间的通信。在这种情况下，我们将配置同一工作区和集群中的服务之间的通信。

### 使用用户界面

1. 在“租户”下，选择“工作区”。
2. 在 `bookinfo-ws` 工作区卡上，单击“安全组”。
3. 单击你之前创建的 `bookinfo-security` 安全组。
4. 选择安全设置选项卡。
5. 单击添加新...以默认名称 `default-setting` 创建新的安全设置。
6. 将新的安全设置重命名为 `bookinfo-security-settings` 。
7. 展开 bookinfo-security-settings 以显示其他配置：身份验证设置和授权设置。
8. 单击身份验证设置并将流量模式字段设置为必需。
9. 单击授权设置并将模式字段设置为工作空间。
10.  单击保存更改。

### 使用 tctl

创建以下 `security.yaml` 文件：

```yaml
# ... (The contents of security.yaml)
```

使用 `tctl` 应用配置：

```bash
tctl apply -f security.yaml
```

### 验证安全设置

等待配置传播后，通过尝试从 `sleep` 服务访问服务来测试安全设置。

<details>
<summary>标准 Kubernetes</summary>

```bash
kubectl exec "$(kubectl get pod -l app=sleep -n sleep -o jsonpath={.items..metadata.name})" -c sleep -n sleep -- curl http://productpage.bookinfo:9080/productpage -v
```

</details>

<details>
<summary>OpenShift</summary>

```bash
oc exec "$(oc get pod -l app=sleep -n sleep -o jsonpath={.items..metadata.name})" -c sleep -n sleep -- curl http://productpage.bookinfo:9080/productpage -v
```

</details>

你应该收到类似于以下内容的输出：

```text
HTTP/1.1 403 Forbidden
...
RBAC: access denied
```

这表示由于安全设置，从 `sleep` 服务到 `bookinfo` 产品页面的通信被拒绝。这确保不允许来自工作区外部的服务访问应用程序工作区内的服务。

### 允许访问特定服务

允许访问特定服务安全组，你可以添加 `ServiceSecuritySetting` 来覆盖该服务的规则。

<details>
<summary>使用 tctl</summary>

创建以下 `service-security.yaml` 文件：

```yaml
apiVersion: security.tsb.tetrate.io/v2
kind: ServiceSecuritySetting
metadata:
  organization: tetrate
  name: bookinfo-allow-reviews
  group: bookinfo-security
  workspace: bookinfo-ws
  tenant: tetrate
spec:
  service: bookinfo/reviews.bookinfo.svc.cluster.local
  settings:
    authenticationSettings:
      trafficMode: REQUIRED
    authorization:
      mode: CLUSTER
```

使用 `tctl` 应用配置：

```bash
tctl apply -f service-security.yaml
```

</details>

等待配置传播后，测试从 `sleep` 服务对评论服务的访问。

<details>
<summary>标准 Kubernetes</summary>

```bash
kubectl exec "$(kubectl get pod -l app=sleep -n sleep -o jsonpath={.items..metadata.name})" -c sleep -n sleep -- curl http://reviews.bookinfo:9080/reviews/0 -v
```

</details>

<details>
<summary>OpenShift</summary>

```bash
oc exec "$(oc get pod -l app=sleep -n sleep -o jsonpath={.items..metadata.name})" -c sleep -n sleep -- curl http://reviews.bookinfo:9080/reviews/0 -v
```

</details>

你应该收到成功的响应：

```text
HTTP/1.1 200 OK
...
```

这表示允许从 `sleep` 服务到 `bookinfo` 评论服务的通信，因为你添加了 `ServiceSecuritySetting` 来允许访问。

通过执行这些步骤，你已成功配置 TSB 安全设置以限制来自工作区外部的访问，从而增强环境的安全性。
