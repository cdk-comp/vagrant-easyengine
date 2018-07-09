# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'

# Load the settings file
settings = YAML.load_file(File.join(File.dirname(__FILE__), "vee-conf.yaml"))

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

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

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
config.vm.box = settings["vm_box"]

  config.vm.provider "parallels"
  config.vm.provider "virtualbox"

  if !Vagrant.has_plugin?('vagrant-cachier')
    puts "The vagrant-cachier plugin is required. Please install it with \"vagrant plugin install vagrant-cachier\""
    exit
  end

  if !Vagrant.has_plugin?('vagrant-hostmanager')
    puts "The vagrant-hostmanager plugin is required. Please install it with \"vagrant plugin install vagrant-hostmanager\""
    exit
  end

  if OS.windows?
    if !Vagrant.has_plugin?('vagrant-winnfsd')
      puts "The vagrant-winnfsd plugin is required. Please install it with \"vagrant plugin install vagrant-winnfsd\""
      exit
    end
  end

  if Vagrant.has_plugin?('vagrant-vbguest')
      config.vbguest.auto_update = true
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
    node.vm.hostname = settings['hostname'] ||= 'vee'
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
      puts "Check your vee-conf.yaml file, you have no private key(s) specified."
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
        puts "Check your vee-conf.yaml file, the path to your private key does not exist."
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
          config.vm.synced_folder folder["map"], folder["to"], owner: "www-data", group: "www-data", disabled: false, create: true
      end
    end
  end

  config.ssh.forward_agent = true

  # Configure The email
  if settings["vee_email"].to_s.length == 0
    puts "Check your vee-conf.yaml file, you have no vee_email specified."
    exit
  else
    config.vm.provision "shell" do |s|
      s.inline = "echo $1$2 | grep -xq \"$1$2\" /home/vagrant/.bash_profile || echo \"\n$1$2\" | tee -a /home/vagrant/.bash_profile"
      s.args   = ['export vee_email=', settings["vee_email"]]
    end
  end

  # Configure The email
  if settings["vee_user"].to_s.length == 0
    puts "Check your vee-conf.yaml file, you have no vee_user specified."
    exit
  else
    config.vm.provision "shell" do |s|
      s.inline = "echo $1$2 | grep -xq \"$1$2\" /home/vagrant/.bash_profile || echo \"\n$1$2\" | tee -a /home/vagrant/.bash_profile"
      s.args   = ['export vee_user=', settings["vee_user"]]
    end
  end

  # EasyEngine and custom features
  config.vm.provision "file", source: "vee.sh", destination: "vee.sh"
  config.vm.provision "shell", inline: "source /home/vagrant/.bash_profile && sudo bash vee.sh"

  # Create project from the config
  if settings.include? 'vee_projects'
    config.vm.provision "file", source: "vee-app.sh", destination: "vee-app.sh", run: "always"
    settings["vee_projects"].each do |project|
      if project["host"].to_s.length != 0
        config.vm.provision "shell", run: "always" do |s|
          s.inline = "$1$2 && $3$4 && $5$6 && bash /home/vagrant/vee-app.sh"
          s.args   = ['export vee_app=', project["host"], 'export vee_repo=', project["repo"], 'export vee_type=', project["type"]]
        end
      end
    end
  end
end
