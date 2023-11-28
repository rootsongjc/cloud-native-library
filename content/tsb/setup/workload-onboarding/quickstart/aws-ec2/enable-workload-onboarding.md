---
title: 启用工作负载上线
weight: 2
---

为了启用工作负载上线，你需要以下信息：

* 用于分配工作负载上线端点的 DNS 名称
* 该 DNS 名称的 TLS 证书

在本示例中，你将使用 DNS 名称 `onboarding-endpoint.example`，因为我们不希望你使用可路由的 DNS 名称。

## 准备证书

出于生产目的，你需要使用由可信任的证书颁发机构（CA）签名的 TLS 证书，例如 [Let's Encrypt](https://letsencrypt.org/) 或内部 CA（如 [Vault](https://www.vaultproject.io/)）。

在本示例中，你将设置一个示例 CA，它将在本指南的其余部分中使用。

通过执行以下命令创建一个自签名证书（`example-ca.crt.pem`）和
CA 私钥（`example-ca.key.pem`）：

```bash
openssl req \
  -x509 \
  -subj '/CN=Example CA' \
  -days 3650 \
  -sha256 \
  -newkey rsa:2048 \
  -nodes \
  -keyout example-ca.key.pem \
  -out example-ca.crt.pem \
  -config <(cat <<EOF
# "openssl req" 命令的配置部分
[ req ]
distinguished_name     = req                 # 包含要提示输入的显著名称字段的部分的名称
x509_extensions        = v3_ca               # 包含要添加到自签名证书的扩展列表的部分的名称

# 包含要添加到自签名证书的扩展列表的部分的名称
[ v3_ca ]
basicConstraints       = CA:TRUE             # 为了与破损的软件兼容性而不标记为关键
subjectKeyIdentifier   = hash                # PKIX 建议
authorityKeyIdentifier = keyid:always,issuer # PKIX 建议
EOF
)
```

然后，通过执行以下命令创建证书签名请求（`onboarding-endpoint.example.csr.pem`）和
工作负载上线端点的私钥（`onboarding-endpoint.example.key.pem`）：

```bash
openssl req \
  -subj '/CN=onboarding-endpoint.example' \
  -sha256 \
  -newkey rsa:2048 \
  -nodes \
  -keyout onboarding-endpoint.example.key.pem \
  -out onboarding-endpoint.example.csr.pem
```

最后，通过执行以下命令创建 DNS 名称 `onboarding-endpoint.example` 的证书
（`onboarding-endpoint.example.crt.pem`），该证书由你在前面步骤中创建的 CA 签名：

```bash
openssl x509 \
  -req \
  -days 3650 \
  -sha256 \
  -in onboarding-endpoint.example.csr.pem \
  -out onboarding-endpoint.example.crt.pem \
  -CA example-ca.crt.pem \
  -CAkey example-ca.key.pem \
  -CAcreateserial \
  -extfile <(cat <<EOF
# 包含要添加到证书的扩展列表的名称部分
extensions = usr_cert

# 包含要添加到证书的扩展列表的名称部分
[ usr_cert ]
basicConstraints       = CA:FALSE            # 为了与破损的软件兼容性而不标记为关键
subjectKeyIdentifier   = hash                # PKIX 建议
authorityKeyIdentifier = keyid:always,issuer # PKIX 建议

keyUsage               = digitalSignature, keyEncipherment
extendedKeyUsage       = serverAuth
subjectAltName         = DNS:onboarding-endpoint.example
EOF
)
```

然后，通过执行以下命令将证书部署到 Kubernetes 集群：

```bash
kubectl create secret tls onboarding-endpoint-tls-cert \
  -n istio-system \
  --cert=onboarding-endpoint.example.crt.pem \
  --key=onboarding-endpoint.example.key.pem
```

## 启用工作负载上线

一旦 TLS 证书准备好，你可以通过执行以下命令启用工作负载上线：

```bash
cat <<EOF | kubectl apply -f -
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  name: controlplane
  namespace: istio-system
spec:
  meshExpansion:
    onboarding:
      endpoint:
        hosts:
        - onboarding-endpoint.example
        secretName: onboarding-endpoint-tls-cert
      localRepository: {}
EOF
```

上述命

令指定了应使用 DNS 名称 `onboarding-endpoint.example` 设置工作负载上线端点，使用在 secret `onboarding-endpoint-tls-cert` 中可用的证书。

它还指定应部署一个本地存储库，其中包含用于 Workload Onboarding 代理和 Istio Sidecar 的 DEB/RPM 包。

执行上述命令后，请等待直到各个 Workload Onboarding 组件可用：

```bash
kubectl wait --for=condition=Available -n istio-system \
  deployment/vmgateway \
  deployment/onboarding-plane \
  deployment/onboarding-repository
```

## 验证工作负载上线端点

由于你未使用可路由的 DNS 名称，因此需要找出已公开的工作负载上线端点的地址。

执行以下命令以获取地址（DNS 名称或 IP 地址）：

```bash
ONBOARDING_ENDPOINT_ADDRESS=$(kubectl get svc vmgateway \
  -n istio-system \
  -ojsonpath="{.status.loadBalancer.ingress[0]['hostname', 'ip']}")
```

在本指南的其余部分中，你将使用存储在 `ONBOARDING_ENDPOINT_ADDRESS` 环境变量中的地址。

最后，执行以下命令以验证端点是否可用于外部流量。

```bash
curl -f -i \
  --cacert example-ca.crt.pem \
  --connect-to "onboarding-endpoint.example:443:${ONBOARDING_ENDPOINT_ADDRESS}:443" \
  "https://onboarding-endpoint.example/install/"
```

你应该会看到类似以下内容的输出：

```text
HTTP/2 200
content-type: text/html; charset=utf-8
server: istio-envoy

<pre>
<a href="deb/">deb/</a>
<a href="rpm/">rpm/</a>
</pre>
```