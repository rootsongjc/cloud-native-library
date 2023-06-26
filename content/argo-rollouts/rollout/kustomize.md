---
weight: 11
title: "Kustomize 集成"
linkTitle: "Kustomize"
date: '2023-06-21T16:00:00+08:00'
type: book
tags: ["kustomize","Argo Rollouts"]
---

可以通过使用[转换器配置](https://github.com/kubernetes-sigs/kustomize/tree/master/examples/transformerconfigs)来扩展 Kustomize 以理解 CRD 对象。使用转换器配置，可以“教授”kustomize 有关 Rollout 对象的结构，并利用 kustomize 功能，例如 ConfigMap/Secret 生成器、变量引用以及通用标签和注释。要将 Rollouts 与 kustomize 结合使用：

1. 下载 [`rollout-transform.yaml`](kustomize/rollout-transform.yaml) 到你的 kustomize 目录。

2. 在你的 kustomize `configurations` 部分中包含 `rollout-transform.yaml`：

```yaml
kind: Kustomization
apiVersion: kustomize.config.k8s.io/v1beta1

configurations:
- rollout-transform.yaml
```

展示了使用 Rollouts 中的转换器的能力的 kustomize 应用程序示例可以在[这里](https://github.com/argoproj/argo-rollouts/blob/master/docs/features/kustomize/example)看到。

- 在 Kustomize 3.6.1 中，可以直接从远程资源引用配置：

```yaml
configurations:
  - https://argoproj.github.io/argo-rollouts/features/kustomize/rollout-transform.yaml
```

- 使用 Kustomize 4.5.5，kustomize 可以使用 Kubernetes OpenAPI 数据获取关于[资源类型](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/openapi)的合并键和补丁策略信息。例如，给定以下 Rollout：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: rollout-canary
spec:
  strategy:
    canary:
      steps:
      # 详细的金丝雀步骤已省略
  template:
    metadata:
      labels:
        app: rollout-canary
    spec:
      containers:
      - name: rollouts-demo
        image: argoproj/rollouts-demo:blue
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
```

用户可以通过 kustomization 文件中的补丁来更新 Rollout，将镜像更改为 nginx：

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- rollout-canary.yaml

openapi:
  path: https://raw.githubusercontent.com/argoproj/argo-schema-generator/main/schema/argo_all_k8s_kustomize_schema.json

patchesStrategicMerge:
- |-
  apiVersion: argoproj.io/v1alpha1
  kind: Rollout
  metadata:
    name: rollout-canary
  spec:
    template:
      spec:
        containers:
        - name: rollouts-demo
          image: nginx
```

OpenAPI 数据是自动生成的，并在此[文件](https://github.com/argoproj/argo-schema-generator/blob/main/schema/argo_all_k8s_kustomize_schema.json)中定义。

展示了使用 OpenAPI 数据与 Rollouts 的 kustomize 应用程序示例可以在[这里](https://github.com/argoproj/argo-rollouts/blob/master/test/kustomize/rollout)看到。
