#!/usr/bin/env python3
################################################################################
# Script Name: user/2fa.py
# Description: Check or disable 2FA for a user.
# Usage: opencli user-2fa <username> [disable]
# Author: Stefan Pejcic
# Created: 16.11.2023
# Last Modified: 22.11.2023
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
import sys
import configparser

def main(args):
    if not args or len(args) < 2:
        print("Usage: opencli user-2fa <username> [disable]")
        return 1

    username = args[0]
    action = args[1] if len(args) > 2 else None

    # DB
    config_file = "/usr/local/admin/db.cnf"
    config = configparser.ConfigParser()
    config.read(config_file)
    mysql_database = config.get('database', 'name', fallback='panel')

    def execute_mysql_query(query):
        return subprocess.run(query, shell=True, capture_output=True, text=True).stdout.strip()

    # If action is provided, update the twofa value
    if action == "disable":
        # Disable 2FA for the user
        execute_mysql_query(f"mysql --defaults-extra-file={config_file} -D {mysql_database} -e \"UPDATE users SET twofa_enabled='0' WHERE username='{username}';\"")
        print(f"Two-factor authentication for {username} is now {RED}DISABLED{RESET}.")
    elif action is not None:
        print(f"Error: Invalid action '{action}'.")
    else:
        # Get the twofa value for the provided username
        twofa = execute_mysql_query(f"mysql --defaults-extra-file={config_file} -D {mysql_database} -e \"SELECT twofa_enabled FROM users WHERE username='{username}';\"")

        # Check the value of twofa and display the status
        if not twofa:
            print(f"No twofa value found for {username}.")
        elif twofa == "0":
            print(f"Two-factor authentication for {username} is {RED}DISABLED{RESET}.")
        elif twofa == "1":
            print(f"Two-factor authentication for {username} is {GREEN}ENABLED{RESET}.")
        else:
            print(f"Invalid twofa value for {username}.")

        # Print the retrieved twofa value
        print("Retrieved twofa value:", twofa)

    return 0
