#!/usr/bin/env bash
set -euo pipefail
KV=""; NAME=""; TENANT=""; CLIENTID=""
while getopts "v:n:t:c:h" opt; do
  case "$opt" in
    v) KV="$OPTARG" ;; n) NAME="$OPTARG" ;; t) TENANT="$OPTARG" ;; c) CLIENTID="$OPTARG" ;; h) echo "usage: $0 -v <kv> -n <name> -t <tenant> -c <clientId>"; exit 0 ;;
  esac
done
[ -z "$KV" ] && echo "missing -v" && exit 1
[ -z "$NAME" ] && echo "missing -n" && exit 1
[ -z "$TENANT" ] && echo "missing -t" && exit 1
[ -z "$CLIENTID" ] && echo "missing -c" && exit 1
read -s -p "Enter secret value: " SECRET; echo
az keyvault secret set --vault-name "$KV" --name "$NAME" --value "$SECRET" >/dev/null
echo "Secret $NAME set in Key Vault $KV"
