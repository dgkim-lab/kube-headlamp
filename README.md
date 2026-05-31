# kube-headlamp

Kubernetes manifests for running Headlamp in the local k3s cluster.

## Learn

- [What is Headlamp?](WHATIS-HEADLAMP.md)
- [Official Headlamp homepage](https://headlamp.dev/)
- [Creating the Headlamp Client in Keycloak](KEYCLOAK-CLIENT.md)
- [Configuring k3s for Keycloak OIDC](K3S-OIDC.md)

Headlamp is exposed on the LAN through the k3s Traefik ingress controller:

```text
https://headlamp.k3s.dgkim.net
```

## Deploy

Apply the manifests with Kustomize support built into `kubectl`:

```sh
kubectl apply -k manifests
```

Verify the deployment:

```sh
kubectl -n kube-system get deploy,svc,ingress headlamp
kubectl -n kube-system get serviceaccount headlamp-viewer
```

## Login

Create a short-lived read-only token:

```sh
scripts/get-token.sh
```

Open the Headlamp URL and paste the token when prompted.

The `headlamp-viewer` service account is bound to the built-in Kubernetes
`view` ClusterRole, so it can inspect common cluster resources but cannot
modify them.

To create a token with a different lifetime or copy it to the clipboard:

```sh
scripts/get-token.sh --duration 24h --copy
```

## Keycloak OIDC Login

Headlamp is also configured to read OIDC settings from a `headlamp-oidc`
Secret. See [Creating the Headlamp Client in Keycloak](KEYCLOAK-CLIENT.md) for
the Keycloak-side client, mapper, and group settings. See
[Configuring k3s for Keycloak OIDC](K3S-OIDC.md) for the k3s API server
settings.

Create the Headlamp OIDC Secret:

```sh
kubectl -n kube-system create secret generic headlamp-oidc \
  --from-literal=client-id=headlamp \
  --from-literal=client-secret='<keycloak-client-secret>' \
  --from-literal=issuer-url='https://<keycloak-host>/realms/<realm>' \
  --from-literal=scopes='openid,email,profile,offline_access'
```

Or create/update only the Kubernetes Secret with the one-time setup script:

```sh
cp scripts/keycloak.env.example.sh scripts/keycloak.env.sh
vi scripts/keycloak.env.sh
source scripts/keycloak.env.sh

scripts/configure-headlamp-oidc-secret.sh
```

Sync Keycloak's public TLS certificate chain into the Headlamp namespace:

```sh
scripts/sync-keycloak-oidc-ca.sh
```

Apply or restart Headlamp after creating the secret:

```sh
kubectl apply -k manifests
kubectl -n kube-system rollout restart deploy/headlamp
```

The main ingress uses HTTPS only on Traefik's `websecure` entrypoint.
cert-manager creates the `kube-system/headlamp-tls` Secret with the
`letsencrypt-route53-prod` ClusterIssuer. A separate HTTP ingress only redirects
requests to HTTPS.

The manifests bind the Keycloak group `headlamp-viewers` to the Kubernetes
`view` ClusterRole. Put users who should have read-only Headlamp access in that
Keycloak group, or edit `manifests/rbac-oidc-viewers.yaml` to match the group or
user claim you want to authorize.

## Local Port Forward

If ingress or DNS is unavailable, use a local port forward:

```sh
kubectl -n kube-system port-forward service/headlamp 8080:80
```

Then open:

```text
http://localhost:8080
```

## Remove

```sh
kubectl delete -k manifests
```
