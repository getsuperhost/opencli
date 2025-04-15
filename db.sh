#!/bin/bash
################################################################################
# Script Name: db.sh
# Description: MySQL database management functions for OpenPanel
# Usage: opencli db [command] [options]
# Author: Stefan Pejcic
# Created: 01.11.2023
# Last Modified: 23.02.2025
# Company: openpanel.com
# Copyright (c) openpanel.com
################################################################################

set -e  # Exit on error

#########################################################################
############################### DB LOGIN ################################
#########################################################################

# MySQL configuration
config_files=("/etc/my.cnf" "/etc/mysql/my.cnf" "$HOME/.my.cnf")
mysql_database="panel"
mysql_user="root"
mysql_defaults_file=""
mysql_use_ssl="false"  # Set to "true" to enable SSL/TLS

# Function to check if any MySQL config file is available
check_config_file() {
    for config_file in "${config_files[@]}"; do
        if [ -f "$config_file" ] && [ -r "$config_file" ]; then
            mysql_defaults_file="$config_file"
            return 0
        fi
    done
    echo "Error: No readable MySQL configuration file found."
    echo "Checked locations: ${config_files[*]}"
    return 1
}

# Check for MySQL client
check_mysql_client() {
    if ! command -v mysql &> /dev/null; then
        echo "Error: MySQL client not found. Please install the MySQL client package."
        return 1
    fi
    return 0
}

# Create base MySQL command with consistent options
get_mysql_base_cmd() {
    local options="$1"
    local base_cmd="mysql"

    # Add defaults file if available
    if [ -n "$mysql_defaults_file" ]; then
        base_cmd="$base_cmd --defaults-file=\"$mysql_defaults_file\""
    fi

    # Add SSL if enabled
    if [ "$mysql_use_ssl" = "true" ]; then
        base_cmd="$base_cmd --ssl"
    fi

    # Add any additional options
    if [ -n "$options" ]; then
        base_cmd="$base_cmd $options"
    fi

    echo "$base_cmd"
}

# Function to execute MySQL commands with proper error handling
execute_mysql_command() {
    local command="$1"
    local options="$2"
    local output_file="$3"
    local error_file="/tmp/mysql_error_$$.tmp"

    # Build the command
    local mysql_cmd
    if [ -z "$mysql_defaults_file" ]; then
        mysql_cmd="mysql $options"
    else
        mysql_cmd="mysql --defaults-file=\"$mysql_defaults_file\" $options"
    fi

    # Add SSL if enabled
    if [ "$mysql_use_ssl" = "true" ]; then
        mysql_cmd="$mysql_cmd --ssl"
    fi

    # Run the command
    if [ -n "$output_file" ]; then
        eval "$mysql_cmd -e \"$command\"" > "$output_file" 2> "$error_file"
    else
        eval "$mysql_cmd -e \"$command\"" 2> "$error_file"
    fi

    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        if [ -s "$error_file" ]; then
            echo "MySQL Error: $(cat "$error_file")"
        else
            echo "MySQL Error: Unknown error occurred (exit code: $exit_code)"
        fi
    fi

    rm -f "$error_file"
    return $exit_code
}

# Create a function for database cache management
init_cache() {
    cache_dir="/tmp/opencli_db_cache"
    cache_ttl=300 # Time to live in seconds (5 minutes)

    # Create cache directory if it doesn't exist
    if [ ! -d "$cache_dir" ]; then
        mkdir -p "$cache_dir" 2>/dev/null
    fi
}

# Function to get/set cached data
get_cached_data() {
    local cache_key="$1"
    local refresh_func="$2"
    local cache_file="${cache_dir}/${cache_key}.cache"

    # Check if cache exists and is fresh
    if [ -f "$cache_file" ] && [ $(($(date +%s) - $(stat -c %Y "$cache_file"))) -lt "$cache_ttl" ]; then
        cat "$cache_file"
    else
        # Generate fresh data using the passed function name
        local result
        result=$($refresh_func)
        echo "$result" > "$cache_file"
        echo "$result"
    fi
}

