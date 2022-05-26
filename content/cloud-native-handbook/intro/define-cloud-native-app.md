---
title: 什么是云原生应用？
linktitle: 什么是云原生应用？
type: book
date: '2022-05-03T00:00:00+01:00'
# Prev/next pager order (if `docs_section_pager` enabled in `params.toml`)
weight: 3
---

本文参考的是 [OAM 规范](https://github.com/oam-dev/spec)中对云原生应用的定义，并做出了引申。

云原生应用是一个相互关联但又不独立的组件（service、task、worker）的集合，这些组件与配置结合在一起并在适当的运行时实例化后，共同完成统一的功能目的。

## 云原生应用模型

下图是 OAM 定义的云原生应用模型示意图，为了便于理解，图中相同颜色的部分为同一类别的对象定义。

![云原生应用模型](../../images/cloud-native-app-model.png "云原生应用模型")

OAM 的规范中定义了以下对象，它们既是 OAM 规范中的基本术语也是云原生应用的基本组成。

- **Workload（工作负载）**：应用程序的工作负载类型，由平台提供。
- **Component组件）**：定义了一个 `Workload` 的实例，并以基础设施中立的术语声明其运维特性。
- **Trait（特征）**：用于将运维特性分配给组件实例。
- **ApplicationScope（应用作用域）**：用于将组件分组成具有共同特性的松散耦合的应用。
- **ApplicationConfiguration（应用配置）**：描述 `Component` 的部署、`Trait` 和 `ApplicationScope`。

## 关注点分离

下图是不同角色对于该模型的关注点示意图。

![云原生应用模型中的目标角色](../../images/roles.png "云原生应用模型中的目标角色")

我们可以看到对于一个云原生应用来说，不同的对象是由不同的角色来负责的：

- 基础设施运维：提供不同的 `Workload` 类型供开发者使用；
- 应用运维：定义适用于不同 `Workload` 的运维属性 `Trait` 和管理 `Component` 的 `ApplicationScope` 即作用域；
- 应用开发者：负责应用组件 `Component` 的定义；
- 应用开发者和运维：共同将 `Component` 与运维属性 `Trait` 绑定在一起，维护应用程序的生命周期；

基于 OAM 中的对象定义的云原生应用可以充分利用平台能力自由组合，开发者和运维人员的职责可以得到有效分离，组件的复用性得到大幅提高。

## 定义标准

CNCF 中的有几个定义标准的「开源项目」，其中有的项目都已经毕业。

- [SMI（Service Mesh Interface）](https://github.com/servicemeshinterface/smi-spec)：服务网格接口
- [Cloud Events](https://github.com/cloudevents/spec)：Serverless 中的事件标准
- [TUF](https://github.com/theupdateframework/specification)：更新框架标准
- [SPIFFE](https://github.com/spiffe/spiffe)：身份安全标准

这其中唯独没有应用定义标准，[CNCF SIG App delivery](https://github.com/cncf/sig-app-delivery) 即是要做这个的。当然既然要指定标准，自然要对不同平台和场景的逻辑做出更高级别的抽象（这也意味着你在掌握了底层逻辑的情况下还要学习更多的概念），这样才能屏蔽底层差异。

## OAM 简介

OAM 全称是 Open Application Model，从名称上来看它所定义的就是一种模型，同时也实现了基于 OAM 的我认为这种模型旨在定义了云原生应用的标准。

- 开放（Open）：支持异构的平台、容器运行时、调度系统、云供应商、硬件配置等，总之与底层无关
- 应用（Application）：云原生应用
- 模型（Model）：定义标准，以使其与底层平台无关

既然要制定标准，自然要对不同平台和场景的逻辑做出更高级别的抽象（这也意味着你在掌握了底层逻辑的情况下还要学习更多的概念），这样才能屏蔽底层差异。本文将默认底层平台为 Kubernetes。

- 是从管理大量 [CRD](../../GLOSSARY.html#crd) 中汲取的经验。
- 业务和研发的沟通成本，比如 YAML 配置中很多字段是开发人员不关心的。

## 设计原则

OAM 规范的设计遵循了以下[原则](https://github.com/oam-dev/spec/blob/master/9.design_principles.md)：

- 关注点分离：根据功能和行为来定义模型，以此划分不同角色的职责，
- 平台中立：OAM 的实现不绑定到特定平台；
- 优雅：尽量减少设计复杂性；
- 复用性：可移植性好，同一个应用程序可以在不同的平台上不加改动地执行；
- 不作为编程模型：OAM 提供的是应用程序模型，描述了应用程序的组成和组件的拓扑结构，而不关注应用程序的具体实现。

下图是 OAM 规范示意图。

![OAM 规范示意图](../../images/oam-spec.png "OAM 规范示意图")

## OAM 工作原理

OAM 的工作原理如下图所示（图片引用自孙健波在《OAM: 云原生时代的应用模型与 下一代 DevOps 技术》中的分享）。

![OAM 的原理](../../images/oam-principle.jpg "OAM 的原理")

OAM Spec 定义了云原生应用的规范（使用一些 [CRD](../../GLOSSARY.html#crd) 定义）， [KubeVela](https://kubevela.io/) 可以看做是 OAM 规范的解析器，将应用定义翻译为 Kubernetes 中的资源对象。可以将上图分为三个层次：

- **汇编层**：即人工或者使用工具来根据 OAM 规范定义汇编出一个云原生应用的定义，其中包含了该应用的工作负载和运维能力配置。
- **转义层**：汇编好的文件将打包为 YAML 文件，由 [KubeVela](https://kubevela.io/) 或其他 OAM 的实现将其转义为 Kubernetes 或其他云服务（例如 Istio）上可运行的资源对象。
- **执行层**：执行经过转义好的云平台上的资源对象并执行资源配置。

## 参考

- [The Open Application Model specification - github.com](https://github.com/oam-dev/spec)