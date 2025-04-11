#!/bin/bash
################################################################################
# Script Name: functions.sh
# Description: Collection of utility functions for OpenCLI scripts.
# Author: Stefan Pejcic
# Created: 15.11.2023
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

# Import specific function libraries
source_if_exists() {
	local file="$1"
	if [ -f "$file" ]; then
		source "$file"
		return 0
	fi
	return 1
}

# Source function libraries
source_if_exists "/usr/local/opencli/functions/error_handling.sh"
source_if_exists "/usr/local/opencli/functions/api.sh"

# Get the database host from configuration
get_db_host() {
	# ...existing code...
}

# Get the database user from configuration
get_db_user() {
	# ...existing code...
}

# Get the database password from configuration
get_db_password() {
	# ...existing code...
}

# Get the database name from configuration
get_db_name() {
	# ...existing code...
}

# Check if a user exists in the system
user_exists() {
	local username="$1"
	# ...existing code...
}

# Check if a user has admin privileges
check_admin_privileges() {
	local username="$1"
	# ...existing code...
}

# Get version information
get_version_info() {
	local version=$(cat /root/.env | grep "VERSION" | cut -d'"' -f2)
	if [ -z "$version" ]; then
		version="unknown"
	fi
	echo "$version"
}

# Get server IP address
get_server_ip() {
	# ...existing code...
}

# Format JSON output
format_json_response() {
	local data="$1"
	local pretty="${2:-false}"

	if [ "$pretty" = "true" ] && command -v jq &> /dev/null; then
		echo "$data" | jq '.'
	else
		echo "$data"
	fi
}

# Send email notification
send_email_notification() {
	local recipient="$1"
	local subject="$2"
	local message="$3"

	if [ -f "/usr/local/opencli/send_mail.sh" ]; then
		bash /usr/local/opencli/send_mail.sh "$recipient" "$subject" "$message"
		return $?
	fi

	return 1
}

# Check resource usage and alert if needed
check_resource_usage() {
	# ...existing code...
}

# Backup critical files before modifying
backup_file() {
	local file="$1"
	local backup_dir="/var/backups/openpanel/$(date +%Y%m%d)"

	if [ -f "$file" ]; then
		mkdir -p "$backup_dir"
		cp "$file" "${backup_dir}/$(basename "$file").$(date +%H%M%S)"
		return 0
	fi

	return 1
}

# Verify configuration files
verify_config() {
	local config_file="$1"
	local required_fields="$2"

	if [ ! -f "$config_file" ]; then
		return 1
	fi

	for field in $required_fields; do
		if ! grep -q "^$field=" "$config_file"; then
			return 1
		fi
	done

	return 0
}

# Create a lock file to prevent concurrent execution
create_lock() {
	local lock_name="$1"
	local lock_file="/var/run/opencli/${lock_name}.lock"

	mkdir -p "$(dirname "$lock_file")"

	if [ -f "$lock_file" ]; then
		pid=$(cat "$lock_file")
		if kill -0 "$pid" 2>/dev/null; then
			return 1
		fi
	fi

	echo $$ > "$lock_file"
	return 0
}

# Remove a lock file
release_lock() {
	local lock_name="$1"
	local lock_file="/var/run/opencli/${lock_name}.lock"

	if [ -f "$lock_file" ]; then
		rm -f "$lock_file"
	fi

	return 0
}

# Check if a feature is available in the current version
feature_available() {
	local feature="$1"
	local required_version="$2"
	local current_version=$(get_version_info)

	if [ "$current_version" = "unknown" ]; then
		return 1
	fi

	# Compare versions
	if [ "$(printf '%s\n' "$required_version" "$current_version" | sort -V | head -n1)" = "$required_version" ]; then
		return 0
	else
		return 1
	fi
}
