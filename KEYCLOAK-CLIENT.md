# Creating the Headlamp Client in Keycloak

Create a confidential OpenID Connect client in the same Keycloak realm that your
k3s API server trusts.

## Client

In the Keycloak admin console:

1. Select the realm used for Kubernetes users.
2. Open `Clients`.
3. Click `Create client`.
4. Set `Client type` to `OpenID Connect`.
5. Set `Client ID` to `headlamp`.
6. Enable `Client authentication`.
7. Enable `Standard flow`.
8. Disable flows Headlamp does not need, such as `Direct access grants` and
   `Service accounts roles`.
9. Set `Valid redirect URIs` to:

```text
https://headlamp.k3s-test.dgkim.net/oidc-callback
```

10. Set `Web origins` to:

```text
https://headlamp.k3s-test.dgkim.net
```

Save the client and copy the client secret from the `Credentials` tab.

## Groups Claim

Kubernetes RBAC in this repo authorizes the Keycloak group
`headlamp-viewers`, so Keycloak must include a `groups` claim in the token.

Create the mapper on the Headlamp client's dedicated client scope:

1. Open `Clients`.
2. Open the `headlamp` client.
3. Open `Client scopes`.
4. Open the dedicated scope for this client.
5. Add a mapper by configuration.
6. Choose `Group Membership`.
7. Set `Name` to `groups`.
8. Set `Token Claim Name` to `groups`.
9. Turn `Full group path` off, unless your Kubernetes RBAC subject uses full
   paths such as `/platform/headlamp-viewers`.
10. Enable `Add to ID token`.
11. Enable `Add to access token`.
12. Save the mapper.

It is normal if `groups` does not exist under `Manage > Client scopes`.
`groups` is the token claim name used by the mapper. It only needs to be an OIDC
scope if you intentionally create a reusable client scope named `groups` and put
the mapper there.

## User Group

Create or reuse this Keycloak group:

```text
headlamp-viewers
```

Add users who should have read-only Headlamp access to that group. The matching
Kubernetes RBAC is defined in `manifests/rbac-oidc-viewers.yaml`.

## Scopes

Use these Headlamp scopes unless you created a separate Keycloak client scope
named `groups`:

```text
openid,email,profile,offline_access
```

The `groups` claim comes from the protocol mapper above, not from the requested
scope list. `offline_access` is requested so Headlamp receives a refresh token
for its session refresh flow.

## Certificate Chain

Headlamp is configured to trust a ConfigMap named `headlamp-oidc-ca` in
`kube-system`. If Keycloak's TLS certificate is managed by cert-manager in the
`keycloak` namespace, sync its public certificate chain before restarting
Headlamp:

```sh
scripts/sync-keycloak-oidc-ca.sh
```

## Kubernetes API Server

The Kubernetes API server must trust the same Keycloak realm, otherwise Headlamp
login can succeed but Kubernetes API requests will be rejected. For k3s, see
[Configuring k3s for Keycloak OIDC](K3S-OIDC.md).
