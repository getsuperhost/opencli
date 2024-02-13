#!/usr/bin/env python3
################################################################################
# Script Name: php/default_php_version.py
# Description: View or change the default PHP version used for new domains added by the user.
# Usage: python3 php-default_php_version.py <username>
#        python3 php-default_php_version.py <username> --update <new_php_version>
# Author: Stefan Pejcic
# Created: 07.10.2023
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

import sys
import re

def update_php_version(new_php_version, config_file):
    # Use re to update the PHP version in the configuration file
    with open(config_file, 'r') as file:
        content = file.read()
        updated_content = re.sub(r'(default_php_version:\s*)php[0-9.]+', fr'\1php{new_php_version}', content)
    with open(config_file, 'w') as file:
        file.write(updated_content)

def validate_php_version(php_version):
    if not re.match(r'^[0-9]\.[0-9]$', php_version):
        print("Invalid PHP version format. Please use the format 'number.number' (e.g., 8.1 or 5.6).")
        sys.exit(1)

if len(sys.argv) < 2:
    print("Usage: python3 {} <username> [--update <new_php_version>]".format(sys.argv[0]))
    sys.exit(1)

username = sys.argv[1]
config_file = f"/usr/local/panel/core/users/{username}/server_config.yml"

if not os.path.exists(config_file):
    print(f"Configuration file for user '{username}' not found.")
    sys.exit(1)

if len(sys.argv) > 2 and sys.argv[2] == "--update":
    if len(sys.argv) < 4:
        print("Usage: python3 {} <username> --update <new_php_version>".format(sys.argv[0]))
        sys.exit(1)

    new_php_version = sys.argv[3]
    validate_php_version(new_php_version)
    update_php_version(new_php_version, config_file)
    print(f"Default PHP version for user '{username}' updated to: {new_php_version}")
else:
    with open(config_file, 'r') as file:
        php_version_match = re.search(r'default_php_version:\s*php([0-9.]+)', file.read())
        if php_version_match:
            php_version = php_version_match.group(1)
            print(f"Default PHP version for user '{username}' is: {php_version}")
        else:
            print(f"Default PHP version for user: '{username}' not found in the configuration file.")
            sys.exit(1)
            
