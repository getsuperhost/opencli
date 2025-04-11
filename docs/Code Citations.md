# Code Citations

## System monitoring functions
The following code for CPU usage monitoring is adapted from the EasyCWMP project,
which is licensed under GPL-2.0:

Source: https://github.com/pivasoftware/snappy-easycwmp-easycwmp/blob/fef997fc65c5d2fea34a223eb38fb4929e536139/ext/openwrt/scripts/functions/device_info

```bash
# Get CPU usage percentage
cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
```

This code works by:
1. Running `top` in batch mode for a single iteration
2. Extracting the CPU idle percentage with grep and sed
3. Converting idle percentage to usage percentage with awk

The original function has been modified slightly to fit our specific needs
for monitoring system resources in the OpenCLI API.

## Memory monitoring functions
The following memory monitoring functions are written by our team:

```bash
# Get memory usage information
mem_info=$(free -m)
mem_total=$(echo "$mem_info" | awk '/Mem:/ {print $2}')
mem_used=$(echo "$mem_info" | awk '/Mem:/ {print $3}')
mem_percentage=$((mem_used * 100 / mem_total))
```

## Disk monitoring functions
The disk usage monitoring is implemented using standard Linux utilities:

```bash
# Get disk usage information
disk_info=$(df -h --output=used,avail,pcent / | tail -n1)
disk_used=$(echo "$disk_info" | awk '{print $1}')
disk_avail=$(echo "$disk_info" | awk '{print $2}')
disk_percentage=$(echo "$disk_info" | awk '{print $3}' | tr -d '%')
```

## Service status checking
The service monitoring code is custom-written for OpenPanel's architecture:

```bash
# Check OpenPanel service
openpanel_status="running"
docker_ps=$(docker ps -f name=openpanel_openpanel --format '{{.Status}}')
if [ -z "$docker_ps" ]; then
    openpanel_status="stopped"
fi
```

