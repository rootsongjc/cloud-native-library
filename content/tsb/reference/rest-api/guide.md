---
title: REST API Guide
menu-title: Guide
description: Guide describing how to use our REST API for communication with TSB.
---

In this guide you'll learn how to use the TSB REST API to perform common
operations on the platform. The examples in this guide use `curl`, because it's
a popular command used to perform HTTP requests, however, any tool that can do
HTTP will work.

## Authentication

TSB has two main authentication mechanisms: basic authentication and JWT token
authentication.

### Basic Auth

[Basic HTTP authentication](https://tools.ietf.org/html/rfc7617) is done by
sending the HTTP `Authorization` header with the credentials encoded in the
header value. The basic format of the header is:

```text
Authorization: Basic base64(username:password)
```

For example:

```text
Authorization: Basic dGVzdDoxMjPCow==
```

### JWT Token Auth

JWT Token authentication is header-based, and it's configured by setting a JWT
token in the `x-tetrate-token` header. For example:

```text
x-tetrate-token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

## HTTP verbs

The TSB REST API uses the common HTTP verbs to model all the operations that you
can make on the different TSB resources:

- **GET** requests are used to get lists of resources or get the details of
  specific objects.
- **POST** requests are used to create new resources.
- **PUT** requests are used to modify existing resources.
- **DELETE** requests are used to delete resources and their children.

### Example: common resource CRUD operations

The following examples show how to use the common CRUD operations on TSB
resources using the REST API:

#### Resource creation

In this example, you'll create a tenant in an existing organization.
You do this by sending the corresponding POST requests to the TSB rest API and
using Basic Authentication:

```bash
$ curl -u username:password \
    https://tsbhost:8443/v2/organizations/myorg/tenants \
    -X POST -d@- <<EOF
{
    "name": "mytenant",
    "tenant": {
      "displayName": "My tenant",
      "description": "Tenant created using the TSB REST API"
    }
}
EOF
```

Output:

```json
{"fqn":"organizations/myorg/tenants/mytenant","displayName":"My tenant","etag":"\"hhO8m7WN3LM=\"","description":"Tenant created using the TSB REST API"}
```

### Modify a resource

Resources are modified by sending an updated object in a PUT request.

In order to update an object, you need to have the last copy of it. TSB has
mechanisms to prevent concurrent updates and avoid conflicting versions of the
same objects. To this end, TSB assigns an etag to every object and updates it
every time the object is updated. It is mandatory to send the last etag for the
object in PUT requests, to tell TSB that you are modifying the most recent
version of the object.

In this example you'll:

✓ Send a GET request first, to get the last version of the object (updated with the latest etag).<br />
✓ Locally modify the returned JSON.<br />
✓ Send back the modified JSON document in a PUT request.

```bash
curl -u username:password \
    https://tsbhost:8443/v2/organizations/myorg/tenants/mytenant \
    -X GET | jq .

```

Output:
```json
{
  "fqn": "organizations/myorg/tenants/mytenant",
  "displayName": "My tenant",
  "etag": "\"hhO8m7WN3LM=\"",
  "description": "Tenant created using the TSB REST API"
}
```

Modify the JSON document and send it back. It is important to keep the etag
field:

```bash
curl -u username:password \
    https://tsbhost:8443/v2/organizations/myorg/tenants/mytenant \
    -X PUT -d@- <<EOF
{
  "fqn": "organizations/myorg/tenants/mytenant",
  "displayName": "My Modified tenant",
  "etag": "\"hhO8m7WN3LM=\"",
  "description": "Modified description"
}
EOF
```

Output:

```json
{"fqn":"organizations/myorg/tenants/mytenant","displayName":"My Modified tenant","etag":"\"BhsObrdJUWI=\"","description":"Modified description"}
```

### Delete a resource

Resources are deleted by sending the corresponding DELETE requests to the
resource's URL. If a request is sent to a parent resource, then all child
resources will be deleted as well.

```bash
curl -u username:password \
    https://tsbhost:8443/v2/organizations/myorg/tenants/mytenant \
    -X DELETE
```
