#!/bin/bash
set -eo pipefail

source ../config/cluster.config
source ../config/$PLATFORM.config
source ../config/utils.sh

main() {
  announce "Deploying test apps for $TEST_APP_NAMESPACE_NAME."

  set_namespace $TEST_APP_NAMESPACE_NAME
  init_registry_creds
  init_connection_specs
  copy_conjur_config_map
  create_app_config_map

  IMAGE_PULL_POLICY='IfNotPresent'

  deploy_sidecar_app
  deploy_init_container_app
  sleep 15  # allow time for containers to initialize
}

###########################
init_registry_creds() {
  if ! [ "${DOCKER_EMAIL}" = "" ]; then
      announce "Creating image pull secret."
    
      kubectl delete --ignore-not-found secret dockerpullsecret

      kubectl create secret docker-registry dockerpullsecret \
        --docker-server=$DOCKER_REGISTRY_URL \
        --docker-username=$DOCKER_USERNAME \
        --docker-password=$DOCKER_PASSWORD \
        --docker-email=$DOCKER_EMAIL
  fi
}

###########################
init_connection_specs() {
  # Set authn URL to either Follower service in cluster or external Follower
  if $CONJUR_FOLLOWERS_IN_CLUSTER; then
    conjur_appliance_url=https://conjur-follower.$CONJUR_NAMESPACE_NAME.svc.cluster.local/api
  else
    conjur_appliance_url=https://$CONJUR_MASTER_HOST_NAME:$CONJUR_FOLLOWER_PORT
  fi

  conjur_authenticator_url=$conjur_appliance_url/authn-k8s/$AUTHENTICATOR_ID

  conjur_authn_login_prefix=host/conjur/authn-k8s/$AUTHENTICATOR_ID/apps/$TEST_APP_NAMESPACE_NAME/service_account
}

###########################
# create copy of conjur config map in the app namespace
copy_conjur_config_map() {
  $CLI delete --ignore-not-found cm $CONJUR_CONFIG_MAP
  $CLI get cm $CONJUR_CONFIG_MAP -n default -o yaml \
    | sed "s/namespace: default/namespace: $TEST_APP_NAMESPACE_NAME/" \
    | $CLI create -f -
}

###########################
# APP_CONFIG_MAP defines values for app authentication
create_app_config_map() {
  $CLI delete --ignore-not-found configmap $APP_CONFIG_MAP
  $CLI create configmap $APP_CONFIG_MAP \
        -n $TEST_APP_NAMESPACE_NAME \
        --from-literal=conjur-authn-url="$conjur_authenticator_url" \
        --from-literal=conjur-authn-login-init="$conjur_authn_login_prefix/oc-test-app-summon-init" \
        --from-literal=conjur-authn-login-sidecar="$conjur_authn_login_prefix/oc-test-app-summon-sidecar"
}

###########################
deploy_sidecar_app() {
  $CLI delete --ignore-not-found \
    deployment/test-app-summon-sidecar \
    service/test-app-summon-sidecar \
    serviceaccount/test-app-summon-sidecar \
    serviceaccount/oc-test-app-summon-sidecar

  sleep 5

  test_app_image=$(repo_image_tag test-app $TEST_APP_NAMESPACE_NAME) 
  authenticator_client_image=$(repo_image_tag conjur-authn-k8s-client $TEST_APP_NAMESPACE_NAME)

  sed -e "s#{{ TEST_APP_DOCKER_IMAGE }}#$test_app_image#g" ./$PLATFORM/test-app-summon-sidecar.yml |
    sed -e "s#{{ AUTHENTICATOR_CLIENT_IMAGE }}#$authenticator_client_image#g" |
    sed -e "s#{{ IMAGE_PULL_POLICY }}#$IMAGE_PULL_POLICY#g" |
    sed -e "s#{{ CONJUR_VERSION }}#$CONJUR_VERSION#g" |
    sed -e "s#{{ CONJUR_MASTER_HOST_NAME }}#$CONJUR_MASTER_HOST_NAME#g" |
    sed -e "s#{{ CONJUR_MASTER_HOST_IP }}#$CONJUR_MASTER_HOST_IP#g" |
    sed -e "s#{{ CONJUR_ACCOUNT }}#$CONJUR_ACCOUNT#g" |
    sed -e "s#{{ CONJUR_AUTHN_LOGIN_PREFIX }}#$conjur_authn_login_prefix#g" |
    sed -e "s#{{ CONJUR_APPLIANCE_URL }}#$conjur_appliance_url#g" |
    sed -e "s#{{ CONJUR_AUTHN_URL }}#$conjur_authenticator_url#g" |
    sed -e "s#{{ TEST_APP_NAMESPACE_NAME }}#$TEST_APP_NAMESPACE_NAME#g" |
    sed -e "s#{{ AUTHENTICATOR_ID }}#$AUTHENTICATOR_ID#g" |
    sed -e "s#{{ CONFIG_MAP_NAME }}#$CONJUR_CONFIG_MAP#g" |
    sed -e "s#{{ CONJUR_VERSION }}#'$CONJUR_VERSION'#g" |
    $CLI create -f -

  echo "Test app/sidecar deployed."
}

###########################
deploy_init_container_app() {
  $CLI delete --ignore-not-found \
    deployment/test-app-summon-init \
    service/test-app-summon-init \
    serviceaccount/test-app-summon-init \
    serviceaccount/oc-test-app-summon-init

  sleep 5

  test_app_image=$(repo_image_tag test-app $TEST_APP_NAMESPACE_NAME) 
  authenticator_client_image=$(repo_image_tag conjur-authn-k8s-client $TEST_APP_NAMESPACE_NAME)

  sed -e "s#{{ TEST_APP_DOCKER_IMAGE }}#$test_app_image#g" ./$PLATFORM/test-app-summon-init.yml |
    sed -e "s#{{ AUTHENTICATOR_CLIENT_IMAGE }}#$authenticator_client_image#g" |
    sed -e "s#{{ IMAGE_PULL_POLICY }}#$IMAGE_PULL_POLICY#g" |
    sed -e "s#{{ CONJUR_VERSION }}#$CONJUR_VERSION#g" |
    sed -e "s#{{ CONJUR_MASTER_HOST_NAME }}#$CONJUR_MASTER_HOST_NAME#g" |
    sed -e "s#{{ CONJUR_MASTER_HOST_IP }}#$CONJUR_MASTER_HOST_IP#g" |
    sed -e "s#{{ CONJUR_ACCOUNT }}#$CONJUR_ACCOUNT#g" |
    sed -e "s#{{ CONJUR_AUTHN_LOGIN_PREFIX }}#$conjur_authn_login_prefix#g" |
    sed -e "s#{{ CONJUR_APPLIANCE_URL }}#$conjur_appliance_url#g" |
    sed -e "s#{{ CONJUR_AUTHN_URL }}#$conjur_authenticator_url#g" |
    sed -e "s#{{ TEST_APP_NAMESPACE_NAME }}#$TEST_APP_NAMESPACE_NAME#g" |
    sed -e "s#{{ AUTHENTICATOR_ID }}#$AUTHENTICATOR_ID#g" |
    sed -e "s#{{ CONFIG_MAP_NAME }}#$CONJUR_CONFIG_MAP#g" |
    sed -e "s#{{ CONJUR_VERSION }}#'$CONJUR_VERSION'#g" |
    $CLI create -f -

  echo "Test app/init-container deployed."
}

main $@