# Function to invalidate cache
invalidate_cache() {
    local cache_key="$1"
    if [ -z "$cache_key" ]; then
        # Invalidate all cache
        rm -rf "${cache_dir:?}"/* 2>/dev/null
    else
        # Invalidate specific key
        rm -f "${cache_dir}/${cache_key}.cache" 2>/dev/null
    fi
}

# Function to test MySQL connection
test_connection() {
    if execute_mysql_command "SELECT 1" "--silent" &> /dev/null; then
        return 0
    else
        echo "Error: Unable to connect to MySQL server."
        echo "Please check your MySQL credentials and server status."
        return 1
    fi
}

#########################################################################
############################ DB COMMANDS ################################
#########################################################################

# Display database status
db_status() {
    echo "MySQL Database Status:"
    echo "----------------------"

    # Check if MySQL is running
    if systemctl is-active --quiet mysql || systemctl is-active --quiet mariadb; then
        echo "Status: Running"
    else
        echo "Status: Not Running"
        return 1
    fi

    # Display version
    local version=$(execute_mysql_command "SELECT VERSION();" "-N")
    echo "Version: $version"

    # Display database size
    echo -e "\nDatabase Sizes:"
    execute_mysql_command "
    SELECT table_schema AS 'Database',
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
    FROM information_schema.tables
    GROUP BY table_schema
    ORDER BY SUM(data_length + index_length) DESC;" "--table"

    # Display active connections
    echo -e "\nActive Connections:"
    execute_mysql_command "
    SELECT user, host, db, command, time
    FROM information_schema.processlist
    WHERE command != 'Sleep'
    LIMIT 10;" "--table"

    return 0
}

# Backup specified database
db_backup() {
    local backup_db="$1"
    local backup_dir="/var/backups/mysql"
    local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    local backup_file="$backup_dir/${backup_db}_${timestamp}.sql"

    # Create backup directory if it doesn't exist
    if [ ! -d "$backup_dir" ]; then
        mkdir -p "$backup_dir"
    fi

    echo "Creating backup of database '$backup_db'..."

    if ! command -v mysqldump &> /dev/null; then
        echo "Error: mysqldump utility not found."
        return 1
    fi

    if [ -z "$mysql_defaults_file" ]; then
        mysqldump "$backup_db" > "$backup_file" 2>/dev/null
    else
        mysqldump --defaults-file="$mysql_defaults_file" "$backup_db" > "$backup_file" 2>/dev/null
    fi

    if [ $? -eq 0 ]; then
        # Compress the backup file
        gzip -f "$backup_file"
        echo "Backup completed: ${backup_file}.gz"
        echo "Backup size: $(du -h "${backup_file}.gz" | cut -f1)"
    else
        echo "Error: Backup failed."
        return 1
    fi

    return 0
}

# List all databases
db_list() {
    echo "Available Databases:"
    execute_mysql_command "SHOW DATABASES;" "--table"
    return 0
}

# Show tables in a database
db_tables() {
    local target_db="$1"

    if [ -z "$target_db" ]; then
        target_db="$mysql_database"  # Use default if none specified
    fi

    echo "Tables in database '$target_db':"
    execute_mysql_command "SHOW TABLES FROM \`$target_db\`;" "--table"
    return 0
}

# Execute a query
db_query() {
    local target_db="$1"
    local query="$2"

    if [ -z "$target_db" ] || [ -z "$query" ]; then
        echo "Error: Both database and query must be specified."
        return 1
    fi

    echo "Executing query on database '$target_db':"
    echo "$query"
    echo "---------------------------------"
    execute_mysql_command "USE \`$target_db\`; $query;" "--table"
    return 0
}

# Optimize database tables
db_optimize() {
    local target_db="$1"

    if [ -z "$target_db" ]; then
        target_db="$mysql_database"  # Use default if none specified
    fi

    echo "Optimizing tables in database '$target_db'..."

    # Get list of tables
    local tables=$(execute_mysql_command "SHOW TABLES FROM \`$target_db\`;" "-N")

    for table in $tables; do
        echo "  Optimizing table '$table'..."
        execute_mysql_command "OPTIMIZE TABLE \`$target_db\`.\`$table\`;" "--silent"
    done

    echo "Optimization completed."
    return 0
}

# Repair database tables
db_repair() {
    local target_db="$1"

    if [ -z "$target_db" ]; then
        target_db="$mysql_database"  # Use default if none specified
    fi

    echo "Repairing tables in database '$target_db'..."

    # Get list of tables
    local tables=$(execute_mysql_command "SHOW TABLES FROM \`$target_db\`;" "-N")

    for table in $tables; do
        echo "  Repairing table '$table'..."
        execute_mysql_command "REPAIR TABLE \`$target_db\`.\`$table\`;" "--silent"
    done

    echo "Repair completed."
    return 0
}

# Show disk usage
db_size() {
    local target_db="$1"

    if [ -z "$target_db" ]; then
        # Show all database sizes
        echo "Database sizes:"
        execute_mysql_command "
        SELECT table_schema AS 'Database',
        ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
        FROM information_schema.tables
        GROUP BY table_schema
        ORDER BY SUM(data_length + index_length) DESC;" "--table"
    else
        # Show specific database size and table sizes
        echo "Size of database '$target_db':"
        execute_mysql_command "
        SELECT table_schema AS 'Database',
        ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
        FROM information_schema.tables
        WHERE table_schema = '$target_db'
        GROUP BY table_schema;" "--table"

        echo -e "\nTable sizes in database '$target_db':"
        execute_mysql_command "
        SELECT table_name AS 'Table',
        ROUND(data_length / 1024 / 1024, 2) AS 'Data Size (MB)',
        ROUND(index_length / 1024 / 1024, 2) AS 'Index Size (MB)',
        ROUND((data_length + index_length) / 1024 / 1024, 2) AS 'Total Size (MB)'
        FROM information_schema.tables
        WHERE table_schema = '$target_db'
        ORDER BY (data_length + index_length) DESC;" "--table"
    fi

    return 0
}

# Show available database engines
db_engines() {
    echo "Available database engines:"
    execute_mysql_command "SHOW ENGINES;" "--table"
    return 0
}

# Handle database creation
db_create() {
    local db_name="$1"
    local charset="${2:-utf8mb4}"
    local collation="${3:-utf8mb4_unicode_ci}"

    if [ -z "$db_name" ]; then
        echo "Error: Database name is required."
        echo "Usage: opencli db create <database_name> [charset] [collation]"
        return 1
    fi

    echo "Creating database '$db_name' with charset '$charset' and collation '$collation'..."

    execute_mysql_command "CREATE DATABASE IF NOT EXISTS \`$db_name\` CHARACTER SET $charset COLLATE $collation;" || return 1

    echo "Database '$db_name' created successfully."

    # Invalidate database list cache
    invalidate_cache "db_list"
    return 0
}

# Handle database deletion
db_drop() {
    local db_name="$1"
    local force="$2"

    if [ -z "$db_name" ]; then
        echo "Error: Database name is required."
        echo "Usage: opencli db drop <database_name> [--force]"
        return 1
    fi

    # Safety check for production/important databases
    if [ "$db_name" = "mysql" ] || [ "$db_name" = "information_schema" ] || [ "$db_name" = "performance_schema" ] || [ "$db_name" = "sys" ]; then
        echo "Error: Cannot drop system database '$db_name'."
        return 1
    fi

    if [ "$force" != "--force" ]; then
        read -p "Are you sure you want to drop database '$db_name'? This cannot be undone. [y/N] " -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Database drop cancelled."
            return 1
        fi
    fi

    echo "Dropping database '$db_name'..."

    execute_mysql_command "DROP DATABASE IF EXISTS \`$db_name\`;" || return 1

    echo "Database '$db_name' dropped successfully."

    # Invalidate database list cache
    invalidate_cache "db_list"
    return 0
}

# Display usage information
show_usage() {
    echo "Usage: opencli db [command] [options]"
    echo ""
    echo "Commands:"
    echo "  status              Show database server status"
    echo "  list                List all databases"
    echo "  tables [db]         List tables in the specified database (default: panel)"
    echo "  backup [db]         Backup the specified database (default: panel)"
    echo "  size [db]           Show database disk usage"
    echo "  optimize [db]       Optimize database tables"
    echo "  repair [db]         Repair database tables"
    echo "  query [db] [query]  Execute a SQL query on the specified database"
    echo "  engines             Show available database engines"
    echo "  create [db]         Create a new database"
    echo "  drop [db]           Drop a database"
    echo ""
    echo "Examples:"
    echo "  opencli db status"
    echo "  opencli db backup panel"
    echo "  opencli db size"
    echo "  opencli db query panel \"SELECT * FROM users LIMIT 5;\""
    echo "  opencli db create newdb"
    echo "  opencli db drop olddb"
    echo ""
}

#########################################################################
############################### MAIN LOGIC ##############################
#########################################################################

# Check prerequisites
check_config_file || exit 1
check_mysql_client || exit 1

# Initialize cache
init_cache

# Parse command-line arguments
if [ $# -eq 0 ]; then
    show_usage
    exit 0
fi

command="$1"
shift

case "$command" in
    status)
        test_connection && db_status
        ;;
    list)
        test_connection && db_list
        ;;
    tables)
        test_connection && db_tables "$1"
        ;;
    backup)
        db_name="${1:-$mysql_database}"
        test_connection && db_backup "$db_name"
        ;;
    size)
        test_connection && db_size "$1"
        ;;
    optimize)
        db_name="${1:-$mysql_database}"
        test_connection && db_optimize "$db_name"
        ;;
    repair)
        db_name="${1:-$mysql_database}"
        test_connection && db_repair "$db_name"
        ;;
    query)
        if [ $# -lt 2 ]; then
            echo "Error: Both database and query must be specified."
            show_usage
            exit 1
        fi
        test_connection && db_query "$1" "$2"
        ;;
    engines)
        test_connection && db_engines
        ;;
    create)
        db_create "$1" "$2" "$3"
        ;;
    drop)
        db_drop "$1" "$2"
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        echo "Error: Unknown command '$command'"
        show_usage
        exit 1
        ;;
esac

exit $?
