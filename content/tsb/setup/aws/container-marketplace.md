---
title: Install Tetrate Service Bridge from the AWS Container Marketplace
description: Steps to install TSB from the AWS Container Marketplace
---

This document describes how to install Tetrate Service Bridge (TSB) in your Amazon Kubernetes (EKS) cluster through the AWS Container Marketplace.
 
:::note
This document is intended for users who have purchased Tetrate's AWS Container Marketplace offering.
It will not work if you have not subscribed to the Tetrate Container Marketplace offering.
Please contact Tetrate if you're interested in an AWS Marketplace Private Offer.
:::

## Overview of the Tetrate Operator

The Tetrate Operator is a Kubernetes Operator from Tetrate that makes it easier to install, deploy, and upgrade TSB. The AWS Container Marketplace offering for Tetrate Service Bridge installs a version of the Tetrate Operator in an EKS cluster. After that, TSB can be installed in any namespace in your EKS cluster.
Throughout this document, it is assumed that  the TSB will be installed in the `tsb` namespace.
 
Prerequisites for using the Tetrate Operator
To use the Marketplace's Tetrate offering, make sure you meet the following requirements:
* You have access to an EKS cluster (Kubernetes 1.16 or above) configured with IAM roles for service accounts.
* You have cluster-admin access on the EKS cluster.
* You have set up an EKS cluster, and you have `kubectl` setup.
* You have [downloaded `tctl`](../../reference/cli/guide/index#installation)
Installation

## Create and configure the AWS IAM roles for your Kubernetes cluster
AWS IAM permissions are granted to Tetrate through the use of AWS's IAM roles for Kubernetes Service Accounts. This feature must be enabled at the cluster level.
Create an IAM role for the Tetrate Operator pod named `eks-tsb-operator`, and [configure it for use by EC2 per AWS guide](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-service.html). You will replace the trust relationship later.
Then grant AWS managed policy `AWSMarketplaceMeteringRegisterUsage` to `eks-tsb-operator`.
 
Create the trust relationship on the IAM role. Use the following template and replace `AWS_ACCOUNT_ID` and `OIDC_PROVIDER` with appropriate values.

`AWS_ACCOUNT_ID` should be replaced with your AWS account ID.

`OIDC_PROVIDER` should be replaced with the OpenID Connect Provider URL for your Kubernetes cluster. You must remove the `https://` prefix from the URL before replacement

For more details on IAM OIDC providers for EKS clusters, please refer to [the official documentation](https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::AWS_ACCOUNT_ID:oidc-provider/OIDC_PROVIDER"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "OIDC_PROVIDER:sub": "system:serviceaccount::tsb:tsb-operator-management-plane"
        }
      }
    }
  ]
}
```

## Install the Tetrate Operator and TSB Management Plane

Using the Tetrate CLI (`tctl`), generate the Kubernetes manifest for Tetrate Operator and install it into your Kubernetes cluster.

Generate the CRDs for TSB Management plane using the following command:

```bash{promptUser: alice}
tctl install manifest management-plane-operator \
   --registry 709825985650.dkr.ecr.us-east-1.amazonaws.com/tetrate-io > managementplaneoperator.yaml
```

Open the file `managementplaneoperator.yaml` you made above, and locate the `ServiceAccount` definition for `tsb-operator-management-plane`. Inside the YAML definition for the `ServiceAccount`, add the `annotation` section with the IAM role information so that the ServiceAccount can access it. Replace the `AWS_ACCOUNT_ID` in the annotation with your AWS account ID:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    platform.tsb.tetrate.io/application: tsb-operator-managementplane
    platform.tsb.tetrate.io/component: tsb-operator
    platform.tsb.tetrate.io/plane: management
  name: tsb-operator-management-plane
  namespace: 'tsb'
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::AWS_ACCOUNT_ID:role/eks-tsb-operator 
```

Deploy the operator using `kubectl`, making sure that your Kubernetes context is pointed to the correct cluster:

```bash{promptUser: alice}
kubectl apply -f managementplaneoperator.yaml
```
Deploying the Tetrate Operator may take a little bit of time. You can monitor its status by running the following command:
 
```bash{promptUser: alice}
kubectl -n tsb get pod -owide
```
 
You should see some text resembling the example below. The operator is ready when the READY and STATUS columns have the values `1/1` and `Running` respectively. 

```bash{promptUser: alice}
kubectl -n tsb get pod -owide
NAME                                             READY   STATUS    RESTARTS   AGE   IP               NODE                                              NOMINATED NODE   READINESS GATES
tsb-operator-management-plane-68c98756d5-n44d7   1/1     Running   0          71s   192.168.17.234   ip-192-168-24-207.ca-central-1.compute.internal   <none>          <none>
```
 
Follow the instructions on [Management Plane installation](../self_managed/management-plane-installation#management-plane-installation) and finish installing the Management Plane].

## Accessing TSB UI

Obtain the ELB address assigned to the Management Plane by executing the following command:

```bash{promptUser: alice}
kubectl -n tsb get svc -l=app=envoy
NAME    TYPE           CLUSTER-IP       EXTERNAL-IP                                                                 PORT(S)                                         AGE
envoy   LoadBalancer   10.100.157.254   a72dd70af1bf64e7d86a7352a9568ea1-952780637.ca-central-1.elb.amazonaws.com   8443:32457/TCP,9443:30475/TCP,42422:32238/TCP   10m
```

Assign a DNS record pointing to your ELB. Please refer to [the official documentation](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-creating.html) for details.

Once you have the DNS records setup, you can access the Web UI using the URL `https://<DNS Name>:8443`.

## Next steps

Please [contact us](https://tetrate.io) if you have further questions.
