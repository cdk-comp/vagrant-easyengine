#!/usr/bin/env bash
#
# vagrant_up provisioning file
#
# Author: Dima Minka
#
# File version 1.1.2

source /home/vagrant/.bash_profile

# DEFINE COLORS
RED='\033[0;31m' # error
GRN='\033[0;32m' # success
BLU='\033[0;34m' # task
BRN='\033[0;33m' # headline
NC='\033[0m' # no color

# CUSTOM VARS
app_name=$1
ee_apps_path="/var/www/"
apps_path="/home/vagrant/apps/"
config_yaml="/home/vagrant/apps/$app_name.yml"

# ERROR Handler
# ask user to continue on error
function continue_error {
  read -p "$(echo -e "${RED}Do you want to continue anyway? (y/n) ${NC}")" -n 1 -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    printf "\n${RED}»»» aborting VAGRANT-EASYENGINE setup! ${NC}\n"
    exit 1
  else
    printf "\n${GRN}»»» continuing VAGRANT-EASYENGINE setup... ${NC}\n"
  fi
}
trap 'continue_error' ERR

# REQUIREMENTS
####################################################################################################

# YAML PARSER FUNCTION
function parse_yaml() {
    local prefix=$2
    local s
    local w
    local fs
    s='[[:space:]]*'
    w='[a-zA-Z0-9_]*'
    fs="$(echo @|tr @ '\034')"
    sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s[:-]$s\(.*\)$s\$|\1$fs\2$fs\3|p" "$1" |
    awk -F"$fs" '{
    indent = length($1)/2;
    vname[indent] = $2;
    for (i in vname) {if (i > indent) {delete vname[i]}}
        if (length($3) > 0) {
            vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
            printf("%s%s%s=(\"%s\")\n", "'"$prefix"'",vn, $2, $3);
        }
    }' | sed 's/_=/+=/g'
}

# root user change
noroot() {
  sudo -EH -u "vagrant" "$@";
}

# App create
function ee_app_create () {
  printf "${BRN}[=== CREATE $app_name APP ===]${NC}\n"
  service nginx start
  # INSTALL WORDPRESS
  vagrant_user=$vagrant_user-$(app_random 5)
  if [ ! -z "$CONF_admin_user" ]; then
    vagrant_user=$CONF_admin_user;
  fi
  if [ ! -z "$CONF_admin_password" ]; then
    vagrant_pass=$CONF_admin_password
  else
    vagrant_pass=$(app_random 32)
  fi
  if [ ! -z "$CONF_admin_email" ]; then
    vagrant_email=$CONF_admin_email;
  fi
  if $CONF_ee_app_wp; then
  printf "${BLU}»»» creating app and wordpress install...${NC}\n"
    yes | ee site create $app_name --wp --email=$vagrant_email --user=$vagrant_user --pass=$vagrant_pass --php7
  else
    yes | ee site create $app_name --php7 --mysql
  fi
  # move to synced folder
  mv $ee_apps_path$app_name $apps_path
  # create symlink to www directory
  ln -s $apps_path$app_name $ee_apps_path$app_name
  # git pull to app
  if [ ! -z "$CONF_app_repo" ]; then
    project_pull
  fi
  # create .env configuration file
  env_init $vagrant_user $vagrant_pass $vagrant_email
  # change ee public directory
  if [ ! -z "$CONF_ee_app_public" ]; then
    ee_public_change
  fi
  # install custom workflow
  if [ "$CONF_wpworkflow" == "bedrock" ] || [ ! -z "$CONF_app_repo" ]; then
    noroot composer install
    wp core install --url="$app_name" --title="$app_name" --admin_user="$vagrant_user" --admin_password="$vagrant_pass" --admin_email="$vagrant_email" --allow-root
  fi
}

# App delete
function ee_app_delete () {
  printf "${BRN}[=== DELETE $app_name APP ===]${NC}\n"
  rm $ee_apps_path$app_name
  mv $apps_path$app_name $ee_apps_path
  yes | ee site $CONF_ee_site_config $app_name
}

# App enable/disable
function ee_app_switch () {
  printf "${BRN}[=== Switch to $CONF_ee_site_config for $app_name ===]${NC}\n"
  ee site $CONF_ee_site_config $app_name
}

# Random hash with custom count of characters
function app_random () {
  echo $(base64 /dev/urandom | tr -d '/+' | dd bs=$1 count=1 2>/dev/null)
}

