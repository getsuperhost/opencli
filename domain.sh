#!/bin/bash
################################################################################
# Script Name: domain.sh
# Description: View and set domain/ip for accessing panels.
# Usage: opencli domain [set <domain_name | ip] 
# Author: Stefan Pejcic
# Created: 09.02.2025
# Last Modified: 17.03.2025
# Company: openpanel.com
# Copyright (c) openpanel.com
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

CADDY_FILE="/etc/openpanel/caddy/Caddyfile"
DOMAINS_DIR="/etc/openpanel/caddy/domains/"

get_server_ipv4(){
	# list of ip servers for checks
	IP_SERVER_1="https://ip.openpanel.com"
	IP_SERVER_2="https://ipv4.openpanel.com"
	IP_SERVER_3="https://ifconfig.me"

	current_ip=$(curl --silent --max-time 2 -4 $IP_SERVER_1 || \
                 wget --timeout=2 -qO- $IP_SERVER_2 || \
                 curl --silent --max-time 2 -4 $IP_SERVER_3)

	# If no site is available, get the ipv4 from the hostname -I
	if [ -z "$current_ip" ]; then
	    # ip addr command is more reliable then hostname - to avoid getting private ip
	    current_ip=$(ip addr|grep 'inet '|grep global|head -n1|awk '{print $2}'|cut -f1 -d/)
	fi

	    is_valid_ipv4() {
	        local ip=$1
	        # is it ip
	        [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] && \
	        # is it private
	        ! [[ $ip =~ ^10\. ]] && \
	        ! [[ $ip =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]] && \
	        ! [[ $ip =~ ^192\.168\. ]]
	    }
	
	   
	if ! is_valid_ipv4 "$current_ip"; then
	        echo "Invalid or private IPv4 address: $current_ip. Please contact support."
	fi

 echo $current_ip

}



do_reload() {
   if [[ "$3" != '--no-restart' ]]; then
       cd /root
       # restart only user panel!
       docker compose restart openpanel > /dev/null 2>&1

	# start caddy if not running!
       docker compose down caddy > /dev/null 2>&1 && docker compose up -d caddy  > /dev/null 2>&1
   fi
}

get_current_domain() {
    current_domain=$(grep -oP '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' /etc/openpanel/caddy/Caddyfile | head -n 1)
    echo "$current_domain"
}

get_current_domain_or_ip() {
   current_domain=$(get_current_domain)
    if [[ $current_domain == 'example.net' ]]; then
        current_domain=$(get_server_ipv4)
    fi
    echo $current_domain
}

update_domain() {

      update_caddyfile() {
	    sed -i "s/$current_domain/$new_hostname/g" $CADDY_FILE
      }

 	create_mv_file() {
 		mkdir -p ${DOMAINS_DIR}
 		if [[ $new_hostname == 'example.net' ]]; then
   			rm ${DOMAINS_DIR}$current_domain.conf 
		else
		    if [ -f "${DOMAINS_DIR}$current_domain.conf" ]; then
		        mv ${DOMAINS_DIR}$current_domain.conf ${DOMAINS_DIR}$new_hostname.conf  > /dev/null 2>&1
		    fi
		    touch ${DOMAINS_DIR}$new_hostname.conf
		fi
	}
      
      update_redirects() {
            
            if [[ $new_hostname == 'example.net' ]]; then
                new_hostname="http://$server_ip"
            else
                new_hostname="https://$new_hostname"
            fi

		sed -i -E 's|(redir @openpanel )https?://[^:]+:|\1'$new_hostname':|; s|(redir @openadmin )https?://[^:]+:|\1'$new_hostname':|' /etc/openpanel/caddy/redirects.conf

	}


	success_msg() {
            if [[ $new_hostname == 'http://example.net' ]]; then
                new_hostname="$server_ip"
            fi
            
            echo "$new_hostname is now set for accessing the OpenPanel and OpenAdmin interfaces."             
	}


      current_domain=$(get_current_domain)
      server_ip=$(get_server_ipv4)
     
      update_caddyfile
      create_mv_file
      update_redirects
      do_reload
      success_msg

}





usage() {

echo "Usage:"
echo ""
echo "opencli domain                        - displays current url  "
echo "opencli domain set example.net        - set domain name for access"
echo "opencli domain ip                     - set IP for access"
}


if [ -z "$1" ]; then
    get_current_domain_or_ip
elif [[ "$1" == 'set' && -n "$2" ]]; then
    if [[ "$2" =~ ^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$ ]]; then
        new_hostname=$2
        update_domain $new_hostname
    else
        echo "Invalid domain format. Please provide a valid domain."
        usage
    fi       
elif [[ "$1" == 'ip' ]]; then
        new_hostname="example.net"
        update_domain $new_hostname
else
    usage
fi

exit 0
           
