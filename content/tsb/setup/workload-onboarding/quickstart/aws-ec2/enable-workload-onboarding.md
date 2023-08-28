---
title: Enable Workload Onboarding
---

In order to enable Workload Onboarding you need the following pieces of information:

* The DNS name to assign the Workload Onboarding Endpoint
* TLS certificate for that DNS name

For this example you will be using the DNS name `onboarding-endpoint.example`,
as we do not expect you to use a routable DNS name.

## Prepare the Certificates

For production purposes you will need to use a TLS certificate signed by a
trust Certificate Authority (CA), such as [Let's Encrypt](https://letsencrypt.org/)
or an internal CA such as [Vault](https://www.vaultproject.io/).

In this example you will setup an example CA which will be used
throughout the rest of this guide.

Create a self-signed certificate (`example-ca.crt.pem`) and
and CA private key (`example-ca.key.pem`) by issuing the following command:

```bash{promptUser: "alice"}
openssl req \
  -x509 \
  -subj '/CN=Example CA' \
  -days 3650 \
  -sha256 \
  -newkey rsa:2048 \
  -nodes \
  -keyout example-ca.key.pem \
  -out example-ca.crt.pem \
  -config <(cat <<EOF
# section with configuration for "openssl req" command
[ req ]
distinguished_name     = req                 # name of a section containing the distinguished name fields to prompt for
x509_extensions        = v3_ca               # name of a section containing a list extentions to add to the self signed certificate

# section with a list of extentions to add to the self signed certificate
[ v3_ca ]
basicConstraints       = CA:TRUE             # not marked as critical for compatibility with broken software
subjectKeyIdentifier   = hash                # PKIX recommendation
authorityKeyIdentifier = keyid:always,issuer # PKIX recommendation
EOF
)
```

Then, create the certificate signing request (`onboarding-endpoint.example.csr.pem`) and
the private key for the Workload Onboarding Endpoint (`onboarding-endpoint.example.key.pem`):

```bash{promptUser: "alice"}
openssl req \
  -subj '/CN=onboarding-endpoint.example' \
  -sha256 \
  -newkey rsa:2048 \
  -nodes \
  -keyout onboarding-endpoint.example.key.pem \
  -out onboarding-endpoint.example.csr.pem
```

Finally create the certificate for the DNS name `onboarding-endpoint.example`
(`onboarding-endpoint.example.crt.pem`) signed by the CA you created in
previous steps:

```bash{promptUser: "alice"}
openssl x509 \
  -req \
  -days 3650 \
  -sha256 \
  -in onboarding-endpoint.example.csr.pem \
  -out onboarding-endpoint.example.crt.pem \
  -CA example-ca.crt.pem \
  -CAkey example-ca.key.pem \
  -CAcreateserial \
  -extfile <(cat <<EOF
# name of a section containing a list of extensions to add to the certificate
extensions = usr_cert

# section with a list of extensions to add to the certificate
[ usr_cert ]
basicConstraints       = CA:FALSE            # not marked as critical for compatibility with broken software
subjectKeyIdentifier   = hash                # PKIX recommendation
authorityKeyIdentifier = keyid:always,issuer # PKIX recommendation

keyUsage               = digitalSignature, keyEncipherment
extendedKeyUsage       = serverAuth
subjectAltName         = DNS:onboarding-endpoint.example
EOF
)
```

Then deploy the certificate into the Kubernetes cluster by issuing the
following command:

```bash{promptUser: "alice"}
kubectl create secret tls onboarding-endpoint-tls-cert \
  -n istio-system \
  --cert=onboarding-endpoint.example.crt.pem \
  --key=onboarding-endpoint.example.key.pem
```

## Enable Workload Onboarding

Once we the TLS certificates are ready you can enable Workload Onboarding
by issuing the following command:

```bash{promptUser: "alice"}
cat <<EOF | kubectl apply -f -
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  name: controlplane
  namespace: istio-system
spec:
  meshExpansion:
    onboarding:
      endpoint:
        hosts:
        - onboarding-endpoint.example
        secretName: onboarding-endpoint-tls-cert
      localRepository: {}
EOF
```

The above specifies that the Workload Onboarding Endpoint should be
setup using the DNS name `onboarding-endpoint.example` using the certificates
available in the secret `onboarding-endpoint-tls-cert`.

It also specifies that a local repository with DEB/RPM packages for 
Workload Onboarding Agent and Istio sidecar should be deployed.

Once you execute the above command, wait until individual components
Workload Onboarding are available:

```bash{promptUser: "alice"}
kubectl wait --for=condition=Available -n istio-system \
  deployment/vmgateway \
  deployment/onboarding-plane \
  deployment/onboarding-repository
```

## Verify the Workload Onboarding Endpoint

Since you are not using a routable DNS name, you will need to 
find out address of the Workload Onboarding Endpoint that
has been exposed.

Execute the following to obtain the address (DNS name or IP address):

```bash{promptUser: "alice"}
ONBOARDING_ENDPOINT_ADDRESS=$(kubectl get svc vmgateway \
  -n istio-system \
  -ojsonpath="{.status.loadBalancer.ingress[0]['hostname', 'ip']}")
```

You will be using the address stored in the `ONBOARDING_ENDPOINT_ADDRESS` environment
variable throughout the rest of this guide.

Finally, execute the following command to verify that the endpoint is
available for external traffic. 

```bash{promptUser: "alice"}
curl -f -i \
  --cacert example-ca.crt.pem \
  --connect-to "onboarding-endpoint.example:443:${ONBOARDING_ENDPOINT_ADDRESS}:443" \
  "https://onboarding-endpoint.example/install/"
```

You should see an output similar to the following:

```text
HTTP/2 200
content-type: text/html; charset=utf-8
server: istio-envoy

<pre>
<a href="deb/">deb/</a>
<a href="rpm/">rpm/</a>
</pre>
```
