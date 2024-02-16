#!/bin/bash

dbpass=''        # Docker db password
directory="backup"      # Folder to keep backup
data_dir_path='/var/www/html/'      # Make sure your all data in 'bookstack' folder and it is not mentioned in this path
virtual_env_dir='/var/www/html/venv'        # Define virtual env dir for backup
mega_email=''
mega_password=''
mega_folder='bookstack_backups'
# Color Reset
Color_Off='\033[0m'       # Reset
Blue='\033[0;34m'         # Blue
Yellow='\033[0;33m'      # Yellow
Green='\033[0;32m'        # Green
Cyan='\033[0;36m'         # Cyan

echo -e "\n ${Cyan} Starting Bookstack server backup (Docker installation) ${Color_Of}"
# Create a new backup directory if does not exists
bkp_directory() {
    if [ ! -d "$directory" ]; then       
        mkdir -p "$directory"
        echo -e "\n ${Green} Directory '$directory' created.${Color_Of}"
    else
        echo -e "\n ${Yellow} Directory '$directory' already exists.${Color_Of}"
    fi
}

# Backup docker database in sql format
bkp_database() {
    echo -e "\n ${Blue} Backing up database ${Color_Of}"
    docker exec bookstack_db /usr/bin/mysqldump -u bookstack  --password=${dbpass} bookstackapp > ${directory}/bookstack_db_$(date -d "today" +"%Y%m%d%H%M").sql
    echo -e "\n ${Green} Database backup completed ${Color_Of}"
}

# Backup data folders
bkp_dataFolder() {
    echo -e "\n ${Blue} Backing up APP Data ${Color_Of}"
    timestamp=$(date +%Y_%m_%d_%H_%M)
    tar -czf ${directory}/bookstack_appdata_${timestamp}.tar.gz -C ${data_dir_path} bookstack
    echo -e "\n ${Green} APP Data backup completed ${Color_Of}"
}

# Change permission of backup folder
bkp_permission() {
    chmod -R +666 ${directory}
}

# Activate Virtual environment
bkp_virtualEnv() {
    echo -e "\n ${Blue} Uploading fieles to mega ${Color_Of}"
    source ${virtual_env_dir}/bin/activate
    python3 upload_to_mega.py ${mega_email} ${mega_password} ${mega_folder} ${directory}
    deactivate
    echo -e "\n ${Green} Backupfiles moved to mega ${Color_Of}"
}

#Run
bkp_directory
bkp_database
bkp_dataFolder
bkp_permission
bkp_virtualEnv
