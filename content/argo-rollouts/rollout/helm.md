---
weight: 10
title: "将 Argo Rollouts 和 Helm 一起使用"
linkTitle: "Helm"
date: '2023-06-21T16:00:00+08:00'
type: book
tags: ["Helm","Argo Rollouts"]
---

Argo Rollouts 将始终响应 Rollouts 资源的更改，无论更改是如何进行的。这意味着 Argo Rollouts 与你可能用来管理部署的所有模板解决方案兼容。

Argo Rollouts 清单可以使用 [Helm 包管理器](https://helm.sh/)进行管理。如果你的 Helm Chart 包含 Rollout 资源，那么一旦你安装或升级 Chart，Argo Rollouts 将接管并启动渐进式交付流程。

以下是使用 Helm 管理的 Rollout 示例：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: {{ template "helm-guestbook.fullname" . }}
  labels:
    app: {{ template "helm-guestbook.name" . }}
    chart: {{ template "helm-guestbook.chart" . }}
    release: {{ .Release.Name }}
    heritage: {{ .Release.Service }}
spec:
  replicas: {{ .Values.replicaCount }}
  revisionHistoryLimit: 3
  selector:
    matchLabels:
      app: {{ template "helm-guestbook.name" . }}
      release: {{ .Release.Name }}
  strategy:
    blueGreen:
      activeService: {{ template "helm-guestbook.fullname" . }}
      previewService: {{ template "helm-guestbook.fullname" . }}-preview
  template:
    metadata:
      labels:
        app: {{ template "helm-guestbook.name" . }}
        release: {{ .Release.Name }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /
              port: http
          readinessProbe:
            httpGet:
              path: /
              port: http
          resources:
{{ toYaml .Values.resources | indent 12 }}
    {{- with .Values.nodeSelector }}
      nodeSelector:
{{ toYaml . | indent 8 }}
    {{- end }}
    {{- with .Values.affinity }}
      affinity:
{{ toYaml . | indent 8 }}
    {{- end }}
    {{- with .Values.tolerations }}
      tolerations:
{{ toYaml . | indent 8 }}
    {{- end }}

```

你可以在[此](https://github.com/argoproj/argo-rollouts/tree/master/examples/helm-blue-green)找到完整示例。
