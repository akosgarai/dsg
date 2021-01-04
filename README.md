# CiviCRM telepítése Composer használatával.

Szeretnék egy alkalmazást, amely composer használatával inicializál egy Drupal 8 site-ot, amire ezután egy CiviCRM alkalmazást is telepít. Ennek a megvalósítását szeretném scriptek használatával elérni, hogy ezen scripteket felhasználva minél több dolog automatizálható legyen. A lényeg, hogy legyenek scriptek (make targetek) amelyekkel a lokális telepítés elvégezhető (ubuntu rendszeren), illetve github CI pipeline során is futtathatóak legyenek. Szintén szeretnék alap teszteket (lokális és CI-hoz adaptáltakat), melyekkel ellenőrizni tudom a telepítés helyességét.

## Linkek doksikhoz.

- [CiviCRM](https://civicrm.org/)
- [Drupal](https://www.drupal.org/)
- [composer](https://getcomposer.org/)
- [rendszerkövetelmények](https://docs.civicrm.org/installation/en/latest/general/requirements/) CiviCRM-hez.

## Szoftver verziók kiválasztása.

A fő cél a CiviCRM alkalmazás telepítése, tehát ennek a követelményeiből induljunk ki. Ennél a php 7.2 és 7.3 verziók ajánlottak, a php 7.4 még nem, de hamarosan támogatottá válhat. Ebből kiindulva a 7.3-as verziót választottam a php-ból. Ennek megfelelően kell telepíteni a szükséges php-extenision csomagokat is. (sudo apt-get install php7.3 php7.3-cli php7.3-fpm php7.3-mysql php7.3-json php7.3-opcache php7.3-mbstring php7.3-xml php7.3-gd php7.3-curl)
A CiviCRM mysql adatbázist követel meg, úgyhogy ezt a csomagot is telepíteni kell.

## Installation steps - local install.

First of all we have to install the system dependencies with the `make environment_dependencies` target. It wraps the following steps:

- `make install_deps` for installing the necessary packages with apt-get.
- `make install_apps` for starting and enabling the mysql daemon and running the secure install script.
- `make create_db_user` for creating the user for our database.
- `make install_composer` to install the composer application.

The next step is the build process, and the `make build` target is given for this. It does the followings:

- `make create_database` for the database initialization.
- `make create_composer_project` for creating an empty composer project. The name of the new directory is the value of the `SITE_NAME` env.
- `make install_drupal_with_commandline` for installing the drupal site with drush cli tool. Composer can require drush. (it generates the first user: Installation complete.  User name: admin  User password: h3QDB7aBUL)
- `make install_civicrm_with_commandline` for installing the civicrm with composer.
- `make copy_application_to_target` copy application under the www directory.
- `make create_apache_config` setup apache with a newly generated apache config file.

Install a custom theme, and sets it as administration theme. It seems buggy.
- Optional step: install custom theme (gin) as administration theme with `make install_custom_admin_theme` comand.

After the first installation, where the system deps. are installed, we can skip a couple of steps from the build process. The `make rebuild` target wraps the necessary steps.

## Uninstall - local machine.

Just run the `make cleanup_generated_project` command. It deletes the stuff from the www directory, from the current directory, and also removes the apache config.
