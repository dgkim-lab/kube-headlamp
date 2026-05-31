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
  - oidc-username-claim=email
  - oidc-groups-claim=groups
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

The issuer URL must be reachable from the k3s server and its HTTPS certificate
must be trusted by the server.
