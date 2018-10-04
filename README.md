![Vagrant-EasyEngine Screenshot](https://user-images.githubusercontent.com/12497991/45975046-d39a8700-c04b-11e8-8ec4-1c6723645b26.jpg)

**Version Beta** (24.09.2018)

Vagrant EasyEngine for modern WordPress development
========================
[EasyEngine](https://github.com/rtCamp/easyengine) - [Vagrant](https://vagrantup.com/) - [Parallels](https://www.parallels.com) - [VirtualBox](https://www.virtualbox.org)

A lemp stack with EasyEngine, Ubuntu 16.04/18.04, vagrant, nginx, apache, php-5-7.2, php-fpm, mysql 5.7, git, composer, wordmove and more.

Install
=======

1. copy `vagrant-conf.yml.example` to `vagrant-conf.yml`
 ```bash
 $ mv vagrant-conf.yml.example vagrant-conf.yml
 ```
 - Change ip
 - Change max RAM memory
 - Change max CPU's
 - Change hostname/servername
 - Change provider
 - Change vagrant_email
 - Change vagrant_user
 - Change the ssh keys path
 - Change vm_box for your custom vagrant box
 - Set aliases
2. choose your virtualization product
 - install virtualbox >= 5.1.12 or parallels >= 13 (Mac os only)
3. install vagrant >= 2.1.2
4. install the necessary plugins for vagrant, if not yet happened
 ```bash
 $ vagrant plugin install vagrant-hostmanager
 $ vagrant plugin install vagrant-cachier
 $ vagrant plugin install vagrant-vbguest
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
vagrant-conf.yml
```

Create app on vagrant up/reload:

```yaml
aliases:
  - app.test # must be
```

Check README_CONFIG.md for more information about app configuration and setup

How it works
============

if you call http://0.test it will search for a index.php inside the /var/www/0.test/htdocs folder. It is really easy to start with any application.

Special
=======
Switch to the `www-data` user

```bash
$ vagrant ssh
$ sudo -s
$ su www-data
$ cd ~/APPNAME

```

or simple connect with ssh

```bash
$ ssh www-data@app.test

```

Switch php7 to php72
====================
```bash
$ vagrant ssh
$ sudo ee site edit app.test
```

Find line with **7.conf** and change to **72.conf**

old config
```txt
include common/php7.conf;
include common/locations-php7.conf;
```

new config
```txt
include common/php72.conf;
include common/locations-php72.conf;
```

TODO
==========
- [ ] cdkrock autoinstall support
- [ ] movefile auto init
- [ ] PHP 7.1/7.2 auto config on install
- [ ] Script for fast project init: repo creation, staging creation and more (runcloud api)
- [ ] Remove all .git directories if exist key
- [ ] Make new repo on vagrant_up

Change Log
==========


## Credit to WPDistillery and EasyEngine

[wpdistillery.org](https://wpdistillery.org)

## What is WPDistillery?
WP Distillery does all the work for you when setting up a new WordPress project with EasyEngine.
