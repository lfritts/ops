# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "trusty"
  config.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"

  # accessing "localhost:8080" will access port 80 on the guest machine.
  config.vm.network :forwarded_port, guest: 80, host: 8080 #Nginx
  config.vm.network :forwarded_port, guest: 8082, host: 8082 #Gunicorn (no site media)
  config.vm.network :forwarded_port, guest: 8083, host: 8083 #Development Server
  config.vm.network :forwarded_port, guest: 5432, host: 5432 #PostgreSQL
  config.vm.network :forwarded_port, guest: 9200, host: 9200 #Elasticsearch Server (direct)
  config.vm.network :forwarded_port, guest: 9225, host: 9225 #Elasticsearch Proxy Server

  #SSH connections made will enable agent forwarding.
  config.ssh.forward_agent = true

  # Shared folders
  config.vm.synced_folder "./", "/home/vagrant/ops"
 
  # Provider-specific configuration so you can fine-tune various
  config.vm.provider :virtualbox do |vb|
    # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ["modifyvm", :id, 
                  "--memory", "4096",
                  "--cpus", 6,
                  "--name", "GlobAllomeTree ops"]
  end
end
