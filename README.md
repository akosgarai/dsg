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

First of all, we need to have the expected php version and extensions, mysql database client, with user and database.
- Run the `make install_deps` for installing the necessary packages with apt-get.
- After this step, run the `make install_apps` for starting and enabling the mysql daemon and running the secure install script.
- For creating the user for our database `make create_db_user` make target is provided.
- The database is deleted and reinitialized with the `make create_database` target.
- Composer could be installed with the `make install_composer` target.
- We need to create an empty composer project with the `make create_composer_project` make target. The name of the new directory is the value of the `SITE_NAME` env.
