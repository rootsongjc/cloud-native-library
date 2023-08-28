---
title: Configure WorkloadGroup and Sidecar
---

You will deploy the `ratings` application on an AWS EC2 instance
and onboard it into the service mesh.

## Create a `WorkloadGroup`

Execute the following command to create a `WorkloadGroup`:

```bash{promptUser: "alice"}
cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadGroup
metadata:
  name: ratings
  namespace: bookinfo
  labels:
    app: ratings
spec:
  template:
    labels:
      app: ratings
      class: vm
      cloud: aws
    network: aws                      # (1)
    serviceAccount: bookinfo-ratings  # (2)
EOF
```

The field `spec.template.network` is set to a non-empty value to indicate
to the Istio control plane that the VM you will create later has no direct
connectivity to the Kubernetes Pods.

The field `spec.template.serviceAccount` declares that the workload have the
identity of the service account `bookinfo-ratings` within the Kubernetes cluster.
The service account `bookinfo-ratings` was created during the [deployment of the Istio bookinfo example earlier](./bookinfo)

## Create the Sidecar Configuration

Execute the following command to create a new sidecar configuration:

```bash{promptUser: "alice"}
cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: bookinfo-ratings-no-iptables
  namespace: bookinfo
spec:
  workloadSelector:                  # (1)
    labels:
      app: ratings
      class: vm
  ingress:
  - defaultEndpoint: 127.0.0.1:9080  # (2)
    port:
      name: http
      number: 9080                   # (3)
      protocol: HTTP
  egress:
  - bind: 127.0.0.2                  # (4)
    port:
      name: http
      number: 9080                   # (5)
      protocol: HTTP
    hosts:
    - ./*                            # (6)
EOF
```

The above sidecar configuration will only apply to workloads that have the
labels `app=ratings` and `class=vm` (1). The `WorkloadGroup` you have created
has these labels.

Istio proxy will be configured to listen on `<host IP>:9080` (3) and will
forward *incoming* requests to the application that listens on `127.0.0.1:9080` (2).

And finally the proxy will be configured to listen on `127.0.0.2:9080` (4) (5) to
proxy *outgoing* requests out of the application to other services (6) that have port `9080` (5).

## Allow Workloads to Join the `WorkloadGroup`

You will need to create an [`OnboardingPolicy`](../../guides/setup#allow-workloads-to-join-workloadgroup)
resource to explicitly authorize workloads deployed outside of Kubernetes to join the mesh.

First, obtain your [AWS Account ID](https://docs.aws.amazon.com/general/latest/gr/acct-identifiers.html).
If you do not know your AWS Account ID, see the [AWS Account Docs](https://docs.aws.amazon.com/IAM/latest/UserGuide/console_account-alias.html) for more details on how to find your ID.

If you already have your [`aws` CLI](https://aws.amazon.com/cli/) setup, you can
execute the following command:

```bash{promptUser: "alice"}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
```

Then create an `OnboardingPolicy` to allow any AWS EC2 instance from your
AWS Account ID to join any `WorkloadGroup` in the `bookinfo` namespace
by executing the following command. Replace `AWS_ACCOUNT_ID` with the
appropriate value.

```bash{promptUser: "alice"}
cat <<EOF | kubectl apply -f -
apiVersion: authorization.onboarding.tetrate.io/v1alpha1
kind: OnboardingPolicy
metadata:
  name: allow-aws-vms
  namespace: bookinfo            # (1)
spec:
  allow:
  - workloads:
    - aws:
        accounts:
        - <AWS_ACCOUNT_ID>       # (2)
        ec2: {}                  # (3)
    onboardTo:
    - workloadGroupSelector: {}  # (4)
EOF
```

The above policy applies to any AWS EC2 instances (3) owned by the account
specified in (2), and allows them to join any `WorkloadGroup` (4) in the
namespace `bookinfo` (1)
