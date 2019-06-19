#!/bin/bash 
set -euo pipefail

source ../config/cluster.config
source ../config/kubernetes.config
source ../config/utils.sh

announce "Creating Test App namespace."

set_namespace default

if has_namespace "$TEST_APP_NAMESPACE_NAME"; then
  echo "Namespace '$TEST_APP_NAMESPACE_NAME' exists, not going to create it."
  set_namespace $TEST_APP_NAMESPACE_NAME
else
  echo "Creating '$TEST_APP_NAMESPACE_NAME' namespace."

  $CLI create namespace $TEST_APP_NAMESPACE_NAME
  
  set_namespace $TEST_APP_NAMESPACE_NAME
fi

$CLI delete --ignore-not-found rolebinding test-app-conjur-authenticator-role-binding-$CONJUR_NAMESPACE_NAME

sed -e "s#{{ TEST_APP_NAMESPACE_NAME }}#$TEST_APP_NAMESPACE_NAME#g" ./$PLATFORM/test-app-conjur-authenticator-role-binding.yml |
  sed -e "s#{{ CONJUR_NAMESPACE_NAME }}#$CONJUR_NAMESPACE_NAME#g" |
  $CLI create -f -
