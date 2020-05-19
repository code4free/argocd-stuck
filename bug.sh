#!/usr/bin/env bash

set -euo pipefail

function port::free() {
  local -i base_port=20000
  local -i increment=1
  local -i port=$base_port

  while (netstat -taln | grep $port >/dev/null 2>&1); do
    port=$((port+increment))
  done
  echo "$port"
}

function k8s::wait_for_app() {
  for (( i=0; i<180; i++ )); do
    if [[ "$(kubectl get app $1 -n $2 --output jsonpath='{.status.sync.status}' 2>/dev/null):$(kubectl get app $1 -n $2 --output jsonpath='{.status.health.status}' 2>/dev/null)" == "Synced:Healthy" ]]; then
      echo -e "\nApp: ${1} OK"
      kubectl describe app $1 -n $2
      return 0
    else
      echo -n "."
      sleep 1
    fi
  done
  kubectl describe app $1 -n $2
  return 1
}

function k8s::wait_for_deploy() {
  for (( i=0; i<500; i++ )); do
    if [[ "$(kubectl get deploy $1 -n $2 --output jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null)" == "True" ]]; then
      echo -e "\nDeploy: ${1} OK"
      return 0
    else
      echo -n "."
      sleep 1
    fi
  done
  return 1
}

function k3d::create() {
  k3d create \
    --name "$NAME" \
    --wait 180 \
    --image docker.io/rancher/k3s:v1.18.2-k3s1 \
    --api-port "$(port::free)"

  export KUBECONFIG="$(k3d get-kubeconfig --name="$NAME")"
}

function k3d::delete() {
    k3d delete --name "$NAME" || echo "K3S: '$NAME' not found."
}

function k3d::deploy() {
  kubectl create ns myns
  kubectl apply -n kube-system -f argocd.yaml
  k8s::wait_for_deploy argocd-application-controller myns
  k8s::wait_for_deploy argocd-repo-server myns
  k8s::wait_for_deploy argocd-redis myns
  sleep 15
  kubectl apply -n myns -f app.yaml
  k8s::wait_for_app level1-app myns
}

export NAME="${1:-test-cluster}"

while (k3d::delete && k3d::create && k3d::deploy); do
  echo 'App healthy. Retrying...';
done