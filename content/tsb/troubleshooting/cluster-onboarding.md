---
title: 集群载入故障排除
description: 如何排除控制平面载入问题。
weight: 9
---

本文档解释了将新的控制平面引入 TSB 时最常见的问题。

## 连接性

部署 `tsb-operator-control-plane` 需要与管理平面 URL 具有连接性。通信是通过 `tsb` 命名空间中的 `front-envoy` 组件执行的，由 `envoy` 服务提供。

请确保控制平面可以访问它，且没有被网络策略、安全组或任何防火墙阻止。

## 故障排除

一旦你已经应用了[必要的机密](../../setup/helm/controlplane#secrets-configuration)，安装了控制平面 Operator，并创建了控制平面 CR，如果存在一些配置错误，一些 Pod 可能无法启动。始终检查 `tsb-operator-control-plane` 的日志，因为它将提供有关可能出错的详细信息。

### 服务帐号问题

如果未创建用于生成令牌的服务帐号，你将收到以下错误：

```bash
error	controlplane	token rotation failed, retrying in 15m0s: secret istio-system/cluster-service-account not found: Secret "cluster-service-account" not found [scope="controlplane"]
```

或者也可能发生配置不正确的情况：

```bash
error	controlplane	token rotation failed, retrying in 15m0s: cluster has been configured with incorrect service account secret. ControlPlane CR has cluster name "demo", but service account secret has "organizations/tetrate/clusters/not-demo" [scope="controlplane"]
```

在此示例中，我们创建了名为 `demo` 的集群对象，但在 CP 中，我们正在为名为 `not-demo` 的集群生成服务帐号。要解决此问题，你需要在 `values.yaml` 文件中添加集群名称和服务帐号令牌以安装 CP。首先生成令牌：

```bash
tctl install cluster-service-account --cluster demo > /tmp/demo.jwk
```

然后在 `values.yaml` 文件中配置集群名称和 JWK 文件：

```yaml
secrets:
  tsb:
  ...
  clusterServiceAccount:
    clusterFQN: organizations/tetrate/clusters/demo
    JWK: |
      '{{ .Secrets.ClusterServiceAccount.JWK }}'
```

集群名称必须与控制平面 CR 中的 `spec.managementPlane.clusterName` 中添加的集群名称匹配。

{{<callout note 注意>}}
记得重新启动 `tsb-operator-control-plane` Pod 以生成机密，一旦生成，重新启动控制平面 Pod。
{{</callout>}}

### 控制平面证书问题

如果在管理平面中配置的 `tsb-certs` 证书不包含与控制平面 CR 中的 `spec.managementPlane.host` 配置的正确 URI SAN，或者 `tsb` 命名空间中的 `tsb-certs` 和 `istio-system` 命名空间中的 `mp-cert` 都不包含相同的 URI SAN，或者它们没有由相同的根/中间 CA 签名，你将收到以下错误：

```bash
error	controlplane	token rotation failed, retrying in 7.153870785s: generate tokens: rpc error: code = Unavailable desc = connection error: desc = "transport: authentication handshake failed: tls: failed to verify certificate: x509: certificate is valid for demo.tsb.tetrate.io, not tsb.tetrate.io" [scope="controlplane"]
```

你可以通过在控制平面 `values.yaml` 文件中配置值 `secrets.tsb.cacert` 来更新 `mp-cert`，或者通过在管理平面 `values.yaml` 文件中配置值 `secrets.tsb.cert` 和 `secrets.tsb.key` 来更新 `tsb-certs`。

如果在 `tsb-certs` 中提供的证书由公共 CA（如 Digicert 或 Let’s Encrypt）签名，你可以让控制平面 CR 的默认值保持不变，但如果此证书由内部 CA 签名或者是自签名的，你可能会收到以下错误：

```bash
error	controlplane	token rotation failed, retrying in 1.661766738s: generate tokens: rpc error: code = Unavailable desc = connection error: desc = "transport: authentication handshake failed: x509: certificate signed by unknown authority" [scope="controlplane"]
```

如果是这种情况，你需要修改控制平面 CR 以将 `spec.managementPlane.selfSigned` 设置为 `true`。

{{<callout note 注意>}}
记得重新启动 `tsb-operator-control-plane` Pod 以生成机密，一旦生成，重新启动控制平面 Pod。
{{</callout>}}

### XCP 连接问题

如果新引入的集群没有报告集群状态或新配置未在集群中创建，请检查 `istio-system` 命名空间中的 `edge` Pod 日志，即使 Pod 正在运行，也可能存在一些问题。例如：

```bash
warn	stream	error getting stream. retrying in 21.72809085s: rpc error: code = Unavailable desc = connection error: desc = "transport: authentication handshake failed: tls: failed to verify certificate: x509: certificate is valid for xcp.tetrate.io, not tsb.tetrate.io"	name=configs-4d116fd6
```

在这种情况下，`tsb` 命名空间中的 `xcp-central-cert` 配置为 `xcp.tetrate.io`，但在控制平面 CR 中配置的主机是 `tsb.tetrate.io`。要更新证书，你需要根据[这个](../../../setup/helm/managementplane#xcp-secrets-configuration)更新管理平面 `values.yaml`。

如果 `edge` 无法启动，你可以描述 Pod 以获取更多信息。有时候无法启动是因为：

```bash
  Warning  FailedMount  7m15s (x7 over 7m47s)  kubelet            MountVolume.SetUp failed for volume "xcp-central-auth-jwt" : secret "xcp-edge-central-auth-token" not found
  Warning  FailedMount  

 5m44s                  kubelet            Unable to attach or mount volumes: unmounted volumes=[xcp-central-auth-ca], unattached volumes=[config-map-volume xcp-central-auth-jwt xcp-central-auth-ca xcp-edge-webhook-ca kube-api-access-hxk8l webhook-certs]: timed out waiting for the condition
  Warning  FailedMount   3m26s                  kubelet            Unable to attach or mount volumes: unmounted volumes=[xcp-central-auth-ca], unattached volumes=[xcp-edge-webhook-ca kube-api-access-hxk8l webhook-certs config-map-volume xcp-central-auth-jwt xcp-central-auth-ca]: timed out waiting for the condition
  Warning  FailedMount  95s (x11 over 7m47s)   kubelet            MountVolume.SetUp failed for volume "xcp-central-auth-ca" : secret "xcp-central-ca-bundle" not found
  Warning  FailedMount  69s                    kubelet            Unable to attach or mount volumes: unmounted volumes=[xcp-central-auth-ca], unattached volumes=[kube-api-access-hxk8l webhook-certs config-map-volume xcp-central-auth-jwt xcp-central-auth-ca xcp-edge-webhook-ca]: timed out waiting for the condition
```

此错误是因为 `istio-system` 命名空间中的秘密 `xcp-central-ca-bundle` 不存在。此秘密必须包含相同的 URI SAN，并且必须由 `tsb` 命名空间中的 `xcp-central-cert` 签名，并且必须由相同的根/中间 CA 签名。要配置此秘密，你需要更新控制平面 `values.yaml` 文件中的值 `secrets.xcp.rootca`。

{{<callout note 注意>}}
记得重新启动 `tsb-operator-control-plane` Pod 以生成机密，一旦生成，重新启动 `edge` Pod。
{{</callout>}}
