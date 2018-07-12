#!/usr/bin/env bash

app_check=/var/www/$vee_app

project_create () {
    sudo service nginx start
    sudo yes | sudo ee site create $vee_app --php7 --mysql
}

project_pull () {
    sudo rm -rf /var/www/$vee_app/*
    cd /var/www/$vee_app && git init && git remote add origin $vee_repo
    sudo -u www-data -i git --git-dir=/var/www/$vee_app/.git --work-tree=/var/www/$vee_app pull --depth=1 origin master
}

project_install () {
    composer install
}

env_init () {

    vee_tmp=/var/www/$vee_app
    ee site info $vee_app > $vee_tmp/$vee_app.txt

    mv $vee_tmp/.env $vee_tmp/.env.old

    db_details=("DB_NAME" "DB_USER" "DB_PASS")
    for i in "${!db_details[@]}"; do
        db_data=$(grep "${db_details[$i]}" "$vee_tmp/$vee_app.txt")
        db_data=${db_data// /=}
        db_data=${db_data//[[:blank:]]/}
        db_data=${db_data//DB_PASS/DB_PASSWORD}
        echo $db_data >> $vee_tmp/.env
    done

    echo "" >> $vee_tmp/.env

    echo "# Optional variables" >> $vee_tmp/.env
    echo "# DB_HOST=localhost" >> $vee_tmp/.env
    echo "# DB_PREFIX=wp_" >> $vee_tmp/.env

    echo "" >> $vee_tmp/.env

    echo "WP_ENV=development" >> $vee_tmp/.env
    echo "WP_HOME=http://$vee_app" >> $vee_tmp/.env
    echo "WP_SITEURL=\${WP_HOME}/wp" >> $vee_tmp/.env

    echo "" >> $vee_tmp/.env

    echo "# Generate your keys here: https://roots.io/salts.html" >> $vee_tmp/.env
    echo "AUTH_KEY='generateme'" >> $vee_tmp/.env
    echo "SECURE_AUTH_KEY='generateme'" >> $vee_tmp/.env
    echo "LOGGED_IN_KEY='generateme'" >> $vee_tmp/.env
    echo "NONCE_KEY='generateme'" >> $vee_tmp/.env
    echo "AUTH_SALT='generateme'" >> $vee_tmp/.env
    echo "SECURE_AUTH_SALT='generateme'" >> $vee_tmp/.env
    echo "LOGGED_IN_SALT='generateme'" >> $vee_tmp/.env
    echo "NONCE_SALT='generateme'" >> $vee_tmp/.env

    rm $vee_tmp/$vee_app.txt

    if [ "$vee_type" == "bedrock" ]; then
        ln -s web htdocs
    fi
}

if [ ! -d "$app_check" ]; then
    project_create
    if [ ! -z "$vee_repo" ]; then
        project_pull
    fi

    if [ "$vee_type" == "bedrock" ] || [ "$vee_type" == "skeleton" ]; then
        env_init
        project_install
    fi
fi
