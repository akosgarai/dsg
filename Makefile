PHP_VER=7.3
SUDO=sudo
DB_NAME=drupal
DB_USER="drupaluser@localhost"
DB_PW="Drup4l.Us5r"
SITE_NAME="composer-site.com"

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
	curl -sS https://getcomposer.org/installer -o composer-setup.php && sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer && rm composer-setup.php

create_composer_project:
	composer create-project drupal/recommended-project:8.x "${SITE_NAME}"

install_drupal_with_commandline:
	cd "${SITE_NAME}" && composer require drush/drush && ./vendor/drush/drush/drush site:install

install_civicrm_with_commandline:
	cd "${SITE_NAME}" && \
		composer config extra.enable-patching true && \
		composer require civicrm/civicrm-asset-plugin:'~1.1' && \
		composer require -W civicrm/civicrm-core:'~5.29' && \
		composer require civicrm/civicrm-packages:'~5.29' && \
		composer require civicrm/civicrm-drupal-8:'5.29'

