#!/usr/bin/env python3
################################################################################
# Script Name: webserver/check_if_file_exists.py
# Description: Check if a certain file exists in a user's home directory.
# Usage: opencli webserver-check_if_file_exists <username> <file_path>
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

import sys
import subprocess

def main(args):
    # Check if the correct number of arguments is provided
    if len(args) != 2:
        print("Usage: opencli webserver-check_if_file_exists <username> <file_path>")
        sys.exit(1)

    username = args[0]
    file_path = args[1]
    check_file_exists(username, file_path)

def check_file_exists(username, file_path):
    # Construct the full path to the file inside the container
    full_path = f"/home/{username}/{file_path}"

    # Use `docker exec` to check if the file exists inside the container
    try:
        subprocess.run(["docker", "exec", username, "test", "-f", full_path], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        # this checks for both files and folders
        # subprocess.run(["docker", "exec", username, "test", "-e", full_path], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        print(f"{full_path} exists in the container {username}.")
    except subprocess.CalledProcessError:
        print(f"{full_path} does not exist in the container {username}.")
