---
title: Installing the Bookinfo Example
---

In order to demonstrate how a workload deployed outside of Kubernetes integrates with
the rest of the mesh, we need to have some other application(s) it could
communicate with.

For the purposes of this guide, you need to deploy [Istio Bookinfo](https://istio.io/latest/docs/examples/bookinfo/) example.

into your Kubernetes cluster.

## Deploy Bookinfo example

Create the namespace `bookinfo`, and add the proper labels:

```bash{promptUser: "alice"}
kubectl create namespace bookinfo
kubectl label namespace bookinfo istio-injection=enabled
```

Deploy the bookinfo application:

```bash{promptUser: "alice"}
cat <<EOF | kubectl apply -n bookinfo -f -
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
spec:
  mtls:
    mode: STRICT
EOF

kubectl apply -n bookinfo -f https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/platform/kube/bookinfo.yaml

kubectl wait --for=condition=Available -n bookinfo deployments --all
```

In order to send requests into the `bookinfo` product page from your local
environment, you will need to set up port forwarding.

Run the following command in a separate terminal session:

```bash{promptUser: "alice"}
kubectl port-forward -n bookinfo service/productpage 9080
```

The product page will become accessible on `http://localhost:9080`.
To verify the product page visually, open `http://localhost:9080/productpage`
in a browser. If you refresh the page multiple times, 2 out of 3 times you should see rating stars on the page.

Alternatively, to verify from the command line, run:

```bash{promptUser: "alice"}
for i in `seq 1 9`; do
  curl -fsS "http://localhost:9080/productpage?u=normal" | grep "glyphicon-star" | wc -l | awk '{print $1" stars on the page"}'
done
```

2 out of 3 times you should get a message `10 stars on the page`:

```bash{promptUser: "alice"}
10 stars on the page
0 stars on the page
10 stars on the page
```

## Scale the `ratings` Application Down

In this guide you will deploy the `ratings` application through the
VM via Workload Onboarding. In order to do this we must first
"disable" the default `ratings` application deployed with the
bookinfo sample.

Run the following commands and scale down the `ratings` application down to 0 replicas:

```bash{promptUser: "alice"}
kubectl scale deployment ratings-v1 -n bookinfo --replicas=0

kubectl wait --for=condition=Available -n bookinfo deployment/ratings-v1
```

To verify that the `ratings` application has been scaled down and
no longer appears on the product page, follow the instructions in the
previous section and access the product page. Two out of three times
you should see the message `Ratings service is currently unavailable`.  
