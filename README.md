# Bare-metal Kubernetes Cluster with Gitpod and GitLab on Virtual Machines with Vagrant and Ansible


## Introduction

This repository provides a [Vagrantfile](Vagrantfile) and some [Ansible playbooks](ansible-playbooks/) that create a bare-metal [Kubernetes](https://kubernetes.io/) cluster based on virtual machines (VirtualBox) with a pre-installed [Gitpod](https://gitpod.io/) and [GitLab](https://gitlab.com/) on your Linux server. With this installation you are able to create Git repositories in your self-hosted GitLab and to develop your software with your self-hosted Gitpod fully in your browser.


## Prerequisites

In order to bring the Kubernetes cluster up and running the following requirements must be met:

- [VirtualBox](https://www.virtualbox.org/) installed, as virtual machine provider
- [Vagrant](https://www.vagrantup.com/) installed, to setup the virtual machines
- [Ansible](https://www.ansible.com/) installed, to install Kubernetes, Gitpod and GitLab on the virtual machines
- A DNS server that resolves the Gitpod and GitLab domains to the virtual machines (see [below](#dns-setup-and-tls-certificates))
- X.509 certificates for Transport Layer Security (TLS) encryption for Gitpod and GitLab domains (see [below](#dns-setup-and-tls-certificates))

This example setting has been created on an [Arch Linux](https://www.archlinux.org/) server with VirtualBox 6.1.10, Vagrant 2.2.9, and Ansible 2.9.10.

### DNS Setup and TLS Certificates

To run this example you need domain names for Gitpod and GitLab, a running DNS server that resolves the domains as well as valid SSL/TLS certificates for these domains. [Gitpod needs wildcard domains](https://www.gitpod.io/docs/self-hosted/latest/install/https-certs). The easiest way is to create a subdomain under which the Gitpod and GitLab domains will be located. Let us call this domain dev.example.com. Gitpod will be available at gitpod.dev.example.com/workspaces and GitLab at gitlab.dev.example.com.

#### TLS Certificates from Let’s Encrypt

Free TLS certificates can be obtained from [Let’s Encrypt](https://letsencrypt.org/). Create a certificate for the following domains:
- `dev.example.com`
- `*.dev.example.com`
- `*.gitlab.dev.example.com`
- `*.gitpod.dev.example.com`
- `*.ws.gitpod.dev.example.com`

You can use this command:
```shell
$ certbot/certbot certonly \
    --manual \
    --preferred-challenges=dns \
    --email info@example.com \
    --agree-tos \
    -d dev.example.com \
    -d *.dev.example.com \
    -d *.gitlab.dev.example.com \
    -d *.gitpod.dev.example.com \
    -d *.ws.gitpod.dev.example.com
```

Copy the *.pem files to `sync/gitpod-self-hosted/secrets/https-certificates`. You need to generate a `dhparams.pem` file as well:
```shell
$ openssl dhparam -out sync/gitpod-self-hosted/secrets/https-certificates/dhparams.pem 2048
```

You can use the script [scripts/letsencrypt-docker.sh](scripts/letsencrypt-docker.sh) to create your certificates with certbot running in Docker. You just need to have Docker installed and the environment variable `DOMAIN` and `EMAIL` set, e.g.:
```shell
$ export DOMAIN=dev.example.com
$ export EMAIL=info@example.com
$ ./scripts/letsencrypt-docker.sh
```

Follow the instructions of certbot. That’s it.

#### DNS configuration with dnsmasq

You need to configure your DNS server to resolve your Gitpod and GitLab domains to your virtual machines. Let’s assume the IP address of your host machine is `10.0.0.75` the domain name dev.example.com and all subdomains need to resolve to this IP.

If you have [dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html) running as DNS server you can simple add the following line to your dnsmasq configuration:
```
address=/dev.example.com/10.0.0.75
```

#### Traffic routing with iptables

If you would like to access your Gitpod and GitLab installation from you network you need to route your traffic through your host system. If you have [iptables](http://netfilter.org/) installed you can add some iptable rules. Run the script [scripts/add-iptables-rules.sh](scripts/add-iptables-rules.sh) as root with the network interface like this:
```shell
$ sudo ./scripts/add-iptables-rules.sh eth0
```

_Note: These rules are not persistent. This script has to be re-run after reboot._

## Create and Start Kubernetes Cluster

The Kubernetes cluster is created and installed with Vagrant. By default, 4 VMs are created (1 master and 3 nodes) with the following characteristics:

| VM name    | IP address    | Memory  | CPUs | Disk Size |
|------------|---------------|--------:|-----:|----------:|
| k8s-master | 192.168.50.10 | 3072 MB |    2 |     80 GB |
| k8s-node-1 | 192.168.50.11 | 8192 MB |    4 |     80 GB |
| k8s-node-2 | 192.168.50.12 | 8192 MB |    4 |     80 GB |
| k8s-node-3 | 192.168.50.13 | 8192 MB |    4 |     80 GB |

You can change these parameters in the [Vagrantfile](Vagrantfile). Lower resources (CPUs, Memory, …) are most likely also sufficient. It creates the 4 VMs based on `ubuntu/bionic64` and
1. creates a Kubernetes cluster with
   - [Docker](https://www.docker.com/), [container.d](https://containerd.io/), [Kubernetes](https://kubernetes.io/) with [kubeadm, kubelet, and kubectl](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl)
   - [Calico](https://www.projectcalico.org/) as [Kubernetes network model](https://kubernetes.io/docs/concepts/cluster-administration/networking/)
   - [Rancher Local Path Provisioner](https://github.com/rancher/local-path-provisioner) as [Local Persistence Volume](https://kubernetes.io/docs/concepts/storage/volumes/#local) provisioner

   _(see [ansible-playbooks/common-tasks.yml](ansible-playbooks/common-tasks.yml), [ansible-playbooks/master-playbook.yml](ansible-playbooks/master-playbook.yml), and [ansible-playbooks/node-playbook.yml](ansible-playbooks/node-playbook.yml))_

2. installs GitLab and Gitpod

    _(see [ansible-playbooks/gitlab-gitpod-playbook.yml](ansible-playbooks/gitlab-gitpod-playbook.yml))_

To start the installation, you can use the script [scripts/setup-cluster.sh](scripts/setup-cluster.sh) like this:
```shell
$ ./scripts/setup-cluster.sh dev.example.com
```

The installation takes some time depending on your machine and internet connections (up to 1 hour).

If you would like to create a snapshot after installing the Kubernetes cluster (before installing GitLab and Gitpod) you can use the `-s` param like this:
```shell
$ ./scripts/setup-cluster.sh -s plain-kubernetes dev.example.com
```

That allows you to play with `gitlab-gitpod-playbook.yml` without the need to install the whole cluster again. Just run the following after you modified `gitlab-gitpod-playbook.yml`:
```shell
$ vagrant snapshot restore plain-kubernetes
$ export DOMAIN=dev.example.com
$ vagrant provision k8s-master --provision-with gitlab-gitpod
```

After the installation open GitLab at https://gitlab.dev.example.com and create a user account as well as a Git repository, e.g. repository `sample` of user `alice`. You can open this repository in Gitpod by opening:
https://gitpod.dev.example.com/#https://gitlab.dev.example.com/alice/sample

You will find your Gitpod workspaces at https://gitpod.dev.example.com/workspaces.

The folder [sync](sync) is mounted on the master node. Run
```shell
$ vagrant ssh k8s-master
```
and you will find the folder in `/home/vagrant/sync`.
