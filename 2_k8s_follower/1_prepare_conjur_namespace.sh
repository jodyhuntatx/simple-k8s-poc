#!/bin/bash
set -euo pipefail

source ../config/cluster.config
source ../config/kubernetes.config
source ../config/utils.sh

main() {
  set_namespace default

  create_conjur_namespace
  create_service_account
  create_cluster_role
}

create_conjur_namespace() {
  announce "Creating Conjur namespace."
  
  if has_namespace "$CONJUR_NAMESPACE_NAME"; then
    echo "Namespace '$CONJUR_NAMESPACE_NAME' exists, not going to create it."
    set_namespace $CONJUR_NAMESPACE_NAME
  else
    echo "Creating '$CONJUR_NAMESPACE_NAME' namespace."
    
    kubectl create namespace $CONJUR_NAMESPACE_NAME
    
    set_namespace $CONJUR_NAMESPACE_NAME
  fi
}

create_service_account() {
    if has_serviceaccount $CONJUR_SERVICEACCOUNT_NAME; then
        echo "Service account '$CONJUR_SERVICEACCOUNT_NAME' exists, not going to create it."
    else
        $cli create serviceaccount $CONJUR_SERVICEACCOUNT_NAME -n $CONJUR_NAMESPACE_NAME
    fi
}

create_cluster_role() {
  $cli delete --ignore-not-found clusterrole conjur-authenticator-$CONJUR_NAMESPACE_NAME

  sed -e "s#{{ CONJUR_NAMESPACE_NAME }}#$CONJUR_NAMESPACE_NAME#g" ./$PLATFORM/conjur-authenticator-role.yaml |
    $cli apply -f -
}

main $@