# Change default public directory 'htdocs' to 'web'
function ee_public_change () {
  printf "${BLU}»»» Change default public directory 'htdocs' to $CONF_ee_app_public for $app_name${NC}\n"
  sed -i -e "s/htdocs/$CONF_ee_app_public/g" "/etc/nginx/sites-available/$app_name"
  sudo service nginx reload
}

# Git pull for last commit from repository master
function project_pull () {
  printf "${BLU}»»» Git pull for $apps_path$app_name${NC}\n"
  sudo rm -rf $apps_path$app_name/*
  cd $apps_path$app_name && git init && git remote add origin $CONF_app_repo
  noroot git --git-dir=$apps_path$app_name/.git --work-tree=$apps_path$app_name pull --depth=1 origin master
}

# Check for git repository and add to composer, else wpackagist
function package_installer () {
  package=$1
  package_type=$2
  activate=$3
  dev=$4
  re="^(https|git)(:\/\/|@)([^\/:]+)[\/:]([^\/:]+)\/(.+).git$"
  if [[ $package =~ $re ]]; then
    user=${BASH_REMATCH[4]}
    repo=${BASH_REMATCH[5]}
    noroot composer config repositories.$user/$repo '{"type":"package","package": {"name": "'$user/$repo'","version": "master","type": "wordpress-'$package_type'","source": {"url": "'$package'","type": "git","reference":"master"}}}'
    noroot composer require $user/$repo:dev-master
    if [ "$activate" == "activate" ]; then
      wp plugin activate $repo --allow-root
    fi
  else
    noroot composer require $dev wpackagist-$package_type/$package
    if [ "$activate" == "activate" ]; then
      wp plugin activate $package --allow-root
    fi
  fi
}

# ENV configuration file creation with actual project details
function env_init () {

  echo "=============================="
  echo ".env init for $app_name"
  echo "=============================="

  ee site info $app_name > $apps_path$app_name/$app_name.txt

  if [ -f "$apps_path$app_name/.env" ]; then
    mv $apps_path$app_name/.env $apps_path$app_name/.env.old
  fi

  db_details=("DB_NAME" "DB_USER" "DB_PASS")
  for i in "${!db_details[@]}"; do
    db_data=$(grep "${db_details[$i]}" "$apps_path$app_name/$app_name.txt")
    db_data=${db_data// /=}
    db_data=${db_data//[[:blank:]]/}
    db_data=${db_data//DB_PASS/DB_PASSWORD}
    echo $db_data >> $apps_path$app_name/.env
  done

  echo "" >> $apps_path$app_name/.env
  echo "WP_USER=$1" >> $apps_path$app_name/.env
  echo "WP_PASS=$2" >> $apps_path$app_name/.env
  echo "WP_MAIL=$3" >> $apps_path$app_name/.env

  echo "" >> $apps_path$app_name/.env

  echo "# Optional variables" >> $apps_path$app_name/.env
  echo "# DB_HOST=localhost" >> $apps_path$app_name/.env
  echo "DB_PREFIX=wp_$(app_random 5)_" >> $apps_path$app_name/.env

  echo "" >> $apps_path$app_name/.env

  echo "CDK_CUSTOM=custom,multisite,theme" >> $apps_path$app_name/.env
  echo "CDK_HOST=$app_name" >> $apps_path$app_name/.env
  echo "CDK_MEMORY=1024M" >> $apps_path$app_name/.env
  echo "CDK_PROTOCOL=http" >> $apps_path$app_name/.env
  echo "CDK_THEME=false" >> $apps_path$app_name/.env

  echo "" >> $apps_path$app_name/.env

  echo "# Multisite configuration for nginx servers - add to yours conf file" >> $apps_path$app_name/.env
  echo "# if (!-e \$request_filename) {" >> $apps_path$app_name/.env
  echo "#     rewrite /wp-admin$ \$scheme://\$host\$uri/ permanent;" >> $apps_path$app_name/.env
  echo "#     rewrite ^/[_0-9a-zA-Z-]+(/wp-.*) /wp\$app_name last;" >> $apps_path$app_name/.env
  echo "#     rewrite ^/[_0-9a-zA-Z-]+(/.*\.php)$ /wp\$app_name last;" >> $apps_path$app_name/.env
  echo "# }" >> $apps_path$app_name/.env
  echo "WP_ALLOW_MULTISITE=false" >> $apps_path$app_name/.env
  echo "WP_MULTISITE=false" >> $apps_path$app_name/.env

  echo "" >> $apps_path$app_name/.env

  echo "WP_ENV=development" >> $apps_path$app_name/.env
  echo "WP_HOME=\${CDK_PROTOCOL}://\${CDK_HOST}" >> $apps_path$app_name/.env
  echo "WP_SITEURL=\${WP_HOME}/wp" >> $apps_path$app_name/.env

  echo "" >> $apps_path$app_name/.env

  echo "# Generate your keys here: https://roots.io/salts.html" >> $apps_path$app_name/.env
  echo "AUTH_KEY='generateme'" >> $apps_path$app_name/.env
  echo "SECURE_AUTH_KEY='generateme'" >> $apps_path$app_name/.env
  echo "LOGGED_IN_KEY='generateme'" >> $apps_path$app_name/.env
  echo "NONCE_KEY='generateme'" >> $apps_path$app_name/.env
  echo "AUTH_SALT='generateme'" >> $apps_path$app_name/.env
  echo "SECURE_AUTH_SALT='generateme'" >> $apps_path$app_name/.env
  echo "LOGGED_IN_SALT='generateme'" >> $apps_path$app_name/.env
  echo "NONCE_SALT='generateme'" >> $apps_path$app_name/.env

  rm $apps_path$app_name/$app_name.txt
}

# SETUP WORDPRESS
function wp_settings () {
  if $CONF_setup_settings ; then
    printf "${BLU}»»» configure settings...${NC}\n"
    if [ -z "$CONF_ee_app_public" ]; then
      cd $apps_path$app_name/htdocs
    fi
    wp user update 1 --first_name=$CONF_admin_first_name --last_name=$CONF_admin_last_name --allow-root
    printf "» timezone:\n"
    wp option update timezone $CONF_timezone --allow-root
    wp option update timezone_string $CONF_timezone --allow-root
    printf "» permalink structure:\n"
    wp rewrite structure "$CONF_wpsettings_permalink_structure" --allow-root
    wp rewrite flush --hard --allow-root
    printf "» description:\n"
    wp option update blogdescription "$CONF_wpsettings_description" --allow-root
    printf "» image sizes:\n"
    wp option update thumbnail_size_w $CONF_wpsettings_thumbnail_width --allow-root
    wp option update thumbnail_size_h $CONF_wpsettings_thumbnail_height --allow-root
    wp option update medium_size_w $CONF_wpsettings_medium_width --allow-root
    wp option update medium_size_h $CONF_wpsettings_medium_height --allow-root
    wp option update large_size_w $CONF_wpsettings_large_width --allow-root
    wp option update large_size_h $CONF_wpsettings_large_height --allow-root
    printf "» custom options override:\n"
    wp option update default_pingback_flag 0 --allow-root
    wp option update default_ping_status 0 --allow-root
    wp option update default_comment_status 0 --allow-root
    wp option update comment_registration 1 --allow-root
    wp option update comment_moderation 1 --allow-root
    wp option update blog_public 0 --allow-root
    wp option update page_on_front 4 --allow-root
    wp option update date_format "d/m/Y" --allow-root
    wp option update time_format "H:i" --allow-root
    wp option update uploads_use_yearmonth_folders 0 --allow-root
    wp option update start_of_week 0 --allow-root
    if ! $CONF_wpsettings_convert_smilies ; then
      printf "» smiles convert:\n"
      wp option update convert_smilies 0 --allow-root
    fi
    if $CONF_wpsettings_page_on_front ; then
      printf "» front page:\n"
      # create and set frontpage
      wp post create --post_type=page --post_title="$CONF_wpsettings_frontpage_name" --post_content='Front Page created by vagrant-easyengine' --post_status=publish --allow-root
      wp option update page_on_front $(wp post list --post_type=page --post_status=publish --posts_per_page=1 --pagename="$CONF_wpsettings_frontpage_name" --field=ID --format=ids --allow-root) --allow-root
      wp option update show_on_front 'page' --allow-root
    fi
  else
    printf "${BLU}>>> skipping settings...${NC}\n"
  fi
}

# INSTALL/REMOVE THEME
function wp_themes () {
  if $CONF_setup_theme ; then
    printf "${BRN}[=== CONFIGURE THEME ===]${NC}\n"
    if [ ! -z "$CONF_theme_url" ]; then
      printf "${BLU}»»» downloading $CONF_theme_name...${NC}\n"
      wp theme install $CONF_theme_url --force --allow-root
    fi
    printf "${BLU}»»» installing/activating $CONF_theme_name...${NC}\n"
    if [ ! -z "$CONF_theme_rename" ]; then
      # rename theme
      printf "${BLU}»»» renaming $CONF_theme_name to $CONF_theme_rename...${NC}\n"
      mv wp-content/themes/$CONF_theme_name wp-content/themes/$CONF_theme_rename
      wp theme activate $CONF_theme_rename --allow-root
    else
      wp theme activate $CONF_theme_name --allow-root
    fi
    if [ ! -z "$CONF_theme_remove" ]; then
      printf "${BLU}»»» removing default themes...${NC}\n"
      # loop trough themes that shall be removed
      for loopedtheme in "${CONF_theme_remove[@]}"
      do :
        #make sure the theme to delete is not the chosen one
        if [ $loopedtheme != $CONF_theme_name ]; then
          printf "${BLU}» removing $loopedtheme...${NC}\n"
          wp theme delete $loopedtheme --allow-root

        fi
      done
      # end loop
    fi

  else
    printf "${BLU}>>> skipping theme installation...${NC}\n"
  fi
}

# PLUGINS
function wp_plugins () {
  if $CONF_setup_plugins ; then
    printf "${BRN}[=== PLUGINS ===]${NC}\n"
    printf "${BLU}»»» removing WP default plugins${NC}\n"

    if [ "$CONF_wpworkflow" == "bedrock" ] || [ ! -z "$CONF_app_repo" ]; then
      printf "${BLU}»»» adding active plugins from wpackagist${NC}\n"
      for entry in "${CONF_plugins_active[@]}"
      do
        package_installer $entry plugin activate
      done

      printf "${BLU}»»» adding inactive plugins from wpackagist${NC}\n"
      for entry in "${CONF_plugins_inactive[@]}"
      do
        package_installer $entry plugin inactive
      done

      printf "${BLU}»»» adding composer require-dev plugins from wpackagist${NC}\n"
      for entry in "${CONF_plugins_require_dev[@]}"
      do
        package_installer $entry plugin inactive --dev
      done
    else
      wp plugin delete akismet --allow-root
      wp plugin delete hello --allow-root
      printf "${BLU}»»» adding active plugins${NC}\n"
      for entry in "${CONF_plugins_active[@]}"
      do
        wp plugin install $entry --activate --allow-root
      done

      printf "${BLU}»»» adding inactive plugins${NC}\n"
      for entry in "${CONF_plugins_inactive[@]}"
      do
        wp plugin install $entry --allow-root
      done
    fi
  else
    printf "${BLU}>>> skipping Plugin installation...${NC}\n"
  fi
}

# CLEANUP±
function wp_clean () {
  if $CONF_setup_cleanup ; then
    printf "${BRN}[=== CLEANUP ===]${NC}\n"
    if $CONF_setup_cleanup_comment ; then
      printf "${BLU}»»» removing default comment...${NC}\n"
      wp comment delete 1 --force --allow-root
    fi
    if $CONF_setup_cleanup_posts ; then
      printf "${BLU}»»» removing default posts...${NC}\n"
      wp post delete 1 2 --force --allow-root
    fi
    if $CONF_setup_cleanup_files ; then
      printf "${BLU}»»» removing WP readme/license files...${NC}\n"
      # delete default files
      if [ -f readme.html ];    then rm readme.html;    fi
      if [ -f license.txt ];    then rm license.txt;    fi
    fi
  else
    printf "${BLU}>>> skipping Cleanup...${NC}\n"
  fi
}

# EXECUTIVE SETUP
####################################################################################################

printf "${BRN}========== VAGRANT-EASYENGINE UP SCRIPTS START ==========${NC}\n\n"

# CHECK FOR ROOT-DIR
if [ ! -d "apps" ]; then
  printf "${BLU}»»» creating root dir \"apps\"...${NC}\n"
  mkdir apps
fi

# CHECK FOR CONF FILE
if [ ! -f "$config_yaml" ]; then
    printf "${RED}Config file not exist, setup aborting!${NC}\n"
fi

# READ CONFIG
eval $(parse_yaml $config_yaml "CONF_")

# CREATE/DELETE/DISABLE/ENABLE APP
if $CONF_setup_ee ; then
  if [ ! -d "$ee_apps_path$app_name" ] && [ "$CONF_ee_site_config" == "create" ]; then
    ee_app_create
    wp_settings
    wp_themes
    wp_plugins
    wp_clean
  fi
  if [ -d "$ee_apps_path$app_name" ] && [ "$CONF_ee_site_config" == "delete" ]; then
    ee_app_delete
  fi
  if [ "$CONF_ee_site_config" == "disable" ] || [ "$CONF_ee_site_config" == "enable" ]; then
    ee_app_switch
  fi
else
  printf "${BLU}>>> skip app creation, check easyengine app setup...${NC}\n"
fi


printf "${BRN}========== VAGRANT-EASYENGINE UP SCRIPTS FINISHED ==========${NC}\n"