---
weight: 4
linkTitle: VPA
title: "垂直 Pod 自动缩放"
date: '2023-06-21T16:00:00+08:00'
type: book
---

垂直 Pod 自动缩放（Vertical Pod Autoscaling，VPA）通过自动配置资源需求降低维护成本并提高集群资源利用率。

## VPA 模式

VPAs 有四种操作模式：

1. “Auto”：VPA 在创建 pod 时分配资源请求，使用首选的更新机制更新现有 pod 的资源请求。目前，这相当于“Recreate”（见下文）。一旦在不重启（“in-place”）更新 pod 请求方面可用，它可能会成为“Auto”模式的首选更新机制。注意：此 VPA 功能是实验性的，可能会导致你的应用停机。
2. “Recreate”：VPA 在创建 pod 时分配资源请求，并在请求的资源与新建议显著不同时将其从现有 pod 中驱逐出来（如果定义了 Pod Disruption Budget，则会尊重它）。只有在需要确保每当资源请求更改时都重启 pod 时才应使用此模式。否则，请优先考虑“Auto”模式，一旦可用，该模式可以利用不重启更新。注意：此 VPA 功能是实验性的，可能会导致你的应用停机。
3. “Initial”：VPA 仅在创建 pod 时分配资源请求，从不更改它们。
4. “Off”：VPA 不会自动更改 pod 的资源要求。建议计算并可以在 VPA 对象中进行检查。

## 示例

以下是使用 Argo-Rollouts 的垂直 Pod 自动缩放器的示例。

Rollout 示例应用程序：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: vpa-demo-rollout
  namespace: test-vpa
spec:
  replicas: 5
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {duration: 10}
      - setWeight: 40
      - pause: {duration: 10}
      - setWeight: 60
      - pause: {duration: 10}
      - setWeight: 80
      - pause: {duration: 10}
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: vpa-demo-rollout
  template:
    metadata:
      labels:
        app: vpa-demo-rollout
    spec:
      containers:
      - name: vpa-demo-rollout
        image: ravihari/nginx:v1
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: "5m"       
            memory: "5Mi" 
```

Rollout 示例应用程序的 VPA 配置：

```yaml  
apiVersion: "autoscaling.k8s.io/v1beta2"
kind: VerticalPodAutoscaler  
metadata:  
  name: vpa-rollout-example  
  namespace: test-vpa  
spec:  
  targetRef:  
    apiVersion: "argoproj.io/v1alpha1"  
    kind: Rollout  
    name: vpa-demo-rollout  
  updatePolicy:  
    updateMode: "Auto"  
  resourcePolicy:  
    containerPolicies:  
    - containerName: '*'  
    minAllowed:  
      cpu: 5m  
      memory: 5Mi  
    maxAllowed:  
      cpu: 1  
      memory: 500Mi  
    controlledResources: ["cpu", "memory"]  
```

最初部署时描述 VPA 时，我们不会看到推荐，因为它需要几分钟时间才能完成。

```yaml
Name:         kubengix-vpa
Namespace:    test-vpa
Labels:       <none>
Annotations:  <none>
API Version:  autoscaling.k8s.io/v1
Kind:         VerticalPodAutoscaler
Metadata:
  Creation Timestamp:  2022-03-14T12:54:06Z
  Generation:          1
  Managed Fields:
    API Version:  autoscaling.k8s.io/v1beta2
    Fields Type:  FieldsV1
    fieldsV1:
      f:metadata:
        f:annotations:
          .:
          f:kubectl.kubernetes.io/last-applied-configuration:
      f:spec:
        .:
        f:resourcePolicy:
          .:
          f:containerPolicies:
        f:targetRef:
          .:
          f:apiVersion:
          f:kind:
          f:name:
        f:updatePolicy:
          .:
          f:updateMode:
    Manager:         kubectl-client-side-apply
    Operation:       Update
    Time:            2022-03-14T12:54:06Z
  Resource Version:  3886
  UID:               4ac64e4c-c84b-478e-92e4-5f072f985971
