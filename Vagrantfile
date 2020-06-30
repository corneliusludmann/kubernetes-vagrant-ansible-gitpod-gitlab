IMAGE_NAME = "ubuntu/bionic64"
NUMBER_OF_NODES = 3
MASTER_MEMORY = 3072
MASTER_CPUS = 2
NODE_MEMORY = 8192
NODE_CPUS = 4
NODE_DISK_SIZE = "80GB"
DOMAIN = ENV["DOMAIN"] || "example.com"

# https://docs.gitlab.com/charts/installation/version_mappings.html
# Chart version 4.0.4 → GitLab version 13.0.5
GITLAB_CHART_VERSION = ENV["GITLAB_CHART_VERSION"] || "4.0.4"

# helm repo add nginx-stable https://helm.nginx.com/stable
# helm search repo -l nginx-stable
# Chart version 0.5.0 → nginx version 1.7.0
NGINX_CHART_VERSION = ENV["NGINX_CHART_VERSION"] || "0.5.0"

Vagrant.configure("2") do |config|
    config.ssh.insert_key = false

    config.vm.define "k8s-master" do |master|
        master.vm.box = IMAGE_NAME
        master.vm.provider "virtualbox" do |v|
            v.memory = MASTER_MEMORY
            v.cpus = MASTER_CPUS
        end
        master.vm.network "private_network", ip: "192.168.50.10"
        master.vm.synced_folder "sync/", "/home/vagrant/sync"
        master.vm.hostname = "k8s-master"
        master.vm.provision "ansible" do |ansible|
            ansible.playbook = "ansible-playbooks/master-playbook.yml"
            ansible.extra_vars = {
                node_ip: "192.168.50.10",
            }
        end

        master.vm.provision "gitlab-gitpod", run: "never", type: "ansible" do |ansible|
            ansible.limit = "k8s-master"
            ansible.playbook = "ansible-playbooks/gitlab-gitpod-playbook.yml"
            ansible.extra_vars = {
                domain: DOMAIN,
                gitlab_chart_version: GITLAB_CHART_VERSION,
                nginx_chart_version: NGINX_CHART_VERSION,
            }
        end
    end

    (1..NUMBER_OF_NODES).each do |i|
        config.vm.define "k8s-node-#{i}" do |node|
            node.vm.box = IMAGE_NAME
            node.vm.provider "virtualbox" do |v|
                v.memory = NODE_MEMORY
                v.cpus = NODE_CPUS
            end
            node.disksize.size = NODE_DISK_SIZE
            node.vm.network "private_network", ip: "192.168.50.#{i + 10}"
            node.vm.hostname = "k8s-node-#{i}"
            node.vm.provision "ansible" do |ansible|
                ansible.playbook = "ansible-playbooks/node-playbook.yml"
                ansible.extra_vars = {
                    node_ip: "192.168.50.#{i + 10}",
                }
            end
        end
    end
end
