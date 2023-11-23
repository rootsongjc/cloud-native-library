---
title: 将虚拟机上的单体应用迁移到你的集群
weight: 2
---

本文将教你如何将虚拟机上的部分"单体"工作负载迁移到集群，并在虚拟机和集群之间分流流量。

在这个示例中，在虚拟机上运行的服务器将被视为"单体"应用程序。如果虚拟机正在调用其他虚拟机，可以按照相同的步骤进行操作。只需确保可以从你的集群解析并访问被调用的虚拟机。

在开始之前：
- [安装 TSB 管理平面](../../../setup/self-managed/management-plane-installation)
- 载入了一个[集群](../../../setup/self-managed/onboarding-clusters)
- [安装数据面操作员](../../../concepts/operators/data-plane)
- 配置一个虚拟机以运行在 TSB 工作负载中（本指南假定使用 Ubuntu 20.04）。

第一步是安装 Docker。

```bash
sudo apt-get update
sudo apt-get -y install docker.io
```

然后，运行 httpbin 服务器并测试其是否正常工作。

```bash
sudo docker run -d \
    --name httpbin \
    -p 127.0.0.1:80:80 \
    kennethreitz/httpbin
curl localhost/headers
{
    "headers": {
        "Accept": "*/*", 
        "Host": "localhost", 
        "User-Agent": "curl/7.68.0"
    }
}
```

接下来，将虚拟机载入到你的集群中，按照[VM 载入文档](../../../setup/workload-onboarding/onboarding-vms)的指示进行操作。
在你的集群中为你的虚拟机创建以下服务账户。

```bash
kubectl create namespace httpbin
kubectl label namespace httpbin istio-injection=enabled
cat <<EOF | kubectl apply -f-
apiVersion: v1
kind: ServiceAccount
metadata:
  name: httpbin
  labels:
    account: httpbin
  namespace: httpbin
EOF
```

调整你在虚拟机上载入的 WorkloadEntry，以适应你的工作负载。以下是 httpbin 的示例。

```yaml
apiVersion: networking.istio.io/v1beta1
kind: WorkloadEntry
metadata:
  name: httpbin-vm
  namespace: httpbin
  annotations:
    sidecar-bootstrap.istio.io/ssh-host: <ssh-host>
    sidecar-bootstrap.istio.io/ssh-user: istio-proxy
    sidecar-bootstrap.istio.io/proxy-config-dir: /etc/istio-proxy
    sidecar-bootstrap.istio.io/proxy-image-hub: docker.io/tetrate
    sidecar-bootstrap.istio.io/proxy-instance-ip: <proxy-instance-ip>
spec:
  address: <vm-address>
  labels:
    class: vm
    app: httpbin
    version: v1
  serviceAccount: httpbin
  network: <vm-network-name>
```

修改 Sidecar 资源，并确保已设置任何必要的防火墙规则，以允许流量流向你的虚拟机。

```yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: httpbin-no-iptables
  namespace: httpbin
spec:
  egress:
  - bind: 127.0.0.2
    hosts:
    - ./*
  ingress:
  - defaultEndpoint: 127.0.0.1:80
    port:
      name: http
      number: 80
      protocol: HTTP
  workloadSelector:
    labels:
      app: httpbin
      class: vm
```

在你的集群中，添加以下内容以配置从你的集群到虚拟机的流量流向。

```bash
cat <<EOF | kubectl apply -f-
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  labels:
    app: httpbin
  namespace: httpbin
spec:
  ports:
  - port: 80
    targetPort: 80
    name: http
  selector:
    app: httpbin
EOF
```

使用 tctl 应用入口网关配置，配置一个网关来接受流量并将其转发到虚拟机。

{{<callout note 注意>}}
在生产中使用时，应根据需要更新此配置以匹配你的设置。例如，如果你有一个工作空间或网关组，可以使用。
{{</callout>}}

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  name: foo-ws
  tenant: <tenant>
spec:
  namespaceSelector:
    names:
      - "*/httpbin"
---
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
  name: httpbin
  workspace: foo-ws
  tenant: <tenant>
spec:
  namespaceSelector:
    names:
      - "*/httpbin"
  configMode: BRIDGED
---
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
  name: httpbin
  group: httpbin
  workspace: foo-ws
  tenant: <tenant>
spec:
  workloadSelector: # 根据你正在配置的网关进行调整
    namespace: httpbin
    labels:
        app: httpbin-gateway
  http:
    - name: httpbin
      port: 8080
      hostname: "httpbin.tetrate.io"
      routing:
        rules:
          - route:
              host: "httpbin/httpbin.httpbin.svc.cluster.local"
              port: 80
```

在这一点上，你应该能够将流量发送到你的网关，主机为`httpbin.tetrate.io`，并且它应该被转发到你的虚拟机。

你可以通过手动设置主机标头并访问你的网关的 IP（例如`curl -v -H "Host: httpbin.tetrate.io" 34.122.114.216/headers`，其中`34.122.114.216`是你的网关的地址）来验证这一点。

现在，你可以将指向你的虚拟机的任何内容（DNS 或 L4 LB 等）指向你的集群网关。流量将流向你的集群，然后流向你的虚拟机。

现在，将在虚拟机上运行的 httpbin 工作负载添加到你的集群，并将流量的一部分发送到集群版本。首先，使用 tctl 应用以下配置（根据需要进行调整）。

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: Group
metadata:
  name: httpbin
  workspace: foo-ws
  tenant: <tenant>
spec:
  namespaceSelector:
    names:
      - "<cluster>/httpbin"
  configMode: BRIDGED
---
apiVersion: traffic.tsb.tetrate.io/v2
kind: ServiceRoute
metadata:
  name: httpbin
  group: httpbin
  workspace: foo-ws
  tenant: <tenant>
spec:
  service: httpbin/httpbin
  subsets:
  - name: v1
    labels:
      version: v1
    weight: 100
```

这将会将 100% 的流量发送到虚拟机，因为你在将应用程序部署到集群之前设置了这个。要开始流量分流，请在你的集群中运行以下命令。

```bash
cat <<EOF | kubectl apply -f-
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
  labels:
    app: httpbin
    version: v2
  namespace: httpbin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin
      version: v2
  template:
    metadata:
      labels:
        app: httpbin
        version: v2
    spec:
      serviceAccountName: httpbin
      containers:
      - name: httpbin
        image: kennethreitz/httpbin
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
EOF
```

验证应用程序是否在你的集群中运行。

现在编辑 TSB ServiceRoute 配置，包括在集群中部署的新 v2 版本，并使用`tctl`应用它（根据需要进行调整）。

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: ServiceRoute
metadata:
  name: httpbin
  group: httpbin
  workspace: foo-ws
  tenant: <tenant>
spec:
  service: httpbin/httpbin
  subsets:
  - name: v1
    labels:
      version: v1
    weight: 80
  - name: v2
    labels:
      version: v2
    weight: 20
```

现在，向你的应用程序发送一些请求通过你的网关。

你可以通过日志或 TSB UI 来验证流量在你的虚拟机和集群应用程序之间分流。

一旦你满意新版本的性能，你可以逐渐增加流量百分比，直到所有流量都被发送到你的集群，而不再流向虚拟机。
