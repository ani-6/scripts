#!/bin/bash
__FILE__=$0

. $(dirname $0)/config.config

# Log file
log_file="$(dirname $0)/backup.log"

# Redirect stdout and stderr to log file with timestamps
exec > >(while IFS= read -r line; do echo "$(date '+%Y-%m-%d %H:%M:%S') $line"; done | tee -a $log_file) 2>&1

# Color Reset
Color_Off='\033[0m'       # Reset
Blue='\033[0;34m'         # Blue
Yellow='\033[0;33m'      # Yellow
Green='\033[0;32m'        # Green
Cyan='\033[0;36m'         # Cyan

echo -e "\n ${Cyan} Starting Bookstack server backup (Docker installation) ${Color_Off}"
# Create a new backup directory if does not exists
bkp_directory() {
    if [ ! -d "$data_dir_path/bookstack/$bkp_directory" ]; then       
        mkdir -p "$data_dir_path/bookstack/$bkp_directory"
        echo -e "\n ${Green} Directory '$bkp_directory' created.${Color_Off}"
    else
        echo -e "\n ${Yellow} Directory '$bkp_directory' already exists.${Color_Off}"
    fi
}

# Backup docker database in sql format
bkp_database() {
    echo -e "\n ${Blue} Backing up database ${Color_Off}"
    docker exec bookstack_db /usr/bin/mysqldump -u bookstack  --password=${dbpass} bookstackapp > ${data_dir_path}/bookstack/${bkp_directory}/bookstack_db_$(date -d "today" +"%Y_%m_%d_%H_%M").sql
    echo -e "\n ${Green} Database backup completed ${Color_Off}"
}

# Backup data folders
bkp_dataFolder() {
    echo -e "\n ${Blue} Backing up APP Data ${Color_Off}"
    timestamp=$(date +%Y_%m_%d_%H_%M)
    tar --exclude='backup' -czf ${data_dir_path}/bookstack/${bkp_directory}/bookstack_appdata_${timestamp}.tar.gz -C ${data_dir_path} bookstack
    echo -e "\n ${Green} APP Data backup completed ${Color_Off}"
}

# Change permission of backup folder
bkp_permission() {
    chmod -R +666 ${data_dir_path}/bookstack/${bkp_directory}
}

# Backup to mega drive
bkp_mega() {
    echo -e "\n ${Blue} Uploading files to mega ${Color_Off}"
    source ${virtual_env_dir}/bin/activate
    python3 $(dirname $0)/upload_to_mega.py ${mega_email} ${mega_password} ${mega_folder} ${bkp_directory} ${data_dir_path}
    deactivate
    echo -e "\n ${Green} Backup files moved to mega ${Color_Off}"
}

#Run
bkp_directory
bkp_database
bkp_dataFolder
bkp_permission
bkp_mega
