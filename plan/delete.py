#!/usr/bin/python3
################################################################################
# Script Name: plan/delete
# Description: Delete hosting plan
# Usage: opencli plan-delete <PLAN_NAME>
# Docs: https://docs.openpanel.co/docs/admin/scripts/users#add-user
# Author: Radovan Jecmenica
# Created: 01.12.2023
# Last Modified: 01.12.2023
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
    print(f"Usage: {script_name} <plan_name>")
    sys.exit(1)

# Function to delete plan and associated data
def delete_plan(plan_name, config_file, mysql_database):
    # Check if there are users on the plan
    users_count_query = f"SELECT COUNT(*) FROM users INNER JOIN plans ON users.plan_id = plans.id WHERE plans.name = '{plan_name}';"
    users_count_process = subprocess.Popen(['mysql', '--defaults-extra-file=' + config_file, '-D', mysql_database, '-e', users_count_query], stdout=subprocess.PIPE)
    users_count_output = users_count_process.communicate()[0]
    users_count = int(users_count_output.splitlines()[1])

    if users_count > 0:
        print(f"Cannot delete plan '{plan_name}' as there are users assigned to it. List of users:")
        
        # List users on the plan
        users_data_query = f"SELECT users.username FROM users INNER JOIN plans ON users.plan_id = plans.id WHERE plans.name = '{plan_name}';"
        users_data_process = subprocess.Popen(['mysql', '--defaults-extra-file=' + config_file, '-D', mysql_database, '--table', '-e', users_data_query], stdout=subprocess.PIPE)
        users_data_output = users_data_process.communicate()[0]
        users_data = users_data_output.decode('utf-8')

        if users_data:
            print(users_data)
        else:
            print(f"No users on plan '{plan_name}'.")
        sys.exit(1)
    else:
        # Delete the plan data
        delete_plan_query = f"DELETE FROM plans WHERE name = '{plan_name}';"
        subprocess.run(['mysql', '--defaults-extra-file=' + config_file, '-D', mysql_database, '-e', delete_plan_query])

        # Delete the Docker network
        subprocess.run(['docker', 'network', 'rm', plan_name])

        print(f"Docker network '{plan_name}' deleted successfully.")
        print(f"Plan '{plan_name}' deleted successfully.")

def main(args):
    # Command-line argument processing
    if len(args) < 1:
        print_usage()

    plan_name = args[0]

    config_file = "/usr/local/admin/db.cnf"
    config = configparser.ConfigParser()
    config.read(config_file)
    mysql_database = config.get('database', 'name', fallback='panel')

    # Delete the plan and associated data
    delete_plan(plan_name, config_file, mysql_database)

if __name__ == "__main__":
    main(sys.argv)
