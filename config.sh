#!/bin/bash
################################################################################
# Script Name: config.sh
# Description: View / change configuration for users and set defaults for new accounts.
# Usage: opencli config get <setting_name>
#        opencli config update <setting_name> <new_value>
# Author: Stefan Pejcic
# Created: 01.11.2023
# Last Modified: 23.02.2025
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

config_file="/etc/openpanel/openpanel/conf/openpanel.config"

# Check if configuration file exists
if [ ! -f "$config_file" ]; then
    echo "Error: Configuration file $config_file not found."
    exit 1
fi

# Check if configuration file is readable
if [ ! -r "$config_file" ]; then
    echo "Error: Cannot read configuration file $config_file. Please check permissions."
    exit 1
fi

########################## UPDATE NGINX PROXY FILE FOR DOMAINS ##########################
proxy_conf_file="/etc/openpanel/nginx/vhosts/openpanel_proxy.conf"

# Function to update SSL configuration in proxy_conf_file
update_ssl_config() {
    ssl_value="$1"

    # Validate SSL parameter
    if [ "$ssl_value" != "yes" ] && [ "$ssl_value" != "no" ]; then
        echo "Error: SSL value must be 'yes' or 'no'."
        exit 1
    fi

    # Check if proxy configuration file exists
    if [ ! -f "$proxy_conf_file" ]; then
        echo "Error: Proxy configuration file $proxy_conf_file not found."
        return 1
    fi

    if [ "$ssl_value" = "yes" ]; then
        # Update https to http in the proxy_conf_file if it's not already present
        if grep -q 'return 301[[:space:]]\+http://' "$proxy_conf_file"; then
            sed -i 's|return 301[[:space:]]\+http:|return 301 https:|' "$proxy_conf_file"
            echo "Updated SSL configuration to use HTTPS"
        else
            echo "SSL is already configured as 'https' in $proxy_conf_file"
        fi
    elif [ "$ssl_value" = "no" ]; then
        # Update http to https in the proxy_conf_file if it's not already present
        if grep -q 'return 301[[:space:]]\+https://' "$proxy_conf_file"; then
            sed -i 's|return 301[[:space:]]\+https:|return 301 http:|' "$proxy_conf_file"
            echo "Updated SSL configuration to use HTTP"
        else
            echo "SSL is already configured as 'http' in $proxy_conf_file"
        fi
    fi
}

# Function to update port configuration in proxy_conf_file
update_port_config() {
    new_port="$1"

    # Validate port parameter
    if ! [[ "$new_port" =~ ^[0-9]+$ ]] || [ "$new_port" -lt 1 ] || [ "$new_port" -gt 65535 ]; then
        echo "Error: Invalid port number. Must be between 1-65535."
        exit 1
    fi

    # Check if proxy configuration file exists
    if [ ! -f "$proxy_conf_file" ]; then
        echo "Error: Proxy configuration file $proxy_conf_file not found."
        return 1
    fi

    current_port=$(grep -oE 'return 301 https://[^:]+:([0-9]+);|return 301 http://[^:]+:([0-9]+);' "$proxy_conf_file" | grep -oE '[0-9]+;' | tr -d ';')

    if [ "$current_port" = "$new_port" ]; then
        echo "Port is already set to $new_port"
        return 0
    fi

    sed -Ei "s|(return 301 https://[^:]+:)([0-9]+;)|\1$new_port;|;s|(return 301 http://[^:]+:)([0-9]+;)|\1$new_port;|" "$proxy_conf_file"
    echo "Updated port configuration from $current_port to $new_port"
}

# Function to update openpanel_proxy configuration in proxy_conf_file
update_openpanel_proxy_config() {
    new_value="$1"

    # Check if proxy configuration file exists
    if [ ! -f "$proxy_conf_file" ]; then
        echo "Error: Proxy configuration file $proxy_conf_file not found."
        return 1
    fi

    current_value=$(grep -A1 "location /$$$$ {" "$proxy_conf_file" | grep -o '/[^[:space:]]*' | head -n 1)

    if [ "$current_value" = "/$new_value" ]; then
        echo "Proxy value is already set to $new_value"
        return 0
    fi

    # Update the value in the 2nd line after "location /$$$$ {"
    sed -i "0,/location \/openpanel/{n;s|/[^[:space:]]*|/$new_value|}" "$proxy_conf_file"
    echo "Updated openpanel_proxy configuration from $current_value to /$new_value"
}

