VEE - Vagrant EasyEngine for modern WordPress development
========================
[EasyEngine](https://github.com/rtCamp/easyengine) - [Vagrant](https://vagrantup.com/) - [Parallels](https://www.parallels.com) - [VirtualBox](https://www.virtualbox.org)

A lemp stack with EasyEngine, Ubuntu 16.04/18.04, vagrant, nginx, apache, php-5-7.2, php-fpm, mysql 5.7, git, composer, wordmove and more.


Install
=======

1. copy `vee-conf.yaml.example` to `vee-conf.yaml`
 ```bash
 $ mv vee-conf.yaml.example vee-conf.yaml
 ```
 - Change ip
 - Change max RAM memory
 - Change max CPU's
 - Change hostname/servername
 - Change vee_email
 - Change vee_user
 - Change the ssh keys path
 - Set aliases
2. choose your virtualization product
 - install virtualbox >= 5.1.12 or parallels >= 13 (Mac os only)
3. install vagrant >= 2.1.2
4. install the necessary plugins for vagrant, if not yet happened
 ```bash
 $ vagrant plugin install vagrant-hostmanager
 $ vagrant plugin install vagrant-cachier
 $ vagrant plugin install vagrant-winnfsd # only for Windows
 ```

 Hostmanager is needed to add/remove entries in your local /etc/hosts file. To support development domains
 Cachier is needed to prevent downloading rpm´s again. This is usefull during setting up a vm, when you have online internet  via cellphone like inside a train :-)
 
 If you're using parallels you also have to install the vagrant plugin
 ```bash
 $ vagrant plugin install vagrant-parallels
 ```

4. start vagrant with virtual box
 ```bash
 $ vagrant up
 ```
 or with parallels
 ```bash
 $ vagrant up --provider=parallels
 ```

Config Option
=============

You can setup dedicated virtual hosts, sync folders, VM hardware in 

```
vee-conf.yaml
```

How it works
============

if you call http://0.test it will search for a index.php inside the /var/www/0.test/htdocs folder. It is really easy to start with any application.

Special
==========
Switch to the `www-data` user

```bash
$ ssh vagrant@vee
$ sudo -i
$ su www-data
$ cd ~/apps/APPNAME

```

or simple connect with ssh

```bash
$ ssh www-data@vee

```


TODO
==========
- [ ] Admin app - for custom app installation/removing
- [ ] Make app with git repo on install and another features by wizard
- [X] SSH access to www-data:www-data after EasyEngine installation
- [X] Mount sync folders automatically after the first reload
- [ ] Bedrock auto install
- [ ] PHP 7.1/7.2 auto config on install
- [ ] Script for fast project init: repo creation, staging creation and more (runcloud api)

Change Log
==========
