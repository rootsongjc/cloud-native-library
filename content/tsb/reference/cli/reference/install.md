---
title: tctl install
description: Install command
---

Generates install manifests and applies it to a cluster

**Options**

```
  -h, --help   help for install
```

**Options inherited from parent commands**

```
  -c, --config string               Path to the config file to use. Can also be
                                    specified via TCTL_CONFIG env variable. This flag
                                    takes precedence over the env variable.
      --debug                       Print debug messages for all requests and responses
      --disable-tctl-version-warn   If set, disable the outdated tctl version warning. Can also be
                                    specified via TCTL_DISABLE_VERSION_WARN env variable.
  -p, --profile string              Use specific profile (default "default")
```

## tctl install cluster-certs

Generate cluster certs for securely communicating with the management plane

```
tctl install cluster-certs [flags]
```

**Examples**

```

# Retrieve cluster certs
tctl install cluster-certs --cluster <cluster-name>"

```

**Options**

```
      --cluster string           The name of the cluster to generate certs for.
  -x, --context string           The kube context for the management plane cluster.
  -n, --controlplane string      The namespace in the cluster that the control plane is installed in. (default "istio-system")
  -h, --help                     help for cluster-certs
  -k, --kubeconfig string        The kubeconfig file for the management plane cluster. Must be able to manage secrets and cert-manager custom resources.
  -m, --managementplane string   The namespace that the management plane is installed in. (default "tsb")
```

**Options inherited from parent commands**

```
  -c, --config string               Path to the config file to use. Can also be
                                    specified via TCTL_CONFIG env variable. This flag
                                    takes precedence over the env variable.
      --debug                       Print debug messages for all requests and responses
      --disable-tctl-version-warn   If set, disable the outdated tctl version warning. Can also be
                                    specified via TCTL_DISABLE_VERSION_WARN env variable.
  -p, --profile string              Use specific profile (default "default")
```

## tctl install cluster-service-account

Generate a cluster service account key for securely communicating with the management plane

```
tctl install cluster-service-account [flags]
```

**Examples**

```

# Create a cluster service account key
tctl install cluster-service-account --cluster <cluster-name>

```

**Options**

```
      --cluster string   The name of the cluster to generate certs for.
      --create-cluster   Create a cluster object in Service Bridge if it doesn't exist (default true)
  -h, --help             help for cluster-service-account
```

**Options inherited from parent commands**

```
  -c, --config string               Path to the config file to use. Can also be
                                    specified via TCTL_CONFIG env variable. This flag
                                    takes precedence over the env variable.
      --debug                       Print debug messages for all requests and responses
      --disable-tctl-version-warn   If set, disable the outdated tctl version warning. Can also be
                                    specified via TCTL_DISABLE_VERSION_WARN env variable.
  -p, --profile string              Use specific profile (default "default")
```

## tctl install demo

Install a batteries-included Service Bridge into a single Kubernetes cluster.

**Synopsis**

Install a batteries-included Service Bridge into a single Kubernetes cluster.

The CLI will be automatically preconfigured to connect to the installed Service Bridge as an Administrator.
The configuration will be saved in a profile named after the configured Kubernetes context, and the Bridge
connection configuration and the user configuration will be named after the Kubernetes cluster where Service
Bridge has been installed.

The Kubernetes context to deploy to is read from the environment's configured kubeconfig. See
https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/ for more information on
kubeconfig.

```
tctl install demo [flags]
```

**Examples**

```

tctl install demo --registry <registry-location>

```

**Options**

```
      --admin-password string    The password for the superuser. By default a secure password will be auto-generated.
      --cluster string           The name of the demo cluster. (default "demo")
  -h, --help                     help for demo
  -o, --org string               The organization to configure (default "tetrate")
  -r, --registry string          The docker registry with the service bridge images [required]
      --set stringArray          set values on the command line (can specify multiple or separate values with commas: key1=val1,key2=val2)
      --set-file stringArray     set values from respective files specified via the command line (can specify multiple or separate values with commas: key1=path1,key2=path2)
      --set-string stringArray   set STRING values on the command line (can specify multiple or separate values with commas: key1=val1,key2=val2)
      --timeout duration         Timeout to login to the management plane. (default 30s)
  -f, --values strings           specify values in a YAML file or a URL (can specify multiple)
```

**Options inherited from parent commands**

```
  -c, --config string               Path to the config file to use. Can also be
                                    specified via TCTL_CONFIG env variable. This flag
                                    takes precedence over the env variable.
      --debug                       Print debug messages for all requests and responses
      --disable-tctl-version-warn   If set, disable the outdated tctl version warning. Can also be
                                    specified via TCTL_DISABLE_VERSION_WARN env variable.
  -p, --profile string              Use specific profile (default "default")
```

