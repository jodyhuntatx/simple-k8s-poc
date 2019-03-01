#!/bin/bash 
set -euo pipefail

source ../config/demo.config
source ../config/kubernetes.config
source ../config/utils.sh

clear
announce "Retrieving secrets with access token."

set_namespace $TEST_APP_NAMESPACE_NAME

  sidecar_api_pod=$($cli get pods --no-headers -l app=test-app-summon-sidecar | awk '{ print $1 }')
  if [[ "$sidecar_api_pod" != "" ]]; then
    echo "Sidecar + REST API: $($cli exec -c test-app $sidecar_api_pod -- /webapp.sh)"
    echo "Sidecar + Summon:"
    echo "$($cli exec -c test-app $sidecar_api_pod -- summon /webapp_summon.sh)"
  fi

  init_api_pod=$($cli get pods --no-headers -l app=test-app-summon-init | awk '{ print $1 }')
  if [[ "$init_api_pod" != "" ]]; then
    echo
    echo "Init Container + REST API: $($cli exec -c test-app $init_api_pod -- /webapp.sh)"
    echo "Init Container + Summon:"
    echo "$($cli exec -c test-app $init_api_pod -- summon /webapp_summon.sh)"
  fi

