#!/bin/sh
# Color Reset
Color_Off='\033[0m'       # Reset

Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan

update() {
	# Update system repos
	echo -e "\n ${Cyan} Updating package repositories.. ${Color_Off}"
	sudo apt -qq update
}

installphpext(){
    echo -e "\n ${Cyan} Installing php extensions.. ${Color_Off}"
    sudo apt install -y php imagemagick php-imagick libapache2-mod-php php-common php-mysql php-fpm php-gd php-json php-curl php-zip php-xml php-mbstring php-bz2 php-intl php-bcmath php-gmp
    sudo systemctl reload apache2
} &> /dev/null

getlatestnextcloud(){
    latestVer=$(curl -s https://github.com/nextcloud/server/releases |
        grep -m1 -Eo "[^/]+\.zip")

    Ver="${latestVer:1}"

    echo -e"\n ${Green} Installing Nextcloud Stable version - ${Ver}"

    sudo rm -rf nextcloud-${Ver}
    # Download latest version:
    wget "https://download.nextcloud.com/server/releases/nextcloud-${Ver}"

    unzip nextcloud-${Ver}
    sudo mv nextcloud /var/www/html/
}

#sudo mv nextcloud html
setPermissions(){
    echo -e "\n ${Cyan} Setting permissions for nextcloud folder.. ${Color_Off}"
    sudo chown www-data:www-data /var/www/html/nextcloud/ -R
}

VirtualHost(){
    echo "Creating virtual host"

    sudo sh -c '
    echo "<VirtualHost *:80>
        ServerAdmin admin@example.com
        DocumentRoot "/var/www/html/nextcloud"
        ServerName localhost/nextcloud

        ErrorLog ${APACHE_LOG_DIR}/nextcloud.error
        CustomLog ${APACHE_LOG_DIR}/nextcloud.access combined

        <Directory /var/www/html/nextcloud/>
            Require all granted
            Options FollowSymlinks MultiViews
            AllowOverride All

            <IfModule mod_dav.c>
                Dav off
            </IfModule>

        SetEnv HOME /var/www/html/nextcloud
        SetEnv HTTP_HOME /var/www/html/nextcloud
        Satisfy Any

        </Directory>

    </VirtualHost>" >> /etc/apache2/sites-available/nextcloud.conf'

    sudo sh -c '
    echo "127.0.0.2       pcloud.com" >> /etc/hosts '

    sleep 5
    echo "Virtual host created"
    echo "Activating virtual host and setting up apache"
    sudo a2ensite nextcloud.conf
}

setapacheprem(){
    echo -e "\n ${Cyan} Activating mods for Apache2.. ${Color_Off}"
    sudo a2enmod rewrite headers env dir mime setenvif
    sudo systemctl restart apache2
} &> /dev/null


phpmemlimit(){
    echo -e "\n ${Cyan} Setting up php memory limits... ${Color_Off}"
    sudo sed -i 's/memory_limit = 128M/memory_limit = 612M/g' /etc/php/7.4/apache2/php.ini
}

cleaning(){
    echo -e "\n ${Cyan} Cleaning downloads... ${Color_Off}"
    sudo rm -rf nextcloud-${Ver}
    echo -e "\n ${Green} Nextcloud is installed."
}


#Run
#update
#installphpext
#getlatestnextcloud
setPermissions
VirtualHost
setapacheprem
phpmemlimit
cleaning