#!/bin/bash

# Color Reset
Color_Off='\033[0m'       # Reset

Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan


PASS_MYSQL_ROOT='Site@123' # mysql root password
PASS_PHPMYADMIN_APP='Site@123' # can be random, won't be used again
PASS_PHPMYADMIN_ROOT="${PASS_MYSQL_ROOT}" # Your MySQL root pass


update() {
	# Update system repos
	echo -e "\n ${Cyan} Updating package repositories.. ${Color_Off}"
	sudo apt -qq update
}
installLibre() {
	echo -e "\n ${Cyan} Installing Times Font, LibreOffice VScode and Chrome.. ${Color_Off}"
	sudo apt install -y gnome-tweaks curl unzip x264 # libreoffice-gnome libreoffice
	sudo snap install --classic libreoffice
	sudo snap install --classic code
} &> /dev/null

installgit(){
	echo -e "\n ${Cyan} Installing git.. ${Color_Off}"
	sudo apt install git -y
} &> /dev/null

installtimesfont() {
	echo -e "\n ${Cyan} Installing Times Font.. ${Color_Off}"
	echo msttcorefonts msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections
	sudo apt install -y ttf-mscorefonts-installer
	#sudo fc-cache -f -v
} &> /dev/null

installchrome() {
	echo -e "\n ${Cyan} Installing Chrome.. ${Color_Off}"
	wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
	sudo dpkg -i google-chrome-stable_current_amd64.deb
	sudo rm -rf google-chrome-stable_current_amd64.deb
} &> /dev/null

installApache() {
	# Apache
	echo -e "\n ${Cyan} Installing Apache.. ${Color_Off}"
	sudo apt install apache2 apache2-doc libexpat1 ssl-cert
} &> /dev/null


installPHP() {
	echo -e "\n ${Cyan} Installing PHP and common Modules.. ${Color_Off}"
	sudo apt -qy install php php-common libapache2-mod-php php-curl php-dev php-gd php-imagick php-intl php-mbstring php-mysql php-pear php-pspell php-xml php-zip
} &> /dev/null

installMySQL() {
	# MySQL
	echo -e "\n ${Cyan} Installing MySQL.. ${Color_Off}"

	# set password with `debconf-set-selections` so you don't have to enter it in prompt and the script continues
	sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password ${PASS_MYSQL_ROOT}" # new password for the MySQL root user
	sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${PASS_MYSQL_ROOT}" # repeat password for the MySQL root user

	# DEBIAN_FRONTEND=noninteractive # by setting this to non-interactive, no questions will be asked
	DEBIAN_FRONTEND=noninteractive sudo apt -qy install mysql-server mysql-client
}

secureMySQL() {
	# secure MySQL install
	echo -e "\n ${Cyan} Securing MySQL.. ${Color_Off}"

	mysql --user=root --password=${PASS_MYSQL_ROOT} << EOFMYSQLSECURE
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
FLUSH PRIVILEGES;
EOFMYSQLSECURE

}

installPHPMyAdmin() {
	# PHPMyAdmin
	echo -e "\n ${Cyan} Installing PHPMyAdmin.. ${Color_Off}"

	# set answers with `debconf-set-selections` so you don't have to enter it in prompt and the script continues
	sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" # Select Web Server
	sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true" # Configure database for phpmyadmin with dbconfig-common
	sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password ${PASS_PHPMYADMIN_APP}" # Set MySQL application password for phpmyadmin
	sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password ${PASS_PHPMYADMIN_APP}" # Confirm application password
	sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password ${PASS_MYSQL_ROOT}" # MySQL Root Password
	sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/internal/skip-preseed boolean true"

	DEBIAN_FRONTEND=noninteractive sudo apt -qy install phpmyadmin
}


enableMods() {
	echo -e "\n ${Cyan} Enabling Modules.. ${Color_Off}"
	sudo a2enmod rewrite
	sudo phpenmod mbstring # PHP7
} &> /dev/null

setPermissions() {
	echo -e "\n ${Cyan} Setting Ownership for /var/www.. ${Color_Off}"
	sudo chown -R www-data:www-data /var/www
}

restartApache() {
	# Restart Apache
	echo -e "\n ${Cyan} Restarting Apache.. ${Color_Off}"
	sudo service apache2 restart
}

# RUN
update
installLibre
installgit
installtimesfont
installchrome
installApache
installPHP
installMySQL
secureMySQL
installPHPMyAdmin
enableMods
setPermissions
restartApache

echo -e "\n${Green} SUCCESS! MySQL password is: ${PASS_MYSQL_ROOT} ${Color_Off}"
