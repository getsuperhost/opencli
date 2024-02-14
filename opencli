#!/bin/bash
################################################################################
# Script Name: /usr/local/bin/opencli
# Description: Makes all OpenCLI commands available on the terminal.
# Usage: opencli <COMMAND-NAME>
# Author: Stefan Pejcic
# Created: 15.11.2023
# Last Modified: 30.11.2023
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

# Check if the correct number of arguments is provided
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <COMMAND> [additional_arguments]"
  exit 1
fi

# Define the directory containing the binaries
script_dir="/usr/local/admin/scripts"

# Get the binary name from the first argument
binary_name="$1"

# Replace '-' with '/' in the binary name
binary_command="${binary_name//-//}"

# Check if the Python script file exists in the specified directory
script_path="$script_dir/$binary_command.py"
if [ -f "$script_path" ]; then
  # Shift to remove the script name from the arguments
  shift

  # Execute the Python script with additional arguments if provided
  if [ "$#" -gt 0 ]; then
    python3 "$script_path" "$@"
  else
    python3 "$script_path"
  fi
else
  echo "Error: Script '$script_name' not found in '$script_dir'"
  exit 1
fi
