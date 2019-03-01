#!/bin/bash
set -eo pipefail

source ../config/demo.config
source ../config/kubernetes.config
source ../config/utils.sh

check_env_var "CONJUR_APPLIANCE_IMAGE"
check_env_var "CONJUR_NAMESPACE_NAME"
check_env_var "AUTHENTICATOR_ID"

if [ "${PLATFORM}" = "kubernetes" ] && [ ! is_minienv ]; then
  check_env_var "DOCKER_REGISTRY_URL"
fi

# check if CONJUR_VERSION is consistent with CONJUR_APPLIANCE_IMAGE
appliance_tag=${CONJUR_APPLIANCE_IMAGE//[A-Za-z.]*:/}
appliance_version=${appliance_tag//[.-][0-9A-Za-z.-]*/}
if [ "${appliance_version}" != "$CONJUR_VERSION" ]; then
  echo "ERROR! Your appliance does not match the specified Conjur version."
  exit 1
fi

if [[ "${DEPLOY_MASTER_CLUSTER}" = "true" ]]; then
  check_env_var "CONJUR_VERSION"
  check_env_var "CONJUR_ACCOUNT"
  check_env_var "CONJUR_ADMIN_PASSWORD"
fi
