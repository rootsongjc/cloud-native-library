---
title: End User Authentication with Keycloak
description: End user authn/authz at Ingress Gateway using Keycloak as Identity Provider.
weight: 6
---

In this how-to guide, you'll add user authentication and authorization at an 
Ingress Gateway using Keycloak as the Identity Provider.

Before you get started, make sure you've

✓ Installed the [TSB management plane](../../setup/self_managed/management-plane-installation)<br />
✓ Onboarded a [cluster](../../setup/self_managed/onboarding-clusters)<br />
✓ Installed [Keycloak](https://www.keycloak.org/) with HTTPS enabled

:::note 
This example will use a demo of the [httpbin](https://httpbin.org/) application
that's been tested on GKE. If you intend to follow these steps for production
use, make sure you update the application information in the relevant fields
with your information.
:::

In this guide, you'll:

✓ Add authentication and authorization to an Ingress Gateway for a demo httpbin
  application.<br />
✓ Define two roles and two users: an *admin* user (called Jack) that can do
  everything, and a *normal* user (Sally) that can only do `GET /status`.<br />
✓ Configure your Ingress Gateway to allow all access to the *admin* role and
  only `GET /status` to a *normal* role.<br />
✓ Log in with each user and validate whether the *admin* user `Jack`, can access
  everything and user `Sally` who has the *normal* role is only able to 
  `GET /status`<br />

## What is an OpenID provider?

An OpenID provider is an OAuth 2.0 authorization server which offers
authentication as a service. It ensures the end-user is authenticated and
provides [claims](https://openid.net/specs/draft-jones-json-web-token-07.html#anchor4)
about the end-user, and the authentication event to the client application. In
this example, you'll use Keycloak as the OpenID Provider. You can replicate
similar steps with other OpenID providers such as Auth0 or Okta.

:::note
In this how-to, we will use https://keycloak.example.com as our Keycloak URL.
You should change this to your own Keycloak URL.
:::

## Configuring Keycloak as an OpenID provider

Login to the Keycloak admin interface.

:::note
If you already have the Realm, Roles and Users created, go straight to the
Client section.
:::

### Realm

Start by creating Realm. If this is your first time logging in to Keycloak,
you'll have a default master Realm. This is used to manage access to the
Keycloak interface and should not be used to configure your open ID provider. So
you'll need to create a new realm.

1. Click the **Add Realm** button
2. Set the Realm name -- in this example it's `tetrate`.
3. Click **Create**

### Role

In the created Realm, add two new Roles: admin and normal.

1. Click **Roles** in the left side menu
2. Select the **Add Role** button
3. Set the name as **admin**
4. Click Save
5. Add another Role with name **normal** following the same steps as above

### Users

Add two users -- Jack and Sally -- and map them to their new roles:

1. Click **Users** in the left side menu
2. Select the **Add user** button
3. Fill the details for `Jack`
4. Click **Save**
5. Select the **Credentials** tab
6. Set a password for `Jack`
7. Click **Role Mappings** tab
8. Add the **admin** role
9. Add another user with the name `Sally` and follow the steps above, adding a
   `normal` role in the **Role Mappings** tab

### Client

Clients are entities that can request Keycloak to authenticate a user. In this
case, Keycloak will provide a Single Sign-On that a user will log in into,
retrieve a JWT token, and use that token to authenticate to your Ingress Gateway
managed by TSB.

Adding a new Client.

1. Click **Clients** in the left side menu
2. Select the Client **Create** button
3. Client ID: `tetrateapp`
4. Client Protocol: openid-connect
5. Root URL: https://www.keycloak.org/app/, (https://www.keycloak.org/app/ is an
   SPA testing application available on the Keycloak website).
6. Click **Save**

Then make some updates in the Client.

First, increase the token lifespan to ensure that it doesn't expire too quickly,
or during testing.

1. In the Settings tab, scroll down, select **Advanced Settings**
2. Set the **Access Token Lifespan** to 2 hours
3. Click **Save**

Then, you need to add two mappers so that Keycloak can generate a JWT with data
that you use in the TSB Ingress Gateway.

You'll need to add two types of mappers - an Audience and a Role mapper:


| Mappers | Purpose |
| --- | --- |
| Audience mapper | Adds a client id in the audience field in JWT token. This ensures that you can limit JWT to specific clients. |
| Role mappers |Changes the role from nested struct to array in the JWT token. Currently, TSB cannot handle nested fields in JWT claims. This has been fixed in Istio 1.8 and will be added to TSB in future releases. |

1. Select the **Mappers** tab
2. Click the **Create** button and enter the following information:
   - Name: Audience mapper
   - Mapper Type: Audience
   - Included Client Audience: `tetrateapp`
3. Click **Save**

1. Return to the **Mappers** tab
2. Click on the **Create** button and enter the following information:
   - Name: Role mapper
   - Mapper Type: User Realm Role
   - Token Claim Name: roles
   - Claim JSON Type: String
   Leave multi-valued, add to ID token, Add to access token, and Add user info to ‘on'
3. Click **Save**

### Test User Sign In

Now you have your client configured, sign in and inspect your JWT token

1. Go to https://www.keycloak.org/app/ and enter the following information:
    - Keycloak URL: https://keycloak.example.com/auth
    - Realm: `tetrate`
    - Client: `tetrateapp`
2. Click **Save**

To inspect the JWT token.

1. Open the browser console
2. Click on the **Network** tab
3. Sign in with user Jack's credentials.
4. Look up a request to the `token`. In the response, get the `access_token`.
5. Paste your token into https://jwt.io/

You'll see the following information from your JWT token. You only need to note
three fields that you'll use in your Ingress Gateway configuration: `iss`,
`aud`, and `roles`. 

```json
{
  "exp": 1606908135,
  "iat": 1606900935,
  "auth_time": 1606900917,
  "jti": "c1e45982-38c6-4d0d-b201-9d823eed4c0a",
  "iss": "https://keycloak.example.com/auth/realms/tetrate",
  "aud": [
    "tetrateapp",
    "account"
  ],
  "sub": "06765a3f-b09f-4c46-a0f9-0285c3924409",
  "typ": "Bearer",
  "azp": "tetrateapp",
  "nonce": "f96cd9eb-af9e-4e41-8591-ffc01fd94dd0",
  ...
  "scope": "openid email profile",
  "email_verified": true,
  "roles": [
    "offline_access",
    "admin",
    "uma_authorization"
  ],
  "name": "Jack White",
  "preferred_username": "jack",
  "given_name": "Jack",
  "family_name": "White",
  "email": "jack@tetrate.com"
}
```

You can also get a user JWT token using OAuth's Resource Owner Password Flow.
This flow is enabled by default when you create a Keycloak Client.

```bash{promptUser: Alice}{outputLines: 2-8}
curl --request POST \
    --url https://keycloak.example.com/auth/realms/tetrate/protocol/openid-connect/token \
    --header 'Content-Type: application/x-www-form-urlencoded' \
     --data client_id=tetrateapp \
     --data password=<user_password> \
     --data username=jack \
     --data grant_type=password \
     --data 'scope=openid email profile'
```

## Deploying the Httpbin application with Ingress Gateway

Deploy the `httpbin` application along with the Ingress Gateway.

Create the following [`httpbin.yaml`](../../assets/howto/httpbin.yaml)

<CodeBlock className="language-yaml">
  {httpBinYAML}
</CodeBlock>

Deploy `httpbin` using the kubectl commands to your onboarded clusters

```bash{promptUser: Alice}
kubectl create namespace httpbin
kubectl label namespace httpbin istio-injection=enabled --overwrite=true
kubectl apply -n httpbin -f httpbin.yaml
```

Confirm all services and pods are running

```bash{promptUser: Alice}
kubectl get pods -n httpbin
```

Create an Ingress Gateway [`ingress.yaml`](../../assets/howto/ingress.yaml)

<CodeBlock className="language-yaml">
  {ingressYAML}
</CodeBlock>

Apply your changes

```bash{promptUser: Alice}
kubectl apply -n httpbin -f ingress.yaml
```

Confirm that all services and pods are running. Make sure that you wait until 
the Ingress Gateway has its external IP assigned.

```bash{promptUser: Alice}
kubectl get pods -n httpbin
kubectl get svc -n httpbin
```

Get the Ingress Gateway IP

```bash{promptUser: Alice}
export GATEWAY_HTTPBIN_IP=$(kubectl -n httpbin get service tsb-gateway-httpbin -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

## Configuring Workspaces and Ingress Gateway

Now that you have your application running, you need to create workspaces and
configure your Ingress Gateway. You will need TSB running and tctl for this.

:::note
If you run TSB demo install, you will have a default tenant named `tetrate` and
a default cluster named `demo` which we use in the following configuration
yamls. If you are using this in production, please change it to your own tenant
and cluster.
:::

### Workspace

Create a [`workspace.yaml`](../../assets/howto/workspace.yaml)

<CodeBlock className="language-yaml">
  {workspaceYAML}
</CodeBlock>

Apply your changes

```bash{promptUser: Alice}
tctl apply -f workspace.yaml
```

Make sure that the workspace is created

```bash{promptUser:Alice}
tctl get workspaces httpbin-ws
```

Expected output:

```text
  NAME
  httpbin-ws
```

Next, create an Ingress Gateway to allow access to httpbin from outside the
mesh. You'll start with an insecure Gateway that has no authentication.

### IngressGateway

Create the following [`gateway-no-auth.yaml`](../../assets/howto/gateway-no-auth.yaml). In this example, `httpbin-certs`
is already set for HTTPS connections. 

<CodeBlock className="language-yaml">
  {gatewayNoAuthYAML}
</CodeBlock>

Apply with `tctl`

```bash{promptUser: Alice}
tctl apply -f gateway-no-auth.yaml
```

Verify that you have a gateway created in the httpbin namespace

```bash{promptUser: Alice}
kubectl get gateway -n httpbin httpbin-gw-ingress -o yaml
```

Example output

```yaml

apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  annotations:
    tsb.tetrate.io/fqn: tenants/tetrate/workspaces/httpbin-ws/gatewaygroups/httpbin-gw/ingressgateways/httpbin-gw-ingress
    xcp.tetrate.io/contentHash: ea6e317d90873ee3
  creationTimestamp: "2020-12-03T00:52:32Z"
  generation: 2
  labels:
    xcp.tetrate.io/gatewayGroup: httpbin-gw
    xcp.tetrate.io/workspace: httpbin-ws
  name: httpbin-gw-ingress
  namespace: httpbin
  resourceVersion: "6006430"
  selfLink: /apis/networking.istio.io/v1beta1/namespaces/httpbin/gateways/httpbin-gw-ingress
  uid: ab0ad2d9-b3db-40ac-9926-0e440d7d8c85
spec:
  selector:
    app: tsb-gateway-httpbin
  servers:
  - hosts:
    - httpbin/httpbin.tetrate.com
    port:
      name: http-httpbin
      number: 8443
      protocol: HTTP
  - hosts:
    - httpbin/httpbin.tetrate.com
    port:
      name: mtls-httpbin
      number: 15443
      protocol: HTTPS
    tls:
      mode: ISTIO_MUTUAL
```

Try to access the httpbin by sending it a request

```bash{promptUser: Alice}{outputLines: 3}
export GATEWAY_HTTPBIN_IP=$(kubectl -n httpbin get service tsb-gateway-httpbin -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -k -v "https://httpbin.tetrate.com/get" \
    --resolve "httpbin.tetrate.com:443:${GATEWAY_HTTPBIN_IP}" 
```

## Enabling Authentication and Authorization at Ingress

Now, add the authentication and authorization to your Ingress Gateway by 
creating the following [`gateway-with-auth.yaml`](../../assets/howto/gateway-with-auth.yaml)

<CodeBlock className="language-yaml">
  {gatewayWithAuthYAML}
</CodeBlock>

Notice that in the authentication block -- the **audiences** are set to 
`tetrateapp`, which was set previously in the JWT token.

The authorization block sets two rules: one for the *admin* role which can access
everything and another for the *normal* role which only can access `GET /status`.

Now, apply the changes. Since you have the same name as the previous
`gateway-no-auth.yaml`, it will update your previous gateway.

```bash{promptUser: Alice}
tctl apply -f gateway-with-auth.yaml
```

If you try to access `httpbin` without a JWT token you will get a `403` error

```bash{promptUser: Alice}{outputLines: 2-4}
curl -k -o /dev/null -s \
    -w "%{http_code}\n" "https://httpbin.tetrate.com/get" \
    --resolve "httpbin.tetrate.com:443:${GATEWAY_HTTPBIN_IP}"
403
```

## Access httpbin with JWT Token

Try to access the Gateway with a JWT token. Get the token using Keycloak sample
app or `curl` as explained before, and use the token to make HTTP requests with
`curl` for both users Jack and Sally. Replace `<jack_access_token>` and
`<sally_access_token>` in the `curl` command below to get the user's JWT token.

Try to access `GET /get` with Jack's token *(our admin user)*

```bash{promptUser: Alice}{outputLines: 2-5}
curl -k -o /dev/null -s \
    -w "%{http_code}\n" "https://httpbin.tetrate.com/get" \
    --resolve "httpbin.tetrate.com:443:${GATEWAY_HTTPBIN_IP}" \
    --header "Authorization: Bearer <jack_access_token>"
200
```


Try to access `GET /get` with Sally's token *(our normal user)*. The request
should fail because any user with a *normal* role only is allowed to access
`GET /status/*`

```bash{promptUser: Alice}{outputLines: 2-5}
curl -k -o /dev/null -s \
    -w "%{http_code}\n" "https://httpbin.tetrate.com/get" \
    --resolve "httpbin.tetrate.com:443:${GATEWAY_HTTPBIN_IP}" \
    --header "Authorization: Bearer <sally_access_token>"
403
```

Try to access `GET /status/200` with Sally's token. The request should succeed 
because any user with a *normal* role is allowed to access `GET /status/*`

```bash{promptUser: Alice}{outputLines: 2-5}
curl -k -o /dev/null -s \
    -w "%{http_code}\n" "https://httpbin.tetrate.com/status/200" \
    --resolve "httpbin.tetrate.com:443:${GATEWAY_HTTPBIN_IP}" \
    --header "Authorization: Bearer <sally_access_token>"
200
```

