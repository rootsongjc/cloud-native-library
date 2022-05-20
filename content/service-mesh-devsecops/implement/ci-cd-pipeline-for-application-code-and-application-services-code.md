---
weight: 2
title: 4.2 应用程序代码和应用服务代码的 CI/CD 管道
date: '2022-05-18T00:00:00+08:00'
type: book
---

应用程序代码和应用服务代码驻留在容器编排和资源管理平台中，而实现与之相关的工作流程的 CI/CD 软件通常驻留在同一平台中。应使用第 4.6 节所述的步骤对该管道进行保护，该管道控制下的应用程序代码应接受第 4.8 节所述的安全测试。此外，应用程序所在的调度平台本身应使用运行时安全工具（如 [Falco](https://betterprogramming.pub/kubernetes-security-with-falco-2eb060d3ae7d)）进行保护，该工具可以实时读取操作系统内核日志、容器日志和平台日志，并根据威胁检测规则引擎对其进行处理，以提醒用户注意恶意行为（例如，创建有特权的容器、未经授权的用户读取敏感文件等）。它们通常有一套默认（预定义）的规则，可以在上面添加自定义规则。在平台上安装它们，可以为集群中的每个节点启动代理，这些代理可以监控在该节点的各个 Pod 中运行的容器。这种类型的工具的优点是，它补充了现有平台的本地安全措施，如访问控制模型和 Pod 安全策略，通过实际检测它们的发生来 [防止漏洞](https://searchitoperations.techtarget.com/tip/Terraform-cheat-sheet-Notable-commands-HCL-and-more?utm_campaign=20210726_Infrastructure+as+code+still+a+big+security+buzz&utm_medium=EM&utm_source=NLN&track=NL-1841&ad=939808&asrc=EM_NLN_172629823)。