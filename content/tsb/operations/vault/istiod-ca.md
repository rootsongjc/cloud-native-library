---
title: Istio CA
description: How to combine Vault Agent Injector with Istiod CA Certificates.
---

Before you get started, you must have:<br />
✓ Vault 1.3.1 or newer<br />
✓ Vault Injector 0.3.0 or newer

## Setup Vault

Install Vault (it does not need to be installed in the Kubernetes cluster, but
should be reachable from inside the Kubernetes cluster). The Vault Injector
(agent-injector) must be installed into the cluster and configured to inject
sidecars. This is automatically done by the Helm chart `v0.5.0+` which installs
Vault `0.12+` and Vault-Injector `0.3.0+`. The example below assumes that Vault
is installed in the `tsb` namespace.

For more details, check the
[Vault documentation](https://www.vaultproject.io/docs/platform/k8s/injector/installation).

```bash{promptUser: alice}
helm install --name=vault --set='server.dev.enabled=true'
```

Port forward the vault service to local and set environment values to authenticate to the API
```bash{promptUser: alice}
kubectl port-forward svc/vault  8200:8200 & # this will run it in the background
export VAULT_ADDR='http://[::]:8200'
export VAULT_TOKEN="root"
```

### Create a CA Certificate

:::note
If you already have your own CA certificate and/or an intermediate CA
certificate to use with Istio, skip to
[Adding Intermediate CA Certificate to Vault](#adding-intermediate-ca-certificate-to-vault)
:::

Vault has a `PKI` Secret back-end that supports creation or management of CA
Certificates. It is recommended users create an Intermediate CA certificate for
Istio and keep the Root CA outside of Vault. Refer to
[the Vault documentation](https://www.vaultproject.io/docs/secrets/pki) for more
details.

Generate a self-signed root CA certificate in Vault using the Vault PKI back-end.

```bash{promptUser: alice}{outputLines: 3,6,9}
# Add audit trail in Vault
vault audit enable file file_path=/vault/vault-audit.log

# Enable PKI secret back-end
vault secrets enable pki

# Update PKI lease to 1 year
vault secrets tune -max-lease-ttl=8760h pki

# Create a Self Signed CA
vault write pki/root/generate/internal common_name=tetrate.io ttl=8760h
```

### Intermediate CA for Istio

Now that we have a CA in Vault, we use it to create an intermediate CA for
Istio. We re-use the `pki` Secret back-end but with a new path (`istioca`).
This time we need to get the CA Key and will call the `exported` endpoint
instead of `internal`:

```bash{promptUser: alice}{outputLines: 3,6,9-26}
# Enable PKI in a new path for intermediate CA
vault secrets enable --path istioca pki

# Update lease time to 5 years
vault secrets tune -max-lease-ttl=43800h istioca

# Create Intermediate CA cert and Key
vault write istioca/intermediate/generate/exported common_name="tetrate.io Intermediate Authority" ttl=43800h

Key                 Value
---                 -----
csr                 -----BEGIN CERTIFICATE REQUEST-----
MIICcTCCAVkCAQAwLDEqMCgGA1UEAxMhdGV0cmF0ZS5pbyBJbnRlcm1lZGlhdGUg
...
...
7HJEy22yCFvVcR+Gtf++iZG+w04E2ah99xrzb+NdWDgw6asBg7oJg/bJQoA4/Wb5
OX2jl0E=
-----END CERTIFICATE REQUEST-----
private_key         -----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEA8Vmm2urwUHdAp1j3vs8aOqYGrDz3NwJbm6du+3WmgGHQ+sEC
...
...
yri2DiQWzwk3zIvzNSSbQdACPPeF90BLFW9L4xvN8D6gBxFL0wBa7GY=
-----END RSA PRIVATE KEY-----
private_key_type    rsa
```

Copy the Certificate Signing Request (CSR) into a local file `istioca.csr`
(including the `-----BEGIN CERTIFICATE REQUEST-----` and
`-----END CERTIFICATE REQUEST-----`).

Copy the CA Key into a local file `istioca.key`. It is advised to keep a backup
of this key in a secure place.

Now we can use the Vault CA to sign the CSR:

```bash{promptUser: alice}{outputLines: 2-19}
vault write pki/root/sign-intermediate csr=@istioca.csr format=pem_bundle ttl=43800h
 
Key              Value
---              -----
certificate      -----BEGIN CERTIFICATE-----
MIIDMDCCAhigAwIBAgIUGJgs6yFbK/eDW31RpdSiNeVQYvUwDQYJKoZIhvcNAQEL
...
...
PcPHltvhXDjckPK1jt9gpLMTaBhe9uu7Ve7b2OFv+mtAGiCEvALv+ddLa0GHrl3s
f2vq6A==
-----END CERTIFICATE-----
expiration       1618951159
issuing_ca       -----BEGIN CERTIFICATE-----
MIIDLDCCAhSgAwIBAgIUFVRq5X/cAOlDKl/h34VudUdSiMwwDQYJKoZIhvcNAQEL
...
...
d4SklUyQdxnW96IdkHSPWf46jh31tDWqco6LzmrxD4OmjSeLaf0zeErU1i41xAnW
-----END CERTIFICATE-----
serial_number    18:98:2...:f5
```

Save the `certificate` to a file named `istioca.crt`.

### Adding Intermediate CA Certificate to Vault

We now need to put the signed Intermediate CA certificate into Vault.

```bash{promptUser: alice}
vault write istioca/intermediate/set-signed certificate=@istioca.crt
```

Istio will also generate certificates based on the intermediate CA certificate
and needs both the certificate and its key. While Vault can send the certificate
using its API, we have to take care of the key. To do so, we make a copy of the
key inside a Vault Secret for later.

Enable the `kv` secrets engine if not enabled already.
```bash{promptUser: alice}{outputLines: 2}
vault secrets enable kv
Success! Enabled the kv secrets engine at: kv/
```
Now save the CA key in it.

```bash{promptUser: alice}
vault kv put kv/istioca ca-key.pem=@istioca.key
```

## Configure the Vault-Injector

Configure a Vault role that will match the Kubernetes Service Account of Istio.
This role will be used by the Vault-Injector. In the following example, the role
is named `istiod` and is bound to the `istiod` service account,
`istiod-service-account`.

Enable the Kubernetes auth method:
```bash{promptUser: alice}
vault auth enable kubernetes
```
Create the named role `istiod`
```bash{promptUser: alice}{outputLines: 2-5}
vault write auth/kubernetes/role/istiod \
    bound_service_account_names=istiod-service-account \
    bound_service_account_namespaces=istio-system \
    policies=istioca \
    period=600s
```
Enable the `istiod-service-account` to communicate via the vault-inject container to vault
```bash{promptUser: alice}
export VAULT_SA_NAME=$(kubectl get sa -n istio-system istiod-service-account \
    --output jsonpath="{.secrets[*]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret -n istio-system $VAULT_SA_NAME \
    --output 'go-template={{ .data.token }}' | base64 --decode)
export SA_CA_CRT=$(kubectl config view --raw --minify --flatten \
    --output 'jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode)
export K8S_HOST=$(kubectl config view --raw --minify --flatten \
    --output 'jsonpath={.clusters[].cluster.server}')

vault write auth/kubernetes/config \
        token_reviewer_jwt="$SA_JWT_TOKEN" \
        kubernetes_host="$K8S_HOST" \
        kubernetes_ca_cert="$SA_CA_CRT"

```

Create the Policy that will allow the above mentioned role to access the PKI
Secret back-end. This Policy enables Istio to read the key/values inside the
secret `secret/data/istioca`, where we have stored the Key of the Intermediate
CA. It also allows Istio to access the Intermediate CA and the CA chain (by
using `*`) and finally the Root CA.

```bash{promptUser: alice}{outputLines: 2-9,10-12}
cat > policy.hcl <<EOF
path "kv/istioca" {
    capabilities = ["read", "list"]
}
path "istioca/cert/*" {
    capabilities = ["read", "list"]
}
path "pki/cert/ca" {
    capabilities = ["read", "list"]
}
EOF
vault policy write istioca policy.hcl
```

## Configure TSB ControlPlane CRD

Update your `ControlPlane` CR or Helm values and add the specific `istiod` component
configuration to use Vault:

```yaml
spec:
  components:
    istio:
      kubeSpec:
        overlays:
        - apiVersion: install.istio.io/v1alpha1
          kind: IstioOperator
          name: tsb-istiocontrolplane
          patches:
          - path: spec.meshConfig.defaultConfig.holdApplicationUntilProxyStarts
            value: true
          - path: spec.components.pilot.k8s.env
            value:
            - name: ROOT_CA_DIR
              value: /vault/secrets
          - path: spec.components.pilot.k8s.podAnnotations
            value:
              vault.hashicorp.com/agent-inject: "true"
              vault.hashicorp.com/agent-inject-secret-ca-cert.pem: istioca/cert/ca
              vault.hashicorp.com/agent-inject-secret-ca-key.pem: kv/istioca
              vault.hashicorp.com/agent-inject-secret-cert-chain.pem: istioca/cert/ca_chain
              vault.hashicorp.com/agent-inject-secret-root-cert.pem: pki/cert/ca
              vault.hashicorp.com/agent-inject-template-ca-cert.pem: |
                {{- with secret "istioca/cert/ca" -}}
                {{ .Data.certificate  }}
                {{- end }}
              vault.hashicorp.com/agent-inject-template-ca-key.pem: |
                {{- with secret "kv/istioca" -}}
                {{ index .Data "ca-key.pem" }}
                {{- end }}
              vault.hashicorp.com/agent-inject-template-cert-chain.pem: |
                {{- with secret "istioca/cert/ca_chain" -}}
                {{ .Data.certificate  }}
                {{- end }}
              vault.hashicorp.com/agent-inject-template-root-cert.pem: |
                {{- with secret "pki/cert/ca" -}}
                {{ "" | or ( .Data.certificate ) }}
                {{- end }}
              vault.hashicorp.com/role: istiod
              vault.hashicorp.com/secret-volume-path: /etc/cacerts-vault
```

Here, we add an environment variable `ROOT_CA_DIR` pointing Istio to the
directory where we create the new CA files from Vault. Then we add the
Vault-Injector annotations to create the certificates.

Annotations are composed of a `secret` from Vault and a template defining how to
create the file on the disk. We create one file per certificate component
(certificate, key, chain and root)

## Troubleshooting

If something is wrong, like the `istiod` pods not starting, check in the logs:

#### Pod is failing during Init phase

Check the Vault-Injector logs in the `istiod` pod:

```bash{promptUser: alice}
kubectl logs -n istio-system deployment/istiod -c vault-agent-init
```

#### Pod is failing after Init

```bash{promptUser: alice}
kubectl logs -n istio-system deployment/istiod -c vault-agent
```

#### `istiod` process is crashing

If the certificate is not working, the Vault-Injector will work but `istiod`
will not be able to start. Check `istiod` logs:

```bash{promptUser: alice}
kubectl logs -n istio-system deployment/istiod -c discovery
```
