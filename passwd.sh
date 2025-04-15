#!/bin/bash
################################################################################
# Script Name: passwd.sh
# Description: Secure password management utility for OpenPanel
# Usage: opencli passwd [command] [options]
# Author: OpenCLI Team
# Created: 25.02.2025
# Last Modified: 25.02.2025
# Company: openpanel.com
# Copyright (c) openpanel.com
################################################################################

set -e  # Exit on error

# Password storage location with better security
PASSWORD_DIR="/etc/openpanel/secrets"
PASSWORD_FILE="${PASSWORD_DIR}/passwd.enc"
TEMP_FILE="/tmp/passwd_temp_$$.txt"
KEY_FILE="${PASSWORD_DIR}/.key"
SALT_FILE="${PASSWORD_DIR}/.salt"

# Create required directories with proper permissions
init_password_storage() {
    # Check if password directory exists
    if [ ! -d "$PASSWORD_DIR" ]; then
        mkdir -p "$PASSWORD_DIR" 2>/dev/null
        chmod 700 "$PASSWORD_DIR" 2>/dev/null
    fi

    # Create encryption key if it doesn't exist
    if [ ! -f "$KEY_FILE" ]; then
        openssl rand -hex 32 > "$KEY_FILE"
        chmod 600 "$KEY_FILE"
    fi

    # Create salt if it doesn't exist
    if [ ! -f "$SALT_FILE" ]; then
        openssl rand -hex 16 > "$SALT_FILE"
        chmod 600 "$SALT_FILE"
    fi

    # Create empty password file if it doesn't exist
    if [ ! -f "$PASSWORD_FILE" ]; then
        echo "{}" | openssl enc -aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 \
            -salt -pass file:"$KEY_FILE" > "$PASSWORD_FILE"
        chmod 600 "$PASSWORD_FILE"
    fi
}

# Generate a secure password
generate_password() {
    local length=${1:-16}
    local use_special=${2:-true}

    # Validate length
    if ! [[ "$length" =~ ^[0-9]+$ ]] || [ "$length" -lt 8 ] || [ "$length" -gt 64 ]; then
        echo "Error: Password length must be between 8-64 characters"
        return 1
    fi

    local chars="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    if [ "$use_special" = "true" ]; then
        chars="${chars}!@#$%^&*()-_=+[]{}|;:,.<>?"
    fi

    # Generate password using OpenSSL
    local password=$(openssl rand -base64 128 | tr -dc "$chars" | head -c "$length")
    echo "$password"
}

# List all stored password identifiers
list_passwords() {
    if [ ! -f "$PASSWORD_FILE" ]; then
        echo "No passwords stored yet."
        return 0
    fi

    # Decrypt the password file
    openssl enc -aes-256-cbc -md sha512 -a -d -pbkdf2 -iter 100000 \
        -salt -pass file:"$KEY_FILE" -in "$PASSWORD_FILE" > "$TEMP_FILE" 2>/dev/null || {
            echo "Error: Failed to decrypt password store"
            rm -f "$TEMP_FILE"
            return 1
        }

    # Extract and display keys
    local keys=$(jq -r 'keys[]' "$TEMP_FILE" 2>/dev/null)
    if [ -z "$keys" ]; then
        echo "No passwords stored yet."
    else
        echo "Stored passwords:"
        echo "$keys" | sort | while read -r key; do
            local date=$(jq -r ".[\"$key\"].date" "$TEMP_FILE")
            echo "  - $key (created: $date)"
        done
    fi

    # Clean up
    rm -f "$TEMP_FILE"
}

