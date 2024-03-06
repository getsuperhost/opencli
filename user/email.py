#!/usr/bin/env python3
################################################################################
# Script Name: user/email.py
# Description: Change email for user
# Usage: opencli user-email <USERNAME> <NEW_EMAIL>
# Docs: https://docs.openpanel.co/docs/admin/scripts/
# Author: Radovan Jecmenica
# Created: 06.12.2023
# Last Modified: 06.12.2023
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

# Configuration file
config_file = "/usr/local/admin/db.cnf"
config = configparser.ConfigParser()
config.read(config_file)
mysql_database = config.get('database', 'name', fallback='panel')

# Function to change email in the database
def change_email_in_db(username, new_email):
    mysql_query = f"UPDATE users SET email='{new_email}' WHERE username='{username}';"
    subprocess.run(["mysql", "--defaults-extra-file=" + config_file, "-D", mysql_database, "-e", mysql_query])

# Main function
def main(args):
    # Check if the correct number of arguments is provided
    if len(args) != 2:
        print("Usage: {} <USERNAME> <NEW_EMAIL>".format(args[0]))
        sys.exit(1)

    # Extract arguments
    username = args[0]
    new_email = args[1]

    # Call the function to change email in the database
    change_email_in_db(username, new_email)

    # Check if the function executed successfully
    mysql_query = f"UPDATE users SET email='{new_email}' WHERE username='{username}';"
    if subprocess.run(["mysql", "--defaults-extra-file=" + config_file, "-D", mysql_database, "-e", mysql_query]).returncode == 0:
        print("Email for user {} updated to {}.".format(username, new_email))
    else:
        print("Error: Failed to update email for user {}.".format(username))
