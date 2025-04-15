# OpenCLI Frequently Asked Questions

This document addresses common questions and issues encountered when using OpenCLI.

## General Questions

### What is OpenCLI?

OpenCLI is the command-line interface for managing OpenPanel. It provides a comprehensive set of tools to manage websites, databases, users, and other aspects of your hosting environment.

### What version of OpenCLI am I running?

You can check your current version by running:

```sh
opencli --version
```

### How do I update OpenCLI?

To update OpenCLI independently of OpenPanel:

```sh
cd /usr/local/opencli && git pull
```

## Installation Issues

### OpenCLI command not found

If you encounter "command not found" errors when trying to use OpenCLI, check that:

1. OpenCLI is properly installed at `/usr/local/opencli`
2. The main script is in your PATH at `/usr/local/bin/opencli`
3. The script has executable permissions (`chmod +x /usr/local/bin/opencli`)

### Auto-completion doesn't work

If tab completion for OpenCLI commands is not working:

1. Verify that completion script is installed (`/usr/local/opencli/completion.sh`)
2. Make sure it's sourced in your shell's configuration file
3. Restart your shell or run `source ~/.bashrc` (or equivalent)

## Usage Questions

### How do I see a list of all commands?

To see all available commands:

```sh
opencli commands
```

### Can I use OpenCLI in scripts for automation?

Yes! OpenCLI is designed to work well in scripts. Most commands provide consistent exit codes and can be used in conditional statements. See the User Guide for automation examples.

### How do I get help for a specific command?

Currently, you need to check the command implementation or documentation:

```sh
opencli help
```

Future versions will support command-specific help with:

```sh
opencli <command> --help
```

## Error Handling

### What do the error codes mean?

Error codes in the format ERRxxxxx can be looked up for detailed information:

```sh
opencli error ERR12345
```

### How do I troubleshoot "Permission denied" errors?

"Permission denied" errors typically occur when:

1. The user doesn't have sufficient privileges (try using sudo)
2. A file or directory has incorrect permissions
3. SELinux or AppArmor is preventing the action

Check the log file for more details:

```sh
tail /var/log/openpanel/admin/opencli.log
```

### Why do database commands fail?

Database command failures are usually due to:

1. Incorrect database credentials
2. Database server is unreachable
3. The user lacks required privileges
4. The database name contains invalid characters

Use the `--verbose` flag to get more information:

```sh
opencli --verbose db-list
```

## Database Management

### How do I backup all databases at once?

To backup all databases:

```sh
opencli db-backup-all --output /path/to/backup/directory
```

### Can I schedule automatic database backups?

Yes, you can create a cron job to run database backups automatically:

```sh
# Example cron entry for daily backups at 2 AM
0 2 * * * /usr/local/bin/opencli db-backup-all --output /var/backups/databases/$(date +\%Y-\%m-\%d)
```

### How do I restore a database from backup?

To restore a database from backup:

```sh
opencli db-restore database_name /path/to/backup/file.sql
```

## Website Management

### How do I create a new website with all components?

Use individual commands to set up a complete website:

```sh
# Create the website
opencli website-add example.com /var/www/example.com

# Set up a database
opencli db-create example_com
opencli db-user-create example_user --generate-password
opencli db-grant example_user example_com --all

# Generate SSL certificate
opencli ssl-generate example.com --include www
```

### How do I enable/disable a website?

To enable a website:

```sh
opencli website-enable example.com
```

To disable a website:

```sh
opencli website-disable example.com
```

### How do I check if a website is working?

To check the status of a website:

```sh
opencli website-status example.com
```

## SSL Certificate Management

### How do I generate a Let's Encrypt certificate?

To generate a Let's Encrypt SSL certificate:

```sh
opencli ssl-generate example.com
```

### How do I check when my SSL certificate expires?

To check certificate expiration:

```sh
opencli ssl-check example.com
```

### How do I install a custom SSL certificate?

To install a custom SSL certificate:

```sh
opencli ssl-install example.com /path/to/certificate.crt /path/to/private.key
```

## Security

### How secure is the password management system?

The password management system uses industry-standard AES-256-CBC encryption with PBKDF2 key derivation (100,000 iterations). The encryption key is stored with restricted permissions and sensitive data is never logged.

### Is there a way to audit OpenCLI command usage?

Yes, all OpenCLI commands are logged to `/var/log/openpanel/admin/opencli.log` with timestamps and the executing user.

### How do I securely generate passwords?

To generate a secure random password:

```sh
opencli password-generate --length 20
```

## Advanced Usage

### Can I extend OpenCLI with custom commands?

Yes, you can create custom commands by adding scripts to the appropriate directories in `/usr/local/opencli/`. See the Developer Guide for details.

### How do I contribute to OpenCLI?

Contributions to OpenCLI are welcome. See the Contributing section in the Developer Guide for details on the process.

### Can I use OpenCLI on multiple servers?

Yes, OpenCLI can be installed on multiple servers. Consider using configuration management tools like Ansible to maintain consistent configurations across your servers.
