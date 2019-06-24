Vagrant.configure(2) do |config|

  config.vm.box = "ubuntu/xenial64"

  config.vm.box_check_update = true

  config.vm.network :forwarded_port, guest: 80, host: 8080, auto_correct: true

  config.vm.network "public_network"

  config.vm.synced_folder "./", "/var/www", owner: "www-data", group: "www-data"

  config.vm.provider "virtualbox" do |vb|

    vb.name = "jiam-vagrant-xenial64-php7.1"

    vb.gui = false

    vb.memory = "1024"

    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]

  end

  config.vm.provision "shell" do |shell|
    shell.path ="./setup/vm_build.sh"
  end

end
