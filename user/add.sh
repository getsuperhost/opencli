#!/usr/bin/env python3
################################################################################
# Script Name: user/add.py
# Description: Create a new user with the provided plan_id.
# Usage: opencli user-add <USERNAME> <PASSWORD> <EMAIL> <PLAN_ID>
# Docs: https://docs.openpanel.co/docs/admin/scripts/users#add-user
# Author: Stefan Pejcic
# Created: 01.10.2023
# Last Modified: 15.01.2024
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
import os
import random
import string
import configparser

def generate_random_password():
    characters = string.ascii_letters + string.digits
    return ''.join(random.choice(characters) for i in range(12))

def print_usage():
    print(f"Usage: {sys.argv[0]} <username> <password|generate> <email> <plan_id> [--debug]")
    exit(1)

def extract_host_port(username, port_number):
    command = f"docker port {username}"
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, _ = process.communicate()
    lines = output.decode().split('\n')
    host_ports = []
    for line in lines:
        if f"{port_number}/tcp" in line:
            parts = line.split()
            #if "0.0.0.0" in parts[2] or "[::]" in parts[2]:  # Check if IPv4 or IPv6 address is present
            if "0.0.0.0" in parts[2]:
                host_port = parts[-1].split(':')[1]
                host_ports.append(host_port)
    # Remove duplicates
    host_ports = list(set(host_ports))
    return host_ports





