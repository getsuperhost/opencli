#!/usr/bin/env python3
################################################################################
# Script Name: user_login.py
# Description: Login as the root user inside a user's docker container.
# Usage: opencli user-login <USERNAME>
# Author: Stefan Pejcic
# Created: 21.10.2023
# Last Modified: 14.02.2024
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

# Check if the correct number of command-line arguments is provided
if len(sys.argv) != 2:
    print("Usage: opencli user-login <username>".format(sys.argv[0]))
    sys.exit(1)

username = sys.argv[1]

# Run the docker command using subprocess
subprocess.run(["docker", "exec", "-it", username, "/bin/bash"])
