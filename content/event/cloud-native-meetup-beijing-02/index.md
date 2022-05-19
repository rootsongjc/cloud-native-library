---
title: "云原生社区 meetup 第二期北京站"

event: "云原生社区 meetup 第二期北京站"
event_url: "https://3372087382093.huodongxing.com/event/5574970282500"

location: 中国北京
address:
  street: 建国路 93 号万达广场 A 座新世界百货 7 层良辉会议室
  city: 北京
  region: 北京
  postcode: ''
  country: 中国

summary: '本次活动关注 Istio、云原生存储、可观察性、DubboGo 等。'
abstract: ''

# Talk start and end times.
#   End time can optionally be hidden by prefixing the line with `#`.
date: 2020-12-20T13:00:00+08:00
date_end: 2020-12-20T18:00:00+08:00
all_day: false

# Schedule page publish date (NOT talk date).
publishDate: 2020-12-20T18:00:00+08:00

authors: ["宋净超","孙召昌","赵新","张城","刘硕然"]
tags: ["Istio","DubboGo","SpringCloud","ChubaoFS","OpenTelemetry"]

# Is this a featured talk? (true/false)
featured: false

image:
  caption: '图片来源: [云原生社区](https://cloudnative.to)'
  focal_point: Right

#links:
#  - icon: twitter
#    icon_pack: fab
#    name: Follow
#    url: https://twitter.com/jimmysongio
url_code: ''
url_pdf: ''
url_slides: 'https://github.com/cloudnativeto/academy/tree/master/meetup/02-beijing'
url_video: ''

# Markdown Slides (optional).
#   Associate this talk with Markdown slides.
#   Simply enter your slide deck's filename without extension.
#   E.g. `slides = "example-slides"` references `content/slides/example-slides.md`.
#   Otherwise, set `slides = ""`.
slides: ''

# Projects (optional).
#   Associate this post with one or more of your projects.
#   Simply enter your project's folder or file name without extension.
#   E.g. `projects = ["internal-project"]` references `content/project/deep-learning/index.md`.
#   Otherwise, set `projects = []`.
projects: []
---

### Istio 1.8——还是从前那个少年

讲师：宋净超（Tetrate 布道师、云原生社区创始人）

个人介绍：Tetrate 布道师、CNCF Ambassador、云原生社区 创始人、电子工业出版社优秀译者、出品人。Kubernetes、Istio 等技术的早期使用及推广者。曾就职于科大讯飞、TalkingData 和蚂蚁集团。

议题简介：带你回顾 Istio 的发展历程，看他是否还是从前那个少年，“没有一丝丝改变”，能够经历时间的考验。带你一起来了解 Istio 1.8 的新特性，看它是如何作为传统和现代应用的桥接器，成为云原生应用中的中流砥柱。同时也会为你分享云原生社区的规划，为了推行云原生，我们在行动。

### 百度服务网格在金融行业的大规模落地实践

讲师：孙召昌（百度高级研发工程师）

个人介绍：百度高级研发工程师，现就职于百度基础架构部云原生团队，参与了服务网格产品的研发工作和大规模落地实践，对云原生、微服务、Service Mesh等方向有深入的研究和实践经验。

议题简介：百度服务网格技术在金融行业大规模落地过程的实践经验和思考，主要包括：

1. 支持传统微服务应用的平滑迁移，兼容SpringCloud和Dubbo应用；
2. 灵活对接多种注册中心，支持百万级别的服务注册和发现；
3. 提供丰富的流量治理策略，包括自定义路由、全链路灰度等；
4. 实现业务无侵入的指标统计和调用链展示，满足用户的可观察性需求。

### Apache/Dubbo-go 在云原生时代的实践与探索

讲师：赵新（于雨）

个人介绍：于雨（GitHub ID AlexStocks），dubbogo 社区负责人，一个有十多年服务端基础架构研发经验的一线程序员，陆续改进过 Redis/Muduo/Pika/Dubbo/Dubbo-go/Sentinel-go 等知名项目，目前在蚂蚁集团可信原生部从事容器编排和 Service Mesh 工作。

议题简介：

1. 基于Kubernetes 的微服务通信能力
2. 基于 MOSN 的云原生 Service Mesh 能力
3. 基于应用级注册的服务自省能力
4. dubbo-go 3.0 规划

### 合影、中场休息、签售

中场休息时会有《云原生操作系统 Kubernetes》作者之一张城为大家现场签售。

### 云原生下的可观察性

讲师：张城（元乙）

个人介绍：阿里云技术专家，负责阿里巴巴集团、蚂蚁金服、阿里云等日志采集基础设施，服务数万内外部客户，日流量数十PB。同时负责云原生相关的日志/监控解决方案，包括系统组件，负载均衡，审计，安全，Service Mesh，事件，应用等监控方案。目前主要关注可观察性、AIOps、大规模分析引擎等方向。

议题简介：近年来随着云原生技术的普及，PaaS和SaaS化的程度越来越高，传统的监控系统正在朝可观察性系统的方向演进。在这背景下OpenTelemetry诞生，OpenTelemetry为我们带来了Metric、Tracing、Logging的统一标准，便于我们构建一个统一的可观察性平台。

### 云原生分布式存储解决方案实践

讲师：刘硕然（OPPO）

个人介绍：OPPO互联网云平台分布式文件存储技术负责人，ChubaoFS初创成员及项目维护者。

议题简介：ChubaoFS是云原生的分布式存储系统，目前已经在多家公司生产环境为大规模容器平台的云原生应用提供分布式存储解决方案。主要特点包括高可用，高可扩展，多租户，文件及对象双接口等。与云原生社区的生态也有非常紧密的结合，目前监控使用Prometheus，部署支持Helm，使用支持CSI driver。
