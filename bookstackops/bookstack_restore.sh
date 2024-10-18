#!/bin/bash
__FILE__=$0

# Function to read INI file
read_ini() {
    local ini_file="$1"
    local section="$2"
    local key="$3"

    # Use awk to parse the INI file
    awk -F '=' -v section="[$section]" -v key="$key" '
        $0 ~ section { in_section=1; next }
        /^\[/ { in_section=0 }
        in_section && $1 ~ key { gsub(" ", "", $2); print $2; exit }
    ' "$ini_file"
}

# Load configuration
config_file="$(dirname "$0")/config.ini"
base_dir=$(read_ini "$config_file" "restore" "base_dir")
rst_directory=$(read_ini "$config_file" "restore" "rst_directory")
oldUrl=$(read_ini "$config_file" "restore" "oldUrl")
newUrl=$(read_ini "$config_file" "restore" "newUrl")
dbpass=$(read_ini "$config_file" "database" "dbpass")

# Color Reset
Color_Off='\033[0m'       # Reset
Blue='\033[0;34m'         # Blue
Green='\033[0;32m'        # Green
Red='\033[0;31m'          # Red

# Function to handle errors
handle_error() {
    echo -e "${Red} Error: $1 ${Color_Off}"
    exit 1
}

rst_restore() {
    echo -e "\n ${Blue} Decompressing files ${Color_Off}"
    LATEST_FILE=$(ls -1 "${base_dir}/bookstack_appdata_*.tar.gz" 2>/dev/null | sort -r | head -n 1) || handle_error "Failed to list files."

    if [ -z "$LATEST_FILE" ]; then
        handle_error "No matching file found in ${base_dir}."
    fi

    if [ -d "${base_dir}/${rst_directory}" ]; then
        echo -e "\n ${Blue} Found existing $rst_directory directory. Removing the old directory ${Color_Off}"
        rm -r "${base_dir}/${rst_directory}" || handle_error "Failed to remove old directory."
    fi

    tar -xzf "$LATEST_FILE" --directory "$(dirname "$LATEST_FILE")" || handle_error "Failed to extract $LATEST_FILE."
    echo -e "\n ${Green} Contents of $LATEST_FILE have been extracted to $(dirname "$LATEST_FILE") ${Color_Off}"
}

rst_changeDockerURL() {
    echo -e "\n ${Blue} Changing URL in docker compose file... ${Color_Off}"
    YAML_FILE="docker-compose.yml"

    sed -i "s|^\(\s*- APP_URL=\).*\$|\1${newUrl}|" "${base_dir}/${rst_directory}/$YAML_FILE" || handle_error "Failed to update APP_URL."
    echo -e "\n ${Blue} URL Changed successfully. ${Color_Off}"
}

rst_containers() {
    echo -e "\n ${Blue} Starting docker container ${Color_Off}"
    docker-compose -f "${base_dir}/${rst_directory}/docker-compose.yml" up -d || handle_error "Failed to start docker containers."
    echo -e "\n ${Green} Docker container is up and running ${Color_Off}"
}

rst_dbManual() {
    echo -e "\n ${Blue} Restoring database manually ${Color_Off}"
    cat bookstack_db.sql | docker exec -i bookstack_db /usr/bin/mysql -u bookstack --password="${dbpass}" bookstackapp || handle_error "Database restore failed."
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
            sleep 5
        fi
    done
}

rst_changeURL() {
    echo -e "\n ${Blue} Changing URLs in docker container ${Color_Off}"
    docker exec bookstack /bin/bash -c "cd app/www; yes | php artisan bookstack:update-url ${oldUrl} ${newUrl}; php artisan cache:clear" || handle_error "Failed to change URLs in container."
    echo -e "\n ${Blue} Changed URLs successfully ${Color_Off}"
}

rst_notice() {
    echo -e "\n ${Red} Don't forget to change the URL in the docker file and recreate the container ${Color_Off}"
    echo -e "\n ${Red} Also execute 'php artisan bookstack:update-url <oldUrl> <newUrl>' inside the container ${Color_Off}"
}

# Run the main functions
rst_restore
rst_changeDockerURL
# rst_dbManual  # Uncomment if you want to run this
ret_checkStatus
rst_changeURL
rst_notice
