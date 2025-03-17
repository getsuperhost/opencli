#!/bin/bash
################################################################################
# Script Name: user/change_plan.sh
# Description: Change plan for a user and apply new plan limits.
# Usage: opencli user-change_plan <USERNAME> <NEW_PLAN_NAME>
# Author: Petar Ćurić
# Created: 17.11.2023
# Last Modified: 17.03.2025
# Company: openpanel.co,
# Copyright (c) openpanel.co,
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

# Check if the correct number of parameters is provided
if [ "$#" -ne 2 ] && [ "$#" -ne 3 ]; then
    echo "Usage: opencli user-change-plan <username> <new_plan_name>"
    exit 1
fi

container_name=$1
new_plan_name=$2

debug=false
for arg in "$@"
do
    # Enable debug mode if --debug flag is provided 
    if [ "$arg" == "--debug" ]; then
        debug=true
        break
    fi
done

# DB
source /usr/local/opencli/db.sh

# COMPOSE 
docker_compose_file="/home/$container_name/docker-compose.yml"
if [[ ! -f "$docker_compose_file" ]]; then
    echo "Fatal Error: $docker_compose_file does not exist - changing user limits will not be permanent." >&2
    exit 1
fi

# Function to fetch the current plan ID for the container
get_current_plan_id() {
    local container="$1"
    local query="SELECT plan_id, server FROM users WHERE username = '$container'"
    local result
    result=$(mysql --defaults-extra-file="$config_file" -D "$mysql_database" -N -B -e "$query")

    # Extract plan_id and server from the result
    current_plan_id=$(echo "$result" | awk '{print $1}')
    server=$(echo "$result" | awk '{print $2}')
    if [[ -z "$server" || "$server" == "default" ]]; then
        server="$container"
    fi
}

# Function to fetch plan limits for a given plan ID smece format
get_plan_limits() {
    local plan_id="$1"
    local query="SELECT cpu, ram, docker_image, disk_limit, inodes_limit, bandwidth FROM plans WHERE id = '$plan_id'"
    mysql --defaults-extra-file=$config_file -D "$mysql_database" -N -B -e "$query"
}


get_new_plan_id() {
    local plan_name="$1"
    local query="SELECT id FROM plans WHERE name = '$plan_name'"
    mysql --defaults-extra-file=$config_file -D "$mysql_database" -N -B -e "$query"
}


# Function to fetch single plan limit for a given plan ID and resource type
get_plan_limit() {
    local plan_id="$1"
    local resource="$2"
    local query="SELECT $resource FROM plans WHERE id = '$plan_id'"
    #echo "$query"
    mysql --defaults-extra-file=$config_file -D "$mysql_database" -N -B -e "$query"
}


# Function to fetch the name of a plan for a given plan ID
get_plan_name() {
    local plan_id="$1"
    local query="SELECT name FROM plans WHERE id = '$plan_id'"
    mysql --defaults-extra-file="$config_file" -D "$mysql_database" -N -B -e "$query"
}

# Fetch current plan ID for the container
get_current_plan_id "$container_name"

current_plan_name=$(get_plan_name "$current_plan_id")
new_plan_id=$(get_new_plan_id "$new_plan_name")

# Check if the container exists
if [ -z "$current_plan_id" ]; then
    echo "Error: Container '$container_name' not found in the database."
    exit 1
fi

# Fetch limits for the current plan
current_plan_limits=$(get_plan_limits "$current_plan_id")

# Check if the current plan limits were retrieved
if [ -z "$current_plan_limits" ]; then
    echo "Error: Unable to fetch limits for the current plan ('$current_plan_id')."
    exit 1
fi

# Fetch limits for the new plan
new_plan_limits=$(get_plan_limits "$new_plan_id")

# Check if the new plan limits were retrieved
if [ -z "$new_plan_limits" ]; then
    echo "Error: Unable to fetch limits for the new plan ('$new_plan_id')."
    exit 1
fi






# LIMITS FROM DATABASE
Ncpu=$(get_plan_limit "$new_plan_id" "cpu")
Nram=$(get_plan_limit "$new_plan_id" "ram")
numNram=$(echo "$Nram" | tr -d 'g')
Ndocker_image=$(get_plan_limit "$new_plan_id" "docker_image")
Ndisk_limit=$(get_plan_limit "$new_plan_id" "disk_usage")
numNdisk=$(echo "$Ndisk_limit" | awk '{print $1}')
Ninodes_limit=$(get_plan_limit "$new_plan_id" "inodes_limit")
Nbandwidth=$(get_plan_limit "$new_plan_id" "bandwidth")
storage_in_blocks=$((numNdisk * 1024000))






# SERVER LIMITS
maxCPU=$(nproc)
maxRAM=$(free -g | awk '/^Mem/ {print $2}')





# counters
success_count=0
failure_count=0
write_failure_count=0



