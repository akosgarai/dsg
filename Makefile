PHP_VER=7.3
SUDO=sudo
DB_NAME=drupal
DB_USER="drupaluser@localhost"
DB_PW="Drup4l.Us5r"
SITE_NAME="composer-site.com"
SITE_SLOGAN="This site is build with cli tools."
TARGET_DIR="/var/www/html"
APACHE_CONF_DIR="/etc/apache2"
PROJECTS_BASE_PATH=".."

install_php_deps:
	@./scripts.sh -a "install-php" -s -p "${PHP_VER}"

install_mysql:
	@./scripts.sh -a "install-mysql" -s

start_and_enable_mysql:
	@./scripts.sh -a "configure-mysql" -s

secure_install_mysql:
	@./scripts.sh -a "secure-install-mysql" -s

install_deps: install_php_deps install_mysql

install_apps: start_and_enable_mysql secure_install_mysql

create_db_user:
	@./scripts.sh -a "create-user-mysql" --root-db-user-pw "${MYSQL_DB_PASS}" --db-user-name "${DB_USER}" --db-user-pw "${DB_PW}"

create_database:
	@./scripts.sh -a "create-database-mysql" --root-db-user-pw "${MYSQL_DB_PASS}" --db-user-name "${DB_USER}" --db-name "${DB_NAME}"

install_composer:
	@./scripts.sh -a "install-composer" -s

# this target is for installing the system dependencies, like libs, db, apps.
environment_dependencies: install_deps install_apps create_db_user install_composer

create_composer_project:
	@./scripts.sh -a "create-composer-project" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}"

install_custom_admin_theme:
	cd "${SITE_NAME}" && composer require 'drupal/gin:^3.0' && \
		./vendor/drush/drush/drush theme:enable gin && \
		./vendor/drush/drush/drush config-set system.theme admin gin

install_drupal_with_commandline:
	@./scripts.sh -a "install-drush" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}"
	@./scripts.sh -a "run-drush-install" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}"
	@./scripts.sh -a "run-drush-config-set" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" \
		--drush-config-name "system.site" \
		--drush-config-key "name" \
		--drush-config-value "${SITE_NAME}"
	@./scripts.sh -a "run-drush-config-set" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" \
		--drush-config-name "system.site" \
		--drush-config-key "slogan" \
		--drush-config-value '"${SITE_SLOGAN}"'

install_civicrm_with_commandline:
	@./scripts.sh -a "composer-config" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" \
		--composer-config-key "extra.enable-patching" \
		--composer-config-value "true"
	@./scripts.sh -a "composer-require" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" \
		--composer-project "civicrm/civicrm-asset-plugin:~1.1"
	@./scripts.sh -a "composer-require-with-deps" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" \
		--composer-project "civicrm/civicrm-core:~5.29"
	@./scripts.sh -a "composer-require" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" \
		--composer-project "civicrm/civicrm-packages:~5.29"
	@./scripts.sh -a "composer-require" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" \
		--composer-project "civicrm/civicrm-drupal-8:5.29"
	@./scripts.sh -a "install-civicrm-l10n" -s --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" --civicrm-version "5.29.1"
	@./scripts.sh -a "install-cv" -s
	@./scripts.sh -a "run-cv-install" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" -s

copy_application_to_target:
	@./scripts.sh -a "local-deploy" -s --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" \
		--local-deploy-target "${TARGET_DIR}"

create_apache_config:
	@./scripts.sh -a "apache-config" -s --project-name "${SITE_NAME}" \
		--apache-conf-dir "${APACHE_CONF_DIR}"

# this is the build process. db init, composer project from scratch, drupal install, civicrm install, apache config.
build: create_database create_composer_project install_drupal_with_commandline install_civicrm_with_commandline copy_application_to_target create_apache_config

cleanup_generated_project:
	@./scripts.sh -a "remove-project" -s --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" \
		--apache-conf-dir "${APACHE_CONF_DIR}"  \
		--local-deploy-target "${TARGET_DIR}"

# this target could be used to drop everything and build a brand new application.
rebuild: cleanup_generated_project create_database create_composer_project install_drupal_with_commandline install_civicrm_with_commandline copy_application_to_target create_apache_config
# this target could be used to drop everything and build a brand new application but without civicrm installation.
rebuild-only-drupal: cleanup_generated_project create_database create_composer_project install_drupal_with_commandline copy_application_to_target create_apache_config
