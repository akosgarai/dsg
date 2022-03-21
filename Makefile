PHP_VER ?=7.4
SUDO ?=sudo
DB_NAME ?="dsg"
DB_USER ?="drupaluser@localhost"
DB_PW ?="Drup4l.Us5r"
SITE_NAME ?="dsg-site.com"
SITE_SLOGAN ?="This site is build with cli tools."
TARGET_DIR ?="/var/www/html"
APACHE_CONF_DIR ?="/etc/apache2"
PROJECTS_BASE_PATH ?=".."
SITE_ADMIN_NAME ?="admin"
SITE_ADMIN_PW ?="jPoLvGGGV5"
DB_HOST ?="localhost"
DB_PORT ?=3306
COMPOSER_APP ?=composer1

# this target installs a new theme to the drupal application (with composer), enables it with drush, and sets it as admin theme.
install_custom_admin_theme:
	cd "${SITE_NAME}" && composer require 'drupal/gin:^3.0' && \
		./vendor/drush/drush/drush theme:enable gin && \
		./vendor/drush/drush/drush config-set system.theme admin gin

# this target is for installing the system dependencies, like libs, db, apps.
environment_dependencies:
	@./scripts.sh "install-php" -s -p "${PHP_VER}"
	@./scripts.sh "install-mysql" -s
	@./scripts.sh "configure-mysql" -s
	@./scripts.sh "secure-install-mysql" -s
	@./scripts.sh "create-user-mysql" --root-db-user-pw "${MYSQL_DB_PASS}" --db-user-name "${DB_USER}" --db-user-pw "${DB_PW}"
	@./scripts.sh "install-composer" -s

# this is the build process. db init, composer project from scratch, drupal install, apache config.
build:
	@./scripts.sh "create-database-mysql" --root-db-user-pw "${MYSQL_DB_PASS}" --db-user-name "${DB_USER}" --db-name "${DB_NAME}"
	@./scripts.sh "create-composer-project" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}"
	@./scripts.sh "install-drush" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}"
	@./scripts.sh "run-drush-install" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" \
		--db-name "${DB_NAME}" \
		--db-host "${DB_HOST}" \
		--db-port "${DB_PORT}" \
		--root-db-user-pw "${MYSQL_DB_PASS}" \
		--db-user-name "${DB_USER}" \
		--site-admin-user-name "${SITE_ADMIN_NAME}" \
		--site-admin-password "${SITE_ADMIN_PW}"
	@./scripts.sh "run-drush-config-set" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" \
		--drush-config-name "system.site" \
		--drush-config-key "name" \
		--drush-config-value "${SITE_NAME}"
	@./scripts.sh "run-drush-config-set" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" \
		--drush-config-name "system.site" \
		--drush-config-key "slogan" \
		--drush-config-value '"${SITE_SLOGAN}"'
	@./scripts.sh "local-deploy" -s --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" \
		--local-deploy-target "${TARGET_DIR}"
	@./scripts.sh "add-to-www-user" -s --local-deploy-target "${TARGET_DIR}" --project-name "${SITE_NAME}"
	@./scripts.sh "apache-config" -s --project-base-path "${TARGET_DIR}" --project-name "${SITE_NAME}" \
		--apache-conf-dir "${APACHE_CONF_DIR}"

