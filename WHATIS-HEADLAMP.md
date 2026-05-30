# What Is Headlamp?

Headlamp is a graphical user interface for Kubernetes. It gives you a browser
view of cluster resources such as namespaces, nodes, pods, deployments,
services, ingresses, config maps, events, and RBAC-related objects.

In this project, Headlamp is deployed inside the local k3s cluster and exposed
through the existing Traefik ingress controller. That lets you open a web page
instead of inspecting everything only through `kubectl`.

Headlamp still uses Kubernetes authentication and authorization. The manifests
in this repository create a `headlamp-viewer` service account with the built-in
`view` ClusterRole, so the default login token is intended for read-only
inspection.

Use Headlamp when you want to:

- Browse live Kubernetes resources across namespaces.
- Inspect workload status, events, services, and ingress routing.
- Understand what is running in the cluster without memorizing every
  `kubectl get` command.
- Share a visual cluster view while keeping permissions controlled by
  Kubernetes RBAC.

Headlamp does not replace GitOps, manifests, or `kubectl`. It is a visual layer
on top of the Kubernetes API.
