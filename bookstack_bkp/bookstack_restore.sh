#!/bin/bash
__FILE__=$0

. $(dirname $0)/config.config

filename=$1


# Color Reset
Color_Off='\033[0m'       # Reset
Blue='\033[0;34m'         # Blue
Yellow='\033[0;33m'      # Yellow
Green='\033[0;32m'        # Green
Cyan='\033[0;36m'         # Cyan
Red='\033[0;31m'          # Red


echo -e "\n ${Cyan} Starting Bookstack server restore (Docker installation) ${Color_Off}"
rst_restore() {
    echo -e "\n ${Blue} Decompressing files ${Color_Off}"
    if [ ! -d "${base_dir}/$directory" ]; then       
        mkdir -p "$directory"
    fi
    tar -xzf ${base_dir}/${filename}
    
}

rst_containers() {
    echo -e "\n ${Blue} Decompressing files "
    docker-compose -f ${base_dir}/${directory}/docker-compose.yml up -d
    echo -e "\n ${Green} Completed ${Color_Off}"
}

rst_dbManual() {
    echo -e "\n ${Blue} Restoring database manually ${Color_Off}"
    cat bookstack_db.sql | docker exec -i bookstack_db /usr/bin/mysql -u bookstack --password=${dbpass} bookstackapp 
    echo -e "\n ${Green} Completed ${Color_Off}"
}

rst_changeURL(){
    echo -e "\n ${Blue} Changing URL ${Color_Off}"
    docker exec bookstack /bin/bash -c "cd app/www;yes | php artisan bookstack:update-url ${oldUrl} ${newUrl};php artisan cache:clear"
    echo -e "\n ${Blue} Changed URL successfully ${Color_Off}"
}

rst_notice() {
    echo -e "\n ${Red} Don't forget to change url in docker file and recreate the container ${Color_Off}"
    echo -e "\n ${Red} Also excute 'php artisan bookstack:update-url <oldUrl> <newUrl>' inside container ${Color_Off}"
}

# Run
rst_restore
rst_containers
#rst_dbManual
rst_changeURL
#rst_notice