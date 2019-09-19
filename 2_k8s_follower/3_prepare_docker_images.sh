#!/bin/bash 
set -euo pipefail

source ../config/cluster.config
source ../config/kubernetes.config
source ../config/utils.sh

main() {
  prepare_conjur_appliance_image
  prepare_seed_fetcher_image

  echo "Docker images pushed."
}

prepare_conjur_appliance_image() {
  announce "Tagging and pushing Conjur appliance"

  conjur_appliance_image=$(repo_image_tag conjur-appliance $CONJUR_NAMESPACE_NAME)

  docker tag $CONJUR_APPLIANCE_IMAGE $conjur_appliance_image

  docker push $conjur_appliance_image
}

prepare_seed_fetcher_image() {
  if $CONNECTED; then
    announce "Building and pushing seed-fetcher image."
    pushd build/seed-fetcher
      ./build.sh
    popd
  fi

  seed_fetcher_image_tag=$(repo_image_tag seed-fetcher $CONJUR_NAMESPACE_NAME)
  docker tag $SEED_FETCHER_IMAGE $seed_fetcher_image_tag

  docker push $seed_fetcher_image_tag
}

main $@
