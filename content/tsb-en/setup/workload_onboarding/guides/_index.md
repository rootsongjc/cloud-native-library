---
slug: .
title: Workload Onboarding
description: Automatate Onboarding Workloads Deployed Outside of Kubernetes
---

Workload Onboarding is a TSB feature that automates onboarding 
workloads deployed outside of Kubernetes into the service mesh.

For example, you can use it to onboard workloads deployed on VMs (or
perhaps VMs from auto-scaling groups) that are not part of your
Kubernetes clusters.

:::note
The Workload Onboarding feature is currently an alpha feature.

It is quite possible that it does not support all possible deployment
scenarios. Most notably, it does not yet support the use of `Iptables` for
traffic redirection. You should configure your Istio sidecar and your application
as necessary.

At the moment, this feature supports onboarding workloads from the following environments:

* workloads deployed on `AWS EC2` instances
* workloads deployed on `AWS Auto-Scaling Groups`
* workloads deployed as `AWS ECS` tasks
* workloads deployed on-premise
:::

import DocCardList from '@theme/DocCardList';

<DocCardList />
