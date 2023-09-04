---
title: Elasticsearch Credentials
description: How to combine Vault Agent Injector with Elasticsearch.
---

Before you get started, you must have:<br />
✓ Vault 1.3.1 or newer<br />
✓ Vault Injector 0.3.0 or newer<br />
✓ Elasticsearch 6.x or 7.x with basic license or up

## Setup Vault

Install Vault (it does not need to be installed in the Kubernetes cluster, but
should be reachable from inside the Kubernetes cluster). The Vault Injector
(agent-injector) must be installed into the cluster and configured to inject
sidecars. This is automatically done by the Helm chart `v0.5.0+` which installs
Vault `0.12+` and Vault-Injector`0.3.0+`. The example below assumes that Vault
is installed in the `tsb` namespace.

For more details, check the
[Vault documentation](https://www.vaultproject.io/docs/platform/k8s/injector/installation).

```bash
helm install --name=vault --set='server.dev.enabled=true' ./vault-helm
```

## Startup Elasticsearch with Security Enabled

If you manage your own instance of Elasticsearch, you will need to enable
security and set the super-user password.

## Create a Role for Vault

First, using the super-user, create a role that will allow Vault the minimum
privileges by performing a POST to Elasticsearch.

```bash{outputLines: 2-5}
curl -k \
    -X POST \
    -H "Content-Type: application/json" \
    -d '{"cluster": ["manage_security"]}' \
    https://<super-user-username>:<super-user-password>@<elastic-ip>:<elastic-port>/_xpack/security/role/vault
```

Next, create a user for Vault associated with that role.

```bash{outputLines: 2-5}
curl -k \
    -X POST \
    -H "Content-Type: application/json" \
    -d @data.json \
    https://<super-user-username>:<super-user-password>@<elastic-ip>:<elastic-port>/_xpack/security/user/vault
```

The content of `data.json` in this example is:

```json
{
    "password": "<vault-elastic-password>",
    "roles": ["vault"],
    "full_name": "Hashicorp Vault",
    "metadata": {
        "plugin_name": "Vault Plugin Database Elasticsearch",
        "plugin_url": "https://github.com/hashicorp/vault-plugin-database-elasticsearch"
    }
}
```

Now, an Elasticsearch user is configured and ready to be used by Vault.

## Set up the Database secret engine for Elasticsearch

Enable the database secrets engine in Vault.

```bash
vault secrets enable database
```

Expected output:
```text
Success! Enabled the database secrets engine at: database/
```

By default, the secrets engine is enabled at the path with the same name of the
engine. To enable the secrets engine at a different path, use the `-path`
argument.

Configure Vault with the plugin and connection information. You will need to
provide the certificate, key and CA bundle (Root CA and Intermediates):

```bash{outputLines: 2-7}
vault write database/config/tsb-elastic \
    plugin_name="elasticsearch-database-plugin" \
    allowed_roles="tsb-elastic-role" \
    username=vault \
    password=<vault-elastic-password> \
    url=https://<elastic-ip>:<elastic-port> \
    ca_cert=es-bundle.ca
```

Configure a role that maps a name in Vault to a role definition in Elasticsearch.

```bash{outputLines: 2-7}
vault write database/roles/tsb-elastic-role \
    db_name=tsb-elastic \
    creation_statements='{"elasticsearch_role_definition": {"cluster":["manage_index_templates","monitor"],"indices":[{"names":["*"],"privileges":["manage","read","write"]}],"applications":[],"run_as":[],"metadata":{},"transient_metadata":{"enabled":true}}}' \
    default_ttl="1h" \
    max_ttl="24h"

Success! Data written to: database/roles/internally-defined-role
```

For validation of the configuration, generate a new credential by reading from
the `/creds` endpoint with the name of the role:

```bash{outputLines: 2-8}
vault read database/creds/tsb-elastic-role
Key                Value
---                -----
lease_id           database/creds/tsb-elastic-role/jZHuJvZeEOvGJhfFixVcwOyB
lease_duration     1h
lease_renewable    true
password           A1a-SkZ9KgF7BJGn2FRH
username           v-root-tsb-elastic-rol-2eRGSeD09gTNzYHf7a2G-1610542455
```

You can check the Elasticsearch cluster to verify the newly created credential
is present:

```bash{outputLines: 2-9,10-14}
curl -u "vault:<vault-elastic-password>" -ks -XGET https://<super-user-username>:<super-user-password>@<elastic-ip>:<elastic-port>/_xpack/security/user/v-root-tsb-elastic-rol-2eRGSeD09gTNzYHf7a2G-1610542455|jq '.'

{
    "v-root-tsb-elastic-rol-2eRGSeD09gTNzYHf7a2G-1610542455": {
        "username": "v-root-tsb-elastic-rol-2eRGSeD09gTNzYHf7a2G-1610542455",
        "roles": [
            "v-root-tsb-elastic-rol-2eRGSeD09gTNzYHf7a2G-1610542455"
        ],
        "full_name": null,
        "email": null,
        "metadata": {},
        "enabled": true
    }
}
```

## Set up Kubernetes secret engine

Configure a policy named "database", This is a very non-restrictive policy, and
in a production setting, we should lock this down more.

```bash{outputLines: 2-6}
vault policy write es-auth - <<EOF
path "database/creds/internally-defined-role" {
    capabilities = ["read"]
}
EOF
Success! Uploaded policy: es-auth
```

Configure Vault to enable access to the Kubernetes API. This example assumes
that you are running commands in the Vault pod using `kubectl exec`. If you are
not, you will need to find the right JWT Token, Kubernetes API URL (that Vault
will use to connect to Kubernetes) and the CA certificate of the `vaultserver`
service account as described in
[Vault documentation](https://learn.hashicorp.com/tutorials/vault/kubernetes-external-vault?in=vault/kubernetes#define-a-kubernetes-service-account):

```bash{outputLines: 3-5}
vault auth enable kubernetes
vault write auth/kubernetes/config \
    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    kubernetes_host=https://${KUBERNETES_PORT_443_TCP_ADDR}:443 \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
```

Attach our database policy to the service accounts that will use it, namely OAP
service accounts for both management plane and control plane namespaces:

```bash{outputLines: 2-5}
vault write auth/kubernetes/role/es \
    bound_service_account_names=tsb-oap,istio-system-oap,default \
    bound_service_account_namespaces=tsb,istio-system \
    policies=es-auth \
    ttl=1h
```

## Inject Secrets into the Pod

### Management plane

To use Vault Agent Injector in combination with Elasticsearch, add the following
deployment pod annotations and environment variables to the `ManagementPlane`
custom resource.

```yaml
spec:
  components:
    oap:
      kubeSpec:
        deployment:
          env:
            - name: SW_ES_SECRETS_MANAGEMENT_FILE
              value: /vault/secrets/credentials
          podAnnotations:
            vault.hashicorp.com/agent-inject: "true"
            vault.hashicorp.com/agent-init-first: "true"
            vault.hashicorp.com/agent-inject-secret-credentials: "database/creds/tsb-elastic-role"
            vault.hashicorp.com/agent-inject-template-credentials: |
              {{- with secret "database/creds/tsb-elastic-role" -}}
              user={{ .Data.username }}
              password={{ .Data.password }}
              trustStorePass=tetrate
              {{- end -}}
            vault.hashicorp.com/role: "es"
```

### Control plane

The control plane also needs credentials for connecting to Elasticsearch. You
will need to add the pod annotations for Vault injector into the OAP component
in the control plane too. Below is a YAML snippet with the needed changes.

```yaml
spec:
  components:
    oap:
      kubeSpec:
        deployment:
          env:
            - name: SW_ES_SECRETS_MANAGEMENT_FILE
              value: /vault/secrets/credentials
          podAnnotations:
            vault.hashicorp.com/agent-init-first: "true"
            vault.hashicorp.com/agent-inject: "true"
            vault.hashicorp.com/agent-inject-secret-credentials: database/creds/tsb-elastic-role
            vault.hashicorp.com/agent-inject-template-credentials: |
              {{- with secret "database/creds/tsb-elastic-role" -}}
              user={{ .Data.username }}
              password={{ .Data.password }}
              trustStorePass=tetrate
              {{- end -}}
            vault.hashicorp.com/role: es
```

:::warning
After applying the annotations for Vault integration, you should
remove the `elastic-credentials` secret from both management and control plane
namespace.
:::

## Debugging

You can add more debug info from Vault-Injector by adding the annotation:
`vault.hashicorp.com/log-level: trace`
