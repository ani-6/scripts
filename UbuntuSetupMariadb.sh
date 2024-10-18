#!/bin/bash

# Color Reset
Color_Off='\033[0m'       # Text Reset

# Colors for output
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Cyan='\033[0;36m'         # Cyan

# Passwords for MySQL and phpMyAdmin
PASS_MARIADB_ROOT='SqlAdmin987'
PASS_PHPMYADMIN_APP='SqlAdmin987'
PASS_PHPMYADMIN_ROOT="${PASS_MARIADB_ROOT}"

DRY_RUN=false

print_message() {
    local line="-----------------------------------------"
    local message="$1"
    local length=${#message}
    local separator=${line:0:length}

    echo -e "${Cyan}${separator}"
    echo -e "${message}"
    echo -e "${separator}${Color_Off}"
}


print_done() {
	
    echo -e "\n${Green}Done..${Color_Off}"
}

execute() {
    if $DRY_RUN; then
        echo -e "${Yellow}Dry run: $1${Color_Off}"
    else
        eval "$1"
    fi
}

show_dots() {
    while true; do
        echo -n "."
        sleep 0.5
        echo -n "."
        sleep 0.5
        echo -n "."
        sleep 0.5
        echo -ne "\r   \r" # Clears the dots
    done
}

# Update package repositories
update() {
    print_message "Updating package repositories.."
    show_dots & PID=$!
    execute "sudo apt -qq update &> /dev/null"
    echo -ne "\r   \r"
	kill $PID
    print_done
}

# Install developer tools
install_devTools() {
    print_message "Installing Curl, Unzip and tools..."
    show_dots & PID=$!
    execute "sudo apt install -y curl unzip x264 net-tools python3-dev default-libmysqlclient-dev python3.10-venv &> /dev/null"
    echo -ne "\r   \r"
	kill $PID
    print_done
}

# Install git
install_git() {
    print_message "Installing git.."
    show_dots & PID=$!
    execute "sudo apt install git -y &> /dev/null"
    echo -ne "\r   \r"
	kill $PID
    print_done
}

# Install Visual Studio Code
install_vscode() {
    print_message "Installing Visual Studio Code.."
    show_dots & PID=$!
    execute "wget --show-progress -qO vscode.deb 'https://go.microsoft.com/fwlink/?LinkID=760868'"
	execute "sudo dpkg -i vscode.deb &> /dev/null"
	execute "sudo apt-get install -f -y &> /dev/null"
	execute "rm vscode.deb &> /dev/null"
    echo -ne "\r   \r"
	kill $PID
    print_done
}

# Install Apache2
install_apache2() {
    print_message "Installing Apache2.."
    show_dots & PID=$!
    execute "sudo apt install -y apache2 apache2-doc libexpat1 ssl-cert &> /dev/null"
    echo -ne "\r   \r"
	kill $PID
    print_done
}

# Install PHP and common modules
install_php() {
    print_message "Installing PHP and common modules.."
    show_dots & PID=$!
    execute "sudo apt install -qy php php-common libapache2-mod-php php-curl php-dev php-gd php-imagick php-intl php-mbstring php-mysql php-pear php-pspell php-xml php-zip php-sqlite3 &> /dev/null"
    echo -ne "\r   \r"
	kill $PID
    print_done
}

# Install MySQL
install_mariadb() {
    print_message "Installing MariaDB.."
    show_dots & PID=$!
    execute "sudo debconf-set-selections <<< \"mariadb-server mariadb-server/root_password password ${PASS_MARIADB_ROOT}\""
    execute "sudo debconf-set-selections <<< \"mariadb-server mariadb-server/root_password_again password ${PASS_MARIADB_ROOT}\""
    execute "DEBIAN_FRONTEND=noninteractive sudo apt -qy install mariadb-server mariadb-client &> /dev/null"
    echo -ne "\r   \r"
    kill $PID
    print_done
}

# Secure MariaDB installation
secure_mariadb() {
    print_message "Securing MariaDB.."
    show_dots & PID=$!
    
    # Secure and configure MariaDB with password-based login
    execute "sudo mysql --user=root <<-EOFMARIADBSECURE
        -- Remove remote root access
        DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
        -- Remove anonymous users
        DELETE FROM mysql.user WHERE User='';
        -- Remove test databases
        DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
        -- Set root password for password-based login
        SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${PASS_MARIADB_ROOT}');
        -- Use mysql_native_password plugin (optional step, depending on your MariaDB version)
        UPDATE mysql.user SET plugin = 'mysql_native_password' WHERE User = 'root' AND Host = 'localhost';
        -- Flush privileges to apply changes
        FLUSH PRIVILEGES;
EOFMARIADBSECURE"
    
    echo -ne "\r   \r"
    kill $PID
    print_done
}

# Install PHPMyAdmin for MariaDB
install_phpmyadmin() {
    print_message "Installing PHPMyAdmin.."
    show_dots & PID=$!
    
    execute "sudo debconf-set-selections <<< \"phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2\""
    execute "sudo debconf-set-selections <<< \"phpmyadmin phpmyadmin/dbconfig-install boolean true\""
    execute "sudo debconf-set-selections <<< \"phpmyadmin phpmyadmin/mysql/app-pass password ${PASS_PHPMYADMIN_APP}\""
    execute "sudo debconf-set-selections <<< \"phpmyadmin phpmyadmin/app-password-confirm password ${PASS_PHPMYADMIN_APP}\""
    execute "sudo debconf-set-selections <<< \"phpmyadmin phpmyadmin/mysql/admin-pass password ${PASS_MARIADB_ROOT}\""
    execute "sudo debconf-set-selections <<< \"phpmyadmin phpmyadmin/internal/skip-preseed boolean true\""
    execute "DEBIAN_FRONTEND=noninteractive sudo apt -qy install phpmyadmin &> /dev/null"
    
    echo -ne "\r   \r"
    kill $PID
    print_done
}

# Enable necessary modules
enable_mods() {
    print_message "Enabling modules.."
    show_dots & PID=$!
    execute "sudo a2enmod rewrite headers &> /dev/null"
    execute "sudo phpenmod mbstring &> /dev/null"
	echo -ne "\r   \r"
    kill $PID
    print_done
}

# Set permissions for the web directory
set_permissions() {
    print_message "Setting ownership for /var/www/html.."
    show_dots & PID=$!
    execute "sudo chmod -R +777 /var/www/html &> /dev/null"
	echo -ne "\r   \r"
    kill $PID
    print_done
}

# Install python venv
create_venv() {
	print_message "Setting up Python venv"
	show_dots & PID=$!
	execute "python3 -m venv /var/www/html/venv &> /dev/null"
	echo -ne "\r   \r"
	kill $PID
	print_done
}

# Install Redis
install_redis() {
    print_message "Installing Redis.."
    show_dots & PID=$!
    execute "sudo apt install -y redis-server &> /dev/null"
    execute "sudo systemctl start redis-server &> /dev/null"
    execute "sudo systemctl enable redis-server &> /dev/null"
    execute "sudo apt install -y php-redis &> /dev/null"
    execute "sudo phpenmod redis &> /dev/null"
    echo -ne "\r   \r"
	kill $PID
    print_done
}

# Restart Apache2
restart_apache2() {
    print_message "Restarting Apache2.."
    show_dots & PID=$!
    execute "sudo service apache2 restart &> /dev/null"
    echo -ne "\r   \r"
	kill $PID
    print_done
}

# Install Docker and Docker Compose
install_dockerCompose() {
    print_message "Installing Docker and Docker Compose.."
    show_dots & PID=$!
    execute "sudo apt install -y docker-compose &> /dev/null"
    execute "sudo chmod +777 /var/run/docker.sock &> /dev/null"
    echo -ne "\r   \r"
	kill $PID
    print_done
}

# Install LibreOffice
install_libreOffice() {
    print_message "Installing LibreOffice.."
    show_dots & PID=$!
    execute "sudo snap install --classic libreoffice &> /dev/null"
    echo -ne "\r   \r"
	kill $PID
    print_done
}

# Install Opera browser
install_opera() {
    print_message "Installing Opera.."
    show_dots & PID=$!
    execute "sudo snap install opera &> /dev/null"
    echo -ne "\r   \r"
	kill $PID
    print_done
}

# Install Google Chrome browser
install_chrome() {
    print_message "Installing Chrome.."
    show_dots & PID=$!
    execute "wget -q --show-progress https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    execute "sudo dpkg -i google-chrome-stable_current_amd64.deb &> /dev/null"
    execute "sudo rm -rf google-chrome-stable_current_amd64.deb"
    echo -ne "\r   \r"
	kill $PID
    print_done
}

# Install Times New Roman font
install_timesfont() {
    print_message "Installing Times New Roman font.."
    show_dots & PID=$!
    execute "echo msttcorefonts msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections"
    execute "sudo apt install -y ttf-mscorefonts-installer &> /dev/null"
    echo -ne "\r   \r"
	kill $PID
    print_done
}

# Main function to run all installations
main() {
    update
    install_devTools
    install_git
    install_vscode
    install_apache2
    install_php
    install_mariadb
    secure_mariadb
    install_phpmyadmin
    enable_mods
    set_permissions
    create_venv
    #install_redis
    restart_apache2
    install_dockerCompose
    #install_libreOffice 
    #install_opera
    #install_chrome
    #install_timesfont

    echo -e "\n${Green}SUCCESS! MySQL password is: ${PASS_MARIADB_ROOT}${Color_Off}"
}

# Parse command-line arguments
while getopts ":d" opt; do
  case ${opt} in
    d )
      DRY_RUN=true
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      exit 1
      ;;
  esac
done

main