# Add or update a password
add_password() {
    local identifier="$1"
    local password="$2"
    local generate="$3"

    # Validate identifier
    if [ -z "$identifier" ]; then
        echo "Error: Password identifier is required"
        return 1
    fi

    # Generate password if requested
    if [ "$generate" = "generate" ]; then
        password=$(generate_password)
        if [ $? -ne 0 ]; then
            return 1
        fi
    fi

    # If no password provided or generated, prompt for one
    if [ -z "$password" ]; then
        read -s -p "Enter password for '$identifier': " password
        echo
        read -s -p "Confirm password: " password_confirm
        echo

        if [ "$password" != "$password_confirm" ]; then
            echo "Error: Passwords do not match"
            return 1
        fi
    fi

    # Decrypt the password file
    openssl enc -aes-256-cbc -md sha512 -a -d -pbkdf2 -iter 100000 \
        -salt -pass file:"$KEY_FILE" -in "$PASSWORD_FILE" > "$TEMP_FILE" 2>/dev/null || {
            echo "Error: Failed to decrypt password store"
            rm -f "$TEMP_FILE"
            return 1
        }

    # Add/update the password with creation date
    local date=$(date +"%Y-%m-%d %H:%M:%S")
    jq --arg id "$identifier" --arg pwd "$password" --arg date "$date" \
        '.[$id] = {"password": $pwd, "date": $date}' "$TEMP_FILE" > "${TEMP_FILE}.new"

    if [ $? -ne 0 ]; then
        echo "Error: Failed to update password store"
        rm -f "$TEMP_FILE" "${TEMP_FILE}.new"
        return 1
    fi

    # Encrypt and save
    openssl enc -aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 \
        -salt -pass file:"$KEY_FILE" -in "${TEMP_FILE}.new" > "$PASSWORD_FILE" 2>/dev/null || {
            echo "Error: Failed to encrypt password store"
            rm -f "$TEMP_FILE" "${TEMP_FILE}.new"
            return 1
        }

    # Clean up
    rm -f "$TEMP_FILE" "${TEMP_FILE}.new"

    if [ "$generate" = "generate" ]; then
        echo "Generated password for '$identifier': $password"
    else
        echo "Password for '$identifier' stored successfully"
    fi
}

# Get a stored password
get_password() {
    local identifier="$1"
    local show="$2"

    # Validate identifier
    if [ -z "$identifier" ]; then
        echo "Error: Password identifier is required"
        return 1
    fi

    # Decrypt the password file
    openssl enc -aes-256-cbc -md sha512 -a -d -pbkdf2 -iter 100000 \
        -salt -pass file:"$KEY_FILE" -in "$PASSWORD_FILE" > "$TEMP_FILE" 2>/dev/null || {
            echo "Error: Failed to decrypt password store"
            rm -f "$TEMP_FILE"
            return 1
        }

    # Check if password exists
    local exists=$(jq "has(\"$identifier\")" "$TEMP_FILE")
    if [ "$exists" != "true" ]; then
        echo "Error: No password found for '$identifier'"
        rm -f "$TEMP_FILE"
        return 1
    fi

    # Get the password
    local password=$(jq -r ".[\"$identifier\"].password" "$TEMP_FILE")

    # Clean up
    rm -f "$TEMP_FILE"

    # Display or copy password
    if [ "$show" = "show" ]; then
        echo "Password for '$identifier': $password"
    else
        # Try to copy to clipboard if available
        if command -v xclip &> /dev/null; then
            echo -n "$password" | xclip -selection clipboard
            echo "Password for '$identifier' copied to clipboard"
        elif command -v pbcopy &> /dev/null; then
            echo -n "$password" | pbcopy
            echo "Password for '$identifier' copied to clipboard"
        else
            echo "Password for '$identifier': $password"
        fi
    fi
}

