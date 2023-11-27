---
title: Elasticsearch 清理流程
description: 按照描述的步骤清理 Elasticsearch 数据。
weight: 2
---

在某些情况下，由于 Elasticsearch 索引中的数据模型更改，需要清除现有的索引和模板，以便新版本的 OAP 可以正常运行。

下面的步骤描述了如何从 Elasticsearch 中清除此类数据并确保 OAP 组件将正确启动。

{{<callout warning "减少副本数">}}
确保在继续之前按照步骤 1 和步骤 2 进行操作
{{</callout>}}

**1. 将控制平面命名空间中的 `oap-deployment` 部署的副本数减少为 0。**

{{<callout warning 注意>}}
这需要在 TSB 中登记的所有 CP 集群中执行。
{{</callout>}}

```bash
kubectl -n ${CONTROL_NAMESPACE} scale deployment oap-deployment
--replicas=0
```

**2. 将管理命名空间中的 `oap` 部署的副本数减少为 0。**

```bash
kubectl -n ${MANAGEMENT_NAMESPACE} scale deployment oap --replicas=0
```

**3. 执行以下命令以删除 Elasticsearch 中的模板和索引。**

```bash
es_host=localhost
es_port=9200
es_user=<USER>
es_pass=<PASS>
for tmpl in $(curl -u "$es_user:$es_pass" -sS https://$es_host:$es_port/_cat/templates | \
  egrep "skywalking" | \
  awk '{print $1}'); do echo "$tmpl: "; curl -u "$es_user:$es_pass" -sS https://$es_host:$es_port/_index_template/$tmpl -XDELETE; echo "\n";
done
for idx in $(curl -u "$es_user:$es_pass" https://$es_host:$es_port/_cat/indices | \
  egrep "skywalking" | \
  awk '{print $3}'); do echo "$idx: "; curl -u "$es_user:$es_pass" https://$es_host:$es_port/$idx -XDELETE; echo "\n";
done
```

{{<callout note "选择日期">}}
如果你只想删除特定日期的索引，而不是删除所有内容，你只需将上面的命令添加到 grep 中，例如 ```...curl -u "$es_user:$es_pass" https://$es_host:$es_port/_cat/indices | grep "20221006"| ...``` 以此示例，你将删除在 2022 年 10 月 6 日创建的所有索引。
{{</callout>}}

{{<callout note "Elasticsearch 选项">}}
上面的命令假定纯 HTTP Elasticsearch 实例没有身份验证。除了适当设置 `<es_host>` 和 `<es_port>` 外，如果需要，你还需要通过向上面的 `curl` 命令提供 `-u <es_user>:<es_pass>` 来添加基本认证，或者如果需要，将模式设置为 `https`。
{{</callout>}}


**4. 增加管理命名空间中的 `oap` 部署的副本数。**

```bash
kubectl -n ${MANAGEMENT_NAMESPACE} scale deployment oap --replicas=1
```

**密切关注管理平面命名空间中新的 OAP 容器的日志，如果没有错误并且容器正常运行，可以继续执行下一步。**

{{<callout warning "OAP 可用性">}}
确保管理平面中的 OAP 在继续执行此过程之前能够正确启动。该组件的管理平面 pod 会创建系统所需的索引模板和索引，因此在继续扩展控制平面组件之前，你需要确保 OAP 正常运行。
{{</callout>}}

**5. 增加控制平面命名空间中的 `oap-deployment` 部署的副本数。**

{{<callout warning>}}
这需要在 TSB 中登记的所有 CP 集群中执行。
{{</callout>}}

```bash
kubectl -n ${CONTROL_NAMESPACE} scale deployment oap-deployment \
--replicas=1
```