## tctl install image-sync

Copy images from Tetrate's registry to another registry

```
tctl install image-sync [flags]
```

**Examples**

```

# Sync latest images
tctl install image-sync --username <username> --apikey <apikey> --registry <registry-location>

```

**Options**

```
      --accept-eula         Accept the EULA. This should be used in CI/CD pipelines where users have already read and accepted the EULA.
  -k, --apikey string       Tetrate Container Registry API Key [required]. Can also be
                            specified via stdin or TCTL_IMAGE_SYNC_APIKEY env variable. This flag
                            takes precedence over the env variable.
      --apikey-stdin        Tetrate Container Registry API Key specified from stdin.
                            Can also be specified via flag or TCTL_IMAGE_SYNC_APIKEY env variable. This takes precedence over
                            the flag and env variable.
      --create-repository   If set to false, disable the creation of the ECR repository if it doesn't exists. (default true)
  -h, --help                help for image-sync
      --just-print          If set, the image list will be printed to stdout, but images will not be synchronized
      --parallel            If set, synchronize images in parallel. Set --parallel=false to synchronize images serially (default true)
      --raw                 DEPRECATED, WILL BE REMOVED IN 1.7. If set, in conjunction with just-print, the output will only contain the image list (default true)
  -r, --registry string     The user-provided registry where images are pushed [required]
      --show-eula           Show the EULA.
      --skip-demo-images    If set to true, don't download demo images like Postgres.
      --skip-optional       If set to true, don't download optional third-party images like (kubegres or kube-rbac-proxy).
  -u, --username string     Tetrate Container Registry username [required]. Can also be
                            specified via TCTL_IMAGE_SYNC_USERNAME env variable. This flag
                            takes precedence over the env variable.
```

**Options inherited from parent commands**

```
  -c, --config string               Path to the config file to use. Can also be
                                    specified via TCTL_CONFIG env variable. This flag
                                    takes precedence over the env variable.
      --debug                       Print debug messages for all requests and responses
      --disable-tctl-version-warn   If set, disable the outdated tctl version warning. Can also be
                                    specified via TCTL_DISABLE_VERSION_WARN env variable.
  -p, --profile string              Use specific profile (default "default")
```

## tctl install manifest

Output the Kubernetes manifests for installing Service Bridge to stdout

**Options**

```
  -h, --help   help for manifest
```

**Options inherited from parent commands**

```
  -c, --config string               Path to the config file to use. Can also be
                                    specified via TCTL_CONFIG env variable. This flag
                                    takes precedence over the env variable.
      --debug                       Print debug messages for all requests and responses
      --disable-tctl-version-warn   If set, disable the outdated tctl version warning. Can also be
                                    specified via TCTL_DISABLE_VERSION_WARN env variable.
  -p, --profile string              Use specific profile (default "default")
```

## tctl install manifest cluster-operators

Output the Kubernetes manifests for installing the cluster operators (control plane and data plane) to stdout.

```
tctl install manifest cluster-operators [flags]
```

**Examples**

```

tctl install manifest cluster-operators --registry <registry-location>

```

**Options**

```
  -n, --controlplane string      The namespace to deploy the control plane and its operator into. (default "istio-system")
  -d, --dataplane string         The namespace to deploy the data plane and its operator into. (default "istio-gateway")
      --exclude-controlplane     Don't render the control plane operator.
      --exclude-dataplane        Don't render the data plane operator.
  -h, --help                     help for cluster-operators
  -r, --registry string          The docker registry with the service bridge images [required]
      --set stringArray          set values on the command line (can specify multiple or separate values with commas: key1=val1,key2=val2)
      --set-file stringArray     set values from respective files specified via the command line (can specify multiple or separate values with commas: key1=path1,key2=path2)
      --set-string stringArray   set STRING values on the command line (can specify multiple or separate values with commas: key1=val1,key2=val2)
  -f, --values strings           specify values in a YAML file or a URL (can specify multiple)
```

**Options inherited from parent commands**

```
  -c, --config string               Path to the config file to use. Can also be
                                    specified via TCTL_CONFIG env variable. This flag
                                    takes precedence over the env variable.
      --debug                       Print debug messages for all requests and responses
      --disable-tctl-version-warn   If set, disable the outdated tctl version warning. Can also be
                                    specified via TCTL_DISABLE_VERSION_WARN env variable.
  -p, --profile string              Use specific profile (default "default")
```

