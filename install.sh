#!/usr/bin/env bash
#
# Installation script for ECK on Kind cluster
# 
# Pre-requisites:
# - kubectl
# - kind
# - envsubst
###############################################

K8S_CLUSTER_NAME=eck
ECK_VERSION=2.3.0
SCRIPT_PATH="$(
    cd "$(dirname "$0")"
    pwd -P
)"

log_error() {
  echo "$1"
  exit 1
}

validate() {
  # Check passwords set
  [[ -z $DEVELOPER_PASSWORD ]] && log_error "Environment variable DEVELOPER_PASSWORD is empty"
  [[ -z $ELASTIC_PASSWORD ]] && log_error "Environment variable ELASTIC_PASSWORD is empty"

  # Check tools available
  kubectl help >/dev/null 2>&1 || log_error "Tool kubectl not available" 
  kind --version >/dev/null 2>&1 || log_error "Tool kind not available" 
  envsubst -V >/dev/null 2>&1 || log_error "Tool envsubst not available"
}

create_cluster() {
  # Create cluster
  kind get clusters | grep -q $K8S_CLUSTER_NAME && log_error "Kind cluster with name $K8S_CLUSTER_NAME already exist"
  kind create cluster --name $K8S_CLUSTER_NAME

  ready=0
  count=10
  while [[ $ready -eq 0 ]]
  do
    kubectl get nodes | grep -q " Ready " && ready=1
    if [[ $ready -eq 0 ]]
    then
      [[ $count -eq 0 ]] && log_error "Kind cluster did not start properly"
      echo "Waiting cluster to become ready..."
      sleep 5
      count=$((count - 1))
    fi
  done
}

install_operator() {
  kubectl create -f https://download.elastic.co/downloads/eck/${ECK_VERSION}/crds.yaml
  kubectl apply -f https://download.elastic.co/downloads/eck/${ECK_VERSION}/operator.yaml

  #TODO: Verify the operator started correctly
}

install_es() {
  envsubst < $SCRIPT_PATH/manifest-secret.yaml | kubectl apply -f - || log_error "Failed to apply manifest secret"
  kubectl apply -f $SCRIPT_PATH/manifest-es.yaml || log_error "Failed to apply manifest es"
  kubectl apply -f $SCRIPT_PATH/manifest-kibana.yaml || log_error "Failed to apply manifest kibana"
}

# --- Main ---

# Validate
validate

# Check kubectl installed

# Check helm installed

# Create cluster
create_cluster

# Install operator
install_operator

# Install Elasticsearch
install_es