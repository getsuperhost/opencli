################################################################################
# Script Name: update_check.py
# Description: Checks if an update is available from update.openpanel.co servers.
# Usage: opencli update_check
# Docs: https://docs.openpanel.co/docs/admin/scripts/users#list-users
# Author: Stefan Pejcic
# Created: 10.10.2023
# Last Modified: 22.02.2024
# Company: openpanel.co
# Copyright (c) openpanel.co
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

import subprocess
import json
import os
from datetime import datetime
import sys

LOG_FILE = "/usr/local/admin/logs/notifications.log"

# Function to get the last message content from the log file
def get_last_message_content():
    try:
        with open(LOG_FILE, "r") as file:
            lines = file.readlines()
            if lines:
                return lines[-1].strip()
            else:
                return None
    except FileNotFoundError:
        return None

# Function to check if an unread message with the same content exists in the log file
def is_unread_message_present(unread_message_content):
    try:
        with open(LOG_FILE, "r") as file:
            return any("UNREAD" in line and unread_message_content in line for line in file)
    except FileNotFoundError:
        return False

# Function to write notification to log file if it's different from the last message content
def write_notification(title, message):
    current_message = f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} UNREAD {title} MESSAGE: {message}"
    last_message_content = get_last_message_content()

    # Check if the current message content is the same as the last one and has "UNREAD" status
    if message != last_message_content and not is_unread_message_present(title):
        with open(LOG_FILE, "a") as file:
            file.write(current_message + "\n")

# Define the route to check for updates
def update_check(args):
    # Read the local version from /usr/local/panel/version
    try:
        with open("/usr/local/panel/version", "r") as version_file:
            local_version = version_file.read().strip()
    except FileNotFoundError:
        print('{"error": "Local version file not found"}', file=sys.stderr)
        exit(1)

    # Fetch the remote version from https://update.openpanel.co/
    remote_version = subprocess.run(["curl", "-s", "https://update.openpanel.co/"], capture_output=True, text=True).stdout.strip()

    if not remote_version:
        print('{"error": "Error fetching remote version"}', file=sys.stderr)
        write_notification("Update check failed", "Failed connecting to https://update.openpanel.co/")
        exit(1)

    # Compare the local and remote versions
    if local_version == remote_version:
        print(json.dumps({"status": "Up to date", "installed_version": local_version}))
    elif local_version > remote_version:
        write_notification("New OpenPanel update is available", f"Installed version: {local_version} | Available version: {remote_version}")
        print(json.dumps({"status": "Local version is greater", "installed_version": local_version, "latest_version": remote_version}))
    else:
        write_notification("New OpenPanel update is available", f"Installed version: {local_version} | Available version: {remote_version}")
        print(json.dumps({"status": "Update available", "installed_version": local_version, "latest_version": remote_version}))

# Main function to serve as the entry point
def main(args):
    update_check(args)

# Call the main function if the script is executed directly
if __name__ == "__main__":
    main(sys.argv[1:])





