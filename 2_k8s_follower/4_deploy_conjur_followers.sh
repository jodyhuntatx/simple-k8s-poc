#!/bin/bash 
set -eo pipefail

source ../config/cluster.config
source ../config/kubernetes.config
source ../config/utils.sh

main() {
  set_namespace $CONJUR_NAMESPACE_NAME

  docker_login

  copy_conjur_config_map
  deploy_conjur_followers
  re_create_conjur_config_map

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

###########################
# Get copy of conjur configmap from default namespace
copy_conjur_config_map() {
  $CLI delete --ignore-not-found cm $CONJUR_CONFIG_MAP
  $CLI get cm $CONJUR_CONFIG_MAP -n default -o yaml \
    | sed "s/namespace: default/namespace: $CONJUR_NAMESPACE_NAME/" \
    | $CLI create -f -
}

###########################
deploy_conjur_followers() {
  announce "Deploying Conjur Follower pods."

  conjur_appliance_image=$(repo_image_tag "conjur-appliance" "$CONJUR_NAMESPACE_NAME")
  seed_fetcher_image=$(repo_image_tag "seed-fetcher" "$CONJUR_NAMESPACE_NAME") 

  sed -e "s#{{ CONJUR_APPLIANCE_IMAGE }}#$conjur_appliance_image#g" "./$PLATFORM/conjur-follower.yaml" |
    sed -e "s#{{ AUTHENTICATOR_ID }}#$AUTHENTICATOR_ID#g" |
    sed -e "s#{{ IMAGE_PULL_POLICY }}#$IMAGE_PULL_POLICY#g" |
    sed -e "s#{{ CONJUR_MASTER_HOST_NAME }}#$CONJUR_MASTER_HOST_NAME#g" |
    sed -e "s#{{ CONJUR_MASTER_HOST_IP }}#$CONJUR_MASTER_HOST_IP#g" |
    sed -e "s#{{ CONJUR_MASTER_PORT }}#$CONJUR_MASTER_PORT#g" |
    sed -e "s#{{ CONJUR_SEED_FETCHER_IMAGE }}#$seed_fetcher_image#g" |
    sed -e "s#{{ CONJUR_CONFIG_MAP }}#$CONJUR_CONFIG_MAP#g" |
    sed -e "s#{{ CONJUR_FOLLOWER_COUNT }}#${CONJUR_FOLLOWER_COUNT}#g" |
    $CLI create -f -
}

###################################
# Adds follower url & cert to Conjur config map
#
re_create_conjur_config_map() {
  echo "Re-creating Conjur config map w/ Follower URL & cert."
  $CLI delete --ignore-not-found=true -n default configmap $CONJUR_CONFIG_MAP

  # Get master cert from file
  master_url="https://$CONJUR_MASTER_HOST_NAME:$CONJUR_MASTER_PORT"
  master_cert=$(cat "$MASTER_CERT_FILE")
  conjur_seed_file_url=$master_url/configuration/$CONJUR_ACCOUNT/seed/follower

  # Wait for Follower to initialize
  follower_url="https://$CONJUR_FOLLOWER_SERVICE_NAME"
  follower_pod_name=$($CLI get pods | grep conjur-follower | tail -1 | awk '{print $1}')
  echo "Waiting until Follower is ready (about 40 secs)."
  while [[ 'True' != $(kubectl get po "$follower_pod_name" -o 'jsonpath={.status.conditions[?(@.type=="Ready")].status}') ]]; do
    echo -n "."; sleep 3
  done
  echo ""

  # cat Follower cert to cert file
  follower_cert="$($CLI exec $follower_pod_name -- cat /opt/conjur/etc/ssl/conjur.pem)"
  echo "$follower_cert" > $FOLLOWER_CERT_FILE

  $CLI create configmap $CONJUR_CONFIG_MAP \
	-n default \
	--from-literal=follower-namespace-name="$FOLLOWER_NAMESPACE_NAME" \
        --from-literal=conjur-master-url=$master_url 			\
	--from-literal=master-certificate="$master_cert" 		\
        --from-literal=conjur-seed-file-url="$conjur_seed_file_url" 	\
        --from-literal=conjur-follower-url=$follower_url 		\
	--from-literal=follower-certificate="$follower_cert" 		\
        --from-literal=conjur-authn-login-cluster="$CONJUR_CLUSTER_LOGIN" \
        --from-literal=conjur-account="$CONJUR_ACCOUNT" 		\
        --from-literal=conjur-version="$CONJUR_VERSION" 		\
        --from-literal=conjur-authenticators="$CONJUR_AUTHENTICATORS" 	\
        --from-literal=authenticator-id="$AUTHENTICATOR_ID" 		\
        --from-literal=conjur-authn-token-file="/run/conjur/access-token"

  echo "Conjur config map recreated."
}

main $@
