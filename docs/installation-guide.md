# OpenCLI Installation Guide

This guide provides step-by-step instructions for installing and configuring OpenCLI on your server.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation Methods](#installation-methods)
3. [Standard Installation](#standard-installation)
4. [Manual Installation](#manual-installation)
5. [Verifying Installation](#verifying-installation)
6. [Configuration](#configuration)
7. [Upgrading OpenCLI](#upgrading-opencli)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

Before installing OpenCLI, ensure your system meets the following requirements:

- Linux-based operating system (Debian/Ubuntu, CentOS/RHEL, or similar)
- Bash shell
- Root or sudo access
- Git (for installation and updates)
- OpenSSL
- MySQL or MariaDB client (for database operations)
- curl
- wget
- jq (for JSON processing)

## Installation Methods

OpenCLI can be installed in two ways:

1. **Standard Installation**: As part of OpenPanel installation (recommended)
2. **Manual Installation**: Standalone installation for custom setups

## Standard Installation

When you install OpenPanel, OpenCLI is automatically included. The standard installation configures all necessary components, permissions, and creates required configuration files.

To perform a standard installation with OpenPanel:

```sh
# Download the OpenPanel installer
wget https://installer.openpanel.com -O openpanel-installer.sh

# Make the installer executable
chmod +x openpanel-installer.sh

# Run the installer
./openpanel-installer.sh
```

During the OpenPanel installation process, you'll be prompted for configuration options. The installer will automatically set up OpenCLI with the appropriate settings.

## Manual Installation

For standalone installations or custom setups, follow these steps:

### 1. Clone the OpenCLI Repository

```sh
# Create the OpenCLI directory
mkdir -p /usr/local/opencli

# Clone the repository
git clone https://github.com/openpanel/opencli.git /usr/local/opencli
```

### 2. Set Appropriate Permissions

```sh
# Make scripts executable
chmod +x -R /usr/local/opencli/

# Create symbolic link for global access
ln -s /usr/local/opencli/opencli /usr/local/bin/opencli
```

### 3. Create Required Directories

```sh
# Create log directory
mkdir -p /var/log/openpanel/admin

# Set permissions
chmod 755 /var/log/openpanel/admin
```

### 4. Configure Database Access

Create a MySQL/MariaDB configuration file:

```sh
# Create default database configuration
cat > /etc/openpanel/mysql/db.cnf << EOF
[client]
user=root
password=your_secure_password
host=localhost
EOF

# Secure the configuration file
chmod 600 /etc/openpanel/mysql/db.cnf
```

### 5. Set up Command Auto-completion

Add command completion to your shell:

```sh
# Run the installation script
/usr/local/opencli/install.sh

# Or manually add to .bashrc
echo 'source /usr/local/opencli/completion.sh' >> ~/.bashrc
source ~/.bashrc
```

## Verifying Installation

After installation, verify that OpenCLI is working properly:

```sh
# Check OpenCLI version
opencli --version

# View available commands
opencli commands

# Test a basic command
opencli help
```

## Configuration

OpenCLI uses several configuration files that can be customized:

### Database Configuration

The primary database configuration is stored in `/etc/openpanel/mysql/db.cnf`. This file contains the credentials used by OpenCLI to connect to the database.

```
[client]
user=database_user
password=database_password
host=database_host
```

### Log Configuration

Logs are stored in `/var/log/openpanel/admin/opencli.log`. You can adjust log verbosity by using the `--verbose` flag with commands.

### Custom Configuration

For advanced configurations, you can modify the following files:

- `/etc/openpanel/openpanel/conf/openpanel.config`: Main OpenPanel configuration
- `/usr/local/opencli/db.sh`: Database connection settings
- `/etc/openpanel/admin/config/admin.ini`: Admin interface configuration

## Upgrading OpenCLI

OpenCLI can be upgraded independently of OpenPanel:

```sh
# Navigate to the OpenCLI directory
cd /usr/local/opencli

# Pull the latest changes
git pull

# Verify the new version
opencli --version
```

For a controlled upgrade process:

```sh
# Update to a specific version
cd /usr/local/opencli
git fetch
git checkout v202.502.023  # Replace with desired version
```

## Troubleshooting

### Common Issues

#### Command Not Found

If you get "command not found" when trying to use OpenCLI:

```sh
# Check if the symbolic link exists
ls -l /usr/local/bin/opencli

# If not, create it
ln -s /usr/local/opencli/opencli /usr/local/bin/opencli
```

#### Permission Denied

If you encounter permission errors:

```sh
# Check script permissions
ls -la /usr/local/opencli/opencli

# Fix permissions
chmod +x /usr/local/opencli/opencli
```

#### Database Connection Issues

If database commands fail:

```sh
# Verify database configuration
cat /etc/openpanel/mysql/db.cnf

# Test connection
mysql --defaults-file=/etc/openpanel/mysql/db.cnf -e "SELECT 1"
```

#### Log Directory Errors

If log-related errors occur:

```sh
# Create log directory
mkdir -p /var/log/openpanel/admin

# Set permissions
chmod 755 /var/log/openpanel/admin
chown root:root /var/log/openpanel/admin
```

### Getting Help

If you continue to experience issues:

1. Check the logs: `tail -f /var/log/openpanel/admin/opencli.log`
2. Run commands with `--debug` flag for more information
3. Consult the [FAQ](faq.md) for common solutions
4. Visit the [OpenPanel documentation](https://dev.openpanel.com/cli/) for additional resources
