#!/usr/bin/env python3
################################################################################
# Script Name: user/loginlog.py
# Description: View users .loginlog that shows last 20 successfull logins.
# Usage: opencli user-loginlog <USERNAME> [--json]
# Author: Stefan Pejcic
# Created: 16.11.2023
# Last Modified: 17.11.2023
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
import os
import json

# Function to print usage
def print_usage():
    print("Usage: {} <username> [--json]".format(sys.argv[0]))
    sys.exit(1)

# Function to process login log file and output as JSON
def process_login_log_as_json(username):
    login_log_file = "/home/{}/.lastlogin".format(username)
    if not os.path.isfile(login_log_file):
        print("Login log file not found for user:", username)
        sys.exit(1)

    with open(login_log_file, 'r') as file:
        lines = file.readlines()
        json_data = []
        for line in lines[1:]:
            parts = line.split(" - ")
            ip = parts[0].split(": ")[1]
            country = parts[1].split(": ")[1]
            time = parts[2].split(": ")[1].strip()
            json_data.append({"ip": ip, "country": country, "time": time})

        print(json.dumps(json_data, indent=4))

# Main function
def main(args):
    # Check if username is provided
    if len(args) < 1:
        print_usage()

    # Parse command-line options
    username = args[0]
    json_output = False
    for i in range(1, len(args)):
        if args[i] == '--json':
            json_output = True
        else:
            username = args[i]

    # Output data based on options
    if json_output:
        process_login_log_as_json(username)
    else:
        # If no options provided, print the contents of the login log file
        login_log_file = "/home/{}/.lastlogin".format(username)
        if not os.path.isfile(login_log_file):
            print("Login log file not found for user:", username)
            sys.exit(1)

        with open(login_log_file, 'r') as file:
            print(file.read())

