#!/bin/sh

sudo apt update

sudo apt install -y php imagemagick php-imagick libapache2-mod-php7.4 php7.4-common php7.4-mysql php7.4-fpm php7.4-gd php7.4-json php7.4-curl php7.4-zip php7.4-xml php7.4-mbstring php7.4-bz2 php7.4-intl php7.4-bcmath php7.4-gmp

sudo systemctl reload apache2

latestVer=$(curl -s https://github.com/nextcloud/server/releases |
    grep -m1 -Eo "[^/]+\.zip")

Ver="${latestVer:1}"

echo "Installing Nextcloud Stable version - ${Ver}"

sudo rm -rf nextcloud-${Ver}
# Download latest version:
wget "https://download.nextcloud.com/server/releases/nextcloud-${Ver}"

unzip nextcloud-${Ver}

sudo mv nextcloud /var/www/html/

#sudo mv nextcloud html
sudo chown www-data:www-data /var/www/html/nextcloud/ -R

echo "Creating virtual host"

sudo sh -c '
echo "<VirtualHost *:80>
    ServerAdmin admin@example.com
    DocumentRoot "/var/www/html/nextcloud"
    ServerName pcloud.com
    ServerAlias www.pcloud.com

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

sleep 1
echo "Virtual host created"
echo "Activating virtual host and setting up apache"
sudo a2ensite nextcloud.conf
sudo a2enmod rewrite headers env dir mime setenvif
sudo systemctl restart apache2

sleep 1

echo "Setting up php memory limits..."
sleep 1

sudo sed -i 's/memory_limit = 128M/memory_limit = 612M/g' /etc/php/7.4/apache2/php.ini
sudo rm -rf nextcloud-${Ver}
echo "Nextcloud is up and running."
