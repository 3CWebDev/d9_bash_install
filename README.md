# Drupal 9 Bash Installer

Automatically installs Drupal 9 from a bash script, including basic site setup & configuration.

## WHAT IT DOES


* Uses custom composer.json file for base contrib modules installations and .htaccess & robots.txt file protection.
** https://github.com/3CWebDev/drupal-composer-install
* Installs composer optimization.
* Creates default directories and sets permissions: files, libraries, custom themes and custom modules.
* Copies default libraries from local storage.
* Copies custom base (Bootstrap) theme.
* Creates .gitignore file.
* Creates the Drupal database.
* Installs Drupal.
* Creates vhost for new site.
* Customizes settings.php file to set private file directory (outside of /web).
* Creates and configure config sync directory (to be used for importing default configurations)
* Imports default configuration from assets.
* Copies custom .htaccess and robots.txt files.
* Initializes new git repo and make intitial commit.
* Creates Let's Encrypt SSL cert using Cert Bot.


