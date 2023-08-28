---
title: 入口网关
weight: 7
---

在本部分中，你将配置 Ingress Gateway 以允许外部流量到达 TSB 环境中的 bookinfo 应用程序。

## 先决条件

在继续之前，请确保你已完成以下任务：

- 熟悉 TSB 概念。
- 安装 TSB 演示环境。
- 部署 Istio Bookinfo 示例应用程序。
- 创建租户和工作区。
-  创建配置组。
-  配置权限。

## 创建入口网关对象

你将创建一个 Ingress Gateway 对象来为你的 bookinfo 应用程序启用外部流量。

### 创建 `ingress.yaml`

创建一个名为 `ingress.yaml` 的文件，其中包含以下内容：

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: tsb-gateway-bookinfo
  namespace: bookinfo
spec:
  selector:
    app: tsb-gateway-bookinfo
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
```

使用 `kubectl` 应用配置：

```bash
kubectl apply -f ingress.yaml
```

接下来，获取 Ingress Gateway IP（或 AWS 的主机名）并将其存储在环境变量中：

```bash
export GATEWAY_IP=$(kubectl -n bookinfo get service tsb-gateway-bookinfo -o jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}")
```

你可以使用以下方法验证分配的 IP：

```bash
echo $GATEWAY_IP
```

## 为网关配置 TLS 证书

现在，为你的网关设置 TLS 证书。如果你已为你的域准备好 TLS 证书，则可以直接使用它。或者，使用提供的脚本创建自签名证书。

将以下脚本保存为 `gen-cert.sh` ，使其可执行，然后运行它：

```bash
chmod +x gen-cert.sh
./gen-cert.sh bookinfo bookinfo.tetrate.com .
```

创建 Kubernetes 密钥来存储证书。将路径替换为密钥和证书文件的实际路径：

```bash
kubectl -n bookinfo create secret tls bookinfo-certs \
    --key bookinfo.key \
    --cert bookinfo.crt
```

## 使用 UI 配置 Ingress 网关

1. 从工作区列表中，单击“网关组”。
2. 选择你之前创建的 `bookinfo-gw` 网关组。
3. 导航到顶部选项卡上的网关设置以显示网关的配置视图。
4. 单击配置项的名称可显示其可配置字段。如果该项目有子项，请通过单击左侧的箭头将其展开。
5. 使用以下步骤配置网关，确保最后保存更改以避免验证错误：
   - 添加一个新的 Ingress Gateway，默认名称为 `default-ingressgateway` 并将其重命名为 `bookinfo-gw-ingress` 。
   - 将工作负载选择器设置为：
     -  命名空间： `bookinfo`
     - 标签： `app` ，值为 `tsb-gateway-bookinfo`
   - 在 HTTP 服务器下，添加新的 HTTP 服务器：
     -  姓名： `bookinfo`
     -  端口： `8443`
     -  主机名： `bookinfo.tetrate.com`
   - 配置服务器 TLS 设置：
     -  TLS 模式：简单
     -  秘密名称： `bookinfo-certs`
   - 在“路由设置”下，添加 HTTP 规则并配置路由：
     -  服务主机： `<namespace>/productpage.bookinfo.svc.cluster.local`
     -  端口： `9080`
6.  保存更改。

## 使用 tctl 配置 Ingress 网关

创建具有必要配置的 `gateway.yaml` 文件，然后使用 `tctl` 应用它：

```bash
tctl apply -f gateway.yaml
```

## 测试入口流量

要测试你的入口是否正常工作，请使用以下 `curl` 命令，将 `$GATEWAY_IP` 替换为实际的入口网关 IP：

```bash
curl -k -s --connect-to bookinfo.tetrate.com:443:$GATEWAY_IP \
    "https://bookinfo.tetrate.com/productpage" | \
    grep -o "<title>.*</title>"
```

## 访问 Bookinfo 用户界面

要访问 bookinfo UI，请更新你的 `/etc/hosts` 文件以使 `bookinfo.tetrate.com` 解析为你的 Ingress Gateway IP：

```bash
echo "$GATEWAY_IP bookinfo.tetrate.com" | sudo tee -a /etc/hosts
```

现在，你可以在浏览器中访问 <https://bookinfo.tetrate.com/productpage>。请注意，由于是自签名证书，你的浏览器可能会显示安全警告。你通常可以通过浏览器中的“高级”或“继续”选项绕过此警告。
