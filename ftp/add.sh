#!/bin/bash
################################################################################
# Script Name: ftp/add.sh
# Description: Create FTP sub-user for openpanel user.
# Usage: opencli ftp-add <NEW_USERNAME> <NEW_PASSWORD> <FOLDER> <OPENPANEL_USERNAME>
# Docs: https://docs.openpanel.com
# Author: Stefan Pejcic
# Created: 22.05.2024
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

if [ "$#" -lt 4 ] || [ "$#" -gt 5 ]; then
    echo "Usage: opencli ftp-add <new_username> <new_password> '<directory>' <openpanel_username> [--debug]"
    exit 1
fi

username="${1,,}"
password="$2"
directory="$3"
openpanel_username="$4"
DEBUG=false  # Default value for DEBUG


# Parse optional flags to enable debug mode when needed!
for arg in "$@"; do
    case $arg in
        --debug)
            DEBUG=true
            ;;
        *)
            ;;
    esac
done




check_and_start_ftp_server(){
	if [ $(docker ps -q -f name=openadmin_ftp) ]; then
	    :
	else
        cd /root && docker compose up -d ftp_env_generator  >/dev/null 2>&1
	    cd /root && docker compose up -d openadmin_ftp  >/dev/null 2>&1
	fi
}



# Function to read users from users.list files and create them
create_user() {
    docker exec openadmin_ftp sh -c "echo -e '${password}\n${password}' | adduser -h ${directory} -s /sbin/nologin -G xfs ${username} > /dev/null 2>&1"
    # group xfs is id 33 in alpine, but www-data in ubuntu

    # Check if the command was successful
    if [ $? -eq 0 ]; then
        mkdir -p $directory
        #chown 1000:33 $directory # causes user not to be able to write!
        echo "$username|$password|$directory" >> /etc/openpanel/ftp/users/${openpanel_username}/users.list        
        echo "Success: FTP user '$username' created successfully."
    else
        if [ "$DEBUG" = true ]; then
            echo "ERROR: Failed to create FTP user with command:"     
            echo ""
            echo "docker exec openadmin_ftp sh -c 'echo -e ${password}\n${password} | adduser -h $directory -s /sbin/nologin $username'"
            echo ""
            echo "Run the command manually to check for errors."
        else
            echo "ERROR: Failed to create FTP user. To debug run this command on terminal: opencli ftp-add $username $password '$directory' $openpanel_username --debug"  
        fi
        exit 1
    fi
}







# user.openpanel_username
if [[ ! $username == *".${openpanel_username}" ]]; then
    echo "ERROR: FTP username must end with openpanel username, example: '$username.$openpanel_username'"
    echo "       docs: https://openpanel.com/docs/articles/accounts/forbidden-usernames/#ftp"
    exit 1
fi


# Check if password length is at least 8 characters
if [ ${#password} -lt 8 ]; then
    echo "ERROR: Password is too short. It must be at least 8 characters long."
    echo "       docs: https://openpanel.com/docs/articles/accounts/forbidden-usernames/#ftp"
    exit 1
fi

# Check if password contains at least one uppercase letter
if ! [[ $password =~ [A-Z] ]]; then
    echo "ERROR: Password must contain at least one uppercase letter."
    echo "       docs: https://openpanel.com/docs/articles/accounts/forbidden-usernames/#ftp"
    exit 1
fi

# Check if password contains at least one lowercase letter
if ! [[ $password =~ [a-z] ]]; then
    echo "ERROR: Password must contain at least one lowercase letter."
    echo "       docs: https://openpanel.com/docs/articles/accounts/forbidden-usernames/#ftp"
    exit 1
fi

# Check if password contains at least one digit
if ! [[ $password =~ [0-9] ]]; then
    echo "ERROR: Password must contain at least one digit."
    echo "       docs: https://openpanel.com/docs/articles/accounts/forbidden-usernames/#ftp"
    exit 1
fi

# Check if password contains at least one special character
if ! [[ $password =~ [[:punct:]] ]]; then
    echo "ERROR: Password must contain at least one special character."
    echo "       docs: https://openpanel.com/docs/articles/accounts/forbidden-usernames/#ftp"
    exit 1
fi


# check if ftp user exists
user_exists() {
    local user="$1"
    grep -Fq "$user|" /etc/openpanel/ftp/users/${openpanel_username}/users.list
}

mkdir -p /etc/openpanel/ftp/users/${openpanel_username}
touch /etc/openpanel/ftp/users/${openpanel_username}/users.list

# Check if user already exists
if user_exists "$username"; then
    echo "Error: FTP User '$username' already exists."
    exit 1
fi

# check folder path is under the openpanel_username home folder
if [[ $directory != /home/$openpanel_username* ]]; then
    echo "ERROR: Invalid folder '$directory' - folder must start with '/home/$openpanel_username/'."
    exit 1
fi




check_and_start_ftp_server    # start ftpserver
create_user                   # create new user
