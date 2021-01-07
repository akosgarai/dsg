#!/bin/bash

# install PHP and the necessary extensions.
function installPhp {
	local version=$1
	local sudo=$2
	echo "Installing the dependencies for php ${version}"
	${sudo} apt-get install php${version} php${version}-cli php${version}-fpm php${version}-mysql php${version}-json php${version}-opcache php${version}-mbstring php${version}-xml php${version}-gd php${version}-curl php${version}-intl
}

# install mysql.
function installMysql {
	local sudo=$1
	echo "Installing mysql"
	${sudo} apt-get install mysql-server mysql-client
}

# install cv - civicrm installer.
function installCv {
	local sudo=$1
	if ! command -v cv; then
		echo "Installing cv - CiviCRM installer"
		curl -LsS https://download.civicrm.org/cv/cv.phar -o cv
		${sudo} mv cv /usr/local/bin/
		${sudo} chmod +x /usr/local/bin/cv
	fi
}

# enable mysql service daemon
function startEnableMysqlDeamon {
	local sudo=$1
	echo "Starting mysql daemon."
	${sudo} systemctl start mysql
	echo "Enable mysql daemon."
	${SUDO} systemctl enable mysql
}

# wrapper for mysql secure install process.
function secureInstallMysql {
	local sudo=$1
	echo "Running mysql_secure_installation command."
	${sudo} mysql_secure_installation
}

# Creates a user for managing the database. It needs the root
# user name and password for having the grants to create the user.
# It only creates the user if it does not exist.
function createUserMysql {
	local rootUserName=$1
	local rootUserPW=$2
	local newUserName=$3
	local newUserPW=$4
	echo "Creating ${newUserName}/${newUserPW} user if not exists."
	mysql -u "${rootUserName}" "-p${rootUserPW}" --execute="CREATE USER IF NOT EXISTS ${newUserName} IDENTIFIED BY '${newUserPW}';"
}

# It drops the old database, creates a new one, sets the 
# grants for the db user, flushes the privileges.
function createDatabaseMysql {
	local rootUserName=$1
	local rootUserPW=$2
	local siteUserName=$3
	local dbName=$4
	echo "Creating ${dbName} database and giving all grants to ${siteUserName} user."
	mysql -u "${rootUserName}" -p"${rootUserPW}" --execute="DROP DATABASE ${dbName}; CREATE DATABASE ${dbName}; GRANT ALL ON ${dbName}.* TO ${siteUserName}; flush privileges;"
}

# It installs the composer under the /usr/local/bin dir.
function installComposer {
	local sudo=$1
	# download the installer
	curl -sS https://getcomposer.org/installer -o composer-setup.php 
	# run installer
	${sudo} php composer-setup.php --install-dir=/usr/local/bin --filename=composer
	# delete installer
	rm composer-setup.php
}

# It creates a composer project with a given name to the given directory.
# The new project is based on the drupal recommended-project 8.x version.
# In case of missing compser application, in prints error to the stdout.
function createComposerProject {
	local targetDir=$1
	local projectName=$2
	if ! command -v composer; then
		echo "Composer command is not installed. Use the './scripts.sh -a "install-composer" -s' command to install it." >&2
		exit 1
	fi
	cd "${targetDir}"
	composer create-project drupal/recommended-project:8.x "${projectName}"
}

# It installs the drush command to the previously created composer project.
function installDrushCommand {
	local targetDir=$1
	local projectName=$2
	echo "Installing drush with composer"
	composerRequire "${targetDir}" "${projectName}" "drush/drush"
}

# It runs the drush install command in the given composer project.
function runDrushInstall {
	local targetDir=$1
	local projectName=$2
	if ! command -v composer; then
		echo "Composer command is not installed. Use the './scripts.sh -a "install-composer" -s' command to install it." >&2
		exit 1
	fi
	cd "${targetDir}/${projectName}"
	echo "Installing drupal site with drush"
	./vendor/drush/drush/drush site:install 
}

# It runs the cv install command in the given composer project.
function runCvInstall {
	local sudo=$1
	local targetDir=$2
	local projectName=$3
	if ! command -v cv; then
		echo "cv command is not installed. Use the './scripts.sh -a "install-cv" -s' command to install it." >&2
		exit 1
	fi
	cd "${targetDir}/${projectName}"
	echo "Making the directory writable"
	${sudo} chmod +w web/sites/default
	echo "Installing CiviCRM with cv"
	cv core:install --cms-base-url="http://localhost/${projectName}/web" --lang="hu_HU"
	echo "revoke the write permission"
	${sudo} chmod -w web/sites/default
}

