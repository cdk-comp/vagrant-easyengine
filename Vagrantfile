# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Vagrantfile using cdk-comp/vagrant-easyengine
# Check out https://github.com/cdk-comp/vagrant-easyengine-install to learn more about cdk-comp/vagrant-easyengine
#
# Author: Dima Minka
# URL: https://cdk.co.il
#
# File Version: 1.2.2

require 'yaml'

# Load the settings file
settings = YAML.load_file(File.join(File.dirname(__FILE__), "vagrant-conf.yml"))

# Detect host OS for different folder share configuration
module OS
  def OS.windows?
    (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  end

  def OS.mac?
    (/darwin/ =~ RUBY_PLATFORM) != nil
  end

  def OS.unix?
    !OS.windows?
  end

  def OS.linux?
    OS.unix? and not OS.mac?
  end
end

Vagrant.configure("2") do |config|
  config.vm.box = settings["vm_box"] ||= "cdk-comp/vagrant-easyengine"
  config.vm.provider settings["provider"] ||= "virtualbox"

  [
    { :name => "vagrant-hostmanager", :version => ">= 1.8.9" },
    { :name => "vagrant-vbguest", :version => ">= 0.16.0" },
    { :name => "vagrant-cachier", :version => ">= 1.2.1"}
  ].each do |plugin|

  Vagrant::Plugin::Manager.instance.installed_specs.any? do |s|
    req = Gem::Requirement.new([plugin[:version]])
      if (not req.satisfied_by?(s.version)) && plugin[:name] == s.name
        raise "#{plugin[:name]} #{plugin[:version]} is required. Please run `vagrant plugin install #{plugin[:name]}`"
      end
    end
  end

  if OS.windows?
    if !Vagrant.has_plugin?('vagrant-winnfsd')
      puts "The vagrant-winnfsd plugin is required. Please install it with \"vagrant plugin install vagrant-winnfsd\""
    end
  end

  config.cache.scope = :box

  # Vagrant hardware settings
  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--memory", settings["memory"] ||= "2048"]
    vb.customize ["modifyvm", :id, "--cpus", settings["cpus"] ||= "2"]
  end

  config.vm.provider "parallels" do |v|
  v.memory = settings["memory"] ||= "2048"
  v.cpus = settings["cpus"] ||= "2"
  end

  # vagrant-hostmanager config (https://github.com/smdahlen/vagrant-hostmanager)
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = true

  config.vm.define "project" do |node|
    node.vm.hostname = settings['hostname'] ||= 'vagrant-easyengine'
    node.vm.network :private_network, ip: settings['ip'] ||= '192.168.100.100'

    node.hostmanager.aliases = [settings['aliases']]

    config.vm.network :forwarded_port, guest: 80, host: 8080
    config.vm.network :forwarded_port, guest: 443, host: 443
  end

  # Configure The Public Key For SSH Access
  if settings.include? 'authorize'
    if File.exists? File.expand_path(settings["authorize"])
      config.vm.provision "shell" do |s|
        s.inline = "echo $1 | grep -xq \"$1\" /home/vagrant/.ssh/authorized_keys || echo \"\n$1\" | tee -a /home/vagrant/.ssh/authorized_keys"
        s.args = [File.read(File.expand_path(settings["authorize"]))]
      end
    end
  end

  # Copy The SSH Private Keys To The Box
  if settings.include? 'keys'
    if settings["keys"].to_s.length == 0
      puts "Check your vagrant-conf.yml file, you have no private key(s) specified."
      exit
    end
    settings["keys"].each do |key|
      if File.exists? File.expand_path(key)
        config.vm.provision "shell" do |s|
          s.privileged = false
          s.inline = "echo \"$1\" > /home/vagrant/.ssh/$2 && chmod 600 /home/vagrant/.ssh/$2"
          s.args = [File.read(File.expand_path(key)), key.split('/').last]
        end
      else
        puts "Check your vagrant-conf.yml file, the path to your private key does not exist."
        exit
      end
    end
  end

  # Disabling the default /vagrant share
  config.vm.synced_folder '.', '/vagrant', disabled: true

  # Register All Of The Configured Shared Folders
  if settings.include? 'folders'
    settings["folders"].each do |folder|
      if File.exists? File.expand_path(folder["map"])
        # Use vagrant-winnfsd if available https://github.com/flurinduerst/WPDistillery/issues/78
        if Vagrant.has_plugin? 'vagrant-winnfsd'
          config.vm.synced_folder folder["map"], folder["to"],
            nfs: true,
            mount_options: [
            'nfsvers=3',
            'vers=3',
            'actimeo=1',
            'rsize=8192',
            'wsize=8192',
            'timeo=14'
            ]
        else
          config.vm.synced_folder folder["map"], folder["to"], owner: "www-data", group: "www-data", disabled: false, create: true
        end
      end
    end
  end

  config.ssh.forward_agent = true

  # Configure The email
  if settings["vagrant_email"].to_s.length == 0
    puts "Check your vagrant-conf.yml file, you have no vagrant_email specified."
    exit
  else
    config.vm.provision "shell" do |s|
      s.inline = "echo $1$2 | grep -xq \"$1$2\" /home/vagrant/.bash_profile || echo \"\n$1$2\" | tee -a /home/vagrant/.bash_profile"
      s.args   = ['export vagrant_email=', settings["vagrant_email"]]
    end
  end

  # Configure The user
  if settings["vagrant_user"].to_s.length == 0
    puts "Check your vagrant-conf.yml file, you have no vagrant_user specified."
    exit
  else
    config.vm.provision "shell" do |s|
      s.inline = "echo $1$2 | grep -xq \"$1$2\" /home/vagrant/.bash_profile || echo \"\n$1$2\" | tee -a /home/vagrant/.bash_profile"
      s.args   = ['export vagrant_user=', settings["vagrant_user"]]
    end
  end

  # WPDistillery Windows Support
  if Vagrant::Util::Platform.windows?
    config.vm.provision "shell",
    inline: "echo \"Converting Files for Windows\" && sudo apt-get install -y dos2unix && cd /var/www/ && dos2unix wpdistillery/config.yml && dos2unix wpdistillery/provision.sh && dos2unix wpdistillery/wpdistillery.sh",
    run: "always", privileged: false
  end

  if settings["vm_box"] == "cdk-comp/vagrant-easyengine"
    # Basic provison for new box
    config.vm.provision "shell", path: "provision/provision.sh"
    # Run app create with custom configuration
    if settings["app_installer"] == true
      if settings.include? 'aliases'
        config.vm.provision "file", source: "provision/vagrant_up.sh", destination: "vagrant_up.sh", run: "always"
        settings["aliases"].each do |host|
          config.vm.provision "shell", run: "always" do |s|
            s.inline = "sudo bash vagrant_up.sh $1"
            s.args   = host
          end
        end
      end
    end
  end
end
