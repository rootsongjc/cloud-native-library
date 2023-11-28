---
title: 配置本地 WorkloadGroup 和 Sidecar
weight: 1
---

你将在本地虚拟机上部署 `ratings` 应用程序并将其加入服务网格。

## 创建工作负载组

执行以下命令以创建一个 `WorkloadGroup`：

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
    serviceAccount: bookinfo-ratings
EOF
```

字段 `spec.template.network` 被省略，以指示 Istio 控制平面虚拟机在本地具有直接连接到 Kubernetes Pod 的能力。

字段 `spec.template.serviceAccount` 声明工作负载具有 Kubernetes 集群内服务账号 `bookinfo-ratings` 的身份。此服务账号是在之前的 Istio bookinfo 示例部署期间创建的（../../aws-ec2/bookinfo）。

## 创建 Sidecar 配置

执行以下命令以创建新的 Sidecar 配置：

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
      number: 9080                   # (5)
    hosts:
    - ./*                            # (6)
EOF
```

以上 Sidecar 配置仅适用于具有标签 `app=ratings` 和 `class=vm`（1）的工作负载。你创建的 `WorkloadGroup` 具有这些标签。

Istio 代理将配置为侦听 `<host IP>:9080`（3），并将 *传入* 请求转发到侦听 `127.0.0.1:9080`（2）的应用程序。

最后，代理将配置为侦听 `127.0.0.2:9080`（4）（5），以将 *传出* 请求代理到其他服务的应用程序（6），这些服务使用端口 `9080`（5）。

## 允许工作负载通过 JWT 令牌进行身份验证

在本指南中，你将使用 `Sample JWT Credential Plugin` 来为你的本地工作负载提供 [JWT 令牌] 凭据。

在此部分中，你将配置 `Workload Onboarding Plane` 来信任由 `Sample JWT Credential Plugin` 颁发的 JWT 令牌。

执行以下命令将 `Sample JWT Credential Plugin` 下载到本地：

```bash
curl -fL "https://dl.cloudsmith.io/public/tetrate/onboarding-examples/raw/files/onboarding-agent-sample-jwt-credential-plugin_0.0.1_$(uname -s)_$(uname -m).tar.gz" \
  | tar -xz onboarding-agent-sample-jwt-credential-plugin
```

执行以下命令生成供 `Sample JWT Credential Plugin` 使用的唯一签名密钥：

```bash
./onboarding-agent-sample-jwt-credential-plugin generate key \
  -o ./sample-jwt-issuer
```

上述命令将生成两个文件：

* `./sample-jwt-issuer.jwk` - 签名密钥（秘密部分） - 用于配置本地虚拟机上的 `Sample JWT Credential Plugin`
* `./sample-jwt-issuer.jwks` - JWKS 文档（公共部分） - 用于配置 `Workload Onboarding Plane`

执行以下命令将配置 `Workload Onboarding Plane` 以信任由上述生成的密钥签名的 [JWT 令牌]：

```bash
cat << EOF > controlplane.patch.yaml
spec:
  meshExpansion:
    onboarding:
      workloads:
        authentication:
          jwt:
            issuers:
            - issuer: https://sample-jwt-issuer.example
              jwks: |
$(cat sample-jwt-issuer.jwks | awk '{print "                "$0}')
              shortName: my-corp
              tokenFields:
                attributes:
                  jsonPath: .custom_attributes
EOF

kubectl patch controlplane controlplane -n istio-system --type merge --patch-file controlplane.patch.yaml
```

注意：为了使上述命令正常工作，你需要使用 `kubectl` 的版本 `v1.20+`。

## 允许工作负载加入工作负载组

你需要创建一个 [`OnboardingPolicy`](../../../guides/setup) 资源来明确授权在 Kubernetes 之外部署的工作负载加入网格。

执行以下命令：

```bash
cat << EOF | kubectl apply -f -
apiVersion: authorization.onboarding.tetrate.io/v1alpha1
kind: OnboardingPolicy
metadata:
  name: allow-onpremise-vms
  namespace: bookinfo                                # (1)
spec:
  allow:
  - workloads:
    - jwt:
        issuer: "https://sample-jwt-issuer.example"  # (2)
    onboardTo:
    - workloadGroupSelector: {}                      # (3)
EOF
```

以上策略适用于通过由 ID 为 `https://sample-jwt-issuer.example` 的发行者颁发的 [JWT 令牌]（2）进行身份验证的任何 `本地` 工作负载，并允许它们加入 `bookinfo` 命名空间（1）中的任何 `WorkloadGroup`（3）。
