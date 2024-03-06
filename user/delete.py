#!/usr/bin/env python3
# Script Name: user/delete.py
# Description: Delete user account and permanently remove all their data.
# Usage: opencli user-delete <USERNAME> [-y]
# Author: Stefan Pejcic
# Created: 01.10.2023
# Last Modified: 16.11.2023
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

import sys
import subprocess
import configparser

# Function to print usage instructions
def print_usage():
    script_name = sys.argv[0]
    print(f"Usage: opencli {script_name} <username> [-y]")
    sys.exit(1)

# Function to confirm actions with the user
def confirm_action(username, skip_confirmation):
    if skip_confirmation:
        return True

    response = input(f"This will permanently delete user '{username}' and all of its data from the server. Please confirm [Y/n]: ").lower()
    return response in ['yes', 'y']

# Function to remove Docker container and all user files
def remove_docker_container_and_volume(username):
    subprocess.run(['docker', 'stop', username])
    subprocess.run(['docker', 'rm', username])
    subprocess.run(["umount", f"/home/{username}"])
    subprocess.run(['rm', '-rf', f'/home/{username}'])
    subprocess.run(["rm", f"/home/storage_file_{username}"])

# Function to delete all users' domains vhosts files from Nginx
def delete_vhosts_files(username, config_file, mysql_database):
    user_id_query = f"SELECT id FROM users WHERE username='{username}';"
    user_id_process = subprocess.Popen(['mysql', '--defaults-extra-file=' + config_file, '-D', mysql_database, '-e', user_id_query, '-N'], stdout=subprocess.PIPE)
    user_id_output = user_id_process.communicate()[0]
    user_id = user_id_output.decode('utf-8').strip()

    if not user_id:
        print(f"Error: User '{username}' not found in the database.")
        sys.exit(1)

    domain_names_query = f"SELECT domain_name FROM domains WHERE user_id='{user_id}';"
    domain_names_process = subprocess.Popen(['mysql', '--defaults-extra-file=' + config_file, '-D', mysql_database, '-e', domain_names_query, '-N'], stdout=subprocess.PIPE)
    domain_names_output = domain_names_process.communicate()[0]
    domain_names = domain_names_output.decode('utf-8').strip().split('\n')

    for domain_name in domain_names:
        subprocess.run(['certbot', 'revoke', '-n', '--cert-name', domain_name])
        subprocess.run(['certbot', 'delete', '-n', '--cert-name', domain_name])
        subprocess.run(['sudo', 'rm', '-f', f'/etc/nginx/sites-enabled/{domain_name}.conf'])
        subprocess.run(['sudo', 'rm', '-f', f'/etc/nginx/sites-available/{domain_name}.conf'])

    subprocess.run(['systemctl', 'reload', 'nginx'])
    print(f"SSL Certificates, Nginx Virtual hosts, and configuration files for all of user '{username}' domains deleted successfully.")

# Function to delete user from the database
def delete_user_from_database(username, config_file, mysql_database):
    user_id_query = f"SELECT id FROM users WHERE username='{username}';"
    user_id_process = subprocess.Popen(['mysql', '--defaults-extra-file=' + config_file, '-D', mysql_database, '-e', user_id_query, '-N'], stdout=subprocess.PIPE)
    user_id_output = user_id_process.communicate()[0]
    user_id = user_id_output.decode('utf-8').strip()

    if not user_id:
        print(f"Error: User '{username}' not found in the database.")
        sys.exit(1)

    domain_ids_query = f"SELECT domain_id FROM domains WHERE user_id='{user_id}';"
    domain_ids_process = subprocess.Popen(['mysql', '--defaults-extra-file=' + config_file, '-D', mysql_database, '-e', domain_ids_query, '-N'], stdout=subprocess.PIPE)
    domain_ids_output = domain_ids_process.communicate()[0]
    domain_ids = domain_ids_output.decode('utf-8').strip().split('\n')

    for domain_id in domain_ids:
        subprocess.run(['mysql', '--defaults-extra-file=' + config_file, '-D', mysql_database, '-e', f"DELETE FROM sites WHERE domain_id='{domain_id}';"])
    
    subprocess.run(['mysql', '--defaults-extra-file=' + config_file, '-D', mysql_database, '-e', f"DELETE FROM domains WHERE user_id='{user_id}';"])
    subprocess.run(['mysql', '--defaults-extra-file=' + config_file, '-D', mysql_database, '-e', f"DELETE FROM users WHERE username='{username}';"])

    print(f"User '{username}' and associated data deleted from MySQL database successfully.")

# Function to disable UFW rules for ports containing the username
def disable_ports_in_ufw(username):
    # Execute the bash script
    subprocess.run(['/usr/local/admin/scripts/disable_ports_in_ufw.sh', username])

def main(args):
    # Check if the correct number of command-line arguments is provided
    if len(args) != 1 and len(args) != 2:
        print_usage()

    username = args[0]
    skip_confirmation = False

    # Check if the -y flag is provided to skip confirmation
    if len(args) == 2 and args[1] == '-y':
        skip_confirmation = True

    # DB configuration
    config_file = "/usr/local/admin/db.cnf"
    config = configparser.ConfigParser()
    config.read(config_file)
    mysql_database = config.get('database', 'name', fallback='panel')

    # Confirm action
    if not confirm_action(username, skip_confirmation):
        print("Operation canceled.")
        sys.exit(0)

    # Delete user-related data
    delete_vhosts_files(username, config_file, mysql_database)
    remove_docker_container_and_volume(username)
    delete_user_from_database(username, config_file, mysql_database)
    disable_ports_in_ufw(username)

    print(f"User {username} deleted.")
