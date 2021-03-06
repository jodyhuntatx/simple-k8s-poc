#!/bin/bash 
set -euo pipefail

source ../config/cluster.config
source ../config/kubernetes.config
source ../config/utils.sh

main() {
  set_namespace $CONJUR_NAMESPACE_NAME

  announce "Configuring followers."

  configure_followers
  initialize_config_map

  echo "Followers configured."
}

configure_followers() {
  pod_list=$($CLI get pods -l role=follower --no-headers | awk '{ print $1 }')
  
  for pod_name in $pod_list; do
    configure_follower $pod_name &
  done
  
  wait # for parallel configuration of followers
}

configure_follower() {
  local pod_name=$1

  printf "Configuring follower %s...\n" $pod_name

  copy_file_to_container $FOLLOWER_SEED_FILE "/tmp/follower-seed.tar" "$pod_name"

  $CLI exec $pod_name -- evoke unpack seed /tmp/follower-seed.tar

  if [[ $NO_DNS == true ]]; then
    $CLI exec -it $pod_name -- bash -c "echo \"$CONJUR_MASTER_HOST_IP    $CONJUR_MASTER_HOST_NAME\" >> /etc/hosts"
  fi

  $CLI exec $pod_name -- evoke configure follower -p $CONJUR_MASTER_PORT
}

###################################
initialize_config_map() {
  echo "Storing Conjur cert in config map for cluster apps to use."

  $CLI delete --ignore-not-found=true -n default configmap $CONJUR_CONFIG_MAP

  # Store the Conjur cert in a ConfigMap in default namespace
  # follower_cert=$(./get_cert_REST.sh $CONJUR_MASTER_HOST_NAME $CONJUR_FOLLOWER_PORT)
  follower_cert=$(cat "$FOLLOWER_CERT_FILE")
  $CLI create configmap -n default $CONJUR_CONFIG_MAP --from-literal=ssl-certificate="$follower_cert"

  echo "Conjur cert stored."
}

main $@
