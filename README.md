# Drupal site generator - DSG

This tool is writtem for building drupal applications. The tool contains a script file with the commands that I use.

## Motivations

I wanted to play around with the [civicrm](https://civicrm.org/) application, I have checked the documentation, the [system requirements](https://docs.civicrm.org/installation/en/latest/general/requirements/), and i decided to install it on a [drupal 8](https://www.drupal.org/) site. After installing the stuff in the browser a couple of time, I decided to find a way to install it without the browser. According to the [drupal documentation](https://www.drupal.org/docs/develop/using-composer/using-composer-to-install-drupal-and-manage-dependencies) it is possible to install the site with [composer](https://getcomposer.org/) and [drush](https://drushcommands.com/drush-9x/site/site:install/) commands.

## Environment

To be able to use the civicrm and drupal softwares, i had to install some other softwares as dependencies. The civicrm and drupal applications are PHP based, but for civicrm, the v7.3 is recommended, so that I can't use the latest, PHP (7.4). The server machine is an old laptop, with ubuntu 16.04 os. The development server is running on that machine. The necessary packages are already installed there. The following php packages were installed: php7.3 php7.3-cli php7.3-fpm php7.3-mysql php7.3-json php7.3-opcache php7.3-mbstring php7.3-xml php7.3-gd php7.3-curl php7.3-intl
Due to the postgresql database is not supported by the civicrm, the mysql packages were also installed: mysql-server mysql-client

## DSG - Drupal Site Generator CLI

This tool is implemented in the `scripts.sh` file. The tool management is action and flag based. It handles the following actins and flags:

### Actions

For selecting the action what we want to do. Currently the following actions are supported:

- **apache-config** action creates the necessary configuration file, based on the template (apache.conf.template). Then it copies it to the apache directory, enables the config, restarts apache. The sudo flag has to be set for this command.

```bash
./scripts.sh "apache-config" -s --project-name "example.com" --apache-conf-dir "/etc/apache2"
```

- **composer-config** action calls composer config command in the project directory. If the composer application is not installed, it fails.

```bash
./scripts.sh "composer-config" --project-base-path ".." --project-name "example.com" \
	--composer-config-key "extra.enable-patching" --composer-config-value "true"
```

- **composer-require** action calls composer require command in the project directory. If the composer applciation is not installed, it fails.

```bash
./scripts.sh "composer-require" --project-base-path ".." --project-name "example.com" \
	--composer-project "civicrm/civicrm-asset-plugin:~1.1"
```

- **composer-require-with-deps** action calls composer require -W command in the project directory. If the composer applciation is not installed, it fails.

```bash
./scripts.sh "composer-require-with-deps" --project-base-path ".." --project-name "example.com" \
	--composer-project "civicrm/civicrm-asset-plugin:~1.1"
```

- **configure-mysql** action starts and enables the mysql daemon with systemctl command. The sudo flag has to be set for this command.

```bash
./scripts.sh "configure-mysql" -s
```

- **create-composer-project** action calls composer create-project command with drupal/recommended-project:8.x package to the directory.

```bash
./scripts.sh "create-composer-project" --project-base-path ".." --project-name "example.com"
```

- **create-database-mysql** action drops the database if exists, creates a new one, grants all priv. to the database user and flushes the privileges. The action is done in the name of the given mysql user.

```bash
./scripts.sh "create-database-mysql" --root-db-user-pw "passwd" --root-db-user-name "root" \
	--db-user-name "drupaluser" --db-name "drupal"
```

- **create-user-mysql** action creates the db user if not exists and sets its password. The action is done in the name of the given mysql user.

```bash
./scripts.sh "create-user-mysql" --root-db-user-pw "passwd" --root-db-user-name "root" \
	--db-user-name "drupaluser" --db-user-pw "drupaluserpasswd"
```

- **install-civicrm-l10n** action downloads the l10n files of the given civicrm version, unpacks it, copies the necessary files to the civicrm-core directory inside the vendor directory of the project, finally it cleans up. The sudo flag has to be set for this command.

```bash
./scripts.sh "install-civicrm-l10n" -s --project-base-path ".." --project-name "example.com" \
	--civicrm-version "5.29.1"
```

- **install-composer** action downloads the composer installer, installs the composer under the /usr/local/bin directory, then it cleans up. The sudo flag has to be set for this command.

```bash
./scripts.sh "install-composer" -s
```

- **install-cv** action downloads the cv (civicrm cli) application, moves it under /usr/local/bin/ directory, and gives execute permission to it. The sudo flag has to be set for this command.

```bash
./scripts.sh "install-cv" -s
```

- **install-drush** action requires the drush package with composer. Under the hood, it calls composer-require action with drush/drush as package.

```bash
./scripts.sh "install-drush" --project-base-path ".." --project-name "example.com"
```

- **install-mysql** action installs the mysql packages (mysql-server, mysql-client) with apt-get command. The sudo flag has to be set for this command.

```bash
./scripts.sh "install-mysql" -s
```

- **install-php** action install the php and the necessary extensions with apt-get command. The sudo flag has to be set for this command.

```bash
./scripts.sh "install-php" -s -p "7.3"
```

- **local-deploy** action copies the project application to the www directory and setups the owner of the copied directory. The sudo flag has to be set for this command.

```bash
./scripts.sh "local-deploy" -s --project-base-path ".." --project-name "example.com" \
	--local-deploy-target "/var/www/html"
```

- **remove-project** action cleans up the project from the www directory, also from the project directory. Then it removes the apache config from the apache directory if it was deployed and restarts the apache services. The sudo flag has to be set for this command.

```bash
./scripts.sh "remove-project" -s --project-base-path ".." --project-name "example.com" \
	--apache-conf-dir "/etc/apache2"  --local-deploy-target "/var/www/html"
```

- **run-cv-install** action installs the civicrm core module. Unfortunately this action seems to be buggy. After the installation the site is broken. The action changes the permission of the web/sites/default directory in the project directory. It installs the module with the cv application, then it changes back the directory permissions. The action fails if the cv is not installed. The sudo flag has to be set for this command.

```bash
./scripts.sh "run-cv-install" --project-base-path ".." --project-name "example.com" -s
```

- **run-drush-config-set** action calls drush config-set command in the project directory. It sets the given key in the given config to a given value.

```bash
./scripts.sh "run-drush-config-set" --project-base-path ".." --project-name "example.com" \
	--drush-config-name "system.site" --drush-config-key "name" \
	--drush-config-value "The example.com site"
```

- **run-drush-install** action installs the drupal site with the drush tool in the project directory.

```bash
./scripts.sh "run-drush-install" --project-base-path ".." --project-name "example.com"
```

- **secure-install-mysql** action runs the mysql\_secure\_installation command. The sudo flag has to be set for this command.

```bash
./scripts.sh "secure-install-mysql" -s
```

### `--sudo` or `-s`

It enables the sudo mode, that we need for some commands.

### `--php` or `-p`

With this flag, the php version could be updated. It is used in the install-php action.

### `--root-db-user-name`

This flag manages the root user name of the database. It is used in the create-user-mysql and create-database-mysql actions. If this flag is not set in the actions, it defaults to root.

### `--root-db-user-pw`

This flag manages the root user password of the database. It is used in the create-user-mysql and create-database-mysql actions. If this flag is not set in the actions, it defaults to empty string.

### `--db-user-name`

This flag manages the user name of the mysql database user that we create for managing the database of the drupal site. It is used in the create-user-mysql and create-database-mysql actions. If this flag is not set, the actions will fail.

### `--db-user-pw`

This flag manages the password of the mysql database user that we create for managing the database of the drupal site. It is used in the create-user-mysql action. If this flag is not set, the action will fail.

### `--db-name`

This flag manages the name of the mysql database that we create for the drupal site. It is used in the create-database-mysql action. If this flag is not set, it defaults to drupal.

### `--project-base-path`

This flag manages the path of the directory where we have the main directory of the drupal site. It is used in the create-composer-project install-drush run-drush-install run-cv-install run-drush-config-set composer-require composer-require-with-deps composer-config local-deploy remove-project install-civicrm-l10n actions. If this flag is not set, the actions will fail.

### `--project-name`

This flag manages the name of the main directory of the drupal site. It is used in the create-composer-project install-drush run-drush-install run-cv-install run-drush-config-set composer-require composer-require-with-deps composer-config local-deploy apache-config remove-project install-civicrm-l10n actions. If this flag is not set, the actions will fail.

### `--drush-config-name`

This flag manages the config name for the drush config-set command. It is used in the run-drush-config-set action. If this flag is not set, the action will fail.

### `--drush-config-key`

This flag manages the config key for the drush config-set command. It is used in the run-drush-config-set action. If this flag is not set, the action will fail.

### `--drush-config-value`

This flag manages the config value for the drush config-set command. It is used in the run-drush-config-set action. If this flag is not set, it defaults to empy string.

### `--composer-project`

This flag manages the name of the composer project that we want to require. It is used in the composer-require composer-require-with-deps actions. If this flag is not set, the actions will fail.

### `--composer-config-key`

This flag manages the key name for the composer config command. It is used in the composer-config action. If this flag is not set, the action will fail.

### `--composer-config-value`

This flag manages the value for the composer config command. It is used in the composer-config action. If this flag is not set, it defaults to empy string.

### `--local-deploy-target`

This flag manages the target directory of the local deploy, that supposed to be the www directory (eg: /var/www/html). It is used in the local-deploy remove-project actions. If this flag is not set, the actions will fail.

### `--apache-conf-dir`

This flag manages the target directory of the apache configuration (eg: /etc/apache2). It is used in the local-deploy remove-project actions. If this flag is not set, the actions will fail.

### `--civicrm-version`

This flag manages the version string that we are using for installing the civicrm. The l10n file installation needs this. It is used in the install-civicrm-l10n action. If this flag is not set, the action will fail.

### `--site-admin-user-name`

This flag manages the name of the administrator user that is created during the site installation. It is used in the run-drush-install action. If this flag is not set, the action will fail.

### `--site-admin-password`

This flag manages the password of the administrator user that is created during the site installation. It is used in the run-drush-install action. If this flag is not set, the action will fail.

## TODO list

- Naming convention for the action names.

## Make targets

I have implemented a make tool. It was written for gathering the necessary variables into one file.

### Installation steps - local install.

First of all we have to install the system dependencies with the `make environment_dependencies` target. It wraps the following steps / actions:

- install-php
- install-mysql
- configure-mysql
- secure-install-mysql
- create-user-mysql
- install-composer

The next step is the build process, and the `make build` target is given for this. It does the followings:

- create-database-mysql
- create-composer-project
- install-drush
- run-drush-install
- run-drush-config-set
- run-drush-config-set
- local-deploy
- apache-config

After the first installation, where the system deps. are installed, we can skip a couple of steps from the build process. The `make rebuild` target wraps the necessary steps.

### Uninstall - local machine.

Just run the `make cleanup_generated_project` command. It deletes the stuff from the www directory, from the current directory, and also removes the apache config.

### Civicrm

That tool installatin seems to be buggy, but the make targets are provided for building the site with that module. The `make build_with_civicrm` and `make rebuild_with_civicrm` targets are for this.