def main(args):
    if len(args) < 4 or len(args) > 5:
        print_usage()
    else:
        username = args[0]
        password = args[1]
        email = args[2]
        plan_id = args[3]

        # Check if DEBUG flag is set
        debug = "--debug" in args

        # DB
        config_file = "/usr/local/admin/db.cnf"
        config = configparser.ConfigParser()
        config.read(config_file)
        mysql_database = config.get('database', 'name', fallback='panel')

        # Fetch plan information from the database
        query = f"SELECT cpu, ram, docker_image, disk_limit, inodes_limit, bandwidth, name, storage_file FROM plans WHERE id = '{plan_id}'"
        cpu_ram_info = subprocess.run(
            f"mysql --defaults-extra-file={config_file} -D {mysql_database} -e \"{query}\"", 
            shell=True, 
            capture_output=True, 
            text=True
        ).stdout.strip()

        # Splitting the output
        rows = cpu_ram_info.split('\n')
        if len(rows) < 2:
            print("Error: Unable to fetch plan information from the database or incorrect format.")
            exit(1)

        # Skip the first row (column names)
        cpu_ram_info = rows[1]

        cpu, ram, docker_image, disk_limit_raw, inodes, bandwidth, name, storage_file_raw = cpu_ram_info.split('\t')

        # Process storage_file to remove spaces and 'B' and strip 'GB'
        storage_file = subprocess.run(
            ["echo", storage_file_raw],
            capture_output=True,
            text=True
        ).stdout.strip()
        storage_file = subprocess.run(
            ["sed", "s/ //;s/B//;s/GB//"],
            input=storage_file,
            capture_output=True,
            text=True
        ).stdout.strip()

        # Process disk_limit to strip 'GB'
        disk_limit = subprocess.run(
            ["echo", disk_limit_raw],
            capture_output=True,
            text=True
        ).stdout.strip()
        disk_limit = subprocess.run(
            ["sed", "s/GB//"],
            input=disk_limit,
            capture_output=True,
            text=True
        ).stdout.strip()


        # Creating user directories and files
        try:
            subprocess.run(["fallocate", "-l", f"{storage_file}", f"/home/storage_file_{username}"], check=True)
            subprocess.run(["mkfs.ext4", "-N", f"{inodes}", f"/home/storage_file_{username}"], check=True)
            subprocess.run(["mkdir", f"/home/{username}"], check=True)
            subprocess.run(["chown", "1000:33", f"/home/{username}"], check=True)
            subprocess.run(["chmod", "755", f"/home/{username}"], check=True)
            subprocess.run(["chmod", "g+s", f"/home/{username}"], check=True)
            subprocess.run(["mount", "-o", "loop", f"/home/storage_file_{username}", f"/home/{username}"], check=True)
        except subprocess.CalledProcessError as e:
            print("Error:", e)
            exit(1)

    # Determine the web server based on the Docker image
    if "nginx" in docker_image:
        web_server = "nginx"
    elif "litespeed" in docker_image:
        web_server = "litespeed"
    elif "apache" in docker_image:
        web_server = "apache"
    else:
        web_server = "nginx"

    # Function to create Docker network with bandwidth limiting
    def create_docker_network(name, bandwidth):
        found_subnet = False
        for i in range(18, 255):
            subnet = f"172.{i}.0.0/16"
            gateway = f"172.{i}.0.1"
            used_subnets = subprocess.run(["docker", "network", "ls", "--format", "{{.Name}}"], stdout=subprocess.PIPE, text=True).stdout
            if subnet in used_subnets:
                continue
            try:
                subprocess.run(["docker", "network", "create", "--driver", "bridge", "--subnet", subnet, "--gateway", gateway, name], check=True)
                gateway_interface = subprocess.run(["ip", "route"], stdout=subprocess.PIPE, text=True).stdout.split("\n")[0].split()[2]
                subprocess.run(["sudo", "tc", "qdisc", "add", "dev", gateway_interface, "root", "tbf", "rate", f"{bandwidth}mbit", "burst", f"{bandwidth}mbit", "latency", "3ms"], check=True)
                found_subnet = True
                break
            except subprocess.CalledProcessError as e:
                print(f"Error creating network: {e}")
                continue

        if not found_subnet:
            print("No available subnet found. Exiting.")
            return 1
        create_docker_network()
    
    # Creating Docker container
    container_status = ""
    docker_run_command = ["docker", "run", "--network", name, "-d", "--name", username, "-P", "--storage-opt", f"size={disk_limit}G", "--cpus", cpu, "--memory", ram,
                         "-v", f"/home/{username}/var/crons:/var/spool/cron/crontabs",
                         "-v", f"/home/{username}/etc/{name}/sites-available:/etc/{name}/sites-available",
                         "-v", f"/home/{username}:/home/{username}",
                         "--restart", "unless-stopped",
                         "--hostname", os.uname().nodename, docker_image]
    print(docker_run_command)

    if debug:
        print(" ".join(docker_run_command))
    else:
        subprocess.run(docker_run_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    if not debug:
        container_status = subprocess.run(["docker", "inspect", "-f", "{{.State.Status}}", username], capture_output=True, text=True).stdout.strip()

    if container_status != "running":
        print("Error: Container status is not 'running'. Cleaning up...")
        subprocess.run(["umount", f"/home/{username}"])
        subprocess.run(["docker", "rm", "-f", username])
        subprocess.run(["rm", "-rf", f"/home/{username}"])
        subprocess.run(["rm", f"/home/storage_file_{username}"])
        return 1

    ip_address = subprocess.run(["docker", "container", "inspect", "-f", "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}", username], capture_output=True, text=True).stdout.strip()



    # Fetching IP Address
    ip_address = subprocess.run(
        ["docker", "container", "inspect", "-f", "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}", username],
        capture_output=True,
        text=True
    ).stdout.strip()

        # Check if DEBUG is true before printing private ip
    print("IP ADDRESS:", ip_address)

    # Open ports on firewall
    container_ports = ["22", "3306", "7681", "8080"]
    ports_opened = 0
    for port in container_ports:
        host_ports = extract_host_port(username, port)
        for host_port in host_ports:
            if debug:
                if host_port:
                    print(f"Opening port {host_port} for port {port} in UFW")
                    subprocess.run(["ufw", "allow", f"{host_port}/tcp", "comment", username])
                else:
                    print(f"Port {port} not found in container {username}")
            else:
                print("PRE ELSE PRVI")
                if host_port:
                    print(host_port)
                    subprocess.run(["ufw", "allow", f"{host_port}/tcp", "comment", username])
                    ports_opened = 1


# Restart UFW if ports were opened
    if ports_opened:
        if debug:
            print("Restarting UFW")
            subprocess.run(["ufw", "reload"])
        else:
            subprocess.run(["ufw", "reload"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    # Generate a random password if the second argument is "generate"
    if password == "generate":
        password = subprocess.run(
            ["openssl", "rand", "-base64", "12"],
            capture_output=True,
            text=True
        ).stdout.strip()
    # Hash password
    hashed_password = subprocess.run(
        ["python3", "-c", f"from werkzeug.security import generate_password_hash; print(generate_password_hash('{password}'))"],
        capture_output=True,
        text=True
    ).stdout.strip()
    if debug:
        print(f"Creating SSH user {username} inside the docker container...")
        subprocess.run(["docker", "exec", username, "useradd", "-m", "-s", "/bin/bash", "-d", f"/home/{username}", username])
        subprocess.run(["echo", f"{username}:{password}"], input='', capture_output=True, text=True)
        subprocess.run(["docker", "exec", username, "chpasswd"], input=f"{username}:{password}\n", capture_output=True, text=True)
        subprocess.run(["docker", "exec", username, "usermod", "-aG", "www-data", username])
        subprocess.run(["chmod", "-R", "g+w", f"/home/{username}"])
        subprocess.run(["docker", "exec", username, "chmod", "-R", "g+w", f"/home/{username}"])
        print(f"SSH user {username} created with password: {password}")
    else:
        subprocess.run(["docker", "exec", username, "useradd", "-m", "-s", "/bin/bash", "-d", f"/home/{username}", username], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["echo", f"{username}:{password}"], input='', capture_output=True, text=True)
        chpasswd_process = subprocess.Popen(["docker", "exec", username, "chpasswd"], stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        chpasswd_process.communicate(input=f"{username}:{password}\n".encode())
        subprocess.run(["docker", "exec", username, "usermod", "-aG", "www-data", username], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["chmod", "-R", "g+w", f"/home/{username}"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["docker", "exec", username, "chmod", "-R", "g+w", f"/home/{username}"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    # Define the path to the main configuration file
    config_file = "/usr/local/panel/conf/panel.config"
    # Use grep and awk to extract the value of default_php_version
    default_php_version = subprocess.run(
        ["grep", "-E", "^default_php_version=", config_file],
        capture_output=True,
        text=True
    ).stdout.strip().split("=")[-1]
    # Check if default_php_version is empty (in case the panel.config file doesn't exist)
    if not default_php_version:
        if debug:
            print(f"Default PHP version not found in {config_file} using the fallback default version..")
        default_php_version = "php8.2"
    # Create files and folders needed for the user account
    if debug:
        subprocess.run(["mkdir", "-p", f"/usr/local/panel/core/stats/{username}"])
        subprocess.run(["mkdir", "-p", f"/usr/local/panel/core/users/{username}"])
        subprocess.run(["mkdir", "-p", f"/usr/local/panel/core/users/{username}/domains"])
        subprocess.run(["touch", f"/usr/local/panel/core/users/{username}/elastic.lock"])
        subprocess.run(["touch", f"/usr/local/panel/core/users/{username}/redis.lock"])
        subprocess.run(["touch", f"/usr/local/panel/core/users/{username}/memcached.lock"])
        with open(f"/usr/local/panel/core/users/{username}/server_config.yml", "w") as f:
            f.write(f"web_server: {web_server}\n")
            f.write(f"default_php_version: {default_php_version}\n")
        subprocess.run(["opencli", "php-get_available_php_versions", username])
    else:
        subprocess.run(["mkdir", "-p", f"/usr/local/panel/core/stats/{username}"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["mkdir", "-p", f"/usr/local/panel/core/users/{username}"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["mkdir", "-p", f"/usr/local/panel/core/users/{username}/domains"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["touch", f"/usr/local/panel/core/users/{username}/elastic.lock"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["touch", f"/usr/local/panel/core/users/{username}/redis.lock"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["touch", f"/usr/local/panel/core/users/{username}/memcached.lock"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        with open(f"/usr/local/panel/core/users/{username}/server_config.yml", "w") as f:
            f.write(f"web_server: {web_server}\n")
            f.write(f"default_php_version: {default_php_version}\n")
        subprocess.run(["opencli", "php-get_available_php_versions", username], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        # Insert data into MySQL database
        mysql_query = f"INSERT INTO users (username, password, email, plan_id) VALUES ('{username}', '{hashed_password}', '{email}', '{plan_id}');"

        # Escape the '$' character in the MySQL query string
        mysql_query = mysql_query.replace('$', '\$')

        result = subprocess.run(
            f"mysql --defaults-extra-file={config_file} -D {mysql_database} -e \"{mysql_query}\"", 
            shell=True, 
            capture_output=True, 
            text=True,
        )
        print(mysql_query)
        if result.returncode == 0:
            print("Data insertion into MySQL database was successful.")
        else:
            print("Error: Data insertion into MySQL database failed.")
        print(f"Successfully added user {username} password: {password}")
    

    return 0
