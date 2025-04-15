# OpenCLI Quick Start Guide

This quick start guide will help you get up and running with OpenCLI in minutes. It covers the most essential commands and workflows.

## Basic Commands

### Getting Help

To see available commands and general help:

```sh
opencli help
```

To view all available commands with descriptions:

```sh
opencli commands
```

### Checking Version

To check your OpenCLI version:

```sh
opencli --version
```

## User Management

### Creating a User

To create a new user:

```sh
opencli user-add username password email@example.com "Pro Plan"
```

### Listing Users

To list all users:

```sh
opencli user-list
```

For JSON output (useful for scripting):

```sh
opencli user-list --json
```

### Changing User Password

To change a user's password:

```sh
opencli user-password username "new_secure_password"
```

### Suspending/Unsuspending a User

To suspend a user account:

```sh
opencli user-suspend username
```

To reactivate a suspended user:

```sh
opencli user-unsuspend username
```

## Website Management

### Adding a Website

To add a new website for a user:

```sh
opencli website-add example.com /var/www/example.com
```

### Managing SSL Certificates

To generate a Let's Encrypt SSL certificate:

```sh
opencli ssl-generate example.com --include www
```

### Enabling/Disabling a Website

To enable a website:

```sh
opencli website-enable example.com
```

To disable a website temporarily:

```sh
opencli website-disable example.com
```

## Database Management

### Creating a Database

To create a new database:

```sh
opencli db-create database_name
```

With specific charset and collation:

```sh
opencli db-create database_name utf8mb4 utf8mb4_unicode_ci
```

### Creating a Database User

To create a database user:

```sh
opencli db-user-create username password
```

### Granting Database Permissions

To grant all permissions on a database to a user:

```sh
opencli db-grant username database_name --all
```

### Backing up a Database

To backup a database:

```sh
opencli db-backup database_name
```

To specify an output directory:

```sh
opencli db-backup database_name --output /path/to/backup/directory
```

## Password Management

### Generating Secure Passwords

To generate a secure random password:

```sh
opencli password-generate
```

With specific parameters:

```sh
opencli password-generate --length 20 --no-special
```

### Storing Credentials Securely

To store a password securely:

```sh
opencli password-store mysql-root "secure_password"
```

To generate and store in one command:

```sh
opencli password-store api-key generate
```

### Retrieving Stored Passwords

To retrieve a stored password (copies to clipboard if available):

```sh
opencli password-get mysql-root
```

To display the password in the terminal:

```sh
opencli password-get mysql-root show
```

## System Management

### Checking System Status

To view system status:

```sh
opencli system-status
```

### Viewing Error Information

To look up detailed information about an error:

```sh
opencli error ERR12345
```

To view recent errors:

```sh
opencli error --recent
```

### Updating OpenCLI

To update OpenCLI:

```sh
opencli self-update
```

## Tips and Shortcuts

### Using Command Flags

Most commands accept a `--debug` flag for additional information:

```sh
opencli user-add username password email@example.com "Pro Plan" --debug
```

Many commands support JSON output with `--json`:

```sh
opencli db-list --json
```

### Command Completion

Press Tab to autocomplete commands:

```sh
opencli user-<TAB>  # Shows all user-related commands
```

### Command History

To view recently used commands:

```sh
opencli help  # Shows recent and frequent commands at the bottom
```

## Next Steps

Now that you know the basics, explore these resources:

- [User Guide](user-guide.md) for comprehensive examples
- [FAQ](faq.md) for answers to common questions
- [Developer Guide](developer-guide.md) for extending OpenCLI

Run `opencli commands` anytime to discover new functionality.
