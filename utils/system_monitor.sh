#!/bin/bash
# Generated by Copilot

################################################################################
# Script Name: utils/system_monitor.sh
# Description: System monitoring utility for OpenPanel servers
# Usage: opencli utils-system_monitor [--json] [--intervals=N] [--delay=SECONDS]
# Author: Generated by Copilot
################################################################################

source /usr/local/opencli/functions/error_handling.sh

# Default values
FORMAT="human"
INTERVALS=1
DELAY=2
SCRIPT_NAME=$(basename "$0")

# Parse command line arguments
while [[ $# -gt 0 ]]; do
	case "$1" in
		--json)
			FORMAT="json"
			shift
			;;
		--intervals=*)
			INTERVALS="${1#*=}"
			shift
			;;
		--delay=*)
			DELAY="${1#*=}"
			shift
			;;
		--help)
			echo "Usage: opencli utils-system_monitor [OPTIONS]"
			echo ""
			echo "Options:"
			echo "  --json             Output in JSON format"
			echo "  --intervals=N      Number of monitoring intervals (default: 1)"
			echo "  --delay=SECONDS    Delay between intervals in seconds (default: 2)"
			echo "  --help             Show this help message"
			exit 0
			;;
		*)
			exitWithError "Unknown option: $1" 1 "$SCRIPT_NAME"
			;;
	esac
done

# Ensure jq is installed for JSON output
if [ "$FORMAT" = "json" ] && ! command -v jq &> /dev/null; then
	logWarning "jq is not installed. Installing it now..." "$SCRIPT_NAME"

	if command -v apt-get &> /dev/null; then
		apt-get update > /dev/null 2>&1
		apt-get install -y -qq jq > /dev/null 2>&1
	elif command -v yum &> /dev/null; then
		yum install -y -q jq > /dev/null 2>&1
	elif command -v dnf &> /dev/null; then
		dnf install -y -q jq > /dev/null 2>&1
	else
		exitWithError "No compatible package manager found. Please install jq manually." 1 "$SCRIPT_NAME"
	fi

	if ! command -v jq &> /dev/null; then
		exitWithError "Failed to install jq. Please install it manually." 1 "$SCRIPT_NAME"
	fi

	logInfo "jq installed successfully" "$SCRIPT_NAME"
fi

# Function to get CPU usage
getCpuUsage() {
	top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}'
}

# Function to get memory usage
getMemoryUsage() {
	free -m | awk '/Mem:/ {print $2,$3,$4,$5,$6,$7}'
}

# Function to get disk usage
getDiskUsage() {
	df -h --output=target,size,used,avail,pcent | grep -v "^/dev" | grep -v "^tmpfs" | grep -v "^udev"
}

# Function to get active connections
getConnections() {
	netstat -ant | awk '{print $6}' | sort | uniq -c | sort -n
}

# Function to get Docker container status
getDockerStatus() {
	if command -v docker &> /dev/null; then
		docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
	else
		echo "Docker not installed"
	fi
}

# Function to get system load average
getLoadAverage() {
	uptime | awk -F'[a-z]:' '{ print $2 }' | xargs
}

# Function to collect all metrics
collectMetrics() {
	local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
	local cpu_usage=$(getCpuUsage)
	local mem_data=($(getMemoryUsage))
	local mem_total=${mem_data[0]}
	local mem_used=${mem_data[1]}
	local mem_free=${mem_data[2]}
	local mem_percentage=$((mem_used * 100 / mem_total))
	local load_avg=$(getLoadAverage)

	# Check service status
	local openpanel_status="stopped"
	if docker ps | grep -q "openpanel_openpanel"; then
		openpanel_status="running"
	fi

	local admin_status="stopped"
	if systemctl is-active --quiet admin; then
		admin_status="running"
	fi

	local mysql_status="stopped"
	if docker ps | grep -q "openpanel_mysql"; then
		mysql_status="running"
	fi

	local nginx_status="stopped"
	if systemctl is-active --quiet nginx; then
		nginx_status="running"
	fi

	if [ "$FORMAT" = "json" ]; then
		jq -n \
			--arg timestamp "$timestamp" \
			--arg cpu_usage "$cpu_usage" \
			--arg mem_total "$mem_total" \
			--arg mem_used "$mem_used" \
			--arg mem_free "$mem_free" \
			--arg mem_percentage "$mem_percentage" \
			--arg load_avg "$load_avg" \
			--arg openpanel_status "$openpanel_status" \
			--arg admin_status "$admin_status" \
			--arg mysql_status "$mysql_status" \
			--arg nginx_status "$nginx_status" \
			'{
				"timestamp": $timestamp,
				"cpu": {
					"usage_percentage": ($cpu_usage | tonumber)
				},
				"memory": {
					"total": ($mem_total | tonumber),
					"used": ($mem_used | tonumber),
					"free": ($mem_free | tonumber),
					"usage_percentage": ($mem_percentage | tonumber)
				},
				"load_average": $load_avg,
				"services": {
					"openpanel": $openpanel_status,
					"admin": $admin_status,
					"mysql": $mysql_status,
					"nginx": $nginx_status
				}
			}'
	else
		echo "=== System Monitor Report: $timestamp ==="
		echo ""
		echo "CPU Usage: ${cpu_usage}%"
		echo "Memory: ${mem_used}MB / ${mem_total}MB (${mem_percentage}%)"
		echo "Load Average: $load_avg"
		echo ""
		echo "Service Status:"
		echo "- OpenPanel: $openpanel_status"
		echo "- Admin: $admin_status"
		echo "- MySQL: $mysql_status"
		echo "- Nginx: $nginx_status"
		echo ""
		echo "Disk Usage:"
		getDiskUsage
		echo ""
		echo "Active Connections:"
		getConnections
		echo ""
		echo "Docker Containers:"
		getDockerStatus
		echo ""
		echo "====================================="
	fi
}

# Main monitoring loop
for ((i=1; i<=INTERVALS; i++)); do
	collectMetrics

	if [ "$i" -lt "$INTERVALS" ]; then
		sleep "$DELAY"
	fi
done

exit 0
