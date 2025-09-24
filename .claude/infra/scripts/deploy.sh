#!/usr/bin/env bash
set -euo pipefail
usage(){ cat <<EOF
Usage: $0 -g <resourceGroup> -l <location> -p <paramsFile> [-s <subscriptionId>]
Runs WHAT-IF by default. Set APPLY=1 to deploy.
EOF
}
RG=""; LOC=""; PAR=""; SUB="${SUBSCRIPTION_ID:-}"
while getopts "g:l:p:s:h" opt; do
  case "$opt" in
    g) RG="$OPTARG" ;; l) LOC="$OPTARG" ;; p) PAR="$OPTARG" ;; s) SUB="$OPTARG" ;; h) usage; exit 0 ;;
  esac
done
[ -z "$RG" ] && usage && exit 1
[ -z "$LOC" ] && usage && exit 1
[ -z "$PAR" ] && usage && exit 1
command -v az >/dev/null || { echo "Azure CLI required"; exit 1; }
[ -n "$SUB" ] && az account set --subscription "$SUB"
az group create -n "$RG" -l "$LOC" >/dev/null
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BICEP="$ROOT_DIR/bicep/main.bicep"
if [ "${APPLY:-0}" -eq 1 ]; then
  echo ">>> DEPLOYING (APPLY=1)"
  az deployment group create -g "$RG" -f "$BICEP" -p @"$PAR"
else
  echo ">>> WHAT-IF (no changes applied)"
  az deployment group what-if -g "$RG" -f "$BICEP" -p @"$PAR" --no-pretty-print
fi
