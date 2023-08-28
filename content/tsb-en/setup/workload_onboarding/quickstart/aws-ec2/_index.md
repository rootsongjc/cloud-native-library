---
slug: .
title: Quickstart with Workloads on AWS EC2
---

This guide will help you to get started with `Workload Onboarding` in practice.

As part of this guide, you will:
1. Deploy [Istio Bookinfo](https://istio.io/latest/docs/examples/bookinfo/) example into your Kubernetes cluster
1. Deploy `ratings` application on an AWS EC2 instance and onboard
   it into the service mesh
1. Verify traffic between Kubernetes Pod(s) and AWS EC2 instances
1. Deploy `ratings` application on an AWS Auto Scaling Group and
   onboard it into the service mesh

This guide is intended to be an easy-to-follow demonstration of the workload
onboarding capabilities.

To keep things simple, you are not required to configure the infrastructure the way
you would do it in the case of a production deployment.

Specifically:
* you are not required to set up routable DNS records
* you are not required to use a trusted CA authority (such as [Let's Encrypt])
* you are not required to put Kubernetes cluster and AWS EC2 instances on the same
  network or peered networks

Before proceeding, please make sure to complete the following prerequisites:
* Create a Kubernetes cluster to install TSB and example application(s) into
* Follow the instructions in [TSB demo](../../../../setup/self_managed/demo-installation) installation
* Create an AWS account to launch an EC2 instance, deploy a workload there and
  onboard it into the service mesh

import DocCardList from '@theme/DocCardList';

<DocCardList />
