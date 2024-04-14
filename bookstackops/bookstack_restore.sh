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
    LATEST_FILE=$(ls -1 ${base_dir}/bookstack_appdata_*.tar.gz 2>/dev/null | sort -r | head -n 1)
    # Check if LATEST_FILE is empty
    if [ -z "$LATEST_FILE" ]; then
        echo -e "${Red} Error: No matching file found in ${base_dir}. Exiting. ${Color_Off}"
        exit 1
    fi

    if [ -d "${base_dir}/$rst_directory" ]; then
    # Remove the directory
    echo -e "\n ${Blue} Found existing $rst_directory directory \n  Removing the old directory ${Color_Off}"
    rm -r "${base_dir}/$rst_directory"
    fi

    LATEST_FILE=$(ls -1 ${base_dir}/bookstack_appdata_*.tar.gz 2>/dev/null | sort -r | head -n 1)
    # Check if LATEST_FILE is empty
    if [ -z "$LATEST_FILE" ]; then
        echo -e "${Red} Error: No matching file found in ${base_dir}. Exiting. ${Color_Off}"
        exit 1
    fi

    # Extract the contents of the tar.gz file to its own directory
    tar -xzf "$LATEST_FILE" --directory "$(dirname "$LATEST_FILE")"
    echo -e "\n ${Green} Contents of $LATEST_FILE have been extracted to $(dirname "$LATEST_FILE") ${Color_Off}"
}

rst_changeDockerURL() {
    echo -e "\n ${Blue} Changing URL in docker compose file... ${Color_Off}"
    YAML_FILE="docker-compose.yml"

    # Use sed to replace the value of APP_URL in the YAML file
    sed -i "s|^\(\s*- APP_URL=\).*\$|\1${newUrl}|" "${base_dir}/${rst_directory}/$YAML_FILE"
    echo -e "\n ${Blue} URL Changed successfully. ${Color_Off}"
}

rst_containers() {
    echo -e "\n ${Blue} Starting docker container "
    docker-compose -f ${base_dir}/${rst_directory}/docker-compose.yml up -d
    echo -e "\n ${Green} Docker container is up and running ${Color_Off}"
}

rst_dbManual() {
    echo -e "\n ${Blue} Restoring database manually ${Color_Off}"
    cat bookstack_db.sql | docker exec -i bookstack_db /usr/bin/mysql -u bookstack --password=${dbpass} bookstackapp 
    echo -e "\n ${Green} Completed ${Color_Off}"
}

ret_checkStatus() {
    echo -e "\n ${Blue} Checking Bookstack container status ${Color_Off}"
    while true; do
        if [ "$(docker container inspect -f '{{.State.Running}}' bookstack)" == "true" ]; then
            echo -e "\n ${Green} Container is running ${Color_Off}"
            break
        else
            echo -e "\n ${Blue} Container is not running yet. Waiting... ${Color_Off}"
            sleep 5  # Adjust the sleep duration as needed
        fi
    done
    echo -e "\n ${Blue} Checking Bookstack db container status ${Color_Off}"
    while true; do
        if [ "$(docker container inspect -f '{{.State.Running}}' bookstack_db)" == "true" ]; then
            echo -e "\n ${Green} Container is running ${Color_Off}"
            break
        else
            echo -e "\n ${Blue} Container is not running yet. Waiting... ${Color_Off}"
            sleep 5  # Adjust the sleep duration as needed
        fi
    done
}

rst_changeURL(){
    echo -e "\n ${Blue} Changing URL's in docker container ${Color_Off}"
    docker exec bookstack /bin/bash -c "cd app/www;yes | php artisan bookstack:update-url ${oldUrl} ${newUrl};php artisan cache:clear"
    echo -e "\n ${Blue} Changed URL's successfully ${Color_Off}"
}

rst_notice() {
    echo -e "\n ${Red} Don't forget to change url in docker file and recreate the container ${Color_Off}"
    echo -e "\n ${Red} Also excute 'php artisan bookstack:update-url <oldUrl> <newUrl>' inside container ${Color_Off}"
}

# Run
rst_restore
rst_changeDockerURL
rst_containers
#rst_dbManual
ret_checkStatus
rst_changeURL
#rst_notice
