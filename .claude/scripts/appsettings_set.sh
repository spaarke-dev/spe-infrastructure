#!/usr/bin/env bash
set -euo pipefail
APP=""; RG=""; TENANT=""; APIID=""; KVURI=""; CORS=""
while getopts "n:g:t:a:k:o:h" opt; do
  case "$opt" in
    n) APP="$OPTARG" ;; g) RG="$OPTARG" ;; t) TENANT="$OPTARG" ;; a) APIID="$OPTARG" ;; k) KVURI="$OPTARG" ;; o) CORS="$OPTARG" ;; h) echo "usage: $0 -n <app> -g <rg> -t <tenant> -a <api> -k <kvuri> -o <cors>"; exit 0 ;;
  esac
done
[ -z "$APP" ] && echo "missing -n" && exit 1
[ -z "$RG" ] && echo "missing -g" && exit 1
[ -z "$TENANT" ] && echo "missing -t" && exit 1
[ -z "$APIID" ] && echo "missing -a" && exit 1
[ -z "$KVURI" ] && echo "missing -k" && exit 1
[ -z "$CORS" ] && echo "missing -o" && exit 1
az webapp config appsettings set -g "$RG" -n "$APP" --settings   AzureAd__TenantId="$TENANT"   AzureAd__ClientId="$APIID"   AzureAd__ClientSecret="@Microsoft.KeyVault(SecretUri=$KVURI)"   Cors__AllowedOrigins="$CORS"
echo "App settings updated on $APP"
