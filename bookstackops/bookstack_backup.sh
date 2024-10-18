#!/bin/bash
__FILE__=$0

# Load the configuration file
load_config() {
    while IFS='=' read -r key value; do
        if [[ $key && $value ]]; then
            # Remove any leading/trailing whitespace
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs | sed 's/#.*//')  # Remove comments
            eval "${key}='${value}'"
        fi
    done < <(grep -v '^\s*#' "$1")  # Ignore comments
}

load_config "$(dirname $0)/config.config"

# Log file
log_file="$(dirname $0)/backup.log"

# Set to stop script execution on error
set -e

# Parse options for quiet mode
quiet_mode=false
while getopts "q" opt; do
    case ${opt} in
        q) quiet_mode=true ;;
        *) echo "Usage: $0 [-q]" >&2; exit 1 ;;
    esac
done

# Redirect stdout and stderr to log file with timestamps, only if not in quiet mode
if ! $quiet_mode; then
    exec > >(while IFS= read -r line; do echo "$(date '+%Y-%m-%d %H:%M:%S') $line"; done | tee -a $log_file) 2>&1
else
    exec 2> >(while IFS= read -r line; do echo "$(date '+%Y-%m-%d %H:%M:%S') $line"; done | tee -a $log_file)
fi

# Color Reset
Color_Off='\033[0m'       # Reset
Blue='\033[0;34m'         # Blue
Yellow='\033[0;33m'       # Yellow
Green='\033[0;32m'       # Green
Cyan='\033[0;36m'         # Cyan

# Function to print messages only if not in quiet mode
print_message() {
    if ! $quiet_mode; then
        echo -e "$1"
    fi
}

print_message "\n ${Cyan} Starting Bookstack server backup (Docker installation) ${Color_Off}"

# Create a new backup directory if it does not exist
bkp_directory() {
    if [ ! -d "$data_dir_path/bookstack/$bkp_directory" ]; then       
        mkdir -p "$data_dir_path/bookstack/$bkp_directory"
        print_message "\n ${Green} Directory '$bkp_directory' created.${Color_Off}"
    else
        print_message "\n ${Yellow} Directory '$bkp_directory' already exists.${Color_Off}"
    fi
}

# Backup docker database in SQL format
bkp_database() {
    print_message "\n ${Blue} Backing up database ${Color_Off}"
    docker exec bookstack_db /usr/bin/mysqldump -u bookstack --password=${dbpass} bookstackapp > ${data_dir_path}/bookstack/${bkp_directory}/bookstack_db_$(date -d "today" +"%Y_%m_%d_%H_%M").sql
    print_message "\n ${Green} Database backup completed ${Color_Off}"
}

# Backup data folders
bkp_dataFolder() {
    print_message "\n ${Blue} Backing up APP Data ${Color_Off}"
    timestamp=$(date +%Y_%m_%d_%H_%M)
    tar --exclude='backup' -czf ${data_dir_path}/bookstack/${bkp_directory}/bookstack_appdata_${timestamp}.tar.gz -C ${data_dir_path} bookstack
    print_message "\n ${Green} APP Data backup completed ${Color_Off}"
}

# Change permission of backup folder
bkp_permission() {
    sudo chmod -R +666 ${data_dir_path}/bookstack/${bkp_directory}
}

# Backup to mega drive
bkp_mega() {
    print_message "\n ${Blue} Uploading files to mega ${Color_Off}"
    virtual_env_dir=$(echo "${virtual_env_dir}" | xargs)
    source ${virtual_env_dir}/bin/activate
    python3 $(dirname $0)/upload_to_mega.py ${mega_email} ${mega_password} ${mega_folder} ${bkp_directory} ${data_dir_path}
    deactivate
    print_message "\n ${Green} Backup files moved to mega ${Color_Off}"
}

bkp_OCI(){
    print_message "\n ${Blue} Uploading files to OCI ${Color_Off}"
    virtual_env_dir=$(echo "${virtual_env_dir}" | xargs)
    source "${virtual_env_dir}/bin/activate"
    python3 $(dirname $0)/upload_to_oci.py
    deactivate
    print_message "\n ${Green} Backup files moved to OCI ${Color_Off}"
}

# Run functions
bkp_directory
bkp_database
bkp_dataFolder
bkp_permission
#bkp_mega
bkp_OCI
