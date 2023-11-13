---
title: User Synchronization
---

TSB has a teamsync component that will periodically connect to your Identity Provider (IdP) and sync user and team information into TSB.

Currently teamsync supports [LDAP](https://en.wikipedia.org/wiki/Lightweight_Directory_Access_Protocol) and [Azure AD](https://azure.microsoft.com/services/active-directory/), and will do The Right Thing for you automatically. However, if you are using another IdP, you will need to manually perform these tasks. This document will describe how to perform them.

Before you start, make sure that you have:

✓ [Installed TSB Management Plane](../../setup/self_managed/management-plane-installation) <br />
✓ [Login to TSB with tctl](../../setup/tctl_connect) with administrator account<br />
✓ Get your TSB's organization name - Make sure to use organization name configured at installation time in the TSB `ManagementPlane` CR.

## Create Organization

Teamsync not only syncs your users and teams, but it also creates an organization when run for the first time after TSB management plane components are installed.

Therefore if you are using an IdP that is not supported by teamsync, you will also need to perform this step manually.

To create an organization, create following `organization.yaml` and then apply with tctl

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Organization
metadata:
  name: <organization-name>
```

```bash
tctl apply -f organization.yaml
````

## Synchronizing Users and Teams Manually

Synchronization entails fetching users and teams information from IdP and transforming them into a structure that TSB sync API payload then send sync request to TSB API Server. Once they are synchronized, you can assign roles to the users and teams to give them access to TSB resources.

![](../../assets/operations/teamsync.png)

### Fetch Users and Teams from IdP

Details of this step will vary depending on your IdP. You should check your IdP documentation on how to get users and teams. For example, If you are using Okta you may be able to use [List users](https://developer.okta.com/docs/reference/api/users/) and [List groups](https://developer.okta.com/docs/reference/api/groups/) API. Similarly if you are using Keycloak, you may be able to use [List users](https://www.keycloak.org/docs-api/15.0/rest-api/index.html#_users_resource) and [List groups](https://www.keycloak.org/docs-api/15.0/rest-api/index.html#_groups_resource) API.

### Transform Data into TSB sync API payload

Once you obtain the list of users and teams from your IdP, you need to transform them into TSB sync API payload format. The exact details on how to perform this transformation depends on the payload format of your IdP API.

Following is an example of sync API payload. Refer to <a href="../../rest#tag/Organizations/operation/Organizations_SyncOrganization">Sync Organization API</a> for more details.

```json
{
    "sourceType": "MANUAL",
    "users": [
        {
            "id": "user_1_id",
            "email": "user_1@email.com",
            "loginName": "user1",
            "displayName": "User 1"
        },
        {
            "id": "user_2_id",
            "email": "user_2@email.com",
            "loginName": "user2",
            "displayName": "User 2"
        },
    ],
    "teams": [
        {
            "id": "team_1_id",
            "description": "Team 1 description",
            "displayName": "Team 1",
            "memberUserIds": [
                "user_1_id"
            ]
        },
         {
            "id": "team_2_id",
            "description": "Team 2 description",
            "displayName": "Team 2",
            "memberUserIds": [
                "user_2_id"
            ]
        },
    ]
}
```

### Send Sync API Request

After you have transformed the IdP payload into TSB sync API payload, you can send requests to the TSB API server to  synchronize the data .

The following example uses `curl` to send a request to the TSB API server running on `<tsb-host>:8443`, using the TSB admin user credentials. The TSB sync API payload is assumed to be stored in the file `/path/to/data.json`

```bash
curl --request POST \
  --url https://<tsb-host>:8443/v2/organizations/tetrate/sync \
  --header 'Authorization: Basic base64(<admin>:<admin-password>) \
  --header 'Content-Type: application/json' \
  --data-binary '@/path/to/data.json'
```

### Automating the Process

Now that you know how teamsync works, you can create a service that runs periodically (e.g. as `cron` job) using your favorite programming language to automate the synchronization process.
