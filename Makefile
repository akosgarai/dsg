PHP_VER=7.3
SUDO=sudo
DB_NAME=drupal
DB_USER="drupaluser@localhost"
DB_PW="Drup4l.Us5r"
SITE_NAME="composer-site.com"
TARGET_DIR="/var/www/html"
APACHE_CONF_DIR="/etc/apache2/sites-available"

install_php_deps:
	@echo "Installing the dependencies for php ${PHP_VER}"
	${SUDO} apt-get install php${PHP_VER} php${PHP_VER}-cli php${PHP_VER}-fpm php${PHP_VER}-mysql php${PHP_VER}-json php${PHP_VER}-opcache php${PHP_VER}-mbstring php${PHP_VER}-xml php${PHP_VER}-gd php${PHP_VER}-curl php${PHP_VER}-intl

install_mysql:
	@echo "Installing mysql"
	${SUDO} apt-get install mysql-server mysql-client

start_and_enable_mysql:
	${SUDO} systemctl start mysql
	${SUDO} systemctl enable mysql

secure_install_mysql:
	${SUDO} mysql_secure_installation

install_deps: install_php_deps install_mysql

install_apps: start_and_enable_mysql secure_install_mysql

create_db_user:
	mysql -u root -p --execute="CREATE USER IF NOT EXISTS ${DB_USER} IDENTIFIED BY '${DB_PW}';"

create_database:
	mysql -u root -p --execute="DROP DATABASE ${DB_NAME}; CREATE DATABASE ${DB_NAME}; GRANT ALL ON ${DB_NAME}.* TO ${DB_USER}; flush privileges;"

install_composer:
	curl -sS https://getcomposer.org/installer -o composer-setup.php && ${SUDO} php composer-setup.php --install-dir=/usr/local/bin --filename=composer && rm composer-setup.php

# this target is for installing the system dependencies, like libs, db, apps.
environment_dependencies: install_deps install_apps create_db_user install_composer

create_composer_project:
	composer create-project drupal/recommended-project:8.x "${SITE_NAME}"

install_custom_admin_theme:
	cd "${SITE_NAME}" && composer require 'drupal/gin:^3.0' && \
		./vendor/drush/drush/drush theme:enable gin && \
		./vendor/drush/drush/drush config-set system.theme admin gin

install_drupal_with_commandline:
	cd "${SITE_NAME}" && composer require drush/drush && ./vendor/drush/drush/drush site:install

install_civicrm_with_commandline:
	cd "${SITE_NAME}" && \
		composer config extra.enable-patching true && \
		composer require civicrm/civicrm-asset-plugin:'~1.1' && \
		composer require -W civicrm/civicrm-core:'~5.29' && \
		composer require civicrm/civicrm-packages:'~5.29' && \
		composer require civicrm/civicrm-drupal-8:'5.29'

copy_application_to_target:
	${SUDO} cp -R "${SITE_NAME}" "${TARGET_DIR}/"
	${SUDO} chown -R www-data: "${TARGET_DIR}/${SITE_NAME}"

create_apache_config:
	# generate config file from template
	cat apache.conf.template | sed "s|%{SITE_NAME}|${SITE_NAME}|" > "${SITE_NAME}.conf"
	# move generated file to apache conf dir.
	${SUDO} mv "${SITE_NAME}.conf" "${APACHE_CONF_DIR}/${SITE_NAME}.conf"
	# setup user / group for the generated file
	${SUDO} chown root:root "${APACHE_CONF_DIR}/${SITE_NAME}.conf"
	# simlink the config
	if [ ! -e ${APACHE_CONF_DIR}/../sites-enabled/${SITE_NAME}.conf ]; then ${SUDO} ln -s ${APACHE_CONF_DIR}/${SITE_NAME}.conf ${APACHE_CONF_DIR}/../sites-enabled/${SITE_NAME}.conf; fi
	# restart apache service
	${SUDO} systemctl restart apache2.service

# this is the build process. db init, composer project from scratch, drupal install, civicrm install, apache config.
build: create_database create_composer_project install_drupal_with_commandline install_civicrm_with_commandline copy_application_to_target create_apache_config

cleanup_generated_project:
	# delete from www dir
	${SUDO} rm -rf "${TARGET_DIR}/${SITE_NAME}"
	# delete from current directory
	${SUDO} rm -rf "${SITE_NAME}"
	# delete apache config file
	${SUDO} rm "${APACHE_CONF_DIR}/../sites-enabled/${SITE_NAME}.conf"
	${SUDO} rm "${APACHE_CONF_DIR}/${SITE_NAME}.conf"
	# restart apache
	${SUDO} systemctl restart apache2.service

# this target could be used to drop everything and build a brand new application.
rebuild: cleanup_generated_project create_database create_composer_project install_drupal_with_commandline install_civicrm_with_commandline copy_application_to_target create_apache_config
