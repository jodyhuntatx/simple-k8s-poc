#!/bin/bash
source ../config/cluster.config
source ../config/$PLATFORM.config
source ../config/utils.sh

if [[ $# != 1 ]]; then
  echo "specify 'init' or 'side'"
  exit -1
fi
set_namespace $TEST_APP_NAMESPACE_NAME
app_pod=$($CLI get pods | grep $1 | awk '{print $1}')
$CLI exec -it $app_pod -- bash
