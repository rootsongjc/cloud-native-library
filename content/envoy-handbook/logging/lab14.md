---
weight: 70
title: 实验 14：将 Envoy 的日志发送到 Google Cloud Logging
date: '2022-05-18T00:00:00+08:00'
type: book
---

在这个实验中，我们将学习如何将 Envoy 应用日志发送到 Google Cloud Logging。我们将在 GCP 中运行的虚拟机（VM）实例上运行 Envoy，配置 Envoy 实例，将应用日志发送到 GCP 中的云日志。配置 Envoy 实例将允许我们在日志资源管理器中查看 Envoy 的日志，获得日志分析，并使用其他谷歌云功能。

为了使用谷歌云的日志收集、分析和其他工具，我们需要安装云日志代理（Ops Agent）。

在这个演示中，我们将在一个单独的虚拟机上安装 Ops 代理。另外，请注意，其他云供应商可能使用不同的日志工具和服务。

## 安装 Ops 代理

在 Google Cloud，在你的地区创建一个新的虚拟机实例。一旦创建了虚拟机，我们就可以通过 SSH 进入该实例并安装 Ops 代理。

在虚拟机实例中，运行以下命令来安装 Ops 代理。

```sh
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
```

安装 Ops 代理的另一个选择是按照以下步骤进行。

1. 从 GCP 的导航页面，选择**监测**。
2. 在 \"监控 \" 导航页面，选择 \" **仪表盘 \"**。
3. 在仪表板表中，找到并点击**虚拟机实例**。
4. 选择一个没有安装代理的实例旁边的复选框（例如，**代理**栏显示*未检测到*）。
5. 点击**安装代理**按钮，在打开的窗口中，点击在**在 Cloud Shell 中运行**按钮，开始安装。

安装代理的命令将在 Cloud Shell 中打开。你需要做的最后一件事是按回车键开始安装。

下面是成功安装的命令和输出在 Cloud Shell 中的样子。

```sh
$ :> agents_to_install.csv && \
→ echo '"projects/envoy-project/zones/us-west1-a/instances/envoy-instance","[{""type"":""ops-agent""}]"' >> agents_to_install.csv && \
→ curl -sSO https://dl.google.com/cloudagents/mass-provision-google-cloud-ops-agents.py && \
→ python3 mass-provision-google-cloud-ops-agents.py --file agents_to_install.csv
2021-11-03T19:04:31.577710Z Processing instance: projects/peterjs-project/zones/us-west1-a/instances/some-instance.
---------------------Getting output-------------------------
Progress: |==================================================| 100.0% [1/1] (100.0%) completed; [1/1] (100.0%) succeeded; [0/1] (0.0%) failed;
Instance: projects/envoy-project/zones/us-west1-a/instances/envoy-instance successfully runs ops-agent. See log file in: ./google_cloud_ops_agent_provisioning/20211103-190431_576419/envoy-project_us-west1-a_envoy-instance.log

SUCCEEDED: [1/1] (100.0%)
FAILED: [0/1] (0.0%)
COMPLETED: [1/1] (100.0%)

See script log file: ./google_cloud_ops_agent_provisioning/20211103-190431_576419/wrapper_script.log
```

随着安装的进展，虚拟机实例仪表板中的**代理**列将显示待定。一旦代理安装完成，该值将变为 **Ops Agent**，这表明 Ops Agent 已成功安装。

现在我们可以通过 SSH 进入虚拟机实例，安装 func-e（用于运行 Envoy），创建一个基本的 Envoy 配置，并运行它，这样 Envoy 的应用日志就会被发送到 GCP 的云端日志。

## 安装 func-e

要在虚拟机上安装 func-e，请运行：

```sh
curl https://func-e.io/install.sh | sudo bash -s -- -b /usr/local/bin
```

我们可以运行 `func-e --version` 来检查安装是否成功。

## 发送 Envoy 应用日志到云端日志

让我们创建一个我们将在本实验中使用的原始 Envoy 配置。

```yaml
static_resources:
  listeners:
  - name: listener_0
    address:
      socket_address:
        address: 0.0.0.0
        port_value: 10000
    filter_chains:
    - filters:
      - name: envoy.filters.network.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          stat_prefix: ingress_http
          http_filters:
          - name: envoy.filters.http.router
          route_config:
            name: my_first_route
            virtual_hosts:
            - name: direct_response_service
              domains: ["*"]
              routes:
              - match:
                  prefix: "/"
                direct_response:
                  status: 200
                  body:
                    inline_string: "200"
```

将上述 YAML 保存为 `6-lab-3-gcp-logging.yaml`。

让我们来配置 Ops Agent，为 Envoy 创建一个新的接收器，描述如何检索日志。

```yaml
logging:
  receivers:
    envoy:
      type: files
      include_paths:
        - /var/log/envoy.log
  service:
    pipelines:
      default_pipeline:
        receivers: [envoy]
```

将上述内容保存到虚拟机实例上的 `/etc/google-cloud-ops-agent/config.yaml` 文件中。要重新启动 Ops Agent，请运行 `sudo service google-cloud-ops-agent restart`。

在 Ops Agent 使用新配置的情况下，我们可以运行 Envoy，并告诉它把日志写到 `/var/log/envoy.log` 文件中，代理会在那里接收。

```sh
sudo func-e run -c 6-lab-3-gcp-logging.yaml --log-path /var/log/envoy.log
```

接下来，我们可以点击日志，然后点击 GCP 中的日志资源管理器，查看虚拟机上运行的 Envoy 实例的日志。

![GCP的日志资源管理器中的 Envoy 日志](../../images/e6c9d24ely1gzxuj0mrbpj210l0a877q.jpg "GCP的日志资源管理器中的 Envoy 日志")

{{< cta cta_text="下一章" cta_link="../../admin-interface/" >}}
