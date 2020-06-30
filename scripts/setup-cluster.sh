#!/usr/bin/env bash

set -euo pipefail

print_usage() {
    echo "Usage: $0 [-s <snapshot_name>] <your.domain.com>"
    echo
    echo "-s   Save snapshot of VMs after installation of bare-metal kubernetes cluster. Removes existing snapshot with same name (force mode)."
}

if [[ $# -lt 1 ]]; then
    print_usage
    exit 1
fi

snapshot_name=''

while getopts 's:h' flag; do
  case "${flag}" in
    s) snapshot_name="$OPTARG" ;;
    h) print_usage
       exit 0 ;;
    *) print_usage
       exit 1 ;;
  esac
done

export DOMAIN="${!#}"
echo "Your domain: $DOMAIN"

vagrant plugin install vagrant-disksize
vagrant up
if [[ ! -z "$snapshot_name" ]]; then
    vagrant snapshot save "$snapshot_name" --force
fi
vagrant provision k8s-master --provision-with gitlab-gitpod

echo "GitLab root password:"
vagrant ssh k8s-master -c "kubectl get secret gitlab-gitlab-initial-root-password -o jsonpath='{.data.password}' | base64 --decode; echo"
