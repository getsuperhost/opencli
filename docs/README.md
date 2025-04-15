# OpenCLI Documentation

Welcome to the official documentation for OpenCLI, the command-line interface for managing [OpenPanel](https://openpanel.com/).

## Table of Contents

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Usage](#usage)
4. [Command Structure](#command-structure)
5. [Common Commands](#common-commands)
6. [Configuration](#configuration)
7. [Error Handling](#error-handling)
8. [Password Management](#password-management)
9. [Database Management](#database-management)
10. [Troubleshooting](#troubleshooting)

## Introduction

OpenCLI is a powerful command-line interface designed to simplify the management of OpenPanel installations. It provides a comprehensive set of tools for system administrators to efficiently manage websites, databases, users, and other aspects of their hosting environment.

## Installation

OpenCLI is installed automatically with OpenPanel. The installation process adds the `opencli.sh` script to the system path, making it accessible via the `opencli` command. The `commands.sh` script generates a list of all available commands for autocomplete functionality in your shell.

To update OpenCLI independently:

```sh
cd /usr/local/opencli && git pull
```

## Usage

The basic syntax for OpenCLI commands is:

```sh
opencli <command> [arguments]
```

For example:

```sh
opencli user-add username password
```

## Command Structure

OpenCLI commands follow a consistent structure. The command name consists of the directory path within the scripts directory, with slashes replaced by hyphens.

For example, to run the script at `/usr/local/opencli/user/add.sh`, you would use:

```sh
opencli user-add
```

## Common Commands

Here are some of the most frequently used OpenCLI commands:

- `opencli help` - Display help information and recent commands
- `opencli commands` - List all available commands and their usage
- `opencli error <id>` - Look up detailed information about an error
- `opencli faq` - Display frequently asked questions and answers

For a complete list of available commands, run:

```sh
opencli commands
```

## Configuration

OpenCLI automatically reads configuration from standard OpenPanel configuration files. The system is designed to be modular, allowing for independent updates of just the CLI component when needed.

## Error Handling

OpenCLI includes a sophisticated error handling system that provides:

- Detailed error messages with color highlighting (when supported)
- Historical error tracking and analysis
- Smart log formatting for better readability

To investigate an error code:

```sh
opencli error <error-code>
```

## Password Management

OpenCLI includes a secure password management system with:

- Strong password generation
- AES-256-CBC encryption with PBKDF2 key derivation
- Clipboard integration for secure password usage

## Database Management

OpenCLI provides robust database management features including:

- SSL/TLS support for secure database connections
- Query caching for performance optimization
- Safety checks for database creation and deletion

## Troubleshooting

If you encounter issues with OpenCLI:

1. Check that your OpenCLI installation is up to date
2. Verify that the script directory exists at `/usr/local/opencli`
3. Check the log file at `/var/log/openpanel/admin/opencli.log`
4. Use the `opencli error` command to investigate specific error codes

For additional support, visit the [OpenPanel documentation](https://dev.openpanel.com/cli/).
