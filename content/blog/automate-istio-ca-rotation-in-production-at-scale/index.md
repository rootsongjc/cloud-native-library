---
title: "在生产中大规模自动化 Istio CA 轮换"
date: 2022-12-20T14:00:00+08:00
draft: false
authors: ["Tetrate"]
summary: "本文将向您展示如何简化 Istio 中的 CA 管理以降低风险并提高系统的整体稳定性。"
tags: ["Istio","零信任","安全","证书"]
categories: ["Istio"]
links:
  - icon: globe
    icon_pack: fa
    name: 原文
    url: https://tetrate.io/blog/automate-istio-ca-rotation-in-production-at-scale/
---

Istio 的核心功能之一是通过管理网格中服务的身份来促进零信任网络架构。为了在网格中检索用于 mTLS 通信的有效证书，各个工作负载向 *istiod* 发出证书签名请求 (CSR)。Istiod 反过来验证请求并使用证书颁发机构（CA）[签署 CSR 以生成证书](https://istio.io/latest/docs/concepts/security/#pki)。默认情况下，Istio 为此目的使用自己的自签名 CA，但最佳实践是通过为每个 Istio 部署创建一个中间 CA，[将 Istio 集成到您现有的 PKI 中](/blog/istio-trust/)。

如果您正在管理多个集群，这意味着颁发多个中间 CA，每个中间 CA 都应设置为在几个月或更短的时间内到期。管理这些 CA 的生命周期至关重要，因为它们必须在过期或坏事发生之前进行轮换。本文将向您展示如何简化此 CA 管理以**降低风险**并**提高系统的整体稳定性**。

轮换 CA 时的一个关键步骤是确保实际使用新的 CA。默认情况下，Istio 仅在启动时加载其 CA。但是，Istio 可以配置为监视更改并在更新时自动重新加载其 CA。本教程取自我们与管理大量 Istio 部署的企业客户合作开发的生产手册，将展示如何配置 Istio 以自动重新加载其 CA。我们还将介绍如何配置 [cert-manager](https://cert-manager.io/) 以在 Istio 的中间 CA 到期前定期自动轮换，以**提高在多个集群上管理 CA 的操作效率**。

## 先决条件

对于本教程，您至少需要以下内容：

- 一个正在运行的 Kubernetes 集群。像 [minikube](https://minikube.sigs.k8s.io/docs/start/) 或类似的简化的 Kubernetes 安装适用于演示目的；
- [Istioctl](https://cert-manager.io/docs/) v1.14.2 或更高版本；
- [cert-manager](https://cert-manager.io/docs/) v1.7.2 或更高版本。

## 任务 A：安装和配置 cert-manager 以自动轮换 Istio 的 CA

### 步骤 A1：安装证书管理器

以下命令将在您的集群中安装 cert-manager。要安装更新版本的证书管理器，请更改 GitHub URL。

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.10.1/cert-manager.yaml
```

### 步骤 A2：配置 CA

出于演示目的，我们将设置一个自签名 CA，但**不要在生产中使用自签名 CA**。出于生产目的，您应该 [将 cert-manager 配置为使用现有的 PKI](https://tetrate.io/blog/istio-trust/)。

```bash
cat << EOF | kubectl apply -f -
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: selfsigned
  namespace: cert-manager
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: selfsigned-ca
  namespace: cert-manager
spec:
  isCA: true
  duration: 21600h # 900d
  secretName: selfsigned-ca
  commonName: certmanager-ca
  subject:
    organizations:
      - cert-manager
  issuerRef:
    name: selfsigned
    kind: Issuer
    group: cert-manager.io
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-ca
spec:
  ca:
    secretName: selfsigned-ca
EOF
```

### 步骤 A3：为 Istio 配置中间 CA

设置中间 CA Istio 将用于签署工作负载证书，设置为每 60 天（1440 小时）证书轮换一次，并在 15 天（360 小时）到期前更新：

```bash
kubectl create namespace istio-system
cat << EOF | kubectl apply -f -
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: cacerts
  namespace: istio-system
spec:
  secretName: cacerts
  duration: 1440h
  renewBefore: 360h
  commonName: istiod.istio-system.svc
  isCA: true
  usages:
    - digital signature
    - key encipherment
    - cert sign
  dnsNames:
    - istiod.istio-system.svc
  issuerRef:
    name: selfsigned-ca
    kind: ClusterIssuer
    group: cert-manager.io
EOF
```

 **注意**：Cert-manager 将证书和密钥公开为 [`kubernetes.io/tls` Secret](https://kubernetes.io/docs/concepts/configuration/secret/#secret-types)。Istio 可以使用从 [1.14.2 版本](https://istio.io/latest/news/releases/1.14.x/announcing-1.14.2/#changes)开始的 `kubernetes.io/tls` 类型的 Secret。

## 任务 B：安装和配置 Istio 以自动更新其 CA

使用 `istioctl` 安装 Istio。以下 IstioOperator 配置设置环境变量`AUTO_RELOAD_PLUGIN_CERTS=true` 以使 Istio 在更新时自动重新加载其 CA：

```bash
istioctl operator init
cat << EOF | istioctl apply --skip-confirmation -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: demo-istio-install
  namespace: istio-system
spec:
  profile: demo
  components:
    pilot:
      k8s:
        env:
        - name: AUTO_RELOAD_PLUGIN_CERTS
          value: "true"
EOF
```

## 任务 C：配置和验证 Istio 的中间 CA 轮换

### 步骤 C1：配置轮换中间 CA

假设需求发生了变化，我们需要将 CA 轮换周期从 60 天（1440 小时）缩短到 30 天（720 小时）：

```bash
cat << EOF | kubectl apply -f -
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: cacerts
  namespace: istio-system
spec:
  secretName: cacerts
  duration: 720h 
  renewBefore: 360h
  commonName: istiod.istio-system.svc
  isCA: true
  usages:
    - digital signature
    - key encipherment
    - cert sign
  dnsNames:
    - istiod.istio-system.svc
  issuerRef:
    name: selfsigned-ca
    kind: ClusterIssuer
    group: cert-manager.io
EOF
```

### 步骤 C2：验证新的中间 CA 是否已重新加载

查看日志应该会显示 CA 更改：

```bash
kubectl logs -l app=istiod -n istio-system -f
```

您应该在日志输出中看到类似这样的内容：

```
2022-08-11T20:18:41.493247Z	info	Update Istiod cacerts
2022-08-11T20:18:41.493483Z	info	Using kubernetes.io/tls secret type for signing ca files
2022-08-11T20:18:41.716843Z	info	Istiod has detected the newly added intermediate CA and updated its key and certs accordingly
2022-08-11T20:18:41.717170Z	info	x509 cert - Issuer: "CN=istiod.istio-system.svc", Subject: "", SN: 1c43c1686425ee2e63f2db90bd3cf17f, NotBefore: "2022-08-11T20:16:41Z", NotAfter: "2032-08-08T20:18:41Z"
2022-08-11T20:18:41.717220Z	info	x509 cert - Issuer: "CN=certmanager-ca,O=cert-manager", Subject: "CN=istiod.istio-system.svc", SN: c172b51eeb4a2891fe66f30babb42bb0, NotBefore: "2022-08-11T20:17:25Z", NotAfter: "2022-08-13T20:17:25Z"
2022-08-11T20:18:41.717254Z	info	x509 cert - Issuer: "CN=certmanager-ca,O=cert-manager", Subject: "CN=certmanager-ca,O=cert-manager", SN: ea1760f2dcf9806a8c997c4bc4b2fb30, NotBefore: "2022-08-11T20:13:33Z", NotAfter: "2025-01-27T20:13:33Z"
2022-08-11T20:18:41.717256Z	info	Istiod certificates are reloaded
```

## 总结

正如我们所见，使用 cert-manager 来自动化 Istio CA 轮换可以轻松高效地处理关键操作功能。将 Istio 配置为自动重新加载其 CA 无需手动重启 Istio，从而消除了潜在的人为错误来源。

服务网格是一种强大的工具，可用于实施零信任安全实践并大规模提高业务敏捷性和连续性。为服务网格建立有效的运营实践对于利用这种力量至关重要。作为 Istio 和 Envoy 的创始人和核心贡献者，我们 Tetrate 每天都在帮助我们的客户做到这一点。
