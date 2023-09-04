---
title: PostgreSQL Credentials
description: How to combine Vault Agent Injector with PostgreSQL.
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

```bash
helm install --name=vault --set='server.dev.enabled=true' ./vault-helm
```

## Set up the database secret engine for PostgreSQL

Enable the database secrets engine in Vault.

```bash
vault secrets enable database
```

Expected output:
```text
Success! Enabled the database secrets engine at: database/
```

By default, the secrets engine is enabled at the name of the engine. To enable
the secrets engine at a different path, use the `-path` argument.

Configure Vault with the proper plugin and connection information.
In the `connection_url` parameter, replace `postgres.tsb.svc:5432/tsb` with the
full `host:port/db_name` of your PostgreSQL cluster. Only change the lower
`username` and `password` with your own, don't edit the one between `{{ }}` in
the URL, it is used as a template:

```bash{outputLines: 2-6}
vault write database/config/tsb \
    plugin_name=postgresql-database-plugin \
    allowed_roles="pg-role" \
    connection_url="postgresql://{{username}}:{{password}}@postgres.tsb.svc:5432/tsb?sslmode=disable" \
    username="<postgres-username>" \
    password="<postgres-password>"
```

You can review the configuration by using the `read` action:

```bash{outputLines: 2-7}
vault read  database/config/tsb
# Key                                   Value
# ---                                   -----
# allowed_roles                         [pg-role]
# connection_details                    map[connection_url:postgresql://{{username}}:{{password}}@postgres.tsb.svc:5432/?sslmode=disable username:postgres]
# plugin_name                           postgresql-database-plugin
# root_credentials_rotate_statements    []
```

Configure a role that maps a name in Vault to a templated SQL statement which
Vault can execute to create database credentials.<br />
The `max_ttl` defines how long the new credentials are valid.<br />
The `default_ttl` defines a lease time, and the Vault-Injector will renew it
until we reach the `max_ttl`.

TTL values must be paired with the application's database connection lifetime to
ensure they are all closed before the TTL expires.

Run the command below, ensuring that you don't edit the parameters between
`{{ }}` because they are used as a template by Vault:

```bash{outputLines: 2-8}
vault write database/roles/pg-role \
    db_name=tsb \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT ALL ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="12h" \
    max_ttl="24h"

Success! Data written to: database/roles/pg-role
```

Again, use the `read` action to verify the setup:

```bash{outputLines: 2-9,10}
vault read  database/roles/pg-role
# Key                      Value
# ---                      -----
# creation_statements      [CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';       GRANT SELECT ON ALL TABLES IN SCHEMA public TO "{{name}}";]
# db_name                  tsb
# default_ttl              24h
# max_ttl                  24h
# renew_statements         []
# revocation_statements    []
# rollback_statements      []
```

Now, generate a new credential by reading from the `/creds` endpoint with the
name of the role. This is the mechanism that will be used by the Vault-Injector
to grab credentials for your Kubernetes application:

```bash{outputLines: 2-8}
vault read database/creds/pg-role
Key                Value
---                -----
lease_id           database/creds/pg-role/tUEs8eogkk9KL5erU5rLv7hD
lease_duration     24h
lease_renewable    true
password           A1a-1ZYMcUHKJIJH6rrc
username           v-token-pg-role-KQ4ze3GYi5He0D70tEmo-1587973449
```

## Set up Kubernetes Secret Engine

Configure a policy named "pg-auth". This is a very non-restrictive policy, and
in a production setting, you should add more restrictions.

```bash{outputLines: 2-6}
vault policy write pg-auth - <<EOF
path "database/creds/*" {
    capabilities = ["read"]
}
EOF
Success! Uploaded policy: pg-auth
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

Attach the database policy to service accounts from the management namespace
(`tsb` namespace here):

```bash{outputLines: 2-5}
vault write auth/kubernetes/role/pg \
    bound_service_account_names=* \
    bound_service_account_namespaces=tsb \
    policies=pg-auth \
    ttl=24h
```

To add more restrictions create one role per `ServiceAccount`. For PostgreSQL,
you will need one for `tsb-iam`, `tsb-spm` and `default` service accounts
because TSB API pods run with `default` service accounts:

```bash{outputLines: 2-5}
vault write auth/kubernetes/role/pg \
    bound_service_account_names=default,tsb-spm,tsb-iam \
    bound_service_account_namespaces=tsb \
    policies=pg-auth \
    ttl=24h
