#!/bin/bash
################################################################################
# Script Name: user/delete.sh
# Description: Delete user account and permanently remove all their data.
# Usage: opencli user-delete <username> [--force] [--backup]
# Author: Stefan Pejcic
# Created: 01.10.2023
# Last Modified: 17.03.2025
# Company: openpanel.com
# Copyright (c) openpanel.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
################################################################################

source /usr/local/opencli/functions.sh

# Check if script is run by root
if [ "$(id -u)" != "0" ]; then
    echo "Error: This script must be run as root"
    exit 1
fi

# Display help if no arguments provided
if [ $# -eq 0 ]; then
    echo "Usage: opencli user-delete <username> [--force] [--backup]"
    echo ""
    echo "Options:"
    echo "  --force     Delete user without confirmation"
    echo "  --backup    Create backup before deletion"
    echo "  --help      Display this help message"
    exit 1
fi

# Parse command-line arguments
USERNAME=""
FORCE=false
BACKUP=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --force)
            FORCE=true
            shift
            ;;
        --backup)
            BACKUP=true
            shift
            ;;
        --help)
            echo "Usage: opencli user-delete <username> [--force] [--backup]"
            echo ""
            echo "Options:"
            echo "  --force     Delete user without confirmation"
            echo "  --backup    Create backup before deletion"
            echo "  --help      Display this help message"
            exit 0
            ;;
        *)
            if [ -z "$USERNAME" ]; then
                USERNAME="$1"
            else
                echo "Error: Unknown parameter: $1"
                echo "Use --help for usage information"
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate username
if [ -z "$USERNAME" ]; then
    echo "Error: Username is required"
    exit 1
fi

# Check if user exists
if ! user_exists "$USERNAME"; then
    echo "Error: User '$USERNAME' does not exist"
    exit 1
fi

# Create backup if requested
if [ "$BACKUP" = true ]; then
    echo "Creating backup for user $USERNAME before deletion..."
    opencli backup-user "$USERNAME" --quiet
    if [ $? -ne 0 ]; then
        echo "Warning: Backup creation failed, but continuing with deletion"
    else
        echo "Backup created successfully"
    fi
fi

# Confirm deletion unless --force is specified
if [ "$FORCE" = false ]; then
    echo "Warning: You are about to delete user '$USERNAME' and all associated data."
    echo "This action cannot be undone."
    read -p "Are you sure you want to continue? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Operation cancelled"
        exit 0
    fi
fi

echo "Deleting user $USERNAME..."

# 1. Get list of domains for this user
DOMAINS=$(opencli domains-user "$USERNAME" --format simple 2>/dev/null)

# 2. Delete all domains for user
if [ -n "$DOMAINS" ]; then
    echo "Deleting domains for user $USERNAME..."
    for DOMAIN in $DOMAINS; do
        echo "  - Deleting domain: $DOMAIN"
        opencli domains-delete "$DOMAIN" --force >/dev/null 2>&1
    done
fi

# 3. Stop and remove user's Docker container
echo "Removing Docker container for $USERNAME..."
docker stop "$USERNAME" >/dev/null 2>&1
docker rm "$USERNAME" >/dev/null 2>&1

# 4. Remove user from database
echo "Removing user from database..."
DB_HOST=$(get_db_host)
DB_USER=$(get_db_user)
DB_PASS=$(get_db_password)
DB_NAME=$(get_db_name)

mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "DELETE FROM users WHERE username='$USERNAME';"

# 5. Remove user directories
echo "Removing user directories..."
rm -rf "/home/$USERNAME" >/dev/null 2>&1
rm -rf "/var/www/$USERNAME" >/dev/null 2>&1
rm -rf "/var/log/openpanel/users/$USERNAME" >/dev/null 2>&1

# 6. Remove system user
echo "Removing system user..."
userdel -r "$USERNAME" >/dev/null 2>&1

# 7. Remove FTP accounts
echo "Removing FTP accounts..."
opencli ftp-delete "$USERNAME" --all --force >/dev/null 2>&1

# 8. Clean up any remaining services
echo "Cleaning up services..."
# Remove any nginx configurations
rm -f "/etc/nginx/sites-enabled/$USERNAME.conf" >/dev/null 2>&1
rm -f "/etc/nginx/sites-available/$USERNAME.conf" >/dev/null 2>&1
systemctl reload nginx >/dev/null 2>&1

echo "User $USERNAME has been successfully deleted."
exit 0
