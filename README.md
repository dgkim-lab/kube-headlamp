# kube-headlamp

Kubernetes manifests for running Headlamp in the local k3s cluster.

## Learn

- [What is Headlamp?](WHATIS-HEADLAMP.md)
- [Official Headlamp homepage](https://headlamp.dev/)

Headlamp is exposed on the LAN through the k3s Traefik ingress controller:

```text
http://headlamp.k3s.dgkim.net
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
