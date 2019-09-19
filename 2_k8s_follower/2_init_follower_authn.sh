#!/bin/bash

source ../config/cluster.config
source ../config/$PLATFORM.config
source ../config/utils.sh

# This script requires running w/ cluster admin privileges

#################
main() {
  announce "Initializing Follower authentication."

  initialize_conjur_config_map
  apply_manifest
  initialize_variables
}

###################################
initialize_conjur_config_map() {
  echo "Creating Conjur config map." 

  $CLI delete --ignore-not-found=true -n default configmap $CONJUR_CONFIG_MAP

  # Set Conjur Master URL to docker host & port
  master_url="https://$CONJUR_MASTER_HOST_NAME:$CONJUR_MASTER_PORT"
  # master_cert=$(./get_cert_REST.sh $CONJUR_MASTER_HOST_NAME $CONJUR_MASTER_PORT)
  master_cert=$(cat "$MASTER_CERT_FILE")

  conjur_seed_file_url=$master_url/configuration/$CONJUR_ACCOUNT/seed/follower

  $CLI create configmap $CONJUR_CONFIG_MAP \
	-n default \
       --from-literal=follower-namespace-name="$CONJUR_NAMESPACE_NAME" \
        --from-literal=conjur-master-url=$master_url                    \
        --from-literal=master-certificate="$master_cert"                \
        --from-literal=conjur-seed-file-url="$conjur_seed_file_url"     \
        --from-literal=conjur-authn-login-cluster="$CONJUR_CLUSTER_LOGIN" \
        --from-literal=conjur-account="$CONJUR_ACCOUNT"                 \
        --from-literal=conjur-version="$CONJUR_VERSION"                 \
        --from-literal=conjur-authenticators="$CONJUR_AUTHENTICATORS"   \
        --from-literal=authenticator-id="$AUTHENTICATOR_ID"             \
        --from-literal=conjur-authn-token-file="/run/conjur/access-token"

  echo "Conjur config map created."
}

###################################
apply_manifest() {
  echo "Applying manifest in cluster..."

  sed -e "s#{{ CONJUR_NAMESPACE_NAME }}#$CONJUR_NAMESPACE_NAME#g" \
     ./$PLATFORM/templates/conjur-follower-authn.template.yaml  \
     > ./$PLATFORM/conjur-follower-authn-$CONJUR_NAMESPACE_NAME.yaml

  $CLI apply -f ./$PLATFORM/conjur-follower-authn-$CONJUR_NAMESPACE_NAME.yaml

  echo "Manifest applied."
}

###################################
initialize_variables() {
  echo "Initializing variables..."

  # Use a cap-D for decoding on Macs
  if [[ "$(uname -s)" == "Linux" ]]; then
    BASE64D="base64 -d"
  else
    BASE64D="base64 -D"
  fi

  TOKEN_SECRET_NAME="$($CLI get secrets -n $CONJUR_NAMESPACE_NAME \
    | grep 'conjur.*service-account-token' \
    | head -n1 \
    | awk '{print $1}')"

  echo "Initializing cluster ca cert..."
  ./var_value_add_REST.sh \
    conjur/authn-k8s/$AUTHENTICATOR_ID/kubernetes/ca-cert \
    "$($CLI get secret -n $CONJUR_NAMESPACE_NAME $TOKEN_SECRET_NAME -o json \
      | jq -r '.data["ca.crt"]' \
      | $BASE64D)"

  echo "Initializing service-account token..."
  ./var_value_add_REST.sh \
    conjur/authn-k8s/$AUTHENTICATOR_ID/kubernetes/service-account-token \
    "$($CLI get secret -n $CONJUR_NAMESPACE_NAME $TOKEN_SECRET_NAME -o json \
      | jq -r .data.token \
      | $BASE64D)"

  echo "Initializing cluster API URL..."
  ./var_value_add_REST.sh \
    conjur/authn-k8s/$AUTHENTICATOR_ID/kubernetes/api-url \
    "$($CLI config view --minify -o yaml | grep server | awk '{print $2}')"

  echo "Variables initialized."
}

main "$@"
