---
title: "Service Mesh Meetup #6 广州站"
event: "Service Mesh Meetup #6 广州站"
event_url: ""
location: 广东广州
address:
  street: 天河区广电云平广场
  city: 广州
  region: 广东
  postcode: ''
  country: 中国
summary: '这是第六届 Service Mesh Meetup。'
abstract: ''

date: 2019-08-11T13:00:00+08:00
date_end: 2019-08-11T18:00:00+08:00
all_day: false
publishDate: 2019-08-11T13:00:00+08:00

authors: ["张波","彭泽文","涂小刚","敖小剑"]
tags: ["Service Mesh"]
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
url_slides: 'https://github.com/servicemesher/meetup-slides'
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

## 讲师与演讲话题

#### 虎牙直播在微服务改造方面的实践

张波 虎牙基础保障部中间件团队负责人

本次主要分享虎牙注册中心、名字服务、DNS 的改造实践，以及如何通过 Nacos 实现与 istio 打通实现，使微服务平滑过渡到 service mesh。

#### Service Mesh 在蚂蚁集团的生产级安全实践

彭泽文 蚂蚁集团高级开发工程师

介绍通过 Envoy SDS（Secret Discovery Service）实现 Sidecar 证书管理的落地方案；分享如何为可信身份服务构建敏感信息数据下发通道，以及 Service Mesh Sidecar 的 TLS 生产级落地实践。

#### 基于 Kubernetes 的微服务实践

涂小刚 慧择网运维经理

介绍如何跟据现有业务环境情况制定容器化整体解决方案，导入业务进入 K8S 平台，容器和原有业务环境互通。制订接入规范、配置中心对接 K8S 服务、网络互通方案、DNS 互通方案、jenkins-pipeline 流水线构建方案、日志采集方案、监控方案等。

#### Service Mesh 发展趋势（续）：棋到中盘路往何方

敖小剑 蚂蚁集团高级技术专家

继续探讨 Service Mesh 发展趋势：深度分析 Istio 的重大革新 Mixer v2，Envoy 支持 Web Assembly 的意义所在，以及在 Mixer v2 出来之前的权宜之计; 深入介绍 Google Traffic Director 对虚拟机模式的创新支持方式，以及最近围绕 SMI 发生的故事。
