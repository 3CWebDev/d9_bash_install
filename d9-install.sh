#!/usr/bin/env bash

# Author: Shawn Ostermann 
# Composer Plugins for Drupal Developers


# Read DB credentials from external file
source /var/www/private-vars.cfg

db_user=$(eval echo ${DB_USER})
db_user_pass=$(eval echo ${DB_PASSWORD})
UUID=$(eval echo ${UUID})
WORKING_DIR=$(eval echo ${WORKING_DIR})
ASSETS_DIR=$(eval echo ${ASSETS_DIR})

# Change to working directory
cd $WORKING_DIR

# Get user input
echo -n "Enter dir/site name: " 
read site;


database=$site;
echo $database;

# Create Drupal base via Composer
composer create-project 3cwebdev/drupal-composer-install $site --no-interaction;

cd  $WORKING_DIR/$site

composer install;

# https://github.com/zaporylie/composer-drupal-optimizations
# This composer-plugin contains a set of improvements that makes running heavy duty composer commands (i.e. composer update or composer require) much faster.
composer require zaporylie/composer-drupal-optimizations:^1.1 --dev
#composer require 'drupal/backup_migrate:^5.0'


# Make the required directories.
mkdir ./tmp;
mkdir -p web/sites/default/files;
mkdir -p web/libraries;
mkdir -p web/themes/custom
mkdir -p web/modules/custom;


# Copy libaries assets
cp -a $ASSETS_DIR/libraries/. web/libraries/

# Copy custom module assets
cp -a $ASSETS_DIR/custom_blocks/. web/modules/custom/custom_blocks
cp -a $ASSETS_DIR/ccc_custom/. web/modules/custom/ccc_custom


# Copy custom theme assets
mkdir -p web/themes/custom/ccc_bs;
chmod -R 775 web/themes/custom/ccc_bs;
cp -a $ASSETS_DIR/ccc_bs/. web/themes/custom/ccc_bs


# remove previous file in case it already exists
rm .gitignore;

# Create .gitignore
touch .gitignore;
{ echo '.idea'; \
  echo 'core'; \
	echo 'vendor'; \
	echo 'private'; \
  echo 'web/modules/contrib/*'; \
  echo 'web/themes/contrib/*'; \
  echo 'web/sites/default/*'; \
} >> .gitignore;


# Create database
mysql -u "${db_user}" -p"${db_user_pass}" -e "DROP DATABASE IF EXISTS ${database}; CREATE DATABASE ${database};";

# Install Drupal
cd $WORKING_DIR/$site/web
drush si -y standard --db-url=mysql://"${db_user}:${db_user_pass}"@localhost:3306/${site} --account-name=user --account-pass=password --account-mail=EMAIL@DOMAIN.com;


# Update the file/dir owner.
cd ..;
sudo chown -R www-data:www-data .;


# Create and enable vhost for new sub-domain
echo "Creating a vhost..." 

sitesAvailable='/etc/apache2/sites-available/'
sitesAvailabledomain=$site.tampabayweb.us.conf

# Create virtual host rules file
cd $sitesAvailable
echo "
    <VirtualHost *:80>
      ServerAdmin shawn@ccctampabay.com
      DocumentRoot $WORKING_DIR/$site/web
			ServerName $site.tampabayweb.us
			ServerAlias www.$site.tampabayweb.us      
      <Directory "$WORKING_DIR/$site/web">
        Require all granted
        AllowOverride all
      </Directory>
    </VirtualHost>" > $sitesAvailabledomain
echo -e $"\nNew Virtual Host Created\n"

# Enable new vhost
a2ensite $sitesAvailabledomain
service apache2 reload


# Remove old config_sync setting from end of settings.php file
cd $WORKING_DIR/$site
sed -i '$ d' web/sites/default/settings.php
echo "\$settings['config_sync_directory'] = '../config/sync';" >> web/sites/default/settings.php;
#cp -a $ASSETS_DIR/config/. config/sync/

# Enable Menu Link Config module so we can import menu links via config sync
cd $WORKING_DIR/$site/web
#drush en -y menu_link_config

# Set Drupal config sync dir

cd $WORKING_DIR/$site
mkdir config;
mkdir config/sync;
chown -R www-data:www-data config;
chown -R www-data:www-data config/sync;
chmod -R 775 config;

# Perform config import
drush entity:delete shortcut_set
drush -y pm-uninstall shortcut -y;


cd $WORKING_DIR/$site/web;
drush -y config-set "system.site" uuid $UUID
cd $WORKING_DIR/$site;
cp -a $ASSETS_DIR/sync config
chown -R www-data:www-data config
chmod -R 775 config
drush config:import -y

drush cset user.settings register admin_only
drush pmu ccc_custom
drush en ccc_custom
drush cr;

# Export config files
#drush config:export -y

# Copy our default logo file
cp -a $ASSETS_DIR/3C-logo.png web/sites/default/files

# Copy .htaccess and robots.txt
cp -a $ASSETS_DIR/.htaccess web
cp -a $ASSETS_DIR/robots.txt web

# Create private dir
cd $WORKING_DIR/$site
mkdir private;
sudo chown -R www-data:www-data private;

# update settings.php file with out private directory location
echo "\$settings['file_private_path'] = '../private';" >> web/sites/default/settings.php;
#drush php:eval 'file_save_htaccess("../private")';


# Set file and folder permissions
echo "Setting file and folder permissions...";
find . -type d -exec chmod u=rx,g=rx,o=rx '{}' \;
find . -type f -exec chmod u=r,g=r,o=r '{}' \;

cd  $WORKING_DIR/$site

chmod 775 private;
chmod 775 web/sites/default/files;
chmod -R 775 vendor/drush
chmod -R 775 web/libraries;
chmod -R 775 web/themes/custom;
chmod -R 775 web/modules/custom;


cd web
# Change directory permissions to 755.
find sites/default/files -type d -exec chmod 755 {} +
# Change folder permissions to 644.
find sites/default/files -type f -exec chmod 644 {} +
# Set ownership to webserver.
chown -R www-data:www-data sites/default/files


# Create a new git repo.
git init;
git add .;
git commit -m 'Initial commit';


# Done!
echo "";
echo "";
echo "";
echo "***************************";
echo "Done!";
echo "Please browse to http://$site.tampabayweb.us! DON'T FORGET TO CHANGE THE USER 1 NAME AND PASSWORD!";
echo "";
echo "";
echo "Don't forget to protect htaccess and robots.txt by appending the following after drupal-scaffold\": { in comoser.json";
echo ""
echo "#https://www.drupal.org/docs/develop/using-composer/using-drupals-composer-scaffold#toc_6";
echo "***************************";

# Install Let's Encrypt Cert
echo "2" | certbot --apache -d $site.tampabayweb.us
