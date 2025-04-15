# OpenCLI Automation Examples

This document provides practical examples of how to automate common tasks with OpenCLI using bash scripts, cron jobs, and other automation tools.

## Table of Contents

1. [Introduction](#introduction)
2. [Bash Script Examples](#bash-script-examples)
3. [Cron Job Examples](#cron-job-examples)
4. [System Integration Examples](#system-integration-examples)
5. [Python Integration Examples](#python-integration-examples)
6. [Error Handling in Scripts](#error-handling-in-scripts)
7. [Security Best Practices](#security-best-practices)

## Introduction

OpenCLI is designed to work well in scripts and automated workflows. All commands provide consistent exit codes and can output data in machine-readable formats like JSON. This makes OpenCLI ideal for automation tasks such as:

- Scheduled backups
- User provisioning
- Website deployment
- Monitoring and maintenance
- Bulk operations

## Bash Script Examples

### Complete Website Setup Script

This script creates a new user, website, database, and generates an SSL certificate:

```bash
#!/bin/bash
################################################################################
# Script: setup_complete_website.sh
# Description: Sets up a complete website with database and SSL
# Usage: ./setup_complete_website.sh <domain> <username> <password> <email>
################################################################################

# Exit on any error
set -e

# Check parameters
if [ $# -ne 4 ]; then
    echo "Usage: $0 <domain> <username> <password> <email>"
    exit 1
fi

DOMAIN=$1
USERNAME=$2
PASSWORD=$3
EMAIL=$4
DB_NAME=${DOMAIN//./_}
DB_USER=${USERNAME}_db
DOC_ROOT="/var/www/${DOMAIN}"

echo "Starting setup for ${DOMAIN}..."

# Create user if doesn't exist
if ! opencli user-list | grep -q "${USERNAME}"; then
    echo "Creating user ${USERNAME}..."
    opencli user-add "${USERNAME}" "${PASSWORD}" "${EMAIL}" "Standard"
else
    echo "User ${USERNAME} already exists."
fi

# Create website
echo "Creating website ${DOMAIN}..."
opencli website-add "${DOMAIN}" "${DOC_ROOT}" "${USERNAME}"

# Create database
echo "Creating database ${DB_NAME}..."
opencli db-create "${DB_NAME}" utf8mb4 utf8mb4_unicode_ci

# Create database user and grant permissions
echo "Setting up database user ${DB_USER}..."
DB_PASSWORD=$(opencli password-generate --length 16)
opencli db-user-create "${DB_USER}" "${DB_PASSWORD}"
opencli db-grant "${DB_USER}" "${DB_NAME}" --all

# Store database credentials securely for later retrieval
opencli password-store "${DOMAIN}_db_credentials" "${DB_USER}:${DB_PASSWORD}"

# Generate SSL certificate
echo "Generating SSL certificate for ${DOMAIN}..."
opencli ssl-generate "${DOMAIN}" --include www

# Output success message with details
echo "====================================================="
echo "Setup completed successfully!"
echo "====================================================="
echo "Domain: ${DOMAIN}"
echo "Document Root: ${DOC_ROOT}"
echo "Database Name: ${DB_NAME}"
echo "Database User: ${DB_USER}"
echo "Database Password: Stored securely. Retrieve with:"
echo "opencli password-get ${DOMAIN}_db_credentials"
echo "====================================================="

exit 0
```

### Bulk User Management Script

This script performs operations on multiple users defined in a CSV file:

```bash
#!/bin/bash
################################################################################
# Script: bulk_user_manager.sh
# Description: Manages multiple users from a CSV file
# Usage: ./bulk_user_manager.sh users.csv [create|suspend|delete]
# CSV Format: username,password,email,plan
################################################################################

# Check parameters
if [ $# -ne 2 ]; then
    echo "Usage: $0 <csv_file> [create|suspend|delete]"
    exit 1
fi

CSV_FILE=$1
ACTION=$2

# Check if file exists
if [ ! -f "${CSV_FILE}" ]; then
    echo "Error: File ${CSV_FILE} not found."
    exit 1
fi

# Process based on action
case "${ACTION}" in
    create)
        echo "Creating users from ${CSV_FILE}..."
        while IFS=, read -r username password email plan; do
            echo "Creating user: ${username}"
            opencli user-add "${username}" "${password}" "${email}" "${plan}"
        done < "${CSV_FILE}"
        ;;
    suspend)
        echo "Suspending users from ${CSV_FILE}..."
        while IFS=, read -r username _password _email _plan; do
            echo "Suspending user: ${username}"
            opencli user-suspend "${username}"
        done < "${CSV_FILE}"
        ;;
    delete)
        echo "Deleting users from ${CSV_FILE}..."
        while IFS=, read -r username _password _email _plan; do
            echo "Deleting user: ${username}"
            opencli user-remove "${username}" --force
        done < "${CSV_FILE}"
        ;;
    *)
        echo "Error: Invalid action. Use create, suspend, or delete."
        exit 1
        ;;
esac

echo "Operation completed successfully."
exit 0
```

### Automated Database Backup with Rotation

This script backs up all databases and implements rotation for older backups:

```bash
#!/bin/bash
################################################################################
# Script: backup_all_databases.sh
# Description: Backs up all databases and rotates old backups
# Usage: ./backup_all_databases.sh [backup_dir] [days_to_keep]
################################################################################

# Default values
BACKUP_DIR=${1:-"/var/backups/databases"}
DAYS_TO_KEEP=${2:-7}
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_PATH="${BACKUP_DIR}/${DATE}"

# Create backup directory
mkdir -p "${BACKUP_PATH}"

echo "Starting database backups to ${BACKUP_PATH}..."

# Get list of databases in JSON format
DATABASES=$(opencli db-list --json)

# Extract database names using jq if available, otherwise grep and cut
if command -v jq &> /dev/null; then
    DB_NAMES=$(echo "${DATABASES}" | jq -r '.[] | .name')
else
    DB_NAMES=$(echo "${DATABASES}" | grep "name" | cut -d'"' -f4)
fi

# Back up each database
for DB in ${DB_NAMES}; do
    echo "Backing up database: ${DB}"
    BACKUP_FILE="${BACKUP_PATH}/${DB}_${TIMESTAMP}.sql.gz"

    # Skip system databases
    if [[ "${DB}" == "information_schema" || "${DB}" == "performance_schema" || "${DB}" == "mysql" || "${DB}" == "sys" ]]; then
        echo "Skipping system database: ${DB}"
        continue
    fi

    # Perform backup with compression
    opencli db-backup "${DB}" --output "${BACKUP_PATH}" --compress

    # Check if backup was successful
    if [ $? -eq 0 ]; then
        echo "✓ Backup of ${DB} completed successfully"
    else
        echo "✕ Backup of ${DB} failed"
    fi
done

# Rotate old backups
echo "Cleaning backups older than ${DAYS_TO_KEEP} days..."
find "${BACKUP_DIR}" -type d -mtime +"${DAYS_TO_KEEP}" -exec rm -rf {} \; 2>/dev/null || true

echo "Backup process completed. Backups stored in ${BACKUP_PATH}"
exit 0
```

## Cron Job Examples

### Daily Database Backups

Add this to your crontab to run daily backups at 2 AM:

```
# Database backups at 2 AM daily
0 2 * * * /path/to/backup_all_databases.sh /var/backups/databases 7 >> /var/log/db_backups.log 2>&1
```

### Weekly SSL Certificate Check

Check for expiring certificates every Monday at 3 AM:

```
# Check for expiring SSL certificates weekly
0 3 * * 1 /usr/local/bin/opencli ssl-check-all --expiring-within 30 --email admin@example.com >> /var/log/ssl_checks.log 2>&1
```

### Monthly User Usage Report

Generate and email usage reports on the 1st of each month:

```
# Monthly usage reports
0 6 1 * * /path/to/generate_usage_report.sh --email admin@example.com >> /var/log/reports.log 2>&1
```

## System Integration Examples

### Monitoring Integration

This script can be used with monitoring systems like Nagios or Zabbix:

```bash
#!/bin/bash
################################################################################
# Script: check_websites_status.sh
# Description: Checks website statuses for monitoring integration
# Usage: ./check_websites_status.sh
################################################################################

# Get website statuses in JSON format
WEBSITES=$(opencli website-status-all --json)

# Count active and inactive websites
if command -v jq &> /dev/null; then
    TOTAL=$(echo "${WEBSITES}" | jq '.websites | length')
    ACTIVE=$(echo "${WEBSITES}" | jq '.websites | map(select(.status == "active")) | length')
    INACTIVE=$(echo "${WEBSITES}" | jq '.websites | map(select(.status != "active")) | length')
else
    TOTAL=$(echo "${WEBSITES}" | grep -c "domain")
    ACTIVE=$(echo "${WEBSITES}" | grep -c '"status":"active"')
    INACTIVE=$((TOTAL - ACTIVE))
fi

# Output for monitoring system
echo "websites_total=${TOTAL} websites_active=${ACTIVE} websites_inactive=${INACTIVE}"

# Exit with warning status if any websites are inactive
if [ ${INACTIVE} -gt 0 ]; then
    exit 1
fi

exit 0
```

### Integration with Deployment Pipelines

This script deploys a web application from a Git repository:

```bash
#!/bin/bash
################################################################################
# Script: deploy_from_git.sh
# Description: Deploys website from Git repository
# Usage: ./deploy_from_git.sh <domain> <git_repo> <branch>
################################################################################

# Check parameters
if [ $# -lt 2 ]; then
    echo "Usage: $0 <domain> <git_repo> [branch]"
    exit 1
fi

DOMAIN=$1
GIT_REPO=$2
BRANCH=${3:-main}
DOC_ROOT=$(opencli website-info "${DOMAIN}" --json | grep -o '"document_root":"[^"]*"' | cut -d'"' -f4)

# Check if document root exists
if [ -z "${DOC_ROOT}" ]; then
    echo "Error: Could not determine document root for ${DOMAIN}"
    exit 1
fi

echo "Deploying ${GIT_REPO} (${BRANCH}) to ${DOMAIN} (${DOC_ROOT})..."

# Create temporary directory
TMP_DIR=$(mktemp -d)
cd "${TMP_DIR}" || exit 1

# Clone repository
git clone -b "${BRANCH}" "${GIT_REPO}" .

# Run build process if package.json exists
if [ -f "package.json" ]; then
    echo "Node.js project detected, building..."
    npm install
    npm run build

    # Copy build folder if it exists
    if [ -d "build" ]; then
        rm -rf "${DOC_ROOT:?}"/*
        cp -r build/* "${DOC_ROOT}/"
    elif [ -d "dist" ]; then
        rm -rf "${DOC_ROOT:?}"/*
        cp -r dist/* "${DOC_ROOT}/"
    else
        rm -rf "${DOC_ROOT:?}"/*
        cp -r ./* "${DOC_ROOT}/"
    fi
else
    # Simple file copy for other projects
    rm -rf "${DOC_ROOT:?}"/*
    cp -r ./* "${DOC_ROOT}/"
fi

# Set appropriate permissions
chown -R www-data:www-data "${DOC_ROOT}"
chmod -R 755 "${DOC_ROOT}"

# Clean up
cd - || exit 1
rm -rf "${TMP_DIR}"

echo "Deployment completed successfully."
exit 0
```

## Python Integration Examples

### OpenCLI API Wrapper

This Python script provides a convenient wrapper for OpenCLI commands:

```python
#!/usr/bin/env python3
"""
OpenCLI Python Wrapper
A simple wrapper to use OpenCLI commands in Python scripts
"""

import subprocess
import json
import sys

class OpenCLI:
    """Python wrapper for OpenCLI command-line interface"""

    def __init__(self, debug=False):
        """Initialize the OpenCLI wrapper"""
        self.debug = debug

    def _run_command(self, command, json_output=True):
        """Run an OpenCLI command and return the result"""
        cmd = ["opencli"]
        cmd.extend(command.split())

        if json_output:
            cmd.append("--json")

        if self.debug:
            print(f"Running command: {' '.join(cmd)}")

        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            if json_output:
                return json.loads(result.stdout)
            return result.stdout
        except subprocess.CalledProcessError as e:
            if self.debug:
                print(f"Command failed: {e}")
                print(f"stderr: {e.stderr}")
            return None
        except json.JSONDecodeError as e:
            if self.debug:
                print(f"JSON decode error: {e}")
                print(f"Output: {result.stdout}")
            return None

    def list_users(self):
        """List all users"""
        return self._run_command("user-list")

    def create_user(self, username, password, email, plan):
        """Create a new user"""
        cmd = f"user-add {username} {password} {email} \"{plan}\""
        return self._run_command(cmd, json_output=False)

    def list_websites(self, username=None):
        """List websites, optionally filtered by username"""
        cmd = "website-list"
        if username:
            cmd += f" --user {username}"
        return self._run_command(cmd)

    def create_website(self, domain, document_root, username=None):
        """Create a new website"""
        cmd = f"website-add {domain} {document_root}"
        if username:
            cmd += f" {username}"
        return self._run_command(cmd, json_output=False)

    def generate_ssl(self, domain, include_www=False):
        """Generate SSL certificate for a domain"""
        cmd = f"ssl-generate {domain}"
        if include_www:
            cmd += " --include www"
        return self._run_command(cmd, json_output=False)

    def list_databases(self):
        """List all databases"""
        return self._run_command("db-list")

    def create_database(self, name, charset="utf8mb4", collation="utf8mb4_unicode_ci"):
        """Create a new database"""
        cmd = f"db-create {name} {charset} {collation}"
        return self._run_command(cmd, json_output=False)

# Usage example
if __name__ == "__main__":
    cli = OpenCLI(debug=True)

    # Example: List all users
    users = cli.list_users()
    if users:
        print(f"Found {len(users)} users:")
        for user in users:
            print(f"  - {user['username']} ({user['email']})")

    # Example: Create website and database for a new client
    if len(sys.argv) > 1 and sys.argv[1] == "setup":
        domain = input("Domain name: ")
        username = input("Username: ")
        email = input("Email: ")

        # Generate a secure password
        password_cmd = subprocess.run(["opencli", "password-generate"],
                                    capture_output=True, text=True, check=True)
        password = password_cmd.stdout.strip()

        print(f"Setting up {domain} for {username}...")
        cli.create_user(username, password, email, "Standard")
        cli.create_website(domain, f"/var/www/{domain}", username)
        cli.create_database(domain.replace(".", "_"))
        cli.generate_ssl(domain, include_www=True)

        print("Setup completed successfully!")
        print(f"Username: {username}")
        print(f"Password: {password}")
```

## Error Handling in Scripts

### Robust Error Handling Example

This script demonstrates best practices for error handling in OpenCLI scripts:

```bash
#!/bin/bash
################################################################################
# Script: robust_website_creator.sh
# Description: Creates a website with robust error handling
# Usage: ./robust_website_creator.sh <domain> <username>
################################################################################

# Exit on error by default
set -e

# Error handler function
handle_error() {
    local exit_code=$1
    local line_number=$2
    local command=$3
    echo "Error: Command '${command}' failed with exit code ${exit_code} at line ${line_number}"

    # Perform cleanup
    if [ -d "${TMP_DIR}" ]; then
        echo "Cleaning up temporary directory..."
        rm -rf "${TMP_DIR}"
    fi

    # Log error for debugging
    echo "[$(date)] ERROR in ${0}: Command '${command}' failed with exit code ${exit_code} at line ${line_number}" >> /var/log/openpanel/admin/scripts.log

    exit ${exit_code}
}

# Set up error trap
trap 'handle_error $? $LINENO "$BASH_COMMAND"' ERR

# Check parameters
if [ $# -ne 2 ]; then
    echo "Usage: $0 <domain> <username>"
    exit 1
fi

DOMAIN=$1
USERNAME=$2
DOC_ROOT="/var/www/${DOMAIN}"
TMP_DIR=""

# Validate domain format
if ! echo "${DOMAIN}" | grep -qE '^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$'; then
    echo "Error: Invalid domain format: ${DOMAIN}"
    exit 1
fi

# Check if domain already exists
if opencli website-list | grep -q "${DOMAIN}"; then
    echo "Error: Website ${DOMAIN} already exists"
    exit 1
fi

# Check if user exists
if ! opencli user-list | grep -q "${USERNAME}"; then
    echo "Error: User ${USERNAME} does not exist"
    exit 1
fi

# Create temporary directory
TMP_DIR=$(mktemp -d)
echo "Creating website ${DOMAIN} for user ${USERNAME}..."

# Create website with timeout protection
timeout 30s opencli website-add "${DOMAIN}" "${DOC_ROOT}" "${USERNAME}" || {
    echo "Error: Website creation timed out"
    exit 1
}

# Set up default content
echo "Setting up default content..."
cat > "${TMP_DIR}/index.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Welcome to ${DOMAIN}</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; margin: 0; padding: 20px; }
        .container { max-width: 800px; margin: 0 auto; }
        h1 { color: #333; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome to ${DOMAIN}</h1>
        <p>Your website has been successfully created.</p>
    </div>
</body>
</html>
EOF

# Copy files and set permissions
mkdir -p "${DOC_ROOT}"
cp "${TMP_DIR}/index.html" "${DOC_ROOT}/"
chown -R "${USERNAME}:${USERNAME}" "${DOC_ROOT}"
chmod -R 755 "${DOC_ROOT}"

# Generate SSL with retry logic
echo "Generating SSL certificate..."
retry_count=0
max_retries=3
sleep_time=5

while [ ${retry_count} -lt ${max_retries} ]; do
    if opencli ssl-generate "${DOMAIN}" --include www; then
        echo "SSL certificate generated successfully"
        break
    else
        retry_count=$((retry_count + 1))
        if [ ${retry_count} -lt ${max_retries} ]; then
            echo "SSL generation failed, retrying in ${sleep_time} seconds... (${retry_count}/${max_retries})"
            sleep ${sleep_time}
            # Exponential backoff
            sleep_time=$((sleep_time * 2))
        else
            echo "Error: Failed to generate SSL certificate after ${max_retries} attempts"
            exit 1
        fi
    fi
done

# Clean up temporary directory
rm -rf "${TMP_DIR}"

echo "Website ${DOMAIN} created successfully!"
exit 0
```

## Security Best Practices

### Secure API Key Handling

This script demonstrates secure handling of API keys in automation:

```bash
#!/bin/bash
################################################################################
# Script: secure_api_operations.sh
# Description: Demonstrates secure API key handling
# Usage: ./secure_api_operations.sh <operation>
################################################################################

# Use a secure method to retrieve API key rather than hardcoding
get_api_key() {
    # Option 1: Use OpenCLI password store (preferred)
    opencli password-get "api_key" 2>/dev/null || \
    # Option 2: Use environment variable
    echo "${OPENCLI_API_KEY:-}" || \
    # Option 3: Read from secure file with restricted permissions
    cat ~/.opencli/api_key 2>/dev/null
}

# Validate API key is available
API_KEY=$(get_api_key)
if [ -z "${API_KEY}" ]; then
    echo "Error: No API key found"
    exit 1
fi

# Use the API key safely (notice we don't echo it or log it)
perform_api_call() {
    local endpoint=$1
    local method=${2:-GET}
    local data=${3:-}

    # Use temporary file for request data to avoid command-line exposure
    if [ -n "${data}" ]; then
        REQUEST_FILE=$(mktemp)
        echo "${data}" > "${REQUEST_FILE}"
        RESPONSE=$(curl -s -X "${method}" \
            -H "Authorization: Bearer ${API_KEY}" \
            -H "Content-Type: application/json" \
            -d "@${REQUEST_FILE}" \
            "https://api.openpanel.com/v1/${endpoint}")
        rm "${REQUEST_FILE}"
    else
        RESPONSE=$(curl -s -X "${method}" \
            -H "Authorization: Bearer ${API_KEY}" \
            "https://api.openpanel.com/v1/${endpoint}")
    fi

    echo "${RESPONSE}"
}

# Execute requested operation
case "$1" in
    list-users)
        perform_api_call "users"
        ;;
    list-websites)
        perform_api_call "websites"
        ;;
    create-user)
        # Notice we don't include passwords in logs or command-line arguments
        read -p "Username: " username
        read -sp "Password: " password
        echo
        read -p "Email: " email

        # Create JSON data
        data=$(jq -n \
            --arg username "${username}" \
            --arg password "${password}" \
            --arg email "${email}" \
            '{username: $username, password: $password, email: $email}')

        perform_api_call "users" "POST" "${data}"
        ;;
    *)
        echo "Usage: $0 [list-users|list-websites|create-user]"
        exit 1
        ;;
esac

exit 0
```

These examples demonstrate how to effectively use OpenCLI in automated workflows, with consideration for best practices in error handling, security, and system integration.