# It runs the drush config set command in the given composer project with the given parameters.
function runDrushConfigSet {
	local targetDir=$1
	local projectName=$2
	local configName=$3
	local configKey=$4
	local configValue=$5
	cd "${targetDir}/${projectName}"
	echo "Setting the ${configName} ${configKey} to ${configValue}"
	./vendor/drush/drush/drush config-set "${configName}" "${configKey}" "${configValue}"
}

# It runs composer require command with the given package.
function composerRequire {
	local targetDir=$1
	local projectName=$2
	local composerPackage=$3
	if ! command -v composer; then
		echo "Composer command is not installed. Use the './scripts.sh -a "install-composer" -s' command to install it." >&2
		exit 1
	fi
	cd "${targetDir}/${projectName}"
	echo "Require ${composerPackage}."
	composer require "${composerPackage}"
}
function composerRequireWithDependencies {
	local targetDir=$1
	local projectName=$2
	local composerPackage=$3
	if ! command -v composer; then
		echo "Composer command is not installed. Use the './scripts.sh -a "install-composer" -s' command to install it." >&2
		exit 1
	fi
	cd "${targetDir}/${projectName}"
	echo "Require ${composerPackage}."
	composer require -W "${composerPackage}"
}
# It runs the composer config command in the given composer project with the given parameters.
function composerConfig {
	local targetDir=$1
	local projectName=$2
	local configKey=$3
	local configValue=$4
	if ! command -v composer; then
		echo "Composer command is not installed. Use the './scripts.sh -a "install-composer" -s' command to install it." >&2
		exit 1
	fi
	cd "${targetDir}/${projectName}"
	echo "Setting the composer ${configKey} to ${configValue}"
	composer config "${configKey}" "${configValue}"
}

# It deploys the application on the local machine. (copy from composer dir to www dir)
function localDeploy {
	local targetDir=$1
	local projectName=$2
	local wwwdir=$3
	local sudo=$4
	echo "Moving project ${targetDir}/${projectName} to ${wwwdir}/"
	${sudo} cp -R "${targetDir}/${projectName}" "${wwwdir}/"
	echo "Changing owner ${wwwdir}/${projectName} to www-data."
	${sudo} chown -R www-data: "${wwwdir}/${projectName}"
}

# It generates a configuration file from template, and moves it to the apache config dir. It also enables the config.
function apacheConfig {
	local sudo=$1
	local projectName=$2
	local apachedir=$3
	echo "Generate apache config from template."
	cat apache.conf.template | sed "s|%{SITE_NAME}|${projectName}|" > "${projectName}.conf"
	echo "Move the generated ${projectName}.conf file to apache conf ${apachedir}/sites-available/ directory."
	${sudo} mv "${projectName}.conf" "${apachedir}/sites-available/${projectName}.conf"
	echo "Setup apache config owner to root."
	${sudo} chown root:root "${apachedir}/sites-available/${projectName}.conf"
	echo "Simlink to sites-enabled."
	if [ ! -e ${apachedir}/sites-enabled/${projectName}.conf ]; then 
		${sudo} ln -s "${apachedir}/sites-available/${projectName}.conf" "${apachedir}/sites-enabled/${projectName}.conf"
	fi
	echo "Restarting apache service."
	${sudo} systemctl restart apache2.service
}

# It downloads and puts the civicrm l10n files to the right place.
function installCivicrml10n {
	local sudo=$1
	local targetDir=$2
	local projectName=$3
	local version=$4
	curl -LsS "https://download.civicrm.org/civicrm-${version}-l10n.tar.gz" -o "civicrm.${version}-l10n.tar.gz"
	tar -zxvf "civicrm.${version}-l10n.tar.gz"
	cp -R civicrm/l10n/ "${targetDir}/${projectName}/vendor/civicrm/civicrm-core/"
	cp -R civicrm/sql "${targetDir}/${projectName}/vendor/civicrm/civicrm-core/"
	rm -rf civicrm/
	rm "civicrm.${version}-l10n.tar.gz"
}