get_compose_limit() {
    local key="$1"
    local value=$(grep "^$key=" "$docker_compose_file" | cut -d'=' -f2)
    if [[ -n $value ]]; then
        echo "$value"
    else
        echo "Warning: Key '$key' not found in $docker_compose_file."
        # fallback to mysql!
        Ocpu=$(get_plan_limit "$current_plan_id" "$key")
        Oram=$(get_compose_limit "$current_plan_id" "ram")
    fi





# OLD LIMITS
Odocker_image=$(get_plan_limit "$current_plan_id" "docker_image")
Ocpu=$(get_compose_limit "cpu") # from compose file, fallback to mysql!
Oram=$(get_compose_limit "ram") # from compose file, fallback to mysql!





# FUNCTIONS
update_compose_value() {
    local key="$1"
    local value="$2"

    sed -i "s/^$key=[^ ]*/$key=$value/" "$docker_compose_file" > /dev/null 2>&1
    if grep -q "^$key=$value" "$docker_compose_file"; then
        echo "Successfully updated $key to $value in $docker_compose_file."
    else
        ((write_failure_count++))
        echo "[✘] Error changing $key value in docker compose file for the user"
    fi
}



update_container_cpu() {
    if (( $Ncpu > $maxCPU )); then
        echo "Error: New CPU value exceeds the server limit, not enough CPU cores - $Ncpu > $maxCPU."
        exit 1
    
    else
        if $debug; then
            echo "Updating CPU% limit from: $Ocpu to $Ncpu"
        fi
        command="docker --context $server update --cpus=\"$Ncpu\" \"$container_name\""
        eval $command > /dev/null
        if [ $? -eq 0 ]; then
            ((success_count++))
            echo "[✔] CPU limit ($Ncpu) changed successfully for container."
        else
            ((failure_count++))
            echo "[✘] Error setting CPU limit for the container:"
            echo "Command used: $command"
        fi
        update_compose_value "$docker_compose_file" "cpu" "$Ncpu"
    fi
}



update_container_ram() {
    if (( $numNram > $maxRAM )); then
        echo "Warning: Ram limit not changed for the contianer -new value exceeds the server limit, not enough physical memory - $numNram > $maxRam."
    else
        if $debug; then
            echo "Updating Memory limit from: $Oram to $Nram"
        fi
        command="docker --context $server update --memory=\"$Nram\" --memory-swap=\"$Nram\" \"$container_name\""
        eval $command > /dev/null
        if [ $? -eq 0 ]; then
            ((success_count++))
            echo "[✔] Memory limit $Nram changed successfully for container"
        else
            ((failure_count++))
            echo "[✘] Error setting RAM limit for the container:"
            echo "Command used: $command"
        fi 
        update_compose_value "$docker_compose_file" "memory" "$Nram"
    fi
}



update_container_image() {
    if [[ "$Ndocker_image" != "$Odocker_image" ]]; then
        echo "[✘] Error: can't change docker image."
        ((failure_count++))
    else
        if $debug; then
            echo "[✔] Same docker image $Odocker_image is used on both plans."
        fi
        ((success_count++))
    fi
}



update_used_disk_inodes() {
    if $debug; then
        echo "Changing disk limit from: $Odisk_limit to $Ndisk_limit ($storage_in_blocks)"
        echo "Changing inodes limit from: $Oinodes_limit to $Ninodes_limit"
    fi
    command="setquota -u $container_name $storage_in_blocks $storage_in_blocks $Ninodes_limit $Ninodes_limit /"
    eval $command # set quota for user
    if [ $? -eq 0 ]; then
        ((success_count++))
        echo "[✔] Disk usage limit: $Ndisk_limit and inodes limit: $Ninodes_limit applied successfully to the user."
    else
        ((failure_count++))
        echo "[✘] Error setting disk and inodes limits for the user:"
        echo "Command used: $command"
    fi 
    quotacheck -avm > /dev/null                                                              # recheck for all users
    repquota -u / > /etc/openpanel/openpanel/core/users/repquota                             # store to file for openpanel ui
}



# TODO
update_user_tc() {
    echo "Changing port speed to $Nbandwidth is not possible at the moment."
    #((failure_count++))
}


change_plan_name_in_db() {
    if $debug; then
        echo "Changing plan name for user from '$current_plan_name' to: '$new_plan_name'"
    fi
    
    #Menja ID
    query="UPDATE users SET plan_id = $new_plan_id WHERE username = '$container_name';"
    result=$(mysql -D "$mysql_database" -N -B -e "$query")
    if [ $? -eq 0 ]; then
        if [ $failure_count -gt 0 ]; then
            echo "Plan changed successfuly for user $container_name from $current_plan_name to $new_plan_name - ($failure_count warnings)"
        else
            echo "Plan changed successfuly for user $container_name from $current_plan_name to $new_plan_name"
        fi
    else
        echo "Error changing plan id in the database for user - is mysql service running?"
    fi
}

tada() {
    if [ $write_failure_count -gt 0 ]; then
        echo ""
        echo "Error changing $write_failure_count values in file: $docker_compose_file"
        if $debug; then
            echo "Current values:"
            cat $docker_compose_file
        fi
    fi
}





# MAIN
update_container_image          # todo
update_container_cpu            # update cpu% on container and change in docker compose file
update_container_ram            # update ram on container and change in docker compose file
#update_user_tc                 # todo
update_used_disk_inodes         # change quota for user, check all user files and update cached file for user panel
change_plan_name_in_db          # finally store new plan for user in database
tada                            # check if any errors writing data to compose file, if so, cpu and ram changes are not permanent!

exit 0
