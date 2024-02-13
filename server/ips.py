#!/usr/bin/env python3
################################################################################
# Script Name: server/ips.py
# Description: Generates a file that contains a list of users with dedicated IPs
# Usage: python3 server-ips.py <USERNAME>
# Author: Stefan Pejcic
# Created: 16.01.2024
# Last Modified: 16.01.2024
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
import os
import json

def create_ip_file(username, ip):
    json_file = f"/usr/local/panel/core/users/{username}/ip.json"
    with open(json_file, 'w') as file:
        json.dump({"ip": ip}, file)

def main():
    if len(sys.argv) < 2:
        # If no username provided, get all active users
        result = subprocess.run(["opencli", "user-list", "--json"], capture_output=True, text=True)
        usernames = [user["username"] for user in json.loads(result.stdout) if user["status"] != "SUSPENDED"]
    else:
        # If username provided, process only for that user!
        usernames = [sys.argv[1]]

    current_server_main_ip = subprocess.getoutput("curl -s https://ip.openpanel.co || wget -qO- https://ip.openpanel.co")

    for username in usernames:
        # Get the IP from inside the container
        user_ip = subprocess.getoutput(f'docker exec {username} bash -c "curl -s https://ip.openpanel.co || wget -qO- https://ip.openpanel.co"')

        # print to terminal
        print(f"{username} - {user_ip}")

        # Save in json file to be used in openadmin
        if user_ip != current_server_main_ip:
            create_ip_file(username, user_ip)

if __name__ == "__main__":
    main()
    
