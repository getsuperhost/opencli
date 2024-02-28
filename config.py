#!/usr/bin/env python3
################################################################################
# Script Name: config.py
# Description: View / change configuration for users and set defaults for new accounts.
# Usage: opencli config get <setting_name> 
#        opencli config update <setting_name> <new_value>
# Author: Stefan Pejcic
# Created: 01.11.2023
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

config_file = "/usr/local/panel/conf/panel.config"
proxy_conf_file = "/usr/local/panel/templates/vhosts/openpanel_proxy.conf"


def main(args):
    if len(args) < 2 or len(args) > 3:
        print("Usage: opencli config [get|update] <parameter_name> [new_value]")
        sys.exit(1)

    command = args[0]
    param_name = args[1]

    if command == "get":
        get_config(param_name)
    elif command == "update":
        if len(args) != 3:
            print("Usage: opencli config update <parameter_name> <new_value>")
            sys.exit(1)
        new_value = args[2]
        update_config(param_name, new_value)
        if param_name == "ssl":
            update_ssl_config(new_value)
        elif param_name == "port":
            update_port_config(new_value)
        elif param_name == "openpanel_proxy":
            update_openpanel_proxy_config(new_value)
    else:
        print("Invalid command. Usage: opencli config [get|update] <parameter_name> [new_value]")
        sys.exit(1)

def update_ssl_config(ssl_value):
    try:
        with open(proxy_conf_file, 'r') as f:
            lines = f.readlines()

        if ssl_value == "yes":
            with open(proxy_conf_file, 'w') as f:
                for line in lines:
                    if "proxy_pass http://" in line:
                        line = line.replace("proxy_pass http://", "proxy_pass https://")
                    f.write(line)
            print("Updated SSL configuration in", proxy_conf_file)
        elif ssl_value == "no":
            with open(proxy_conf_file, 'w') as f:
                for line in lines:
                    if "proxy_pass https://" in line:
                        line = line.replace("proxy_pass https://", "proxy_pass http://")
                    f.write(line)
            print("Updated SSL configuration in", proxy_conf_file)
    except FileNotFoundError:
        print("Error: File not found.", proxy_conf_file)

def update_port_config(new_port):
    try:
        with open(proxy_conf_file, 'r') as f:
            lines = f.readlines()

        with open(proxy_conf_file, 'w') as f:
            for line in lines:
                if "proxy_pass https://" in line or "proxy_pass http://" in line:
                    line = line.split(":")[0] + ":" + new_port + ";\n"
                f.write(line)
        print("Updated port configuration in", proxy_conf_file, "to", new_port)
    except FileNotFoundError:
        print("Error: File not found.", proxy_conf_file)

def update_openpanel_proxy_config(new_value):
    try:
        with open(proxy_conf_file, 'r') as f:
            lines = f.readlines()

        with open(proxy_conf_file, 'w') as f:
            for line in lines:
                if "location /openpanel" in line:
                    path = line.split('/')[1]
                    line = line.replace(f"/{path}", f"/{new_value}")
                f.write(line)
        print("Updated openpanel_proxy configuration in", proxy_conf_file, "to", new_value)
    except FileNotFoundError:
        print("Error: File not found.", proxy_conf_file)

def get_config(param_name):
    try:
        with open(config_file, 'r') as f:
            for line in f:
                if line.startswith(param_name + '='):
                    print(line.strip().split('=')[1])
                    return
        print(f"Parameter {param_name} does not exist.")
    except FileNotFoundError:
        print("Error: File not found.", config_file)

def update_config(param_name, new_value):
    try:
        with open(config_file, 'r') as f:
            lines = f.readlines()

        with open(config_file, 'w') as f:
            for line in lines:
                if line.startswith(param_name + '='):
                    line = f"{param_name}={new_value}\n"
                f.write(line)
        print("Updated", param_name, "to", new_value)
        if param_name not in ["autoupdate", "default_php_version", "autopatch"]:
            subprocess.run(["service", "panel", "reload"])
            subprocess.run(["rm", "-rf", "/usr/local/panel/core/users/*/data.json"])
    except FileNotFoundError:
        print("Error: File not found.", config_file)