## tctl install manifest control-plane-secrets

Output the Kubernetes manifests for installing the control plane to stdout, including the relevant secrets.

**Synopsis**

This command provides an easy way to generate correctly formatted secrets for installing the control plane. It should be run as part of installation or upgrade of Service Bridge to ensure the correct secret format for the new version.

Manifests are printed to stdout so that they can be committed to source control or applied directly to a Kubernetes cluster depending on deployment preference.

It automatically generates tokens for the control plane to communicate with the management plane. Therefore, you must be logged into the management plane with the correct permissions to create the tokens. This token generation is safe to run multiple times and does not revoke previously created tokens.


```
tctl install manifest control-plane-secrets [flags]
```

**Examples**

```

# Output secrets with required flags
tctl install manifest control-plane-secrets \
	--cluster-service-account "$(cat cluster-service-account-key.jwk)" \
	--cluster demo

# Output secrets with default values for required flags
tctl install manifest control-plane-secrets -y

# Load overlay custom resource from flag
tctl install manifest control-plane -y -f control-cr.yaml

# Load overlay custom resource from stdin
cat control-cr.yaml | tctl install manifest control-plane -y -f-

# Apply directly to Kubernetes
tctl install manifest control-plane-secrets -y | kubectl apply -f-

```

**Options**

```
  -y, --allow-defaults                           Use default values for required fields that aren't provided. DO NOT USE IN PRODUCTION
      --cluster string                           The name of the cluster on which this control plane will be installed [required]. This is what Service Bridge will refer to the cluster as. (default "default")
      --cluster-service-account string           The cluster service account key JWK used to authenticate with the management plane
      --controlplane string                      The namespace of the control plane (default "istio-system")
      --create-cluster                           Create a cluster object in Service Bridge if it doesn't exist (default true)
      --elastic-ca-certificate string            The CA certificate to validate Elasticsearch connections when Elasticsearch is configured to present a self-signed certificate.
      --elastic-password string                  The password Service Bridge will use to communicate with Elasticsearch.
      --elastic-username string                  The username Service Bridge will use to communicate with Elasticsearch.
  -f, --file string                              The custom resource file describing the control plane.
  -h, --help                                     help for control-plane-secrets
      --management-plane-ca-certificate string   The CA certificate to validate TSB management plane APIs if the management plane is configured to present a self-signed certificate.
      --redis-password string                    Password for Redis which is used as the backend for the rate limit server in the control plane
      --redis-tls                                Enable TLS between the rate limit Redis client and server.
      --redis-tls-ca-cert string                 The CA certificate to validate the TLS connection between the rate limit Redis client and server.
      --redis-tls-client-cert string             The client certificate to be used when establishing a mTLS connection between the rate limit Redis client and server.
      --redis-tls-client-key string              The client key to be used when establishing a mTLS connection between the rate limit Redis client and server.
      --xcp-central-ca-bundle string             The CA bundle to validate the certificates presented by XCP Central.
      --xcp-certs string                         The kubernetes secret yaml string for the cluster cert used to securely communicate with the management plane. Can be generated from "tctl install cluster-certs".
```

**Options inherited from parent commands**

```
  -c, --config string               Path to the config file to use. Can also be
                                    specified via TCTL_CONFIG env variable. This flag
                                    takes precedence over the env variable.
      --debug                       Print debug messages for all requests and responses
      --disable-tctl-version-warn   If set, disable the outdated tctl version warning. Can also be
                                    specified via TCTL_DISABLE_VERSION_WARN env variable.
  -p, --profile string              Use specific profile (default "default")
```

## tctl install manifest management-plane-operator

Output the Kubernetes manifests for installing the management plane operator to stdout.

```
tctl install manifest management-plane-operator [flags]
```

**Examples**

```

tctl install manifest management-plane-operator --registry <registry-location>

```

**Options**

```
  -h, --help                     help for management-plane-operator
  -m, --managementplane string   The namespace to deploy the management plane and its operator into. (default "tsb")
  -r, --registry string          The docker registry with the service bridge images [required]
      --set stringArray          set values on the command line (can specify multiple or separate values with commas: key1=val1,key2=val2)
      --set-file stringArray     set values from respective files specified via the command line (can specify multiple or separate values with commas: key1=path1,key2=path2)
      --set-string stringArray   set STRING values on the command line (can specify multiple or separate values with commas: key1=val1,key2=val2)
  -f, --values strings           specify values in a YAML file or a URL (can specify multiple)
```

**Options inherited from parent commands**

