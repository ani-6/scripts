#!/bin/bash

# Color Reset
Color_Off='\033[0m'       # Reset

Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan


PASS_MYSQL_ROOT='SqlAdmin987' # mysql root password
PASS_PHPMYADMIN_APP='SqlAdmin987' # can be random, won't be used again
PASS_PHPMYADMIN_ROOT="${PASS_MYSQL_ROOT}" # Your MySQL root pass


update() {
	# Update system repos
	echo -e "\n ${Cyan} Updating package repositories.. ${Color_Off}"
	sudo apt -qq update
}

install_devTools(){
    echo -e "\n ${Cyan} Installing Curl, Unzip and tools... ${Color_Off}"
	{ 
		sudo apt install -y curl unzip x264 net-tools python3-dev default-libmysqlclient-dev
	} &> /dev/null
	echo -e "\n ${Green} Done.. ${Color_Off}"
}

install_git(){
	echo -e "\n ${Cyan} Installing git.. ${Color_Off}"
	{
		sudo apt install git -y
	} &> /dev/null
	echo -e "\n ${Green} Done.. ${Color_Off}"
}

install_vscode(){
    echo -e "\n ${Cyan} Installing VScode.. ${Color_Off}"
	{ 
		sudo snap install --classic code
	} &> /dev/null
	echo -e "\n ${Green} Done.. ${Color_Off}"
}

install_apache2() {
	# Apache
	echo -e "\n ${Cyan} Installing Apache2.. ${Color_Off}"
	{
		sudo apt install -y apache2 apache2-doc libexpat1 ssl-cert
	} &> /dev/null
	echo -e "\n ${Green} Done.. ${Color_Off}"
}

install_php() {
	echo -e "\n ${Cyan} Installing PHP and common Modules.. ${Color_Off}"
	{
		sudo apt -qy install php php-common libapache2-mod-php php-curl php-dev php-gd php-imagick php-intl php-mbstring php-mysql php-pear php-pspell php-xml php-zip
	} &> /dev/null
	echo -e "\n ${Green} Done.. ${Color_Off}"
}

install_mysql() {
	# MySQL
	echo -e "\n ${Cyan} Installing MySQL.. ${Color_Off}"
	{
		# set password with `debconf-set-selections` so you don't have to enter it in prompt and the script continues
		sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password ${PASS_MYSQL_ROOT}" # new password for the MySQL root user
		sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${PASS_MYSQL_ROOT}" # repeat password for the MySQL root user

		# DEBIAN_FRONTEND=noninteractive # by setting this to non-interactive, no questions will be asked
		DEBIAN_FRONTEND=noninteractive sudo apt -qy install mysql-server mysql-client
	} &> /dev/null
	echo -e "\n ${Green} Done.. ${Color_Off}"
}

secure_mysql() {
	# secure MySQL install
	echo -e "\n ${Cyan} Securing MySQL.. ${Color_Off}"

	mysql --user=root --password=${PASS_MYSQL_ROOT} << EOFMYSQLSECURE
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
FLUSH PRIVILEGES;
EOFMYSQLSECURE

} &> /dev/null

install_phpmyadmin() {
	# PHPMyAdmin
	echo -e "\n ${Cyan} Installing PHPMyAdmin.. ${Color_Off}"
 	{
		# set answers with `debconf-set-selections` so you don't have to enter it in prompt and the script continues
		sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" # Select Web Server
		sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true" # Configure database for phpmyadmin with dbconfig-common
		sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password ${PASS_PHPMYADMIN_APP}" # Set MySQL application password for phpmyadmin
		sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password ${PASS_PHPMYADMIN_APP}" # Confirm application password
		sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password ${PASS_MYSQL_ROOT}" # MySQL Root Password
		sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/internal/skip-preseed boolean true"

		DEBIAN_FRONTEND=noninteractive sudo apt -qy install phpmyadmin
	} &> /dev/null
	echo -e "\n ${Green} Done.. ${Color_Off}"
}

enable_mods() {
	echo -e "\n ${Cyan} Enabling Modules.. ${Color_Off}"
	{
		sudo a2enmod rewrite
		sudo phpenmod mbstring # PHP7
	} &> /dev/null
	echo -e "\n ${Green} Done.. ${Color_Off}"
} 

set_permissions() {
	echo -e "\n ${Cyan} Setting Ownership for User ${Color_Off}"
	{
		sudo chown ani /var/www/html
	} &> /dev/null
	echo -e "\n ${Green} Done.. ${Color_Off}"
}

install_redis(){
	echo -e "\n ${Cyan} Installing Redis.. ${Color_Off}"
	{
		sudo apt install -y redis-server
		sudo systemctl start redis-server
		sudo systemctl enable redis-server
		sudo apt install -y php-redis
		sudo phpenmod redis
	} &> /dev/null
	echo -e "\n ${Green} Done.. ${Color_Off}"
}

restart_apache2() {
	# Restart Apache
	echo -e "\n ${Cyan} Restarting Apache2.. ${Color_Off}"
	{
		sudo service apache2 restart
	} &> /dev/null
	echo -e "\n ${Green} Done.. ${Color_Off}"
}

install_dockerCompose(){
  echo -e "\n ${Cyan} Installing Docker and Docker compose.. ${Color_Off}"
	{
		echo -e "\n ${Yellow} Installing Docker compose.. ${Color_Off}"
		sudo apt install -y docker-compose
		sudo chmod 777 /var/run/docker.sock
	} &> /dev/null
	echo -e "\n ${Green} Done.. ${Color_Off}"
}

install_libreOffice() {
	echo -e "\n ${Cyan} Installing LibreOffice.. ${Color_Off}"
	{ 
	  	echo -e "\n ${Yellow} This will take 10-15 mins.. ${Color_Off}"
		sudo snap install --classic libreoffice
	} &> /dev/null
	echo -e "\n ${Green} Done.. ${Color_Off}"
} 

install_opera(){
    echo -e "\n ${Cyan} Installing Opera.. ${Color_Off}"
	{ 
		sudo snap install opera
	} &> /dev/null
	echo -e "\n ${Green} Done.. ${Color_Off}"
}

install_chrome() {
	echo -e "\n ${Cyan} Installing Chrome.. ${Color_Off}"
	{
		wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
		sudo dpkg -i google-chrome-stable_current_amd64.deb
		sudo rm -rf google-chrome-stable_current_amd64.deb
	} &> /dev/null
	echo -e "\n ${Green} Done.. ${Color_Off}"
}

install_timesfont() {
	echo -e "\n ${Cyan} Installing Times Font.. ${Color_Off}"
	{
		echo msttcorefonts msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections
		sudo apt install -y ttf-mscorefonts-installer
		#sudo fc-cache -f -v
	} &> /dev/null
	echo -e "\n ${Green} Done.. ${Color_Off}"
}

# RUN
update
install_devTools
install_git
install_vscode
install_apache2
install_php
install_mysql
secure_mysql
install_phpmyadmin
enable_mods
set_permissions
install_redis
restart_apache2
install_dockerCompose
#install_libreOffice
install_opera
install_chrome
install_timesfont

echo -e "\n${Green} SUCCESS! MySQL password is: ${PASS_MYSQL_ROOT} ${Color_Off}"
