# OpenCLI

OpenCLI is the command-line interface for managing [OpenPanel](https://openpanel.com/).

## Overview

On installation, the `opencli` script is added to the system path, and `commands.sh` generates a list of all commands to be included in `.bashrc` for autocomplete.

All scripts from `/usr/local/opencli/` can be accessed using the `opencli` command by replacing `/` with `-`.

For example: running `opencli user-add` executes `/usr/bin/opencli` and passes `user-add` as an argument, triggering the execution of the `user/add` script from the scripts directory.

## Getting Help

OpenCLI provides comprehensive help through several commands:

```bash
# Display general help with command categories
opencli help

# Get detailed help for a specific command
opencli help user-add

# List all available commands
opencli commands

# Show frequently asked questions
opencli faq
```

## Installation

OpenCLI is automatically installed with OpenPanel. If you need to install it separately:

```bash
# Clone the repository
git clone https://github.com/openpanel/opencli.git /usr/local/opencli

# Make the main script executable
chmod +x /usr/local/opencli/opencli

# Create symbolic link
ln -s /usr/local/opencli/opencli /usr/local/bin/opencli
```

## Updates

OpenPanel is proud of its modularity, so you can independently update just the OpenCLI when needed:

```bash
cd /usr/local/opencli && git pull
```

## API Access

OpenCLI provides a RESTful API for programmatic access to all functionality:

```bash
# Generate an API token for authentication
opencli api-token-generate

# Set up Nginx configuration for API access
opencli api-nginx-config --install

# List available API endpoints
opencli api-list
```

API Documentation is available at `/docs/api-reference.md` and in Swagger format at `/docs/swagger.yaml`.

## Available Commands

OpenCLI includes numerous commands for managing various aspects of your OpenPanel installation:

### User Management
- **user-add**: Create a new user
- **user-delete**: Delete user
- **user-list**: List all users
- **user-rename**: Rename a user
- **user-password**: Change user password
- **user-suspend**: Suspend a user
- **user-unsuspend**: Unsuspend a user
- **user-2fa**: Manage two-factor authentication
- **user-login**: Generate login URL for a user
- **user-loginlog**: View user login history
- **user-change_plan**: Change a user's plan
- **user-quota**: Check user disk quota
- **user-ssh**: Manage SSH access
- **user-redis**: Manage Redis for a user
- **user-memcached**: Manage Memcached for a user
- **user-email**: Manage user email settings

### Domain Management
- **domains-add**: Add a domain
- **domains-delete**: Delete a domain
- **domains-all**: List all domains
- **domains-user**: List domains for a specific user
- **domains-whoowns**: Check domain ownership
- **domains-dns**: Manage DNS settings
- **domains-dnssec**: Manage DNSSEC settings
- **domains-docroot**: Configure document root
- **domains-stats**: View domain statistics
- **domains-suspend**: Suspend a domain
- **domains-unsuspend**: Unsuspend a domain
- **domains-update_ns**: Update nameservers

### Website Management
- **websites-all**: List all websites
- **websites-user**: List websites for a specific user
- **websites-pagespeed**: Check website performance
- **websites-scan**: Scan website for issues
- **webserver-get_webserver_for_user**: Get webserver type for a user

### Plan Management
- **plan-create**: Create a hosting plan
- **plan-edit**: Edit an existing plan
- **plan-delete**: Delete a plan
- **plan-list**: List all plans
- **plan-apply**: Apply plan changes to users
- **plan-usage**: Check plan usage statistics

### PHP Management
- **php-available_versions**: List available PHP versions
- **php-installed_versions**: List installed PHP versions
- **php-install**: Install a PHP version
- **php-ioncube**: Manage ionCube Loader
- **php-default**: Set default PHP version
- **php-domain**: Set PHP version for a domain
- **php-ini**: Edit PHP configuration

### FTP Management
- **ftp-add**: Add FTP account
- **ftp-delete**: Delete FTP account
- **ftp-list**: List FTP accounts
- **ftp-password**: Change FTP password
- **ftp-path**: Configure FTP path
- **ftp-users**: List FTP users
- **ftp-connections**: View active FTP connections
- **ftp-logs**: View FTP logs

### Email Management
- **email-setup**: Set up email service
- **email-server**: Manage email server
- **email-manage**: Manage email accounts
- **email-webmail**: Configure webmail service

### Server Management
- **server-ips**: List server IPs
- **server-motd**: Configure message of the day
- **server-logrotate**: Manage log rotation
- **docker-limits**: Set Docker resource limits
- **docker-collect_stats**: Collect Docker statistics
- **docker-usage_stats_cleanup**: Clean up usage statistics
- **firewall-reset**: Reset firewall settings
- **files-fix_permissions**: Fix file permissions

### Administration
- **admin**: Manage admin users
- **config**: Configure system settings
- **license**: Manage OpenPanel license
- **port**: Configure service ports
- **domain**: Set panel access domain
- **proxy**: Configure proxy settings
- **report**: Generate system reports
- **backup-user**: Backup user data
- **backup-restore_user**: Restore user data
- **update**: Update OpenPanel
- **version**: Show version information

### API and Documentation
- **api-token-generate**: Generate API authentication token
- **api-gateway**: API request router (internal use)
- **api-nginx-config**: Configure Nginx for API access
- **api-list**: List API endpoints
- **api-plans**: Plans API handler
- **api-php**: PHP API handler
- **api-backups**: Backups API handler
- **commands**: List all available commands
- **faq**: Show frequently asked questions
- **help**: Show help information

## Usage Examples

```bash
# Create a new user
opencli user-add username password email@example.com basic_plan

# List all users
opencli user-list

# Add a domain
opencli domains-add example.com username

# Create a new hosting plan
opencli plan-create 'basic' 'Basic Hosting Plan' 10 5 10 5 50 500000 10 2 4 nginx 1000

# Check system status
opencli report

# Update OpenPanel
opencli update

# Generate an API token
opencli api-token-generate

# Configure Nginx for API access
opencli api-nginx-config --install
```

## License

OpenCLI is distributed under the MIT License. See the LICENSE file for more information.
