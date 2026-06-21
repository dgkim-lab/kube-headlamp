# Copy this file to keycloak.env.sh and edit the values for your Keycloak realm.
# keycloak.env.sh is sourced by scripts/configure-headlamp-oidc-secret.sh.

export HEADLAMP_OIDC_NAMESPACE="kube-system"
export HEADLAMP_OIDC_SECRET_NAME="headlamp-oidc"
export HEADLAMP_OIDC_CLIENT_ID="headlamp"
export HEADLAMP_OIDC_CLIENT_SECRET="replace-with-keycloak-client-secret"
export HEADLAMP_OIDC_ISSUER_URL="https://keycloak.example.com/realms/kubernetes"
export HEADLAMP_OIDC_SCOPES="openid,email,profile,offline_access"
