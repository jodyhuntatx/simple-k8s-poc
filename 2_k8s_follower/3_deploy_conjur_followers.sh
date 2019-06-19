#!/bin/bash 
set -eo pipefail

source ../config/cluster.config
source ../config/kubernetes.config
source ../config/utils.sh

main() {
  set_namespace $CONJUR_NAMESPACE_NAME

  docker_login

  deploy_conjur_followers

  sleep 10

  echo "Followers created."
}

docker_login() {
  if ! [ "${DOCKER_EMAIL}" = "" ]; then
      announce "Creating image pull secret."

      $CLI delete --ignore-not-found secret dockerpullsecret

      $CLI create secret docker-registry dockerpullsecret \
           --docker-server=$DOCKER_REGISTRY_URL \
           --docker-username=$DOCKER_USERNAME \
           --docker-password=$DOCKER_PASSWORD \
           --docker-email=$DOCKER_EMAIL
  fi
}

deploy_conjur_followers() {
  announce "Deploying Conjur Follower pods."

  conjur_appliance_image=$(repo_image_tag $CONJUR_NAMESPACE_NAME conjur-appliance)

  sed -e "s#{{ CONJUR_APPLIANCE_IMAGE }}#$conjur_appliance_image#g" "./$PLATFORM/conjur-follower.yaml" |
    sed -e "s#{{ AUTHENTICATOR_ID }}#$AUTHENTICATOR_ID#g" |
    sed -e "s#{{ IMAGE_PULL_POLICY }}#$IMAGE_PULL_POLICY#g" |
    sed -e "s#{{ CONJUR_FOLLOWER_COUNT }}#${CONJUR_FOLLOWER_COUNT}#g" |
    $CLI create -f -
}

main $@
