# Gitpod + Gitlab on a Kubernetes Cluster with Vagrant and Ansible

- Create HTTPS certs and copy to `sync/gitpod-self-hosted/secrets/https-certificates`, the script `scripts/letsencrypt-docker.sh` could help
- Run `openssl dhparam -out sync/gitpod-self-hosted/secrets/https-certificates/dhparams.pem 2048`
- Configure your DNS, maybe add iptable rules with `scripts/add-iptable-rules.sh` to your host system
- Run `./scripts/setup-cluster.sh <your-domain.com>`, take some time (depending on your internet connection and your machine, ~ 1 hour)
- Open https://gitlab.example.com and https://gitpod.example.com/workspaces (replace your domain)
