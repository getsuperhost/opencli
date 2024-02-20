#!/usr/bin/env python3
################################################################################
# Script Name: update_check.py
# Description: Checks if an update is available from update.openpanel.co servers.
# Usage: opencli update_check
# Author: Stefan Pejcic
# Created: 10.10.2023
# Last Modified: 15.11.2023
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

import os
import sys
import requests
from datetime import datetime

LOG_FILE = "/usr/local/admin/logs/notifications.log"

# Function to get the last message content from the log file
def get_last_message_content():
    try:
        with open(LOG_FILE, 'r') as file:
            lines = file.readlines()
            if lines:
                return lines[-1].strip()
    except FileNotFoundError:
        pass
    return None

# Function to check if an unread message with the same content exists in the log file
def is_unread_message_present(unread_message_content):
    try:
        with open(LOG_FILE, 'r') as file:
            for line in file:
                if line.startswith("UNREAD") and unread_message_content in line:
                    return True
    except FileNotFoundError:
        pass
    return False

# Function to write notification to log file if it's different from the last message content
def write_notification(title, message):
    current_message = f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} UNREAD {title} MESSAGE: {message}\n"
    last_message_content = get_last_message_content()

    if message != last_message_content and not is_unread_message_present(title):
        with open(LOG_FILE, 'a') as file:
            file.write(current_message)

# Define the route to check for updates
def update_check():
    # Read the local version from /usr/local/panel/version
    try:
        with open("/usr/local/panel/version", 'r') as file:
            local_version = file.read().strip()
    except FileNotFoundError:
        print('{"error": "Local version file not found"}', file=sys.stderr)
        sys.exit(1)

    # Fetch the remote version from https://update.openpanel.co/
    try:
        response = requests.get("https://update.openpanel.co/")
        remote_version = response.text.strip()
    except requests.exceptions.RequestException:
        print('{"error": "Error fetching remote version"}', file=sys.stderr)
        write_notification("Update check failed", "Failed connecting to https://update.openpanel.co/")
        sys.exit(1)

    # Compare the local and remote versions
    if local_version == remote_version:
        print('{"status": "Up to date", "installed_version": "' + local_version + '"}')
    elif local_version > remote_version:
        write_notification("New OpenPanel update is available", f"Installed version: {local_version} | Available version: {remote_version}")
        print('{"status": "Local version is greater", "installed_version": "' + local_version + '", "latest_version": "' + remote_version + '"}')
    else:
        write_notification("New OpenPanel update is available", f"Installed version: {local_version} | Available version: {remote_version}")
        print('{"status": "Update available", "installed_version": "' + local_version + '", "latest_version": "' + remote_version + '"}')

# Call the function and print the result
if __name__ == "__main__":
    update_check()