# It deletes the directories and files connected to the given project.
function removeProject {
	local sudo=$1
	local targetDir=$2
	local projectName=$3
	local wwwdir=$4
	local apachedir=$5
	# delete from www dir
	${sudo} rm -rf "${wwwdir}/${projectName}"
	# delete from project directory
	${sudo} rm -rf "${targetDir}/${projectName}"
	# delete apache config file
	local serviceRestart=""
	if [ -e "${apachedir}/sites-enabled/${projectName}.conf" ]; then 
		serviceRestart="1"
		${sudo} rm "${apachedir}/sites-enabled/${projectName}.conf"
	fi
	if [ -e "${apachedir}/sites-available/${projectName}.conf" ]; then 
		serviceRestart="1"
		${sudo} rm "${apachedir}/sites-available/${projectName}.conf"
	fi
	# restart apache
	if [ "${serviceRestart}" != "" ]; then
		${sudo} systemctl restart apache2.service
	fi
}

ACTION=""
SUDO=""
PHP_VER=7.3
DB_ROOT_USER_NAME="root"
# it is kept as empty string, to fail by default.
DB_ROOT_USER_PW=""
DB_USER_NAME=""
DB_USER_PW=""
DB_NAME="drupal"
PROJECT_BASE_PATH=""
PROJECT_NAME=""
DRUSH_CONFIG_NAME=""
DRUSH_CONFIG_KEY=""
DRUSH_CONFIG_VALUE=""
COMPOSER_PROJECT=""
COMPOSER_CONFIG_KEY=""
COMPOSER_CONFIG_VALUE=""
LOCAL_DEPLOY_TARGET=""
APACHE_CONF_DIR=""
CIVICRM_VERSION=""

# manual flag parsing. for the command input.
while [ ! $# -eq 0 ]; do
	case "$1" in
		-a | --action)
			if [ "$2" ]; then
				ACTION=$2
				shift
			fi
			;;
		-p | --php)
			if [ "$2" ]; then
				PHP_VER=$2
				shift
			fi
			;;
		--root-db-user-name)
			if [ "$2" ]; then
				DB_ROOT_USER_NAME=$2
				shift
			fi
			;;
		--root-db-user-pw)
			if [ "$2" ]; then
				DB_ROOT_USER_PW=$2
				shift
			fi
			;;
		--db-user-name)
			if [ "$2" ]; then
				DB_USER_NAME=$2
				shift
			fi
			;;
		--db-user-pw)
			if [ "$2" ]; then
				DB_USER_PW=$2
				shift
			fi
			;;
		--db-name)
			if [ "$2" ]; then
				DB_NAME=$2
				shift
			fi
			;;
		--project-base-path)
			if [ "$2" ]; then
				PROJECT_BASE_PATH=$2
				shift
			fi
			;;
		--project-name)
			if [ "$2" ]; then
				PROJECT_NAME=$2
				shift
			fi
			;;
		--drush-config-name)
			if [ "$2" ]; then
				DRUSH_CONFIG_NAME=$2
				shift
			fi
			;;
		--drush-config-key)
			if [ "$2" ]; then
				DRUSH_CONFIG_KEY=$2
				shift
			fi
			;;
		--drush-config-value)
			if [ "$2" ]; then
				DRUSH_CONFIG_VALUE=$2
				shift
			fi
			;;
		--composer-project)
			if [ "$2" ]; then
				COMPOSER_PROJECT=$2
				shift
			fi
			;;
		--composer-config-key)
			if [ "$2" ]; then
				COMPOSER_CONFIG_KEY=$2
				shift
			fi
			;;
		--composer-config-value)
			if [ "$2" ]; then
				COMPOSER_CONFIG_VALUE=$2
				shift
			fi
			;;
		--local-deploy-target)
			if [ "$2" ]; then
				LOCAL_DEPLOY_TARGET=$2
				shift
			fi
			;;
		--apache-conf-dir)
			if [ "$2" ]; then
				APACHE_CONF_DIR=$2
				shift
			fi
			;;
		--civicrm-version)
			if [ "$2" ]; then
				CIVICRM_VERSION=$2
				shift
			fi
			;;
		-s | --sudo)
			SUDO="sudo"
			;;
		*)
			echo "Invalid parameter name '$1'"
			exit 1
			;;
	esac
	shift
done

