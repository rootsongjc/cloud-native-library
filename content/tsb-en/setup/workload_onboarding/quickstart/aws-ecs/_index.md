---
slug: .
title: Quickstart with Workloads on AWS ECS
---

This guide will help you to get started with `Workload Onboarding` in practice.

As part of this guide, you will:
1. Deploy [Istio Bookinfo](https://istio.io/latest/docs/examples/bookinfo/)
   example into an Elastic Kubernetes Service (EKS) cluster
1. Deploy `ratings` application as an AWS ECS task and onboard it into the
   service mesh
1. Verify traffic between Kubernetes Pod(s) and the AWS ECS task

This guide is intended to be an easy-to-follow demonstration of the workload
onboarding capabilities.

To keep things simple, you are not required to configure the infrastructure the way
you would do it in the case of a production deployment.

Specifically:
* you are not required to set up routable DNS records
* you are not required to use a trusted CA authority (such as [Let's Encrypt])

Before proceeding, please make sure to complete the following prerequisites:
* Create an EKS cluster to install TSB and example application(s) into
* Follow the instructions in [TSB demo](../../../../setup/self_managed/demo-installation)
  installation
* Follow the instructions in [Installing the Bookinfo Example](./../aws-ec2/bookinfo)
* Follow the instructions in [Enable Workload Onboarding](./../aws-ec2/enable-workload-onboarding)

[Let's Encrypt]: https://letsencrypt.org/

import DocCardList from '@theme/DocCardList';

<DocCardList />
