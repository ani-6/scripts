#!/bin/bash

__FILE__=$0
. $(dirname $0)/config.config

# Array of database names
DB_NAMES=("phpapp" "linkace")

script_dir=$(dirname "$(realpath "$0")")
FULL_DIR_PATH=$script_dir/$BACKUP_DIR
bkp_directory() {
    if [ ! -d "$FULL_DIR_PATH" ]; then       
        mkdir -p "$FULL_DIR_PATH"
        echo -e "\n ${Green} Directory '$FULL_DIR_PATH' created.${Color_Off}"
    else
        echo -e "\n ${Yellow} Directory '$FULL_DIR_PATH' already exists.${Color_Off}"
    fi
}

create_backup(){
    # Date format for backup file
    DATE=$(date +"%Y%m%d_%H%M%S")

    # Loop through each database and create backup
    for DB_NAME in "${DB_NAMES[@]}"
    do
        # Backup file name
        BACKUP_FILE="$FULL_DIR_PATH/$DB_NAME-$DATE.sql"

        # Command to take backup
        mysqldump -h ${DB_HOST} -u ${DB_USER} -p${DB_PASS} ${DB_NAME} > $BACKUP_FILE

        # Check if backup was successful
        if [ $? -eq 0 ]; then
            echo "Backup of database $DB_NAME completed successfully. Backup file: $BACKUP_FILE"
        else
            echo "Error: Backup of database $DB_NAME failed."
        fi
    done
}

# Backup to mega drive
bkp_mega() {
    echo -e "\n ${Blue} Uploading files to mega ${Color_Off}"
    source ${virtual_env_dir}/bin/activate
    python3 $(dirname $0)/upload_to_mega.py ${mega_email} ${mega_password} ${mega_folder} ${FULL_DIR_PATH} ${BACKUP_DIR}
    deactivate
    echo -e "\n ${Green} Backupfiles moved to mega ${Color_Off}"
}

# Run
bkp_directory
create_backup
bkp_mega