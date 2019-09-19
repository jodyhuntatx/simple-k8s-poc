#!/bin/bash
set -eo pipefail

source ../config/cluster.config
source ../config/kubernetes.config
source ../config/utils.sh

check_env_var "CONJUR_APPLIANCE_IMAGE"
check_env_var "CONJUR_NAMESPACE_NAME"
check_env_var "AUTHENTICATOR_ID"

if [ "${PLATFORM}" = "kubernetes" ] && [ ! $MINIKUBE ]; then
  check_env_var "DOCKER_REGISTRY_URL"
fi

if [[ "${DEPLOY_MASTER_CLUSTER}" = "true" ]]; then
  check_env_var "CONJUR_VERSION"
  check_env_var "CONJUR_ACCOUNT"
  check_env_var "CONJUR_ADMIN_PASSWORD"
fi
