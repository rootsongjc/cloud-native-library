---
title: Configure WorkloadGroup and Sidecar for the Workload on-premise
---

You will deploy the `ratings` application on a VM on-premise
and onboard it into the service mesh.

## Create a WorkloadGroup

Execute the following command to create a `WorkloadGroup`:

```bash
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
    serviceAccount: bookinfo-ratings
EOF
```

The field `spec.template.network` is omitted to indicate to the Istio control
plane that the VM on-premise has direct connectivity to the Kubernetes Pods.

The field `spec.template.serviceAccount` declares that the workload have the
identity of the service account `bookinfo-ratings` within the Kubernetes cluster.
The service account `bookinfo-ratings` was created during the
[deployment of the Istio bookinfo example earlier](../aws-ec2/bookinfo)

## Create the Sidecar Configuration

Execute the following command to create a new sidecar configuration:

```bash
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
      number: 9080                   # (5)
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

## Allow Workloads to authenticate themselves by means of a JWT Token

For the purposes of this guide, you will be using `Sample JWT Credential Plugin`
to provide your on-premise workload with a [JWT Token] credential.

In this section you will configure `Workload Onboarding Plane` to trust [JWT Token]s
issued by the `Sample JWT Credential Plugin`.

Execute the following command to download `Sample JWT Credential Plugin` locally:

```bash
curl -fL "https://dl.cloudsmith.io/public/tetrate/onboarding-examples/raw/files/onboarding-agent-sample-jwt-credential-plugin_0.0.1_$(uname -s)_$(uname -m).tar.gz" \
  | tar -xz onboarding-agent-sample-jwt-credential-plugin
```

Execute the following command to generate a unique signing key for use by the
`Sample JWT Credential Plugin`:

```bash
./onboarding-agent-sample-jwt-credential-plugin generate key \
  -o ./sample-jwt-issuer
```

The above command will generate 2 files:

* `./sample-jwt-issuer.jwk` - signing key (secret part) - for configuring
  `Sample JWT Credential Plugin` on the VM on-premise
* `./sample-jwt-issuer.jwks` - JWKS document (public part) - for configuring
  `Workload Onboarding Plane`

Execute the following command to configure `Workload Onboarding Plane` to trust
[JWT Token]s signed by the key generated above:

```bash
cat << EOF > controlplane.patch.yaml
spec:
  meshExpansion:
    onboarding:
      workloads:
        authentication:
          jwt:
            issuers:
            - issuer: https://sample-jwt-issuer.example
              jwks: |
$(cat sample-jwt-issuer.jwks | awk '{print "                "$0}')
              shortName: my-corp
              tokenFields:
                attributes:
                  jsonPath: .custom_attributes
EOF

kubectl patch controlplane controlplane -n istio-system --type merge --patch-file controlplane.patch.yaml
```

NOTE: For the above command to work, you need to use `kubectl` `v1.20+`.

## Allow Workloads to Join the WorkloadGroup

You will need to create an [`OnboardingPolicy`](../../guides/setup#allow-workloads-to-join-workloadgroup)
resource to explicitly authorize workloads deployed outside of Kubernetes to join the mesh.

Execute the following command:

```bash
cat << EOF | kubectl apply -f -
apiVersion: authorization.onboarding.tetrate.io/v1alpha1
kind: OnboardingPolicy
metadata:
  name: allow-onpremise-vms
  namespace: bookinfo                                # (1)
spec:
  allow:
  - workloads:
    - jwt:
        issuer: "https://sample-jwt-issuer.example"  # (2)
    onboardTo:
    - workloadGroupSelector: {}                      # (3)
EOF
```

The above policy applies to any `on-premise` workload that authenticates
itself by means of a [JWT Token] issued by an issuer with ID
`https://sample-jwt-issuer.example` (2), and allows them to join any
`WorkloadGroup` (3) in the namespace `bookinfo` (1)


[JWT Token]: https://openid.net/specs/openid-connect-core-1_0.html#IDToken
