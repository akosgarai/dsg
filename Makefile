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
SITE_ADMIN_NAME="admin"
SITE_ADMIN_PW="jPoLvGGGV5"

# this target installs a new theme to the drupal application (with composer), enables it with drush, and sets it as admin theme.
install_custom_admin_theme:
	cd "${SITE_NAME}" && composer require 'drupal/gin:^3.0' && \
		./vendor/drush/drush/drush theme:enable gin && \
		./vendor/drush/drush/drush config-set system.theme admin gin

# this target is for installing the system dependencies, like libs, db, apps.
environment_dependencies:
	@./scripts.sh -a "install-php" -s -p "${PHP_VER}"
	@./scripts.sh -a "install-mysql" -s
	@./scripts.sh -a "configure-mysql" -s
	@./scripts.sh -a "secure-install-mysql" -s
	@./scripts.sh -a "create-user-mysql" --root-db-user-pw "${MYSQL_DB_PASS}" --db-user-name "${DB_USER}" --db-user-pw "${DB_PW}"
	@./scripts.sh -a "install-composer" -s

# this is the build process. db init, composer project from scratch, drupal install, apache config.
build:
	@./scripts.sh -a "create-database-mysql" --root-db-user-pw "${MYSQL_DB_PASS}" --db-user-name "${DB_USER}" --db-name "${DB_NAME}"
	@./scripts.sh -a "create-composer-project" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}"
	@./scripts.sh -a "install-drush" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}"
	@./scripts.sh -a "run-drush-install" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" \
		--db-name "${DB_NAME}" \
		--root-db-user-pw "${MYSQL_DB_PASS}" \
		--db-user-name "${DB_USER}"
	@./scripts.sh -a "run-drush-config-set" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" \
		--drush-config-name "system.site" \
		--drush-config-key "name" \
		--drush-config-value "${SITE_NAME}"
	@./scripts.sh -a "run-drush-config-set" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" \
		--drush-config-name "system.site" \
		--drush-config-key "slogan" \
		--drush-config-value '"${SITE_SLOGAN}"'
	@./scripts.sh -a "local-deploy" -s --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" \
		--local-deploy-target "${TARGET_DIR}"
	@./scripts.sh -a "apache-config" -s --project-name "${SITE_NAME}" \
		--apache-conf-dir "${APACHE_CONF_DIR}"

# this is the build process. db init, composer project from scratch, drupal install, civicrm install, apache config.
build_with_civicrm:
	@./scripts.sh -a "create-database-mysql" --root-db-user-pw "${MYSQL_DB_PASS}" --db-user-name "${DB_USER}" --db-name "${DB_NAME}"
	@./scripts.sh -a "create-composer-project" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}"
	@./scripts.sh -a "install-drush" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}"
	@./scripts.sh -a "run-drush-install" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" \
		--db-name "${DB_NAME}" \
		--root-db-user-pw "${MYSQL_DB_PASS}" \
		--db-user-name "${DB_USER}"
	@./scripts.sh -a "run-drush-config-set" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" \
		--drush-config-name "system.site" \
		--drush-config-key "name" \
		--drush-config-value "${SITE_NAME}"
	@./scripts.sh -a "run-drush-config-set" --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" \
		--drush-config-name "system.site" \
		--drush-config-key "slogan" \
		--drush-config-value '"${SITE_SLOGAN}"'
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
	@./scripts.sh -a "local-deploy" -s --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" \
		--local-deploy-target "${TARGET_DIR}"
	@./scripts.sh -a "apache-config" -s --project-name "${SITE_NAME}" \
		--apache-conf-dir "${APACHE_CONF_DIR}"

cleanup_generated_project:
	@./scripts.sh -a "remove-project" -s --project-base-path "${PROJECTS_BASE_PATH}" --project-name "${SITE_NAME}" \
		--apache-conf-dir "${APACHE_CONF_DIR}"  \
		--local-deploy-target "${TARGET_DIR}"

# this target could be used to drop everything and build a brand new application.
rebuild: cleanup_generated_project build

# this target could be used to drop everything and build a brand new application but without civicrm installation.
rebuild_with_civicrm: cleanup_generated_project build-with-civicrm