Spec:
  Resource Policy:
    Container Policies:
      Container Name:  *
      Controlled Resources:
        cpu
        memory
      Max Allowed:
        Cpu:     1
        Memory:  500Mi
      Min Allowed:
        Cpu:     5m
        Memory:  5Mi
  Target Ref:
    API Version:  argoproj.io/v1alpha1
    Kind:         Rollout
    Name:         vpa-demo-rollout
  Update Policy:
    Update Mode:  Auto
Events:           <none>
```

几分钟后，VPA 开始处理并提供建议：

```yaml
Name:         kubengix-vpa
Namespace:    test-vpa
Labels:       <none>
Annotations:  <none>
API Version:  autoscaling.k8s.io/v1
Kind:         VerticalPodAutoscaler
Metadata:
  Creation Timestamp:  2022-03-14T12:54:06Z
  Generation:          2
  Managed Fields:
    API Version:  autoscaling.k8s.io/v1beta2
    Fields Type:  FieldsV1
    fieldsV1:
      f:metadata:
        f:annotations:
          .:
          f:kubectl.kubernetes.io/last-applied-configuration:
      f:spec:
        .:
        f:resourcePolicy:
          .:
          f:containerPolicies:
        f:targetRef:
          .:
          f:apiVersion:
          f:kind:
          f:name:
        f:updatePolicy:
          .:
          f:updateMode:
    Manager:      kubectl-client-side-apply
    Operation:    Update
    Time:         2022-03-14T12:54:06Z
    API Version:  autoscaling.k8s.io/v1
    Fields Type:  FieldsV1
    fieldsV1:
      f:status:
        .:
        f:conditions:
        f:recommendation:
          .:
          f:containerRecommendations:
    Manager:         recommender
    Operation:       Update
    Time:            2022-03-14T12:54:52Z
  Resource Version:  3950
  UID:               4ac64e4c-c84b-478e-92e4-5f072f985971
Spec:
  Resource Policy:
    Container Policies:
      Container Name:  *
      Controlled Resources:
        cpu
        memory
      Max Allowed:
        Cpu:     1
        Memory:  500Mi
      Min Allowed:
        Cpu:     5m
        Memory:  5Mi
  Target Ref:
    API Version:  argoproj.io/v1alpha1
    Kind:         Rollout
    Name:         vpa-demo-rollout
  Update Policy:
    Update Mode:  Auto
Status:
  Conditions:
    Last Transition Time:  2022-03-14T12:54:52Z
    Status:                True
    Type:                  RecommendationProvided
  Recommendation:
    Container Recommendations:
      Container Name:  vpa-demo-rollout
      Lower Bound:
        Cpu:     25m
        Memory:  262144k
      Target:
        Cpu:     25m
        Memory:  262144k
      Uncapped Target:
        Cpu:     25m
        Memory:  262144k
      Upper Bound:
        Cpu:     1
        Memory:  500Mi
Events:          <none>
```

在这里，我们可以看到 CPU、内存的建议，以及较低的界限、较高的界限、目标等等。如果我们检查 Pod 的状态，旧的 Pod 会被终止，新的 Pod 会被创建。

```yaml
# kubectl get po -n test-vpa -w   
NAME                               READY   STATUS    RESTARTS   AGE
vpa-demo-rollout-f5df6d577-65f26   1/1     Running   0          17m
vpa-demo-rollout-f5df6d577-d55cx   1/1     Running   0          17m
vpa-demo-rollout-f5df6d577-fdpn2   1/1     Running   0          17m
vpa-demo-rollout-f5df6d577-jg2pw   1/1     Running   0          17m
vpa-demo-rollout-f5df6d577-vlx5x   1/1     Running   0          17m
...