# this is the build process. db init, composer project from scratch, drupal install, civicrm install, apache config.
civi_build:
	@./scripts.sh "create-database-mysql" --root-db-user-pw "${MYSQL_DB_PASS}" --db-user-name "${DB_USER}" --db-name "${DB_NAME}"
	@./scripts.sh "create-composer-project" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}"
	@./scripts.sh "install-drush" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}"
	@./scripts.sh "local-deploy" -s --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" \
		--local-deploy-target "${TARGET_DIR}"
	@./scripts.sh "run-drush-install" --project-base-path "${TARGET_DIR}" --project-name "${SITE_NAME}" \
		--db-name "${DB_NAME}" \
		--db-host "${DB_HOST}" \
		--db-port "${DB_PORT}" \
		--root-db-user-pw "${MYSQL_DB_PASS}" \
		--db-user-name "${DB_USER}" \
		--site-admin-user-name "${SITE_ADMIN_NAME}" \
		--site-admin-password "${SITE_ADMIN_PW}"
	@./scripts.sh "run-drush-config-set" --project-base-path "${TARGET_DIR}" --project-name "${SITE_NAME}" \
		--drush-config-name "system.site" \
		--drush-config-key "name" \
		--drush-config-value "${SITE_NAME}"
	@./scripts.sh "run-drush-config-set" --project-base-path "${TARGET_DIR}" --project-name "${SITE_NAME}" \
		--drush-config-name "system.site" \
		--drush-config-key "slogan" \
		--drush-config-value '"${SITE_SLOGAN}"'
	@./scripts.sh "composer-config" --project-base-path "${TARGET_DIR}" --project-name "${SITE_NAME}" \
		--composer-config-key "extra.enable-patching" \
		--composer-config-value "true"
	@./scripts.sh "composer-config" --project-base-path "${TARGET_DIR}" --project-name "${SITE_NAME}" \
		--composer-config-key "extra.compile-mode" \
		--composer-config-value "all"
	@./scripts.sh "composer-require" --project-base-path "${TARGET_DIR}" --project-name "${SITE_NAME}" \
		--composer-project "civicrm/civicrm-asset-plugin:~1.1"
	@./scripts.sh "composer-require-with-deps" --project-base-path "${TARGET_DIR}" --project-name "${SITE_NAME}" \
		--composer-project "civicrm/civicrm-core:~5.43"
	@./scripts.sh "composer-require" --project-base-path "${TARGET_DIR}" --project-name "${SITE_NAME}" \
		--composer-project "civicrm/civicrm-packages:~5.43"
	@./scripts.sh "composer-require" --project-base-path "${TARGET_DIR}" --project-name "${SITE_NAME}" \
		--composer-project "civicrm/civicrm-drupal-8:5.43"
	@./scripts.sh "install-civicrm-l10n" -s --project-base-path "${TARGET_DIR}" --project-name "${SITE_NAME}" --civicrm-version "5.43.2"
	@./scripts.sh "install-cv" -s
	@./scripts.sh "run-cv-install" --project-base-path "${TARGET_DIR}" --project-name "${SITE_NAME}" -s
	@./scripts.sh "add-to-www-user" -s --local-deploy-target "${TARGET_DIR}" --project-name "${SITE_NAME}"
	@./scripts.sh "apache-config" -s --project-base-path "${TARGET_DIR}" --project-name "${SITE_NAME}" \
		--apache-conf-dir "${APACHE_CONF_DIR}"

cleanup_generated_project:
	@./scripts.sh "remove-project" -s --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" \
		--apache-conf-dir "${APACHE_CONF_DIR}"  \
		--local-deploy-target "${TARGET_DIR}"

# this target could be used to drop everything and build a brand new application.
rebuild: cleanup_generated_project build

# this target could be used to drop everything and build a brand new application but without civicrm installation.
rebuild_with_civicrm: cleanup_generated_project build-with-civicrm

# this is the build process. db init, composer project from scratch, drupal install, apache config.
build-drupal: cleanup_generated_project
	@./scripts.sh "drupal-build" -s --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" \
		--db-name "${DB_NAME}" \
		--db-user-name "${DB_USER}" \
		--site-admin-user-name "${SITE_ADMIN_NAME}" \
		--site-admin-password "${SITE_ADMIN_PW}" \
		--apache-conf-dir "${APACHE_CONF_DIR}"  \
		--db-host "${DB_HOST}" \
		--db-port "${DB_PORT}" \
		--root-db-user-pw "${MYSQL_DB_PASS}" \
		--local-deploy-target "${TARGET_DIR}" \
		--composer-app "composer"

# this is the build process. db init, composer project from scratch, drupal install, CRM install, apache config.
build-drupal-civicrm:
	@./scripts.sh "drupal-civicrm-build" -s --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" \
		--db-name "${DB_NAME}" \
		--db-user-name "${DB_USER}" \
		--site-admin-user-name "${SITE_ADMIN_NAME}" \
		--site-admin-password "${SITE_ADMIN_PW}" \
		--apache-conf-dir "${APACHE_CONF_DIR}"  \
		--db-host "${DB_HOST}" \
		--db-port "${DB_PORT}" \
		--root-db-user-pw "${MYSQL_DB_PASS}" \
		--local-deploy-target "${TARGET_DIR}" \
		--composer-app "composer"

# this target could be used for building an app in ci environment.
ci_build:
	@./scripts.sh "ci-build" -s --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" \
		--db-name "${DB_NAME}" \
		--db-user-name "${DB_USER}" \
		--site-admin-user-name "${SITE_ADMIN_NAME}" \
		--site-admin-password "${SITE_ADMIN_PW}" \
		--apache-conf-dir "${APACHE_CONF_DIR}"  \
		--db-host "${DB_HOST}" \
		--db-port "${DB_PORT}" \
		--root-db-user-pw "${MYSQL_DB_PASS}" \
		--local-deploy-target "${TARGET_DIR}"
