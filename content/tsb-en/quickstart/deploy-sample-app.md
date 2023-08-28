---
title: Deploy an Application
description: Deploy the sample bookinfo application in TSB.
weight: 2
---

In this section, you will deploy a sample application (bookinfo) in a demo TSB environment. The deployment will be validated using both the TSB UI and `tctl` commands.

### Prerequisites

Before you proceed with this guide, ensure you have completed the following steps:

- Familiarize yourself with TSB concepts including [workspaces](../concepts/terminology/#workspace) and [groups](../concepts/terminology/#group)
- Install the [TSB demo](../setup/self_managed/demo-installation)

The TSB demo installation takes care of onboarding a cluster, installing required operators, and providing you with the necessary access credentials.

### Deploy Bookinfo Application

You will use the classic Istio [bookinfo application](https://istio.io/latest/docs/examples/bookinfo/) to test TSB's functionality.

#### Create Namespace and Deploy Application

```bash{promptUser: alice}
# Create namespace and label it for Istio injection
kubectl create namespace bookinfo
kubectl label namespace bookinfo istio-injection=enabled

# Deploy the bookinfo application
kubectl apply -n bookinfo -f https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/platform/kube/bookinfo.yaml
```

#### Confirm Services

To confirm that all services and pods are running, execute the following:

```bash{promptUser: alice}
kubectl get pods -n bookinfo
```

Expected output:

```
NAME                             READY   STATUS    RESTARTS   AGE
details-v1-5bc5dccd95-2qx8b      2/2     Running   0          38m
productpage-v1-f56bc8d5c-42kcg   2/2     Running   0          38m
ratings-v1-68f58946ff-vcrdh      2/2     Running   0          38m
reviews-v1-5976d456d4-nltg2      2/2     Running   0          38m
reviews-v2-57cf5b5488-rgq8l      2/2     Running   0          38m
reviews-v3-7745dbf976-4gnl9      2/2     Running   0          38m
```

### Access the Bookinfo Application

Confirm that you can access the bookinfo application:

```bash{promptUser: alice}{outputLines: 2-4}
kubectl exec "$(kubectl get pod -n bookinfo -l app=ratings -o jsonpath='{.items[0].metadata.name}')"  \
    -n bookinfo -c ratings -- curl -s productpage:9080/productpage | \
    grep -o "<title>.*</title>"
```

You should see a similar output:

```
<title>Simple Bookstore App</title>
```

These steps successfully deploy the bookinfo application in your TSB environment, ensuring it's up and running as expected.
