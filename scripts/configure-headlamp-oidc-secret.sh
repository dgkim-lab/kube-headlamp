#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
env_file="${HEADLAMP_OIDC_ENV_FILE:-${script_dir}/keycloak.env.sh}"

if [[ -f "$env_file" ]]; then
  # shellcheck source=/dev/null
  source "$env_file"
fi

namespace="${HEADLAMP_OIDC_NAMESPACE:-kube-system}"
secret_name="${HEADLAMP_OIDC_SECRET_NAME:-headlamp-oidc}"
client_id="${HEADLAMP_OIDC_CLIENT_ID:-headlamp}"
client_secret="${HEADLAMP_OIDC_CLIENT_SECRET:-}"
issuer_url="${HEADLAMP_OIDC_ISSUER_URL:-}"
scopes="${HEADLAMP_OIDC_SCOPES:-openid,email,profile,offline_access}"

usage() {
  cat <<'USAGE'
Usage: scripts/configure-headlamp-oidc-secret.sh [options]

Create or update the Kubernetes Secret consumed by Headlamp for OIDC login.

Options:
  --env-file PATH           Source env file before parsing options (default: scripts/keycloak.env.sh)
  -n, --namespace NAME       Kubernetes namespace (default: kube-system)
  --secret-name NAME         Secret name (default: headlamp-oidc)
  --client-id NAME           OIDC client ID (default: headlamp or HEADLAMP_OIDC_CLIENT_ID)
  --client-secret VALUE      OIDC client secret, or set HEADLAMP_OIDC_CLIENT_SECRET
  --issuer-url URL           OIDC issuer URL, or set HEADLAMP_OIDC_ISSUER_URL
  --scopes VALUE             OIDC scopes (default: openid,email,profile,offline_access)
  -h, --help                 Show this help

Example:
  cp scripts/keycloak.env.example.sh scripts/keycloak.env.sh
  vi scripts/keycloak.env.sh
  source scripts/keycloak.env.sh

  scripts/configure-headlamp-oidc-secret.sh
USAGE
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_value() {
  [[ $# -ge 2 ]] || fail "$1 requires a value"
}

strip_trailing_slash() {
  local value="$1"
  printf '%s\n' "${value%/}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env-file)
      require_value "$@"
      env_file="$2"
      [[ -f "$env_file" ]] || fail "env file does not exist: $env_file"
      # shellcheck source=/dev/null
      source "$env_file"
      namespace="${HEADLAMP_OIDC_NAMESPACE:-$namespace}"
      secret_name="${HEADLAMP_OIDC_SECRET_NAME:-$secret_name}"
      client_id="${HEADLAMP_OIDC_CLIENT_ID:-$client_id}"
      client_secret="${HEADLAMP_OIDC_CLIENT_SECRET:-$client_secret}"
      issuer_url="${HEADLAMP_OIDC_ISSUER_URL:-$issuer_url}"
      scopes="${HEADLAMP_OIDC_SCOPES:-$scopes}"
      shift 2
      ;;
    -n|--namespace)
      require_value "$@"
      namespace="$2"
      shift 2
      ;;
    --secret-name)
      require_value "$@"
      secret_name="$2"
      shift 2
      ;;
    --client-id)
      require_value "$@"
      client_id="$2"
      shift 2
      ;;
    --client-secret)
      require_value "$@"
      client_secret="$2"
      shift 2
      ;;
    --issuer-url)
      require_value "$@"
      issuer_url="$(strip_trailing_slash "$2")"
      shift 2
      ;;
    --scopes)
      require_value "$@"
      scopes="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown option: $1"
      ;;
  esac
done

command -v kubectl >/dev/null 2>&1 || fail "kubectl is not installed or not on PATH"
[[ -n "$client_id" ]] || fail "--client-id is required"
[[ -n "$client_secret" ]] || fail "--client-secret or HEADLAMP_OIDC_CLIENT_SECRET is required"
[[ -n "$issuer_url" ]] || fail "--issuer-url or HEADLAMP_OIDC_ISSUER_URL is required"

kubectl -n "$namespace" create secret generic "$secret_name" \
  --from-literal=client-id="$client_id" \
  --from-literal=client-secret="$client_secret" \
  --from-literal=issuer-url="$issuer_url" \
  --from-literal=scopes="$scopes" \
  --dry-run=client -o yaml | kubectl apply -f -

printf 'Configured Secret %s/%s for Headlamp OIDC login.\n' "$namespace" "$secret_name"