```
  -c, --config string               Path to the config file to use. Can also be
                                    specified via TCTL_CONFIG env variable. This flag
                                    takes precedence over the env variable.
      --debug                       Print debug messages for all requests and responses
      --disable-tctl-version-warn   If set, disable the outdated tctl version warning. Can also be
                                    specified via TCTL_DISABLE_VERSION_WARN env variable.
  -p, --profile string              Use specific profile (default "default")
```

## tctl install manifest management-plane-secrets

Output the Kubernetes manifests for installing the management plane to stdout, including the relevant secrets.

**Synopsis**

This command provides an easy way to generate correctly formatted secrets for installing the management plane. It should be run as part of installation or upgrade of Service Bridge to ensure the correct secret format for the new version.

Manifests are printed to stdout so that they can be committed to source control or applied directly to a Kubernetes cluster depending on deployment preference.

If certificates are not passed to the command, it will automatically generate self-signed certficates using the hostname and organization you provide. If hostname and organization are also not passed, you can opt for self signed certs through ManagementPlane CR.
It is not recommended to use self-signed certificates in production.


```
tctl install manifest management-plane-secrets [flags]
```

**Examples**

```

# Output secrets for all required flags
tctl install manifest management-plane-secrets \
    --elastic-password tsb-elastic-password \
    --elastic-username tsb \
    --ldap-bind-dn 
```

**Options**

```
  -y, --allow-defaults                        Use default values for required fields that aren't provided. DO NOT USE IN PRODUCTION.
      --elastic-ca-certificate string         The CA certificate to validate Elasticsearch connections when Elasticsearch is configured to present a self-signed certificate
      --elastic-password string               The password Service Bridge will use to communicate with Elasticsearch [required] (default "tsb-elastic-password")
      --elastic-username string               The username Service Bridge will use to communicate with Elasticsearch [required] (default "tsb")
  -f, --file string                           The custom resource file describing the management plane
  -h, --help                                  help for management-plane-secrets
      --ldap-bind-dn string                   The DN of the user Service Bridge will use to connect to the LDAP server (default "cn=admin,dc=tetrate,dc=io")
      --ldap-bind-password string             The password Service Bridge will use to connect to the LDAP server (default "admin")
      --ldap-ca-certificate string            The CA certificate to validate LDAP connections when LDAP is configured to present a self-signed certificate
      --managementplane string                The namespace to deploy the management plane and secrets into (default "tsb")
      --oidc-client-secret string             The client secret used to connect to the OIDC server
      --oidc-device-client-secret string      The client secret used for device auth with the OIDC server
      --postgres-ca-certificate string        The CA certificate to validate Postgres connections when Postgres is configured to present a self-signed certificate
      --postgres-client-certificate string    The client certificate that Service Bridge needs to provide to Postgres when Postgres is configured to mutually authenticate
      --postgres-client-key string            The client private key that Service Bridge needs to sign requests to Postgres with when Postgres is configured to mutually authenticate
      --postgres-password string              The password Service Bridge will use to communicate with Postgres [required] (default "tsb-postgres-password")
      --postgres-username string              The username Service Bridge will use to communicate with Postgres [required] (default "tsb")
      --teamsync-azure-client-secret string   The client secret used to connect to Azure AD to synchronize users and groups
      --tsb-admin-password string             The Service Bridge admin password [required]
      --tsb-certs-secret                      Automatically install management plane tsb-certs for secure communication with control planes. This is an alternate to setting self-signed cert issuer in the ManagementPlane CR, so set this to false if ManagementPlane CR is configured for self signed certs (default true)
      --tsb-server-certificate string         The certificate for the Service Bridge API server to present [required]
      --tsb-server-key string                 The private key for the Service Bridge API server to sign requests with [required]
      --tsb-tls-hostname string               A comma-separated list of hostnames and IPs for self-signed certificate generation if Service Bridge server certificate/key pair is not provided (default "demo.tsb.tetrate.io")
      --tsb-tls-org string                    The organization for self-signed certificate generation if Service Bridge server certificate/key pair is not provided (default "tetrate")
      --xcp-certs                             Automatically install management plane certs for secure communication with control planes. Assumes cert-manager is installed in the management plane cluster
```

**Options inherited from parent commands**

```
  -c, --config string               Path to the config file to use. Can also be
                                    specified via TCTL_CONFIG env variable. This flag
                                    takes precedence over the env variable.
      --debug                       Print debug messages for all requests and responses
      --disable-tctl-version-warn   If set, disable the outdated tctl version warning. Can also be
                                    specified via TCTL_DISABLE_VERSION_WARN env variable.
  -p, --profile string              Use specific profile (default "default")
```

