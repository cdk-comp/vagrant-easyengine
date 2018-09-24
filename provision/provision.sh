#!/usr/bin/env bash
#
# vagrant-easyengine provisioning file
#
# Author: Dima Minka
#
# File version 1.1.2

echo "=============================="
echo "You can replace $vagrant_user with your username & $vagrant_email by your email in vagrant-config.yml"
echo "=============================="
sudo chown vagrant:vagrant /home/vagrant/.[^.]*
source /home/vagrant/.bash_profile
sudo echo -e "source ~/.bashrc\n" >> /home/vagrant/.bash_profile
sudo echo -e "[user]\n\tname = $vagrant_user\n\temail = $vagrant_email" > /home/vagrant/.gitconfig

echo "=============================="
echo "Copy gitconfig and bash_profile to www-data directory"
echo "=============================="
sudo cp /home/vagrant/{.gitconfig,.bash_profile} /var/www
sudo chown www-data:www-data /var/www/.[^.]*

echo "=============================="
echo "copy keys from vagrant directory to www-data and root"
echo "=============================="
ssh-keyscan -H bitbucket.org >> /home/vagrant/.ssh/known_hosts
ssh-keyscan -H github.com >> /home/vagrant/.ssh/known_hosts
sudo cp -r /home/vagrant/.ssh /var/www/.ssh
sudo chown -R www-data:www-data /var/www/.ssh
