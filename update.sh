#!/usr/bin/python3

################################################################################
# Script Name: update.py
# Description: Checks if updates are enabled and then if an update is available.
# Usage: opencli update
#        opencli update --force
# Author: Stefan Pejcic
# Created: 10.10.2023
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
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
################################################################################


import subprocess
import json
import sys
import os
import tempfile


# Function to check if an update is needed
def check_update():
    force_update = False

    # Check if the '--force' flag is provided
    if "--force" in sys.argv:
        force_update = True
        print("Forcing updates, ignoring autopatch and autoupdate settings.")

    # Read the user settings from /usr/local/panel/conf/panel.config
    if force_update:
        # When the '--force' flag is provided, set autopatch and autoupdate to "on"
        autopatch = "on"
        autoupdate = "on"
    else:
        with open("/usr/local/panel/conf/panel.config", "r") as config_file:
            for line in config_file:
                if line.startswith("autopatch="):
                    autopatch = line.strip().split("=")[1]
                elif line.startswith("autoupdate="):
                    autoupdate = line.strip().split("=")[1]

    # Only proceed if autopatch or autoupdate is set to "on"
    if autopatch == "on" or autoupdate == "on" or force_update:
        # Run the update_check.py script to get the update status
        update_status = subprocess.run(["opencli", "update_check"], capture_output=True, text=True).stdout.strip()

        # Extract the local and remote version from the update status
        update_status = json.loads(update_status)
        local_version = update_status.get("installed_version")
        remote_version = update_status.get("latest_version")

        # Check if remote_version is available
        if remote_version is None:
            print("No update available.")
            return

        # Compare local and remote versions
        if local_version < remote_version or force_update:
            print("Update is available and will be automatically installed.")

            # Incrementally update from local_version to remote_version
            while local_version < remote_version:
                local_version = get_next_version(local_version)
                print(f"Updating to version {local_version}")
            # Fetch the script content
            script_content = subprocess.run(f"wget -q -O - https://update.openpanel.co/versions/{local_version}", shell=True, capture_output=True, text=True).stdout
            
            # Create a temporary file and write the script content
            with tempfile.NamedTemporaryFile(mode="w", delete=False) as temp_file:
                temp_file.write(script_content)
                temp_file_path = temp_file.name
            
            # Execute the script
            subprocess.run(f"bash {temp_file_path}", shell=True)

            # Clean up temporary file
            os.unlink(temp_file_path)
        else:
            print("No update available.")
    else:
        print("Autopatch and Autoupdate are both set to 'off'. No updates will be installed automatically.")

# Function to compare two semantic versions
def compare_versions(version1, version2):
    array1 = version1.split(".")
    array2 = version2.split(".")

    for i in range(len(array1)):
        if int(array1[i]) > int(array2[i]):
            return 1  # version1 > version2
        elif int(array1[i]) < int(array2[i]):
            return -1  # version1 < version2

    return 0  # version1 == version2

# Function to get the next semantic version
def get_next_version(version):
    array = version.split(".")
    array[-1] = str(int(array[-1]) + 1)
    return ".".join(array)

# Main function
def main(args):
    check_update()

# Call main function if executed as a script
if __name__ == "__main__":
    main(sys.argv[1:])