vpa-demo-rollout-f5df6d577-jg2pw   1/1     Terminating   0          17m
vpa-demo-rollout-f5df6d577-vlx5x   1/1     Terminating   0          17m
vpa-demo-rollout-f5df6d577-jg2pw   0/1     Terminating   0          18m
vpa-demo-rollout-f5df6d577-vlx5x   0/1     Terminating   0          18m
vpa-demo-rollout-f5df6d577-w7tx4   0/1     Pending       0          0s
vpa-demo-rollout-f5df6d577-w7tx4   0/1     Pending       0          0s
vpa-demo-rollout-f5df6d577-w7tx4   0/1     ContainerCreating   0          0s
vpa-demo-rollout-f5df6d577-vdlqq   0/1     Pending             0          0s
vpa-demo-rollout-f5df6d577-vdlqq   0/1     Pending             0          1s
vpa-demo-rollout-f5df6d577-jg2pw   0/1     Terminating         0          18m
vpa-demo-rollout-f5df6d577-jg2pw   0/1     Terminating         0          18m
vpa-demo-rollout-f5df6d577-vdlqq   0/1     ContainerCreating   0          1s
vpa-demo-rollout-f5df6d577-w7tx4   1/1     Running             0          6s
vpa-demo-rollout-f5df6d577-vdlqq   1/1     Running             0          7s
vpa-demo-rollout-f5df6d577-vlx5x   0/1     Terminating         0          18m
vpa-demo-rollout-f5df6d577-vlx5x   0/1     Terminating         0          18m
```

如果我们检查新的 Pod CPU 和内存，它们会根据 VPA 的建议进行更新：


```yaml
# kubectl describe po vpa-demo-rollout-f5df6d577-vdlqq -n test-vpa
Name:         vpa-demo-rollout-f5df6d577-vdlqq
Namespace:    test-vpa
Priority:     0
Node:         argo-rollouts-control-plane/172.18.0.2
Start Time:   Mon, 14 Mar 2022 12:55:06 +0000
Labels:       app=vpa-demo-rollout
              rollouts-pod-template-hash=f5df6d577
Annotations:  vpaObservedContainers: vpa-demo-rollout
              vpaUpdates: Pod resources updated by kubengix-vpa: container 0: cpu request, memory request
Status:       Running
IP:           10.244.0.17
IPs:
  IP:           10.244.0.17
Controlled By:  ReplicaSet/vpa-demo-rollout-f5df6d577
Containers:
  vpa-demo-rollout:
    Container ID:   containerd://b79bd88851fe0622d33bc90a1560ca54ef2c27405a3bc9a4fc3a333eef5f9733
    Image:          ravihari/nginx:v1
    Image ID:       docker.io/ravihari/nginx@sha256:205961b09a80476af4c2379841bf6abec0022101a7e6c5585a88316f7115d17a
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Mon, 14 Mar 2022 12:55:11 +0000
    Ready:          True
    Restart Count:  0
    Requests:
      cpu:        25m
      memory:     262144k
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-mk4fz (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  kube-api-access-mk4fz:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   Burstable
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  38s   default-scheduler  Successfully assigned test-vpa/vpa-demo-rollout-f5df6d577-vdlqq to argo-rollouts-control-plane
  Normal  Pulled     35s   kubelet            Container image "ravihari/nginx:v1" already present on machine
  Normal  Created    35s   kubelet            Created container vpa-demo-rollout
  Normal  Started    33s   kubelet            Started container vpa-demo-rollout
```

## 要求

为了让 VPA 操纵 Rollout，托管 Rollout CRD 的 Kubernetes 集群需要支持 CRD 的子资源。这个功能在 Kubernetes 1.10 版本中引入了 alpha，并在 Kubernetes 1.11 版本中转换为 beta。如果用户想在 v1.10 上使用 VPA，则 Kubernetes 集群操作员需要向 API 服务器添加自定义功能标志。1.10 之后，该标志默认为开启状态。请查看以下[链接](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/)以获取有关设置自定义功能标志的更多信息。

安装 VPA 时，你可能需要将以下内容添加到 RBAC 配置中，以便为 `system:vpa-target-reader` 集群角色添加支持，因为默认情况下 VPA 可能不支持所有版本的 Rollout。

```yaml
  - apiGroups:
      - argoproj.io
    resources:
      - rollouts
      - rollouts/scale
      - rollouts/status
      - replicasets
    verbs:
      - get
      - list
      - watch
```

确保在群集中安装了 Metrics-Server，并且 openssl 更新到最新版本，以便 VPA 的最新版本能够正确地将建议应用于 Pod。
