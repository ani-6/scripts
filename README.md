# Bash Scripts for Ubuntu Setup

This repository contains a collection of bash scripts designed to automate the installation and backup of various tools and services on an Ubuntu system.

## Scripts Overview

### 1. `UbuntuSetup`
This script installs the following tools and packages on an Ubuntu system:
- **LAMP Stack** (Linux, Apache, MySQL, PHP)
- **Development Tools**
- **LibreOffice**
- **VS Code**
- **Browsers** (e.g., Chrome, Opera)

#### Usage:
```bash
bash UbuntuSetup.sh
```

### 2. `UbuntuSetupMariadb`
Similar to the UbuntuSetup script, but it uses MariaDB instead of MySQL for the database in the LAMP stack.
#### Usage:
```bash
bash UbuntuSetupMariadb.sh
```

### 3. `nextcloudUbuntu`

Installs Nextcloud on an Ubuntu system, providing a private cloud file-sharing solution.
#### Usage:
```bash
bash nextcloudUbuntu.sh
```

### 4. `webminUbuntu`

Installs Webmin on Ubuntu for managing Unix-based systems through a web-based interface.
#### Usage:
```bash
bash webminUbuntu.sh
```

### 5. `Bookstackops`
Automates backup and restore of a Bookstack Docker instance, and provides functionality to upload backups to Mega or S3 Bucket.

### 6. `Giteaops`
Automates backup of a Gitea Docker instance and allows uploads to Mega.

### 6. `ExportDockerContainers`
Exports all running Docker containers into a tarball file.