# Delete a stored password
delete_password() {
    local identifier="$1"
    local force="$2"

    # Validate identifier
    if [ -z "$identifier" ]; then
        echo "Error: Password identifier is required"
        return 1
    fi

    # Decrypt the password file
    openssl enc -aes-256-cbc -md sha512 -a -d -pbkdf2 -iter 100000 \
        -salt -pass file:"$KEY_FILE" -in "$PASSWORD_FILE" > "$TEMP_FILE" 2>/dev/null || {
            echo "Error: Failed to decrypt password store"
            rm -f "$TEMP_FILE"
            return 1
        }

    # Check if password exists
    local exists=$(jq "has(\"$identifier\")" "$TEMP_FILE")
    if [ "$exists" != "true" ]; then
        echo "Error: No password found for '$identifier'"
        rm -f "$TEMP_FILE"
        return 1
    fi

    # Confirm deletion unless force flag is set
    if [ "$force" != "--force" ]; then
        read -p "Are you sure you want to delete the password for '$identifier'? [y/N] " -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Password deletion cancelled"
            rm -f "$TEMP_FILE"
            return 0
        fi
    fi

    # Delete the password
    jq "del(.[\"$identifier\"])" "$TEMP_FILE" > "${TEMP_FILE}.new"

    if [ $? -ne 0 ]; then
        echo "Error: Failed to update password store"
        rm -f "$TEMP_FILE" "${TEMP_FILE}.new"
        return 1
    fi

    # Encrypt and save
    openssl enc -aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 \
        -salt -pass file:"$KEY_FILE" -in "${TEMP_FILE}.new" > "$PASSWORD_FILE" 2>/dev/null || {
            echo "Error: Failed to encrypt password store"
            rm -f "$TEMP_FILE" "${TEMP_FILE}.new"
            return 1
        }

    # Clean up
    rm -f "$TEMP_FILE" "${TEMP_FILE}.new"

    echo "Password for '$identifier' deleted successfully"
}

# Display usage information
show_usage() {
    echo "Usage: opencli passwd [command] [options]"
    echo ""
    echo "Commands:"
    echo "  list                          List all stored passwords"
    echo "  generate [length] [no-special] Generate a secure password"
    echo "  add <identifier> [password]   Add or update a password"
    echo "  get <identifier> [show]       Get a stored password"
    echo "  delete <identifier> [--force] Delete a stored password"
    echo ""
    echo "Examples:"
    echo "  opencli passwd list"
    echo "  opencli passwd generate 20"
    echo "  opencli passwd generate 16 no-special"
    echo "  opencli passwd add db-admin"
    echo "  opencli passwd add mysql-root MySecurePassword123"
    echo "  opencli passwd add redis-master generate"
    echo "  opencli passwd get db-admin"
    echo "  opencli passwd get mysql-root show"
    echo "  opencli passwd delete old-access"
    echo ""
}

# Check dependencies
check_dependencies() {
    local missing_deps=()

    if ! command -v openssl &> /dev/null; then
        missing_deps+=("openssl")
    fi

    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "Error: Missing required dependencies: ${missing_deps[*]}"
        echo "Please install them using your package manager."
        return 1
    fi

    return 0
}

#########################################################################
############################### MAIN LOGIC ##############################
#########################################################################

# Check dependencies
check_dependencies || exit 1

# Initialize password storage
init_password_storage

# Parse command-line arguments
if [ $# -eq 0 ]; then
    show_usage
    exit 0
fi

command="$1"
shift

case "$command" in
    list)
        list_passwords
        ;;
    generate)
        length="${1:-16}"
        use_special="true"
        if [ "$2" = "no-special" ]; then
            use_special="false"
        fi
        generate_password "$length" "$use_special"
        ;;
    add)
        identifier="$1"
        password="$2"
        generate=""

        if [ "$password" = "generate" ]; then
            generate="generate"
            password=""
        fi

        add_password "$identifier" "$password" "$generate"
        ;;
    get)
        identifier="$1"
        show="$2"
        get_password "$identifier" "$show"
        ;;
    delete)
        identifier="$1"
        force="$2"
        delete_password "$identifier" "$force"
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        echo "Error: Unknown command '$command'"
        show_usage
        exit 1
        ;;
esac

exit $?
