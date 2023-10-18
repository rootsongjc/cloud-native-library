---
title: Istio CA
description: 如何将 Vault Agent 注入器与 Istiod CA 证书结合使用。
---

在开始之前，你必须拥有：

- Vault 1.3.1 或更新版本
- Vault 注入器 0.3.0 或更新版本

## 设置 Vault

安装 Vault（它不必安装在 Kubernetes 集群中，但应该可以从 Kubernetes 集群内部访问）。必须将 Vault 注入器（agent-injector）安装到集群中，并配置以注入 sidecar。Helm chart `v0.5.0+` 会自动完成这些工作，该 Helm chart 安装了 Vault `0.12+` 和 Vault-Injector `0.3.0+`。下面的示例假定 Vault 安装在 `tsb` 命名空间中。

有关更多详细信息，请参阅 [Vault 文档](https://www.vaultproject.io/docs/platform/k8s/injector/installation)。

```bash
helm install --name=vault --set='server.dev.enabled=true'
```

将 Vault 服务端口转发到本地，并设置环境变量以对 API 进行身份验证

```bash
kubectl port-forward svc/vault  8200:8200 & # 这将在后台运行
export VAULT_ADDR='http://[::]:8200'
export VAULT_TOKEN="root"
```

### 创建 CA 证书

{{<callout note 注意>}}
如果你已经有自己的 CA 证书和/或用于 Istio 的中间 CA 证书，请跳到 [将中间 CA 证书添加到 Vault](#adding-intermediate-ca-certificate-to-vault)。
{{</callout>}}

Vault 有一个支持创建或管理 CA 证书的 `PKI` Secret 后端。建议用户使用 Vault 创建一个用于 Istio 的中间 CA 证书，并将根 CA 保留在 Vault 之外。请参考 [Vault 文档](https://www.vaultproject.io/docs/secrets/pki) 了解更多细节。

使用 Vault PKI 后端在 Vault 中生成一个自签名的根 CA 证书。

```bash
# 在 Vault 中添加审计跟踪
vault audit enable file file_path=/vault/vault-audit.log

# 启用 PKI Secret 后端
vault secrets enable pki

# 更新 PKI 租约为 1 年
vault secrets tune -max-lease-ttl=8760h pki

# 创建自签名 CA
vault write pki/root/generate/internal common_name=tetrate.io ttl=8760h
```

### 为 Istio 创建中间 CA

现在我们在 Vault 中有了一个 CA，我们将其用于创建 Istio 的中间 CA。我们重复使用 `pki` Secret 后端，但使用一个新路径 (`istioca`)。这次我们需要获取 CA 密钥，并调用 `exported` 端点而不是 `internal`。

```bash
# Enable PKI in a new path for intermediate CA
vault secrets enable --path istioca pki

# Update lease time to 5 years
vault secrets tune -max-lease-ttl=43800h istioca

# Create Intermediate CA cert and Key
vault write istioca/intermediate/generate/exported common_name="tetrate.io Intermediate Authority" ttl=43800h

Key                 Value
---                 -----
csr                 -----BEGIN CERTIFICATE REQUEST-----
MIICcTCCAVkCAQAwLDEqMCgGA1UEAxMhdGV0cmF0ZS5pbyBJbnRlcm1lZGlhdGUg
...
...
7HJEy22yCFvVcR+Gtf++iZG+w04E2ah99xrzb+NdWDgw6asBg7oJg/bJQoA4/Wb5
OX2jl0E=
-----END CERTIFICATE REQUEST-----
private_key         -----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEA8Vmm2urwUHdAp1j3vs8aOqYGrDz3NwJbm6du+3WmgGHQ+sEC
...
...
yri2DiQWzwk3zIvzNSSbQdACPPeF90BLFW9L4xvN8D6gBxFL0wBa7GY=
-----END RSA PRIVATE KEY-----
private_key_type    rsa
```

将证书签名请求（CSR）复制到本地文件 `istioca.csr` 中（包括 `-----BEGIN CERTIFICATE REQUEST-----` 和 `-----END CERTIFICATE REQUEST-----`）。

将 CA 密钥复制到本地文件 `istioca.key` 中。建议在安全的地方备份此密钥。

现在我们可以使用 Vault CA 对 CSR 进行签名：

```bash
vault write pki/root/sign-intermediate csr=@istioca.csr format=pem_bundle ttl=43800h
 
Key              Value
---              -----
certificate      -----BEGIN CERTIFICATE-----
MIIDMDCCAhigAwIBAgIUGJgs6yFbK/eDW31RpdSiNeVQYvUwDQYJKoZIhvcNAQEL
...
...
PcPHltvhXDjckPK1jt9gpLMTaBhe9uu7Ve7b2OFv+mtAGiCEvALv+ddLa0GHrl3s
f2vq6A==
-----END CERTIFICATE-----
expiration       1618951159
issuing_ca       -----BEGIN CERTIFICATE-----
MIIDLDCCAhSgAwIBAgIUFVRq5X/cAOlDKl/h34VudUdSiMwwDQYJKoZIhvcNAQEL
...
...
d4SklUyQdxnW96IdkHSPWf46jh31tDWqco6LzmrxD4OmjSeLaf0zeErU1i41xAnW
-----END CERTIFICATE-----
serial_number    18:98:2...:f5
```

将 `certificate` 保存到名为 `istioca.crt` 的文件中。

### 将中间 CA 证书添加到 Vault

现在我们需要将已签名的中间 CA 证书放入 Vault 中。

```bash
vault write istioca/intermediate/set-signed certificate=@istioca.crt
```

Istio 还将基于中间 CA 证书生成证书，并需要证书及其密钥。虽然 Vault 可以通过其 API 发送证书，但我们必须注意密钥。为此，我们将密钥的副本放在 Vault Secret 中以备后用。

如果尚未启用，请启用 `kv` Secrets 引擎。

```bash
vault secrets enable kv
Success! Enabled the kv secrets engine at: kv/
```

现在将 CA 密钥保存在其中。

```bash
vault kv put kv/istioca ca-key.pem=@istioca.key
```

## 配置 Vault-Injector

配置一个与 Istio 的 Kubernetes Service Account 匹配的 Vault 角色。这个角色将被 Vault-Injector 使用。在以下示例中，角色名为 `istiod`，与 `istiod` 服务帐户 `istiod-service-account` 绑定。

启用 Kubernetes 认证方法：

```bash
vault auth enable kubernetes
```

创建名为 `istiod` 的角色：

```bash
vault write auth/kubernetes/role/istiod \
    bound_service_account_names=istiod-service-account \
    bound_service_account_namespaces=istio-system \
    policies=istioca \
    period=600s
```

启用 `istiod-service-account` 以通过 vault-inject 容器与 Vault 进行通信：

```bash
export VAULT_SA_NAME=$(kubectl get sa -n istio-system istiod-service-account \
    --output jsonpath="{.secrets[*]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret -n istio-system $VAULT_SA_NAME \
    --output 'go-template={{ .data.token }}' | base64 --decode)
export SA_CA_CRT=$(kubectl config view --raw --minify --flatten \
    --output 'jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode)
export K8S_HOST=$(kubectl config view --raw --minify --flatten \
    --output 'jsonpath={.clusters[].cluster.server}')

vault write auth/kubernetes/config \
        token_reviewer_jwt="$SA_JWT_TOKEN" \
        kubernetes_host="$K8S_HOST" \
        kubernetes_ca_cert="$SA_CA_CRT"
```

创建一个允许上述角色访问 PKI Secret 后端的策略。此策略使 Istio 能够读取存储了中间 CA 密钥的 `secret/data/istioca` 中的键/值。它还允许 Istio 访问中间 CA 和 CA 链（通过使用 `*`）以及根 CA。

```bash
cat > policy.hcl <<EOF
path "kv/istioca" {
    capabilities = ["read", "list"]
}
path "istioca/cert/*" {
    capabilities = ["read", "list"]
}
path "pki/cert/ca" {
    capabilities = ["read", "list"]
}
EOF
vault policy write istioca policy.hcl
```

## 配置 TSB ControlPlane CRD

更新你的 `ControlPlane` CR 或 Helm 值，并添加特定的 `istiod` 组件配置以使用 Vault：

```yaml
spec:
  components:
    istio:
      kubeSpec:
        overlays:
        - apiVersion: install.istio.io/v1alpha1
          kind: IstioOperator
          name: tsb-istiocontrolplane
          patches:
          - path: spec.meshConfig.defaultConfig.holdApplicationUntilProxyStarts
            value: true
          - path: spec.components.pilot.k8s.env
            value:
            - name: ROOT_CA_DIR
              value: /vault/secrets
          - path: spec.components.pilot.k8s.podAnnotations
            value:
              vault.hashicorp.com/agent-inject: "true"
              vault.hashicorp.com/agent-inject-secret-ca-cert.pem: istioca/cert/ca
              vault.hashicorp.com/agent-inject-secret-ca-key.pem: kv/istioca
              vault.hashicorp.com/agent-inject-secret-cert-chain.pem: istioca/cert/ca_chain
              vault.hashicorp.com/agent-inject-secret-root-cert.pem: pki/cert/ca
              vault.hashicorp.com/agent-inject-template-ca-cert.pem: |
                {{- with secret "istioca/cert/ca" -}}
                {{ .Data.certificate  }}
                {{- end }}
              vault.hashicorp.com/agent-inject-template-ca-key.pem: |
                {{- with secret "kv/istioca" -}}
                {{ index .Data "ca-key.pem" }}
                {{- end }}
              vault.hashicorp.com/agent-inject-template-cert-chain.pem: |
                {{- with secret "istioca/cert/ca_chain" -}}
                {{ .Data.certificate  }}
                {{- end }}
              vault.hashicorp.com/agent-inject-template-root-cert.pem: |
                {{- with secret "pki/cert/ca" -}}
                {{ "" | or ( .Data.certificate ) }}
                {{- end }}
              vault.hashicorp.com/role: istiod
              vault.hashicorp.com/secret-volume-path: /etc/cacerts-vault
```

这里，我们添加了一个名为 `ROOT_CA_DIR` 的环境变量，将 Istio 指向从 Vault 创建新 CA 文件的目录。然后，我们添加了 Vault-Injector 注释以创建证书。

注释由来自 Vault 的 `secret` 和定义如何在磁盘上创建文件的模板组成。我们为每个证书组件创建一个文件（证书、密钥、链和根）。

## 故障排除

如果出现问题，例如 `istiod` pod 无法启动，请检查日志：

#### 初始化阶段 Pod 失败

检查 `istiod` pod 中的 Vault-Injector 日志：

```bash
kubectl logs -n istio-system deployment/istiod -c vault-agent-init
```

#### 初始化后 Pod 失败

```bash
kubectl logs -n istio-system deployment/istiod -c vault-agent
```

#### `istiod` 进程崩溃

如果证书不起作用，Vault-Injector 将正常工作，但 `istiod` 将无法启动。检查 `istiod` 日志：

```bash
kubectl logs -n istio-system deployment/istiod -c discovery
```
