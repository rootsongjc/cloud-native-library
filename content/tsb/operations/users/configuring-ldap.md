---
title: LDAP as the Identity Provider
---

This document describes how to configure the LDAP integration for Tetrate Service Bridge (TSB). LDAP integration in TSB allows you to use LDAP as an Identity Provider for user login to TSB,  as well as synchronizing users and groups from LDAP to TSB automatically.

This document assumes that you already have working knowledge of configuring an LDAP service, as well as how to authenticate using it. 
 
## Configuration
 
LDAP can be configured through `ManagementPlane` CR or Helm values. Following is an example of custom resource YAML that uses LDAP as TSB Identity Provider. You will need to edit the `ManagementPlane` CR or the Helm values and configure the relevant sections. Please refer to [`LDAPSettings`](../../refs/install/managementplane/v1alpha1/spec#ldapsettings) for more details.
 
The following sections will explain more about what each part of the YAML file means.
 
```yaml
spec:
  hub: <registry-location>
  organization: <organization-name>
  ...
  identityProvider:
    ldap:
      host: <ldap-hostname-or-ip>
      port: <ldap-port>
      search:
        baseDN: dc=tetrate,dc=io
      iam:
        matchDN: "cn=%s,ou=People,dc=tetrate,dc=io"
        matchFilter: "(&(objectClass=person)(uid=%s))"
      sync:
        usersFilter: "(objectClass=person)"
        groupsFilter: "(objectClass=groupOfUniqueNames)"
        membershipAttribute: uniqueMember
```
 
## Identity Provider Configuration
 
There are two ways of using LDAP as an Identity provider:
 
- Using Direct Bind Authentication
- Using a Search based Authentication
 
Using the Direct Bind Authentication is preferred as performance is better, but it requires user Distinguished Names ("DN"s) to be uniform across the entire LDAP tree. If this is not the case, a more flexible Search Based Authentication can be configured to authenticate users based on pre-configured queries.
 
These approaches are not mutually exclusive. If both are configured, the Direct Bind Authentication will be attempted first and if users cannot be authenticated, TSB will fallback to using the Search based Authentication.
 
### Direct Bind Authentication
 
Authentication in LDAP is done by performing a bind operation against a DN. The DN is expected to be a user record that has a password configured. The bind operation tries to match the given DN and password with an existing record. Authentication succeeds if the binding operation succeeds.
 
`DN`s, however, are commonly in the form like `uid=nacx,ou=People,dc=tetrate,dc=io`. This format is not convenient for regular logins, as users shouldn't be asked to type the full DN in a login form. Direct Bind Authentication allows you to configure a pattern to match the login user against, and use that as the DN.
 
The following example configures a Direct Bind Authentication pattern:
 
```yaml
iam:
  matchdn: 'uid=%s,ou=People,dc=tetrate,dc=io'
```
 
In this example, upon log in, the `%s` in the pattern will be replaced by the provided login user, and the resulting DN will be used for the bind authentication.
 
 
### Search based authentication
 
As previously explained, Direct Bind Authentication works fine if all users that exist can be matched against the same DN pattern. In some cases, however, users might be created in different parts of the LDAP tree (for example, each user could be created inside a group for a specific department within the organization) making it impossible to have one single pattern to match them all.
 
In this case, you can perform a search on the LDAP tree looking for a record that matches the given username, then attempt a bind authentication with the DN of the record.
 
In order to perform the search, a connection must be established to the LDAP server. This may require credentials if the server is not configured with anonymous access. Please refer to the "[Credential and Certificate](#credential-and-certificate)" section for more details. 
 
The following example shows how to configure the Search based authentication:
 
```yaml
search:
  baseDN: dc=tetrate,dc=io
iam:
  matchfilter: '(&(objectClass=person)(uid=%s))'
```
 
In this example a search is configured to lookup the tree starting at `dc=tetrate,dc=io` (`iam.matchFilter` uses the query defined in `search.baseDN`). And will attempt to match all records that are of type `person` and with the `uid` attribute equal to the given username. Similar to Direct Bind Authentication, the Search pattern expects a `%s` placeholder that will be replaced by the given username.
 
 
### Combining direct and search authentication methods
 
It is possible to combine both authentication methods, to configure a more flexible authentication configuration. When both methods are configured, Direct Bind Authentication will have precedence, as it does not require a traversal of the LDAP tree, and is therefore more efficient.
 
An example that uses both authentication strategies might look like the following
 
```yaml
iam:
  matchdn: 'uid=%s,ou=People,dc=tetrate,dc=io'
  matchfilter: '(&(objectClass=person)(uid=%s))'
```
 
### Using Microsoft Active Directory
 
Microsoft Active Directory implements the LDAP bind authentication in a different way. Instead of using a full DN for the LDAP bind operation, it uses the user (which should be in the form: `user@domain`).
 
Since this is the username that is likely to be configured in a login form, direct authentication could be simply configured as follows:
 
```yaml
iam:
  matchdn: '%s'
```
 
Search Based Authentication in Active Directory can be configured with the following filter, that matches the standard way of identifying user accounts in AD, in case Direct authentication does not cover all the authentication needs:
 
```yaml
iam:
  matchfilter: '(&(objectClass=user)(samAccountName=%s))'
```

## Credential and Certificate
Some operations require running privileged queries against the LDAP server, such as fetching the entire group and user list, or authenticating users using a search. In those cases, if credentials are needed they must be configured in a Kubernetes Secret. 
 
You can use `tctl install manifest management-plane-secrets` to create required credentials and certificates to connect to your LDAP server. 
 
```bash{promptUser: "alice"}
tctl install manifest management-plane-secrets \
    …
    --ldap-bind-dn <ldap-bind-dn> \
    --ldap-bind-password <ldap-bind-password> \
    --ldap-ca-certificate "$(cat ldap-ca.cert)" \
    --tsb-admin-password <tsb-admin-password> \
    --tsb-server-certificate "$(cat foo.cert)" \
    --tsb-server-key "$(cat foo.key)" > managementplane-secrets.yaml
```
 
If you cannot use the above command and need to do this manually, create `ldap-credentials` secret as follows
 
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ldap-credentials
  namespace: tsb
data:
  binddn: 'base64-encoded full DN of the user to use to authenticate'
  bindpassword: 'base64-encoded password'
```
 
Also create a `custom-host-ca` secret if your LDAP is configured to present a self-signed certificate.
 
```bash{promptUser: alice}{outputLines: 2-3}
kubectl create secret generic custom-host-ca \
    --from-file=ca-certificates.crt=<path to custom CA file> \
    --namespace tsb
```
 
 
## User and group synchronization
 
User and group synchronization is done by running the sync queries in the LDAP configuration above. The following example shows two example queries that can be used to get users and groups from a standard LDAP server.
 
The `membershipattribute` is used to match users with the groups they belong to. For every found group, this attribute will be read to extract the information of the members of the group.
 
Note that the queries are highly dependent on the LDAP tree structure and everyone will have to change them to match it.
 
```yaml
sync:
  usersfilter: '(objectClass=person)'
  groupsfilter: '(objectClass=groupOfUniqueNames)'
  membershipattribute: uniqueMember
```
 


