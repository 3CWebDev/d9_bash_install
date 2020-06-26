# Drupal 9 Bash Installer

Automatically installs Drupal 9 from a bash script, including basic site setup & configuration.

## WHAT IT DOES


Uses custom composer.json file for base contrib modules installations and .htaccess & robots.txt file protection.

Installs composer optimization.

Creates default directories and sets permissions: files, libraries, custom themes and custom modules.

Copies default libraries from local storage.

Copies custom base (Bootstrap) theme.

Creates .gitignore file.

Creates the Drupal database.

Creates vhost for new site.

Customizes settings.php file to set private file directory (outside of /web).

Creates and configure config sync directory (to be used for importing default configurations)

Copies custom .htaccess and robots.txt files.

