---
weight: 14
title: 最佳实践
date: '2023-06-21T16:00:00+08:00'
type: book
---

本文介绍了在使用 Argo Rollouts 时的一些最佳实践、技巧和窍门。

## Ingress 目标/稳定主机路由

出于各种原因，通常希望外部服务能够访问预期的 pod（即 canary/preview）或特定的稳定 pod，而不会将流量任意分配给两个版本。一些使用场景包括：

- 新版本的服务可以在内部/私有环境中访问（例如进行手动验证），然后再将其外部公开。
- 外部 CI/CD 管道在将蓝/绿预览堆栈升级到生产环境之前运行测试。
- 运行比较旧版本和新版本行为的测试。

如果使用 Ingress 来将流量路由到服务，则可以添加其他主机规则到 Ingress 规则中，以便能够特别到达期望的（canary/preview）pod 或稳定的 pod。

```yaml
apiVersion：networking.k8s.io/v1beta1
kind：Ingress
metadata：
  name：guestbook
spec：
  rules：
  ＃仅到达所需的Pod（也称为金丝雀/预览）的主机规则
  -主机：guestbook-desired.argoproj.io
    http：
      paths：
      -后端：
          serviceName：guestbook-desired
          servicePort：443
        path：/ *
  ＃仅到达稳定Pod的主机规则
  -主机：guestbook-stable.argoproj.io
    http：
      paths：
      -后端：
          serviceName：guestbook-stable
          servicePort：443
        path：/ *
  ＃默认规则，省略主机，将流量分为所需的与稳定的
  - http：
      paths：
      -后端：
          serviceName：guestbook-root
          servicePort：443
        path：/ *
```

上述技术具有一个好处，即不会产生额外的负载均衡器分配成本。

## 减少运算符内存使用

在具有数千个 rollouts 的集群上，可以通过将 RevisionHistoryLimit 从默认值 10 更改为较低的数字来显着减少 argo-rollouts 运算符的内存使用。Argo Rollouts 的一个用户通过将 RevisionHistoryLimit 从 10 更改为 0，为一个具有 1290 个 rollouts 的集群减少了 27％ 的内存使用率。
