#!/usr/bin/env bash
set -euo pipefail

source_namespace="keycloak"
source_secret="keycloak-tls"
target_namespace="kube-system"
target_configmap="headlamp-oidc-ca"
target_key="ca.crt"

usage() {
  cat <<'USAGE'
Usage: scripts/sync-keycloak-oidc-ca.sh [options]

Copy Keycloak's public TLS certificate chain into the namespace where Headlamp
runs, so Headlamp can use it with -oidc-ca-file.

Options:
  --source-namespace NAME     Namespace containing Keycloak TLS Secret (default: keycloak)
  --source-secret NAME        Keycloak TLS Secret name (default: keycloak-tls)
  --target-namespace NAME     Headlamp namespace (default: kube-system)
  --target-configmap NAME     ConfigMap to create/update (default: headlamp-oidc-ca)
  -h, --help                  Show this help

Example:
  scripts/sync-keycloak-oidc-ca.sh
USAGE
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_value() {
  [[ $# -ge 2 ]] || fail "$1 requires a value"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-namespace)
      require_value "$@"
      source_namespace="$2"
      shift 2
      ;;
    --source-secret)
      require_value "$@"
      source_secret="$2"
      shift 2
      ;;
    --target-namespace)
      require_value "$@"
      target_namespace="$2"
      shift 2
      ;;
    --target-configmap)
      require_value "$@"
      target_configmap="$2"
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
command -v base64 >/dev/null 2>&1 || fail "base64 is not installed or not on PATH"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

kubectl -n "$source_namespace" get secret "$source_secret" \
  -o jsonpath='{.data.tls\.crt}' | base64 -d > "${tmp_dir}/${target_key}"

[[ -s "${tmp_dir}/${target_key}" ]] || fail "source Secret ${source_namespace}/${source_secret} did not contain tls.crt"

kubectl -n "$target_namespace" create configmap "$target_configmap" \
  --from-file="${target_key}=${tmp_dir}/${target_key}" \
  --dry-run=client -o yaml | kubectl apply -f -

printf 'Synced %s/%s tls.crt to ConfigMap %s/%s key %s.\n' \
  "$source_namespace" "$source_secret" "$target_namespace" "$target_configmap" "$target_key"
