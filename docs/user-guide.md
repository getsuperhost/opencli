# OpenCLI User Guide

This user guide provides detailed instructions and examples for using OpenCLI to manage your OpenPanel installation.

## Table of Contents

1. [Getting Started](#getting-started)
2. [User Management](#user-management)
3. [Database Management](#database-management)
4. [Website Management](#website-management)
5. [SSL Certificate Management](#ssl-certificate-management)
6. [Error Handling](#error-handling)
7. [Password Management](#password-management)
8. [System Maintenance](#system-maintenance)
9. [Advanced Usage](#advanced-usage)
10. [Tips and Tricks](#tips-and-tricks)

## Getting Started

### Checking OpenCLI Version

To check your OpenCLI version:

```sh
opencli --version
```

### Getting Help

To display help information:

```sh
opencli help
```

### Listing Available Commands

To see all available commands:

```sh
opencli commands
```

### Command History

To view your recent command history:

```sh
opencli help
```

The output includes your most recently used commands and most frequently used commands.

## User Management

### Adding a New User

To add a new user:

```sh
opencli user-add username password
```

For more secure password handling:

```sh
opencli user-add username --generate-password
```

### Modifying User Permissions

To modify user permissions:

```sh
opencli user-modify username --add-permission website_management
```

### Removing a User

To remove a user:

```sh
opencli user-remove username
```

### Listing Users

To list all users:

```sh
opencli user-list
```

## Database Management

### Creating a Database

To create a new database:

```sh
opencli db-create database_name
```

With charset and collation:

```sh
opencli db-create database_name utf8mb4 utf8mb4_unicode_ci
```

### Creating a Database User

To create a database user:

```sh
opencli db-user-create username password
```

### Granting Database Permissions

To grant permissions:

```sh
opencli db-grant username database_name --all
```

For specific permissions:

```sh
opencli db-grant username database_name --select --insert --update
```

### Database Backup

To backup a database:

```sh
opencli db-backup database_name
```

To specify backup location:

```sh
opencli db-backup database_name --output /path/to/backup/directory
```

### Database Restoration

To restore a database:

```sh
opencli db-restore database_name /path/to/backup/file.sql
```

## Website Management

### Creating a New Website

To create a new website:

```sh
opencli website-add example.com /var/www/example.com
```

### Enabling/Disabling a Website

To enable a website:

```sh
opencli website-enable example.com
```

To disable a website:

```sh
opencli website-disable example.com
```

### Adding Domain Aliases

To add a domain alias:

```sh
opencli website-alias-add example.com www.example.com
```

## SSL Certificate Management

### Generating a Let's Encrypt Certificate

To generate a Let's Encrypt SSL certificate:

```sh
opencli ssl-generate example.com
```

Including www subdomain:

```sh
opencli ssl-generate example.com --include www
```

### Installing a Custom Certificate

To install a custom SSL certificate:

```sh
opencli ssl-install example.com /path/to/certificate.crt /path/to/private.key
```

### Checking Certificate Expiry

To check when a certificate expires:

```sh
opencli ssl-check example.com
```

## Error Handling

### Looking Up Error Information

To look up detailed information about an error code:

```sh
opencli error ERR12345
```

### Viewing Recent Errors

To view recent errors in the logs:

```sh
opencli error --recent
```

### Analyzing Error Patterns

To analyze patterns in errors:

```sh
opencli error --analyze
```

## Password Management

### Generating Secure Passwords

To generate a secure password:

```sh
opencli password-generate
```

With specific length and character sets:

```sh
opencli password-generate --length 20 --no-special
```

### Storing Passwords Securely

To store a password:

```sh
opencli password-store identifier "secure_password"
```

### Retrieving Stored Passwords

To retrieve a stored password:

```sh
opencli password-get identifier
```

To copy directly to clipboard:

```sh
opencli password-get identifier --clipboard
```

## System Maintenance

### Checking System Status

To check the status of OpenPanel services:

```sh
opencli system-status
```

### Updating OpenCLI

To update OpenCLI:

```sh
opencli self-update
```

### Clearing Cache

To clear system caches:

```sh
opencli cache-clear
```

## Advanced Usage

### Running Custom Scripts

To execute a custom script within the OpenPanel environment:

```sh
opencli script-run /path/to/custom/script.sh
```

### Chaining Commands

Commands can be chained for complex operations:

```sh
opencli website-add example.com /var/www/example.com && opencli ssl-generate example.com
```

### Using Output Redirection

Most commands support output redirection:

```sh
opencli user-list --json > users.json
```

## Tips and Tricks

### Command Completion

OpenCLI includes Bash command completion. If it's not already enabled, add the following to your `~/.bashrc`:

```sh
source /usr/local/opencli/completion.sh
```

### Shorthand Aliases

You can create aliases for frequently used commands in your `~/.bashrc`:

```sh
alias ocli='opencli'
alias weblist='opencli website-list'
```

### Automation

OpenCLI can be used in scripts for automation. For example, to create a new website with database and SSL in one script:

```sh
#!/bin/bash
DOMAIN=$1
DB_NAME=${DOMAIN//./_}

# Create website
opencli website-add $DOMAIN /var/www/$DOMAIN

# Create database and user
opencli db-create $DB_NAME
opencli db-user-create ${DB_NAME}_user --generate-password
opencli db-grant ${DB_NAME}_user $DB_NAME --all

# Generate SSL certificate
opencli ssl-generate $DOMAIN --include www
```

### Output Formatting

Many commands support different output formats:

```sh
opencli user-list --format json
opencli user-list --format yaml
opencli user-list --format table
```

### Debugging Commands

For debugging purposes, you can use the verbose flag:

```sh
opencli --verbose user-list
```

This concludes the OpenCLI User Guide. For more information, please refer to the official OpenPanel documentation or use the built-in help system.