# handle action parameter. If it is invalid, it has to print error message.
case "${ACTION}" in
	install-cv)
		if [ "${SUDO}" == "" ]; then
			echo "You have to set the sudo (-s or --sudo) to be able to install composer."
			exit 1
		fi
		installCv "${SUDO}"
		;;
	install-composer)
		if [ "${SUDO}" == "" ]; then
			echo "You have to set the sudo (-s or --sudo) to be able to install composer."
			exit 1
		fi
		installComposer "${SUDO}"
		;;
	install-mysql)
		if [ "${SUDO}" == "" ]; then
			echo "You have to set the sudo (-s or --sudo) to be able to install mysql."
			exit 1
		fi
		installMysql "${SUDO}"
		;;
	configure-mysql)
		if [ "${SUDO}" == "" ]; then
			echo "You have to set the sudo (-s or --sudo) to be able to configure mysql."
			exit 1
		fi
		startEnableMysqlDeamon "${SUDO}"
		;;
	secure-install-mysql)
		if [ "${SUDO}" == "" ]; then
			echo "You have to set the sudo (-s or --sudo) to be able to secure install mysql."
			exit 1
		fi
		secureInstallMysql ${SUDO} 
		;;
	create-user-mysql)
		if [ "${DB_USER_NAME}" == "" ] || [ "${DB_USER_PW}" == "" ]; then
			echo "You have to set the db user credentials (--db-user-name and --db-user-pw) to be able to create mysql user."
			exit 1
		fi
		createUserMysql "${DB_ROOT_USER_NAME}" "${DB_ROOT_USER_PW}" "${DB_USER_NAME}" "${DB_USER_PW}"
		;;
	create-database-mysql)
		if [ "${DB_USER_NAME}" == "" ] || [ "${DB_NAME}" == "" ]; then
			echo "You have to set the db user name and db name (--db-user-name and --db-name) to be able to create mysql database."
			exit 1
		fi
		createDatabaseMysql "${DB_ROOT_USER_NAME}" "${DB_ROOT_USER_PW}" "${DB_USER_NAME}" "${DB_NAME}"
		;;
	install-php)
		if [ "${SUDO}" == "" ]; then
			echo "You have to set the sudo (-s or --sudo) to be able to install php."
			exit 1
		fi
		installPhp "${PHP_VER}" "${SUDO}"
		;;
	create-composer-project)
		if [ "${PROJECT_BASE_PATH}" == "" ] || [ "${PROJECT_NAME}" == "" ]; then
			echo "You have to set both the project base path (--project-base-path) and the project name (--project-name) flags."
			exit 1
		fi
		createComposerProject "${PROJECT_BASE_PATH}" "${PROJECT_NAME}"
		;;
	install-drush)
		if [ "${PROJECT_BASE_PATH}" == "" ] || [ "${PROJECT_NAME}" == "" ]; then
			echo "You have to set both the project base path (--project-base-path) and the project name (--project-name) flags."
			exit 1
		fi
		installDrushCommand "${PROJECT_BASE_PATH}" "${PROJECT_NAME}"
		;;
	run-drush-install)
		if [ "${PROJECT_BASE_PATH}" == "" ] || [ "${PROJECT_NAME}" == "" ]; then
			echo "You have to set both the project base path (--project-base-path) and the project name (--project-name) flags."
			exit 1
		fi
		runDrushInstall "${PROJECT_BASE_PATH}" "${PROJECT_NAME}"
		;;
	run-cv-install)
		if [ "${SUDO}" == "" ]; then
			echo "You have to set the sudo (-s or --sudo) to be able to run cv install."
			exit 1
		fi
		if [ "${PROJECT_BASE_PATH}" == "" ] || [ "${PROJECT_NAME}" == "" ]; then
			echo "You have to set both the project base path (--project-base-path) and the project name (--project-name) flags."
			exit 1
		fi
		runCvInstall "${SUDO}" "${PROJECT_BASE_PATH}" "${PROJECT_NAME}"
		;;
	run-drush-config-set)
		if [ "${PROJECT_BASE_PATH}" == "" ] || [ "${PROJECT_NAME}" == "" ]; then
			echo "You have to set both the project base path (--project-base-path) and the project name (--project-name) flags."
			exit 1
		fi
		if [ "${DRUSH_CONFIG_NAME}" == "" ] || [ "${DRUSH_CONFIG_KEY}" == "" ]; then
			echo "You have to set both the config name (--drush-config-name) and the config key name (--drush-config-key) flags."
			exit 1
		fi
		runDrushConfigSet "${PROJECT_BASE_PATH}" "${PROJECT_NAME}" "${DRUSH_CONFIG_NAME}" "${DRUSH_CONFIG_KEY}" "${DRUSH_CONFIG_VALUE}"
		;;
	composer-require)
		if [ "${PROJECT_BASE_PATH}" == "" ] || [ "${PROJECT_NAME}" == "" ]; then
			echo "You have to set both the project base path (--project-base-path) and the project name (--project-name) flags."
			exit 1
		fi
		if [ "${COMPOSER_PROJECT}" == "" ]; then
			echo "You have to set the composer project (--composer-project \"drush/drush\") flag."
		fi
		composerRequire "${PROJECT_BASE_PATH}" "${PROJECT_NAME}" "${COMPOSER_PROJECT}" 
		;;
	composer-require-with-deps)
		if [ "${PROJECT_BASE_PATH}" == "" ] || [ "${PROJECT_NAME}" == "" ]; then
			echo "You have to set both the project base path (--project-base-path) and the project name (--project-name) flags."
			exit 1
		fi
		if [ "${COMPOSER_PROJECT}" == "" ]; then
			echo "You have to set the composer project (--composer-project \"drush/drush\") flag."
		fi
		composerRequireWithDependencies "${PROJECT_BASE_PATH}" "${PROJECT_NAME}" "${COMPOSER_PROJECT}" 
		;;
	composer-config)
		if [ "${PROJECT_BASE_PATH}" == "" ] || [ "${PROJECT_NAME}" == "" ]; then
			echo "You have to set both the project base path (--project-base-path) and the project name (--project-name) flags."
			exit 1
		fi
		if [ "${COMPOSER_CONFIG_KEY}" == "" ]; then
			echo "You have to set the composer config key (--composer-config-key) flag."
		fi
		composerConfig "${PROJECT_BASE_PATH}" "${PROJECT_NAME}" "${COMPOSER_CONFIG_KEY}" "${COMPOSER_CONFIG_VALUE}" 
		;;
	local-deploy)
		if [ "${SUDO}" == "" ]; then
			echo "You have to set the sudo (-s or --sudo) to be able to deploy the application locally."
			exit 1
		fi
		if [ "${PROJECT_BASE_PATH}" == "" ] || [ "${PROJECT_NAME}" == "" ]; then
			echo "You have to set both the project base path (--project-base-path) and the project name (--project-name) flags."
			exit 1
		fi
		if [ "${LOCAL_DEPLOY_TARGET}" == "" ]; then
			echo "You have to set the target of the local deploy (--local-deploy-target) flag."
		fi
		localDeploy "${PROJECT_BASE_PATH}" "${PROJECT_NAME}" "${LOCAL_DEPLOY_TARGET}" "${SUDO}"
		;;
	apache-config)
		if [ "${SUDO}" == "" ]; then
			echo "You have to set the sudo (-s or --sudo) to be able to deploy the application locally."
			exit 1
		fi
		if  [ "${PROJECT_NAME}" == "" ]; then
			echo "You have to set the project name (--project-name) flag."
			exit 1
		fi
		if  [ "${APACHE_CONF_DIR}" == "" ]; then
			echo "You have to set the apache configuration directory (--apache-conf-dir) flag."
			exit 1
		fi
		apacheConfig "${SUDO}" "${PROJECT_NAME}" "${APACHE_CONF_DIR}"
		;;
	remove-project)
		if [ "${SUDO}" == "" ]; then
			echo "You have to set the sudo (-s or --sudo) to be able to deploy the application locally."
			exit 1
		fi
		if  [ "${APACHE_CONF_DIR}" == "" ]; then
			echo "You have to set the apache configuration directory (--apache-conf-dir) flag."
			exit 1
		fi
		if [ "${LOCAL_DEPLOY_TARGET}" == "" ]; then
			echo "You have to set the target of the local deploy (--local-deploy-target) flag."
		fi
		if [ "${PROJECT_BASE_PATH}" == "" ] || [ "${PROJECT_NAME}" == "" ]; then
			echo "You have to set both the project base path (--project-base-path) and the project name (--project-name) flags."
			exit 1
		fi
		removeProject "${SUDO}" "${PROJECT_BASE_PATH}" "${PROJECT_NAME}" "${LOCAL_DEPLOY_TARGET}" "${APACHE_CONF_DIR}"
		;;
	install-civicrm-l10n)
		if [ "${SUDO}" == "" ]; then
			echo "You have to set the sudo (-s or --sudo) to be able to install composer."
			exit 1
		fi
		if [ "${PROJECT_BASE_PATH}" == "" ] || [ "${PROJECT_NAME}" == "" ]; then
			echo "You have to set both the project base path (--project-base-path) and the project name (--project-name) flags."
			exit 1
		fi
		if [ "${CIVICRM_VERSION}" == "" ]; then
			echo "You have to set the civicrm version (--civicrm-version) flags."
			exit 1
		fi
		installCivicrml10n "${SUDO}" "${PROJECT_BASE_PATH}" "${PROJECT_NAME}" "${CIVICRM_VERSION}"
		;;
	*)
		echo "Invalid action name: '${ACTION}'"
		exit 1
		;;
esac
