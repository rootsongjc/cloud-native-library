---
title: 在本地载入工作负载
description: 如何在本地载入工作负载。
weight: 6
---

本文档描述了使用工作负载载入功能将本地工作负载载入 TSB 的步骤。

在继续之前，请确保你已完成[设置工作负载载入文档](../setup)中描述的步骤。

## 背景

通过工作负载载入加入网格的每个工作负载都必须具有可验证的身份。

云中的 VM 具有开箱即用的可验证身份。此类身份由各云平台提供。

然而，在本地环境中，是一个黑盒。你的本地工作负载是否具有可验证的身份完全取决于你自己的技术堆栈。

因此，要能够载入本地工作负载，你需要确保它们具有[JWT 令牌](https://openid.net/specs/openid-connect-core-1_0.html#IDToken)形式的可验证身份。

## 概述

本地工作负载的工作负载载入设置包括以下额外步骤：

1. 配置受信任的 JWT 发行者
1. 允许本地工作负载加入 WorkloadGroup
1. 配置工作负载载入代理以使用你的自定义凭证插件
1. 载入本地工作负载

## 配置受信任的 JWT 发行者

要配置一组受信任的 JWT 发行者，用于断言本地工作负载的身份，请按以下方式编辑 TSB
[`ControlPlane`](../../../../refs/install/controlplane/v1alpha1/spec) CR 或 Helm values：

```yaml
spec:
  ...
  meshExpansion:
    onboarding:
      ...
      # 专用于本地工作负载的额外配置
      workloads:
        authentication:
          jwt:
            issuers:
            - issuer: <jwt-issuer-id>                        # (1) 必填
              shortName: <short-name>                        # (2) 必填
              jwksUri: <jwks-uri>                            # (3) 可选
              jwks: |
                # {
                #   "keys": [
                #     ...
                #   ]
                # }
                <inlined-jwks-document>                      # (4) 可选
              tokenFields:
                attributes:
                  jsonPath: <jwt-attributes-field-jsonpath>  # (5) 可选
```

其中

1. 必须指定要信任的 JWT `发行者ID`，例如 `https://mycompany.corp`
1. 必须指定要与该发行者关联的简称，例如 `my-corp`
1. 可以指定从中获取签名密钥的 JWKS 文档的 URI，例如
   `https://mycompany.corp/jwks.json`
1. 可以指定一个 JWKS 文档，其中包含签名密钥
1. 可以指定 JWT 令牌内部保存有关工作负载的属性映射的字段，例如 `.custom_attributes`

## 允许本地工作负载加入 WorkloadGroup

要允许本地工作负载加入某些 WorkloadGroup，请创建以下配置的[OnboardingPolicy](../../../../refs/onboarding/config/authorization/v1alpha1/policy)：

```yaml
apiVersion: authorization.onboarding.tetrate.io/v1alpha1
kind: OnboardingPolicy
metadata:
  name: <name>
  namespace: <namespace>
spec:
  allow:
  - workloads:
    - jwt:
        issuer: <jwt-issuer-id>                          # (1) 必填
        subjects:
        - <subject>                                      # (2) 可选
        attributes:
        - name: <attribute-name>                         # (3) 可选
          values:
          - <attribute-value>
    onboardTo:
    - workloadGroupSelector: {} # 该命名空间中的任何 WorkloadGroup
```

其中

1. 必须指定此规则适用的 JWT `发行者ID`，例如
   `https://mycompany.corp`
1. 可以指定此规则适用于的 JWT 主体的显式列表，例如 `us-east-datacenter1-vm007`
1. 可以指定 JWT 必须具有的工作负载属性，以使此规则适用，例如 `region=us-east`

## 配置工作负载载入代理以使用你的自定义凭证插件

为了能够载入本地工作负载，你需要使用一个生成给定工作负载的[JWT 令牌](https://openid.net/specs/openid-connect-core-1_0.html#IDToken)凭证的凭证插件。

首先，在 VM 上安装你的自定义凭证插件，例如在`/usr/local/bin/onboarding-agent-<your-plugin-name>-plugin`。

然后，[配置工作负载载入代理](../../../../refs/onboarding/config/agent/v1alpha1/agent_configuration)以使用该插件。
为此，请按照以下方式编辑 `/etc/onboarding-agent/onboarding.config.yaml`：

```yaml
apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
kind: AgentConfiguration
host:
  custom:
    credential:
    - plugin:
        name: <your-plugin-name>                                         # (1) 必填
        path: /usr/local/bin/onboarding-agent-<your-plugin-name>-plugin  # (2) 可选
        args:
        - <your-plugin-arg>                                              # (3) 可选
        env:
        - name: <YOUR_PLUGIN_CONFIG>                                     # (4) 可选
          value: "<your-plugin-config-value>"
```

其中

1. 必须指定你的凭证插件的名称，例如 `my-jwt-credential`
1. 可以指定插件二进制文件的路径，例如 `/usr/local/bin/onboarding-agent-my-jwt-credential-plugin`
1. 可以指定工作负载载入代理在执行插件二进制文件时必须传递的其他命令行参数，例如 `--

my-arg=my-value`
1. 可以指定工作负载载入代理在执行插件二进制文件时必须设置的其他环境变量，例如 `MY_CONFIG="some value"`

## 载入本地工作负载

要载入本地工作负载，[按照与云中 VM 相同的步骤](../onboarding)进行操作。
