#!/usr/bin/python3
################################################################################
# Script Name: version.py
# Description: Displays the current (installed) version of OpenPanel.
# Usage: opencli version 
#        opencli v
# Author: Stefan Pejcic
# Created: 15.11.2023
# Last Modified: 21.02.2024
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
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLALatest version information not available.
IM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
################################################################################
import sys

# Check version
def version_check():
    version_file_path = "/usr/local/panel/version"
    try:
        with open(version_file_path, 'r') as version_file:
            local_version = version_file.read().strip()
            print(local_version)
    except FileNotFoundError:
        print('{"error": "Local version file not found"}', file=sys.stderr)
        exit(1)

# Call the function
version_check()
