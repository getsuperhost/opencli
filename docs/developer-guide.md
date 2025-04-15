# OpenCLI Developer Guide

This document provides technical details about OpenCLI's architecture, implementation, and development guidelines.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Directory Structure](#directory-structure)
3. [Command Execution Flow](#command-execution-flow)
4. [Development Guidelines](#development-guidelines)
5. [Security Considerations](#security-considerations)
6. [Testing Procedures](#testing-procedures)
7. [Advanced Features](#advanced-features)
8. [Contributing](#contributing)

## Architecture Overview

OpenCLI is built with a modular architecture focused on extensibility and maintainability. The system consists of:

- A main entry point (`/usr/local/bin/opencli`)
- A hierarchical directory of command scripts
- Shared utility libraries for common functions
- Specialized modules for database, password, and error handling

The design follows these key principles:

1. **Command Discoverability**: Commands are automatically detected based on the file structure
2. **Consistent Interface**: All commands follow a standard format for arguments and output
3. **Security First**: Secure handling of sensitive operations and data
4. **Performance Optimization**: Caching and efficient processing for resource-intensive operations

## Directory Structure

```
/usr/local/opencli/
├── commands.sh           # Command listing and documentation generator
├── error.py              # Error handling and reporting system
├── completion.sh         # Bash completion implementation
├── user/                 # User management commands
│   ├── add.sh
│   ├── remove.sh
│   ├── list.sh
│   └── modify.sh
├── db/                   # Database management commands
│   ├── create.sh
│   ├── drop.sh
│   ├── backup.sh
│   └── restore.sh
├── website/              # Website management commands
│   ├── add.sh
│   ├── remove.sh
│   ├── enable.sh
│   └── disable.sh
├── ssl/                  # SSL certificate management
│   ├── generate.sh
│   ├── install.sh
│   └── check.sh
├── lib/                  # Shared libraries
│   ├── db_functions.sh   # Database utility functions
│   ├── password_utils.sh # Password management functions
│   └── logger.sh         # Logging utilities
└── aliases.txt           # Generated list of command aliases
```

## Command Execution Flow

When a user runs an OpenCLI command, the following sequence occurs:

1. The `opencli` main script is invoked with arguments
2. The command name is parsed and mapped to the corresponding script path
   - Hyphens in the command name are translated to directory separators
   - Example: `opencli user-add` → `/usr/local/opencli/user/add.sh`
3. Command execution is logged to `/var/log/openpanel/admin/opencli.log`
4. The appropriate script is executed with any remaining arguments
5. Return code from the script is passed back to the user

### Example Flow Diagram

```
User Input → opencli user-add username password
     │
     ↓
Main Script (`/usr/local/bin/opencli`)
     │
     ↓
Log Command to `/var/log/openpanel/admin/opencli.log`
     │
     ↓
Resolve to Script Path `/usr/local/opencli/user/add.sh`
     │
     ↓
Execute Script with Arguments `username password`
     │
     ↓
Script Processing (potentially using shared libraries)
     │
     ↓
Return Result to User
```

## Development Guidelines

### Creating New Commands

To add a new command to OpenCLI:

1. Create a new script file in the appropriate directory
2. Use the standard header template (shown below)
3. Implement proper parameter validation and error handling
4. Provide meaningful exit codes and error messages
5. Document the command's usage with `Description:` and `Usage:` comments

#### Command Script Template

```bash
#!/bin/bash
################################################################################
# Script Name: command_name.sh
# Description: Brief description of what the command does
# Usage: opencli command-name [arguments]
# Author: Your Name
# Created: DD.MM.YYYY
# Last Modified: DD.MM.YYYY
# Company: openpanel.com
# Copyright (c) openpanel.com
################################################################################

# Source common libraries
source /usr/local/opencli/lib/common.sh

# Parse arguments
if [ "$#" -lt 1 ]; then
  echo "Error: Missing required arguments"
  echo "Usage: opencli command-name [arguments]"
  exit 1
fi

# Command implementation
...

# Exit with appropriate status code
exit 0
```

### Error Handling

All scripts should follow these error handling principles:

1. Validate all user inputs before processing
2. Use meaningful exit codes (0 for success, non-zero for failures)
3. Include descriptive error messages for failure cases
4. Write significant errors to the log file
5. For serious errors, use the error code format `ERRxxxxx` to enable lookup

### Code Style Guidelines

- Use 2-space indentation
- Variables in `lower_snake_case`
- Constants in `UPPER_SNAKE_CASE`
- Always quote variable references (`"$var"` not `$var`)
- Include comments for non-obvious code sections
- Use functions for code that is used more than once

## Security Considerations

### Sensitive Data Handling

When dealing with sensitive data such as passwords:

1. Never output sensitive data to logs
2. Use secure password generation when possible
3. Utilize the encryption utilities in `/usr/local/opencli/lib/password_utils.sh`
4. Don't pass sensitive data as command-line arguments when possible
5. Clean up temporary files containing sensitive data

### Database Operations

For database operations:

1. Always use parameterized queries when possible
2. Validate database names to prevent SQL injection
3. Use SSL/TLS for database connections when available
4. Apply the principle of least privilege for database users
5. Use the provided database functions in `/usr/local/opencli/lib/db_functions.sh`

## Testing Procedures

### Manual Testing

Before submitting any new command or change:

1. Test with valid inputs to verify correct operation
2. Test with invalid or boundary inputs to ensure proper error handling
3. Verify that error messages are helpful and actionable
4. Check if the command works correctly in both interactive and non-interactive modes

### Automated Testing

The `test/` directory contains automated tests for OpenCLI commands:

```bash
# Run all tests
/usr/local/opencli/test/run_tests.sh

# Run tests for a specific module
/usr/local/opencli/test/run_tests.sh user
```

## Advanced Features

### Database Command Caching

Performance-sensitive database operations use a caching system to reduce load:

```bash
# Example of using the caching system
source /usr/local/opencli/lib/db_functions.sh

# Initialize cache
init_cache

# Get cached data, or refresh if needed
websites=$(get_cached_data "website_list" fetch_website_list)

# Invalidate cache when data changes
invalidate_cache "website_list"
```

### Password Management System

The secure password system uses AES-256-CBC encryption with PBKDF2:

```bash
# Example of using the password system
source /usr/local/opencli/lib/password_utils.sh

# Generate a secure password
password=$(generate_password 16 true)

# Store a password securely
add_password "db_admin" "$password"

# Retrieve a password
get_password "db_admin"
```

### Error Analysis System

The Python-based error system provides comprehensive error analysis:

```bash
# Example of using the error system
opencli error ERR12345  # Look up specific error

# Advanced error analysis commands
opencli error --recent   # Show recent errors
opencli error --analyze  # Show error patterns
opencli error --export   # Export error database
```

## Contributing

### Submitting Changes

1. Fork the repository
2. Create a feature branch
3. Implement your changes following the guidelines in this document
4. Add tests for your changes
5. Submit a pull request with a clear description of the changes

### Code Review Process

All contributions undergo code review to ensure:

1. Adherence to coding standards
2. Proper error handling
3. Adequate test coverage
4. Documentation completeness
5. Security best practices

### Documentation

When adding or modifying features, update the relevant documentation:

1. Update command descriptions in script headers
2. Add examples to the user guide if applicable
3. Document any API changes in the developer guide
4. Update the changelog with your changes

For questions or further guidance, contact the OpenPanel development team.
