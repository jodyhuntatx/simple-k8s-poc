#!/bin/bash 
set -euo pipefail

source ../config/cluster.config
source ../config/kubernetes.config
source ../config/utils.sh

main() {
  prepare_conjur_appliance_image

  echo "Docker images pushed."
}

prepare_conjur_appliance_image() {
  announce "Tagging and pushing Conjur appliance"

  conjur_appliance_image=$(repo_image_tag $CONJUR_NAMESPACE_NAME conjur-appliance)

  docker tag $CONJUR_APPLIANCE_IMAGE $conjur_appliance_image

  if ! $MINIKUBE; then
    docker push $conjur_appliance_image
  fi
}

main $@
