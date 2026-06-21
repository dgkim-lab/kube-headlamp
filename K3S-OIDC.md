# Configuring k3s for Keycloak OIDC

Headlamp can complete the browser login with Keycloak, but the Kubernetes API
server must also trust Keycloak tokens. Configure this on the k3s server node.

Edit:

```sh
sudo vi /etc/rancher/k3s/config.yaml
```

Add the OIDC API server arguments:

```yaml
kube-apiserver-arg:
  - oidc-issuer-url=https://<keycloak-host>/realms/<realm>
  - oidc-client-id=headlamp
  - oidc-username-claim=preferred_username
  - oidc-groups-claim=groups
```

Use the exact issuer value from Keycloak's discovery document:

```text
https://<keycloak-host>/realms/<realm>/.well-known/openid-configuration
```

Restart k3s:

```sh
sudo systemctl restart k3s
```

Check that k3s started cleanly:

```sh
sudo systemctl status k3s --no-pager
kubectl get nodes
```

Check that k3s passed the OIDC flags to the embedded API server:

```sh
kubectl get node k3s -o jsonpath='{.metadata.annotations.k3s\.io/node-args}'
sudo journalctl -u k3s -b --no-pager | grep oidc-username-claim
```

The issuer URL must be reachable from the k3s server and its HTTPS certificate
must be trusted by the server.

## Username Claim

This project uses `preferred_username` for Kubernetes usernames. That matches
Keycloak's normal username claim and avoids Kubernetes rejecting tokens when the
user's email address is not marked as verified.

If you prefer email addresses as Kubernetes usernames, use:

```yaml
  - oidc-username-claim=email
```

When using `email`, Keycloak tokens must include:

```json
{
  "email_verified": true
}
```

Otherwise the API server rejects Headlamp requests with:

```text
invalid bearer token, oidc: email not verified
```

Fix that either by marking the user's email as verified in Keycloak, or by using
`preferred_username` as shown above.

## RBAC

OIDC only authenticates the user. Kubernetes permissions still come from RBAC.
The manifests in this repo bind the Keycloak group `headlamp-viewers` to the
built-in `view` ClusterRole:

```sh
kubectl apply -f manifests/rbac-oidc-viewers.yaml
```

If your Keycloak group is different, edit
`manifests/rbac-oidc-viewers.yaml` before applying the manifests.
