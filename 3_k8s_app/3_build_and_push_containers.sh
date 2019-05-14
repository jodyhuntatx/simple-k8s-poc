#!/bin/bash
set -euo pipefail

source ../config/cluster.config
source ../config/kubernetes.config
source ../config/utils.sh

announce "Building and pushing test app images."

readonly APPS=(
  "init"
  "sidecar"
)

pushd webapp
    ./build.sh

    for app_type in "${APPS[@]}"; do
      test_app_image=$(platform_image "test-$app_type-app")
      docker tag test-app:$CONJUR_NAMESPACE_NAME $test_app_image
      if ! is_minienv; then
        docker push $test_app_image
      fi
    done
popd

