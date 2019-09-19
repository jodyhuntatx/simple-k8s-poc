#!/bin/bash
set -euo pipefail

source ../config/cluster.config
source ../config/kubernetes.config
source ../config/utils.sh

announce "Building and pushing test app images."

# Tag authenticator image with registry/namespace prefix & namespace tag
authenticator_image_tag=$(repo_image_tag conjur-authn-k8s-client $TEST_APP_NAMESPACE_NAME)
docker tag $AUTHENTICATOR_CLIENT_IMAGE $authenticator_image_tag
docker push $authenticator_image_tag

pushd webapp
    if $CONNECTED; then
      ./build.sh
    fi

    test_app_image_tag=$(repo_image_tag test-app $TEST_APP_NAMESPACE_NAME) 
    docker tag test-app:latest $test_app_image_tag
    docker push $test_app_image_tag
popd

