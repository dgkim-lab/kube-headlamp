#!/usr/bin/env bash
set -euo pipefail

namespace="kube-system"
service_account="headlamp-viewer"
duration="1h"
copy_token="false"

usage() {
  cat <<'USAGE'
Usage: scripts/get-token.sh [options]

Create a Kubernetes authentication token for Headlamp login.

Options:
  -n, --namespace NAME         Kubernetes namespace (default: kube-system)
  -s, --service-account NAME   ServiceAccount name (default: headlamp-viewer)
  -d, --duration DURATION      Token lifetime, such as 10m, 1h, or 24h (default: 1h)
  -c, --copy                   Copy token to clipboard when pbcopy, wl-copy, or xclip exists
  -h, --help                   Show this help

Examples:
  scripts/get-token.sh
  scripts/get-token.sh --duration 24h --copy
USAGE
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

copy_to_clipboard() {
  local token="$1"

  if command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "$token" | pbcopy
  elif command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$token" | wl-copy
  elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "$token" | xclip -selection clipboard
  else
    fail "--copy was requested, but pbcopy, wl-copy, and xclip are unavailable"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--namespace)
      [[ $# -ge 2 ]] || fail "$1 requires a value"
      namespace="$2"
      shift 2
      ;;
    -s|--service-account)
      [[ $# -ge 2 ]] || fail "$1 requires a value"
      service_account="$2"
      shift 2
      ;;
    -d|--duration)
      [[ $# -ge 2 ]] || fail "$1 requires a value"
      duration="$2"
      shift 2
      ;;
    -c|--copy)
      copy_token="true"
      shift
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

token="$(kubectl -n "$namespace" create token "$service_account" --duration="$duration")"

if [[ "$copy_token" == "true" ]]; then
  copy_to_clipboard "$token"
  printf 'Token copied to clipboard for ServiceAccount %s/%s. Expires in %s.\n' \
    "$namespace" "$service_account" "$duration" >&2
else
  printf '%s\n' "$token"
fi
