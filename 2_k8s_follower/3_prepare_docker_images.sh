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
  announce "Building and pushing seed-fetcher image."

  if $CONNECTED; then
    pushd build/seed-fetcher
      ./build.sh
    popd
  fi

  seed_fetcher_image=$(repo_image_tag $CONJUR_NAMESPACE_NAME seed-fetcher)
  docker tag seed-fetcher:latest $seed_fetcher_image

  docker push $seed_fetcher_image
}

main $@
