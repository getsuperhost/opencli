#!/bin/bash
################################################################################
# Script Name: plan/create.sh
# Description: Create a new hosting plan (Package) and set its limits.
# Usage: opencli plan-create plan_name description email_limit ftp_limit domains_limit websites_limit disk_limit inodes_limit db_limit cpu ram docker_image bandwidth
# name= Name of the plan
# description= Plan description, multiple words allowed inside ""
# email_limit= How many email accounts will the plan have (0 is unlimited).
# ftp_limit= How many ftp accounts will the plan have (0 is unlimited).
# domains_limit= How many domains will the plan have (0 is unlimited).
# websites_limit= How many websites will the plan have (0 is unlimited).
# disk_limit=Disk space limit in GB.
# inodes_limit= inodes limit, it will be automatically set to 500000 if the value is less than 500000.
# db_limit= Database number limit (0 is unlimited).
# cpu= number of cores limit
# ram= Ram space limit in GB.
# docker_image=can be either apache/nginx
# bandwidth=port speed, expressed in mbit/s
# Exsample: ./usr/local/opencli/plan/create plan "new plan" 10 5 10 500000 5 2 4 nginx 1500
# Author: Radovan Jecmenica
# Created: 06.11.2023
# Last Modified: 14.03.2025
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

# Function to display script usage
usage() {
    echo "Usage: opencli plan-create 'name' 'description' email_limit ftp_limit domains_limit websites_limit disk_limit inodes_limit db_limit cpu ram docker_image bandwidth"
    echo
    echo "Arguments:"
    echo "  name          - Name of the plan (string, no spaces)."
    echo "  description   - Plan description (string, use quotes for multiple words)."
    echo "  email_limit   - Max number of email accounts (integer, 0 for unlimited)."
    echo "  ftp_limit     - Max number of FTP accounts (integer, 0 for unlimited)."
    echo "  domains_limit - Max number of domains (integer, 0 for unlimited)."
    echo "  websites_limit- Max number of websites (integer, 0 for unlimited)."
    echo "  disk_limit    - Disk space limit in GB (integer)."
    echo "  inodes_limit  - Max number of inodes (integer, min 250000)."
    echo "  db_limit      - Max number of databases (integer, 0 for unlimited)."
    echo "  cpu           - CPU core limit (integer)."
    echo "  ram           - RAM limit in GB (integer)."
    echo "  docker_image  - Web server type ('apache' or 'nginx')."
    echo "  bandwidth     - Port speed in Mbit/s (integer)."
    echo
    echo "Example:"
    echo "  opencli plan-create 'basic' 'Basic Hosting Plan' 10 5 10 5 50 500000 10 2 4 nginx 1000"
    echo
    exit 1
}

# Check for minimum required arguments
if [ "$#" -lt 13 ]; then
    usage
fi


# DB
source /usr/local/opencli/db.sh

# Function to insert values into the database
insert_plan() {
  local name="$1"
  local description="$2"
  local email_limit="$3"
  local ftp_limit="$4"
  local domains_limit="$5"
  local websites_limit="$6"
  local disk_limit="$7"
  local inodes_limit="$8"
  local db_limit="${9}"
  local cpu="${10}"
  local ram="${11}"
  local docker_image="${12}"
  local bandwidth="${13}"
  
# Format disk_limit with 'GB' 
disk_limit="${disk_limit} GB"

  # Ensure inodes_limit is not less than 500000
  if [ "$inodes_limit" -lt 250000 ]; then
    inodes_limit=250000
  fi

  # Format ram with 'g' at the end
  ram="${ram}g"

  # Insert the plan into the 'plans' table
  local sql="INSERT INTO plans (name, description, email_limit, ftp_limit, domains_limit, websites_limit, disk_limit, inodes_limit, db_limit, cpu, ram, docker_image, bandwidth) VALUES ('$name', '$description', $email_limit, $ftp_limit, $domains_limit, $websites_limit, '$disk_limit', $inodes_limit, $db_limit, $cpu, '$ram', '$docker_image', $bandwidth);"

  mysql --defaults-extra-file=$config_file -D "$mysql_database" -e "$sql"
  if [ $? -eq 0 ]; then
    echo "Inserted: $name into plans"
  else
    echo "Failed to insert: $name into plans"
  fi
}



     ensure_tc_is_installed(){
            # Check if tc is installed
            if ! command -v tc &> /dev/null; then
                # Detect the package manager and install tc
                if command -v apt-get &> /dev/null; then
                    sudo apt-get update > /dev/null 2>&1
                    sudo apt-get install -y -qq iproute2 > /dev/null 2>&1
                elif command -v yum &> /dev/null; then
                    sudo yum install -y -q iproute2 > /dev/null 2>&1
                elif command -v dnf &> /dev/null; then
                    sudo dnf install -y -q iproute2 > /dev/null 2>&1
                else
                    echo "Error: No compatible package manager found. Please install tc command (iproute2 package) manually and try again."
                    exit 1
                fi
        
                # Check if installation was successful
                if ! command -v tc &> /dev/null; then
                    echo "Error: jq installation failed. Please install jq manually and try again."
                    exit 1
                fi
            fi
   }


# Function to check available CPU cores
check_cpu_cores() {
  local available_cores=$(nproc)
  
  if [ "$cpu" -gt "$available_cores" ]; then
    echo "Error: Insufficient CPU cores. Required: ${cpu}, Available: ${available_cores}"
    exit 1
  fi
}

# Function to check available RAM
check_available_ram() {
  local available_ram=$(free -g | awk '/^Mem:/{print $2}')
  
  if [ "$ram" -gt "$available_ram" ]; then
    echo "Error: Insufficient RAM. Required: ${ram}GB, Available: ${available_ram}GB"
    exit 1
  fi
}

# Check for command-line arguments
if [ "$#" -lt 13 ]; then
    echo "Usage: opencli plan-create 'name' 'description' email_limit ftp_limit domains_limit websites_limit disk_limit inodes_limit db_limit cpu ram docker_image bandwidth"
    exit 1
fi


# Capture command-line arguments
name="$1"
description="$2"
email_limit="$3"
ftp_limit="$4"
domains_limit="$5"
websites_limit="$6"
disk_limit="$7"
inodes_limit="$8"
db_limit="$9"
cpu="${10}"
ram="${11}"
docker_image="${12}"
bandwidth="${13}"

# Check available CPU cores before creating the plan
check_cpu_cores "$cpu"

# Check available RAM before creating the plan
check_available_ram "$ram"

# Function to check if the plan name already exists in the database
check_plan_exists() {
  local name="$1"
  local sql="SELECT name FROM plans WHERE name='$name';"
  local result=$(mysql --defaults-extra-file=$config_file -D "$mysql_database" -N -B -e "$sql")
  echo "$result"
}

# Determine the appropriate table name based on the docker_image value
if [ "$docker_image" == "nginx" ]; then
  docker_image="openpanel/nginx"
elif [ "$docker_image" == "litespeed" ]; then
  docker_image="openpanel/litespeed"
elif [ "$docker_image" == "apache" ]; then
  docker_image="openpanel/apache"
else
  docker_image="${12}"
fi

# Check if the plan name already exists in the database
existing_plan=$(check_plan_exists "$name")
if [ -n "$existing_plan" ]; then
  echo "Plan name '$name' already exists. Please choose another name."
  exit 1
fi


# Call the insert_plan function with the provided values
insert_plan "$name" "$description" "$email_limit" "$ftp_limit" "$domains_limit" "$websites_limit" "$disk_limit" "$inodes_limit" "$db_limit" "$cpu" "$ram" "$docker_image" "$bandwidth"