##############################################################################

# Function to get the current configuration value for a parameter
get_config() {
    param_name="$1"

    # Check if parameter name is provided
    if [ -z "$param_name" ]; then
        echo "Error: Parameter name is required."
        return 1
    fi

    # Find the parameter in the config file
    param_value=$(grep "^$param_name=" "$config_file" | cut -d= -f2-)

    if [ -n "$param_value" ]; then
        echo "$param_value"
    elif grep -q "^$param_name=" "$config_file"; then
        echo "Parameter $param_name has no value."
    else
        echo "Parameter $param_name does not exist."
        # List available parameters as a suggestion
        echo "Available parameters:"
        grep -o "^[^=]*=" "$config_file" | tr -d '=' | sort | sed 's/^/  /'
    fi
}

# Function to update a configuration value
update_config() {
    param_name="$1"
    new_value="$2"

    # Check if required parameters are provided
    if [ -z "$param_name" ]; then
        echo "Error: Parameter name is required."
        return 1
    fi

    if [ -z "$new_value" ]; then
        echo "Error: New value is required."
        return 1
    fi

    # Check if the parameter exists in the config file
    if grep -q "^$param_name=" "$config_file"; then
        # Get current value before updating
        current_value=$(grep "^$param_name=" "$config_file" | cut -d= -f2-)

        # Skip update if values are the same
        if [ "$current_value" = "$new_value" ]; then
            echo "Parameter $param_name already has value '$new_value'"
            return 0
        fi

        # Update the parameter with the new value
        sed -i "s/^$param_name=.*/$param_name=$new_value/" "$config_file"
        echo "Updated $param_name from '$current_value' to '$new_value'"

        # Restart the panel service for all settings except autoupdate, default_php_version, and autopatch
        if [ "$param_name" != "autoupdate" ] && [ "$param_name" != "default_php_version" ] && [ "$param_name" != "autopatch" ]; then
            echo "Restarting openpanel service..."
            docker restart openpanel &> /dev/null &                        # run in bg, and dont show error if panel not running
            rm -rf /etc/openpanel/openpanel/core/users/*/data.json         # remove data.json files for all users
        fi

    else
        echo "Parameter $param_name not found in the configuration file."
        # List available parameters as a suggestion
        echo "Available parameters:"
        grep -o "^[^=]*=" "$config_file" | tr -d '=' | sort | sed 's/^/  /'
        return 1
    fi
}

# Function to list all available parameters in the config file
list_config() {
    echo "Available configuration parameters:"
    grep -o "^[^=]*=" "$config_file" | tr -d '=' | sort | while read param; do
        value=$(grep "^$param=" "$config_file" | cut -d= -f2-)
        echo "  $param = $value"
    done
}

# Main script logic
if [ "$#" -lt 1 ]; then
    echo "Usage: opencli config [get|update|list] <parameter_name> [new_value]"
    exit 1
fi

command="$1"

case "$command" in
    get)
        if [ "$#" -lt 2 ]; then
            echo "Usage: opencli config get <parameter_name>"
            exit 1
        fi
        param_name="$2"
        get_config "$param_name"
        ;;
    update)
        if [ "$#" -lt 3 ]; then
            echo "Usage: opencli config update <parameter_name> <new_value>"
            exit 1
        fi
        param_name="$2"
        new_value="$3"
        update_config "$param_name" "$new_value"

        # Handle special parameters that require additional actions
        case "$param_name" in
            ssl)
                update_ssl_config "$new_value"
                ;;
            port)
                update_port_config "$new_value"
                ;;
            openpanel_proxy)
                update_openpanel_proxy_config "$new_value"
                echo "Restarting nginx service..."
                docker restart nginx &> /dev/null &
                ;;
        esac
        ;;
    list)
        list_config
        ;;
    *)
        echo "Invalid command. Usage: opencli config [get|update|list] <parameter_name> [new_value]"
        exit 1
        ;;
esac
