# Simple K8s POC

### Summary
Bash scripts that will setup:
1. DAP master/follower & CLI
2. Optional Follower in K8s cluster
3. Test applications in K8s cluster

### Prerequisites
1. Docker
2. Kubernetes

### Usage
1. cd to cluster/ and edit cluster.config and kubernetes.config per env
2. cd to 1_docker_master and run start
3. cd to either 2_ext_follower or 2_k8s_follower and run start
4. cd to 3_k8s_app and run start
