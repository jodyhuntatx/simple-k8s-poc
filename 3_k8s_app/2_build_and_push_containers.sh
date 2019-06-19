#!/bin/bash
set -euo pipefail

source ../config/cluster.config
source ../config/kubernetes.config
source ../config/utils.sh

announce "Building and pushing test app images."

# Tag authenticator image with registry/namespace prefix & namespace tag
authenticator_image_tag="conjur-authn-k8s-client:$TEST_APP_NAMESPACE_NAME"
docker tag $AUTHENTICATOR_CLIENT_IMAGE $authenticator_image_tag
if ! $MINIKUBE; then
  docker push $authenticator_image_tag
fi

readonly APPS=(
  "init"
  "sidecar"
)

pushd webapp
    if $CONNECTED; then
      ./build.sh
    fi

    for app_type in "${APPS[@]}"; do
      test_app_image="test-$app_type-app:$TEST_APP_NAMESPACE_NAME"
      docker tag test-app:latest $test_app_image
      if ! $MINIKUBE; then
        docker push $test_app_image
      fi
    done
popd