```

## Inject secrets into the pod

To use Vault Agent Injector in combination with PostgreSQL, add the following
deployment pod annotations and environment variables to the ManagementPlane
custom resource.

An overlay is used to re-configure the deployment on the fly:

```yaml
spec:
  dataStore:
    postgres:
      connectionLifetime: 1h # Set connection lifetime
  components:
    apiServer:
      kubeSpec:
        deployment:
          podAnnotations:
            vault.hashicorp.com/agent-inject: 'true'
            vault.hashicorp.com/agent-init-first: 'true'
            vault.hashicorp.com/agent-inject-secret-config.yaml: 'database/creds/pg-role'
            vault.hashicorp.com/agent-inject-template-config.yaml: |
              {{- with secret "database/creds/pg-role" -}}
              data:
                username: {{ .Data.username }}
                password: {{ .Data.password }}
              {{- end -}}
            vault.hashicorp.com/role: 'pg'
            vault.hashicorp.com/secret-volume-path: /etc/dbvault
        overlays:
        - apiVersion: v1
          kind: Deployment
          name: tsb
          patches:
          - path: spec.template.spec.containers[name:tsb].args.[:/etc/db/config\.yaml]
            value: /etc/dbvault/config.yaml
          - path: spec.template.spec.initContainers[name:migration].args.[:/etc/db/config\.yaml]
            value: /etc/dbvault/config.yaml
    iamServer:
      kubeSpec:
        deployment:
          podAnnotations:
            vault.hashicorp.com/agent-inject: 'true'
            vault.hashicorp.com/agent-init-first: 'true'
            vault.hashicorp.com/agent-inject-secret-config.yaml: 'database/creds/pg-role'
            vault.hashicorp.com/agent-inject-template-config.yaml: |
              {{- with secret "database/creds/pg-role" -}}
              data:
                username: {{ .Data.username }}
                password: {{ .Data.password }}
              {{- end -}}
            vault.hashicorp.com/role: 'pg'
            vault.hashicorp.com/secret-volume-path: /etc/dbvault
        overlays:
        - apiVersion: v1
          kind: Deployment
          name: iam
          patches:
          - path: spec.template.spec.containers[name:iam].args.[:/etc/db/config\.yaml]
            value: /etc/dbvault/config.yaml
    spmServer:
      kubeSpec:
        deployment:
          podAnnotations:
            vault.hashicorp.com/agent-inject: 'true'
            vault.hashicorp.com/agent-init-first: 'true'
            vault.hashicorp.com/agent-inject-secret-config.yaml: 'database/creds/pg-role'
            vault.hashicorp.com/agent-inject-template-config.yaml: |
              {{- with secret "database/creds/pg-role" -}}
              data:
                username: {{ .Data.username }}
                password: {{ .Data.password }}
              {{- end -}}
            vault.hashicorp.com/role: 'pg'
            vault.hashicorp.com/secret-volume-path: /etc/dbvault
        job:
          podAnnotations:
            vault.hashicorp.com/agent-inject: 'true'
            vault.hashicorp.com/agent-init-first: 'true'
            vault.hashicorp.com/agent-inject-secret-config.yaml: 'database/creds/pg-role'
            vault.hashicorp.com/agent-pre-populate-only: "true"
            vault.hashicorp.com/agent-inject-template-config.yaml: |
              {{- with secret "database/creds/pg-role" -}}
                data:
                  username: {{ .Data.username }}
                  password: {{ .Data.password }}
              {{- end -}}
            vault.hashicorp.com/role: 'pg'
            vault.hashicorp.com/secret-volume-path: /etc/dbvault
        overlays:
        - apiVersion: v1
          kind: Deployment
          name: spm
          patches:
          - path: spec.template.spec.containers[name:spm].args.[:/etc/db/config\.yaml]
            value: /etc/dbvault/config.yaml
        - apiVersion: v1
          kind: CronJob
          name: spmsync
          patches:
          - path: spec.jobTemplate.spec.template.spec.containers[name:spmsync].args.[:/etc/db/config\.yaml]
            value: /etc/dbvault/config.yaml
```

## Debugging

### Check roles in PostgreSQL

Use the PostgreSQL command line client `psql` to check the role creation inside
the target database, `tsb`:

```bash
psql -h postgres -p 5432 -U tsb -d tsb
```

Once connected to the database, you can use the `\du` command to list all the
current roles for the database:

```text
\du
 
                                                                                 List of roles
                     Role name                      |                         Attributes                         |                          Member of
----------------------------------------------------+------------------------------------------------------------+-------------------------------------------------------------
 rds_ad                                             | Cannot login                                               | {}
 rds_iam                                            | Cannot login                                               | {}
 rds_password                                       | Cannot login                                               | {}
 rds_replication                                    | Cannot login                                               | {}
 rds_superuser                                      | Cannot login                                               | {pg_monitor,pg_signal_backend,rds_replication,rds_password}
 rdsadmin                                           | Superuser, Create role, Create DB, Replication, Bypass RLS+| {}
                                                    | Password valid until infinity                              |
 rdsrepladmin                                       | No inheritance, Cannot login, Replication                  | {}
 tsb                                                | Create role, Create DB                                    +| {rds_superuser}
                                                    | Password valid until infinity                              |
                                                    |                                                            | {}
 v-kubernet-pg-role-5OUfsUQv3xAASWZkbECV-1589890098 | Password valid until 2020-05-20 12:08:23+00                | {}
 v-kubernet-pg-role-7uiTkWgsxphogXub0qpp-1589887199 | Password valid until 2020-05-20 11:20:04+00                | {}
...
```

Here you can see the role `tsb` that was used to configure the database inside
Vault and some roles like `v-kubernet-pg-role-5OUfsUQv3xAASWZkbECV-1589890098`
which correspond to dynamic roles created by the `vault-Injector` sidecar.

You can also list the access rights that were granted to the dynamic roles.
Here is an example with the role `v-kubernet-pg-role-5OUfsUQv3xAASWZkbECV-1589890098`:

```sql
SELECT grantee AS user, CONCAT(table_schema, '.', table_name) AS table,
   CASE
       WHEN COUNT(privilege_type) = 7 THEN 'ALL'
       ELSE ARRAY_TO_STRING(ARRAY_AGG(privilege_type), ', ')
   END AS grants
FROM information_schema.role_table_grants
WHERE grantee='v-kubernet-pg-role-5OUfsUQv3xAASWZkbECV-1589890098'
GROUP BY table_name, table_schema, grantee;
 
                       user                        |         table          | grants
----------------------------------------------------+------------------------+--------
v-kubernet-pg-role-5OUfsUQv3xAASWZkbECV-1589890098 | public.application     | ALL
v-kubernet-pg-role-5OUfsUQv3xAASWZkbECV-1589890098 | public.assignment      | ALL
v-kubernet-pg-role-5OUfsUQv3xAASWZkbECV-1589890098 | public.association     | ALL
...
```
