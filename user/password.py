#!/usr/bin/env python3
################################################################################
# Script Name: user/password.py
# Description: Reset password for a user.
# Usage: opencli user-password <USERNAME> <NEW_PASSWORD | RANDOM> [--ssh]
# Docs: https://docs.openpanel.co/docs/admin/scripts/users#change-password
# Author: Stefan Pejcic
# Created: 30.11.2023
# Last Modified: 30.11.2023
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
import random
import string
import configparser
from werkzeug.security import generate_password_hash

# Function to generate a random password
def generate_random_password():
    return ''.join(random.choices(string.ascii_letters + string.digits, k=12))

# Function to print usage
def print_usage():
    print("Usage: {} <username> <new_password | random> [--ssh]".format(sys.argv[0]))
    sys.exit(1)

# Main function
def main(args):
    # Check if username and new password are provided as arguments
    if len(args) < 2:
        print_usage()

    # Parse command line options
    username = args[0]
    new_password = args[1]
    ssh_flag = False
    random_flag = False  # Flag to check if the new password is initially set as "random"
    DEBUG = False  # Default value for DEBUG

    # Parse optional flags to enable debug mode when needed!
    for arg in args:
        if arg == "--debug":
            DEBUG = True

    for arg in args:
        if arg == "--ssh":
            ssh_flag = True

    # DB
    config_file = "/usr/local/admin/db.cnf"
    config = configparser.ConfigParser()
    config.read(config_file)
    mysql_database = config.get('database', 'name', fallback='panel')

    # Check if new password should be randomly generated
    if new_password == "random":
        new_password = generate_random_password()
        random_flag = True

    # Hash password
    hashed_password = generate_password_hash(new_password)

    # Insert hashed password into MySQL database
    mysql_query = f"UPDATE users SET password='{hashed_password}' WHERE username='{username}';"
    subprocess.run(["mysql", "--defaults-extra-file=" + config_file, "-D", mysql_database, "-e", mysql_query])

    if subprocess.run(["mysql", "--defaults-extra-file=" + config_file, "-D", mysql_database, "-e", mysql_query]).returncode == 0:
        # Add flag check
        if random_flag:
            print(f"Successfully changed password for user {username}, new generated password is: {new_password}")
        else:
            print(f"Successfully changed password for user {username}.")
    else:
        print("Error: Data insertion failed.")
        sys.exit(1)

    # Check if --ssh flag is provided
    if ssh_flag:
        if DEBUG:
            # Change the user password in the Docker container
            echo_process = subprocess.Popen(["echo", f"{username}:{new_password}"], stdout=subprocess.PIPE)
            subprocess.run(["docker", "exec", "-i", username, "chpasswd"], stdin=echo_process.stdout)
            echo_process.stdout.close()
            if random_flag:
                print(f"SSH user {username} in Docker container now also has password: {new_password}")
            else:
                print(f"SSH user {username} password changed.")
        else:
            # Change the user password in the Docker container
            echo_process = subprocess.Popen(["echo", f"{username}:{new_password}"], stdout=subprocess.PIPE)
            subprocess.run(["docker", "exec", "-i", username, "chpasswd"], stdin=echo_process.stdout)
            echo_process.stdout.close()
