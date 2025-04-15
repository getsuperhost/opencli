#!/usr/bin/env python3
"""
OpenCLI Error Log Utility
This script extracts error logs from the OpenPanel container based on an error ID.

Usage:
  opencli error <ERROR_CODE> [--time=<period>]
  opencli error --list
"""

import subprocess
import argparse
import sys
import re
import json
from datetime import datetime, timedelta
import os
import tempfile
from typing import List, Dict, Optional, Tuple, Any

# ANSI color codes for terminal output
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    END = '\033[0m'

    @staticmethod
    def supports_color() -> bool:
        """Check if the terminal supports color output"""
        if os.environ.get('NO_COLOR') is not None:
            return False

        # Check if we're in a terminal
        if not sys.stdout.isatty():
            return False

        # Check platform-specific settings
        platform = sys.platform
        if platform == 'win32':
            return 'ANSICON' in os.environ or 'WT_SESSION' in os.environ

        return True

# Error database with common error codes and their explanations
ERROR_DATABASE = {
    "ERR-001": "Database connection failed. Check database credentials and server status.",
    "ERR-002": "File permission denied. Check file ownership and permissions.",
    "ERR-003": "Invalid configuration parameter.",
    "ERR-004": "Service failed to start. Check service configuration.",
    "ERR-005": "Network connection timeout.",
    "ERROR-AUTH": "Authentication failed. Check credentials.",
    "ERROR-QUOTA": "User quota exceeded.",
    "ERR-DNS": "DNS resolution failed. Check DNS configuration."
}

def format_log_output(log_lines: List[str], error_code: str) -> str:
    """Format the log output with proper highlighting and structure"""
    if not log_lines:
        return f"Error Code '{error_code}' not found in the OpenPanel UI logs."

    formatted = []
    for line in log_lines:
        # Highlight the error code in the output
        if Colors.supports_color():
            highlighted_line = line.replace(error_code, f"{Colors.BOLD}{Colors.RED}{error_code}{Colors.END}")

            # Highlight ERROR text in red
            highlighted_line = re.sub(r'(ERROR|CRITICAL|FATAL)',
                                    f"{Colors.RED}\\1{Colors.END}",
                                    highlighted_line)

            # Highlight WARNING text in yellow
            highlighted_line = re.sub(r'(WARNING|WARN)',
                                    f"{Colors.YELLOW}\\1{Colors.END}",
                                    highlighted_line)

            # Highlight timestamps
            highlighted_line = re.sub(r'(\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2})',
                                    f"{Colors.BLUE}\\1{Colors.END}",
                                    highlighted_line)
        else:
            highlighted_line = line

        formatted.append(highlighted_line)

    return '\n'.join(formatted)

def save_error_to_database(error_code: str, log_lines: List[str]) -> None:
    """Save newly discovered error codes to local database for future reference"""
    if not error_code or not log_lines:
        return

    db_path = os.path.expanduser("~/.local/share/opencli/errors.json")
    os.makedirs(os.path.dirname(db_path), exist_ok=True)

    error_db = {}
    if os.path.exists(db_path):
        try:
            with open(db_path, 'r') as f:
                error_db = json.load(f)
        except (json.JSONDecodeError, IOError):
            # If the file is corrupted or unreadable, start with a new database
            error_db = {}

    # Extract a potential error message from log lines
    error_message = ""
    for line in log_lines:
        if "error:" in line.lower() or "exception:" in line.lower():
            error_message = line.strip()
            break

    timestamp = datetime.now().isoformat()

    if error_code not in error_db:
        error_db[error_code] = {
            "first_seen": timestamp,
            "last_seen": timestamp,
            "count": 1,
            "message": error_message
        }
    else:
        error_db[error_code]["last_seen"] = timestamp
        error_db[error_code]["count"] += 1
        if error_message and not error_db[error_code].get("message"):
            error_db[error_code]["message"] = error_message

    try:
        with open(db_path, 'w') as f:
            json.dump(error_db, f, indent=2)
    except IOError as e:
        print(f"Warning: Could not save error database: {e}")

def get_error_explanation(error_code: str) -> Optional[str]:
    """Get explanation for an error code from the error database"""
    # Check built-in database first
    if error_code in ERROR_DATABASE:
        return ERROR_DATABASE[error_code]

    # Check local database
    db_path = os.path.expanduser("~/.local/share/opencli/errors.json")
    if os.path.exists(db_path):
        try:
            with open(db_path, 'r') as f:
                error_db = json.load(f)
                if error_code in error_db and error_db[error_code].get("message"):
                    return error_db[error_code]["message"]
        except (json.JSONDecodeError, IOError):
            pass

    return None

def extract_error_log_from_docker(error_code: str, time_period: str = "60m") -> List[str]:
    """
    Extract error logs from Docker container logs that contain the specified error code

    Args:
        error_code (str): The error code to search for
        time_period (str): Time period to look back (e.g., "60m", "24h")

    Returns:
        list: List of log lines containing the error code and context
    """
    try:
        # Validate time period format
        if not re.match(r'^\d+[mhsdw]$', time_period):
            print(f"Warning: Invalid time period format '{time_period}'. Using default of 60m.")
            time_period = "60m"

        # Run docker logs command to get container logs
        result = subprocess.run(
            ['docker', '--context', 'default', 'logs', f'--since={time_period}', 'openpanel'],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=True
        )
    except subprocess.CalledProcessError as e:
        if e.returncode == 125:
            print("Error: Docker container 'openpanel' not found.")
            print("Suggestions:")
            print("  - Check if Docker is running")
            print("  - Check if container name is correct")
            print("  - Try running 'docker ps' to view available containers")
            return []
        elif e.returncode == 127:
            print("Error: Docker command not found. Is Docker installed?")
            print("Suggestions:")
            print("  - Install Docker: https://docs.docker.com/get-docker/")
            print("  - Ensure Docker is in your PATH")
            return []
        else:
            print(f"Error running docker logs (code {e.returncode}): {e.stdout}")
            return []
    except FileNotFoundError:
        print("Error: Docker command not found. Is Docker installed?")
        print("Suggestions:")
        print("  - Install Docker: https://docs.docker.com/get-docker/")
        print("  - Ensure Docker is in your PATH")
        return []

    logs = result.stdout.splitlines()

    # Check if we have any logs
    if not logs:
        print("\nNo logs found in the OpenPanel container for the specified time period.")
        return []

    result_log = []
    found_error_code = False
    search_pattern = error_code.lower()

    # Look for the error code and build context
    context_before = []
    context_after_count = 0
    max_context_before = 5  # Number of lines to show before the error
    max_context_after = 10  # Number of lines to show after the error

    for line in reversed(logs):
        line_lower = line.lower()

        # If we found the error code, collect a few more lines for context
        if found_error_code:
            result_log.append(line.strip())
            context_after_count += 1
            if context_after_count >= max_context_after and ('ERROR' in line or 'WARNING' in line):
                break
            if context_after_count >= 20:  # Hard limit on context lines
                break
        # Look for the error code
        elif search_pattern in line_lower:
            found_error_code = True
            result_log.append(line.strip())
            # Add the context we've been collecting
            result_log.extend(context_before)
        # Keep a sliding window of context lines
        else:
            if len(context_before) >= max_context_before:
                context_before.pop(0)
            context_before.append(line.strip())

    result_log.reverse()

    # Save this error to our database for future reference
    save_error_to_database(error_code, result_log)

    return result_log

def find_all_error_codes(time_period: str = "24h") -> List[Dict[str, Any]]:
    """Find all error codes in the container logs"""
    try:
        result = subprocess.run(
            ['docker', '--context', 'default', 'logs', f'--since={time_period}', 'openpanel'],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=True
        )
        logs = result.stdout

        # Extract error codes - assuming they follow common patterns
        error_patterns = [
            r'(?:ERROR|ERR)-[A-Z0-9]+',
            r'Error code: [A-Z0-9-]+',
            r'Error ID: [A-Z0-9-]+',
            r'Exception ID: [A-Z0-9-]+'
        ]

        error_info = []
        for pattern in error_patterns:
            matches = re.findall(pattern, logs, re.IGNORECASE)
            for match in matches:
                code = match.strip()
                if not any(info["code"] == code for info in error_info):
                    # Find a log line example
                    lines = logs.splitlines()
                    example = next((line for line in lines if code.lower() in line.lower()), "")

                    error_info.append({
                        "code": code,
                        "count": len(re.findall(re.escape(code), logs, re.IGNORECASE)),
                        "example": example[:100] + "..." if len(example) > 100 else example
                    })

        return sorted(error_info, key=lambda x: x["count"], reverse=True)

    except Exception as e:
        print(f"Error retrieving logs: {e}")
        return []

def main() -> None:
    """Main function to parse arguments and call log extraction"""
    parser = argparse.ArgumentParser(
        description="Extract error logs from the OpenPanel container by error code.",
        epilog="Example: opencli error ABC123 --time 24h"
    )
    parser.add_argument("error_code", nargs='?', help="The error code to search for in the logs")
    parser.add_argument("--time", "-t", default="60m",
                        help="Time period to look back (e.g., 60m, 24h, 7d). Default: 60m")
    parser.add_argument("--list", "-l", action="store_true",
                        help="List all error codes found in logs")
    parser.add_argument("--verbose", "-v", action="store_true",
                        help="Show more detailed information")

    args = parser.parse_args()

    if args.list:
        # List all error codes in the logs
        if Colors.supports_color():
            print(f"{Colors.BOLD}Searching for error codes in the logs...{Colors.END}")
        else:
            print("Searching for error codes in the logs...")

        error_codes = find_all_error_codes(args.time)

        if error_codes:
            if Colors.supports_color():
                print(f"\n{Colors.BOLD}Found {len(error_codes)} error code(s):{Colors.END}")
            else:
                print(f"\nFound {len(error_codes)} error code(s):")

            for error in error_codes:
                if Colors.supports_color():
                    print(f"  {Colors.RED}{error['code']}{Colors.END} - {error['count']} occurrences")
                else:
                    print(f"  {error['code']} - {error['count']} occurrences")

                if args.verbose and error['example']:
                    print(f"    Example: {error['example']}")

                # Show explanation if available
                explanation = get_error_explanation(error['code'])
                if explanation:
                    if Colors.supports_color():
                        print(f"    {Colors.YELLOW}Explanation:{Colors.END} {explanation}")
                    else:
                        print(f"    Explanation: {explanation}")
        else:
            print("No error codes found in the logs.")

        return

    if not args.error_code:
        parser.print_help()
        return

    error_log = extract_error_log_from_docker(args.error_code, args.time)

    # Print the result
    if not error_log:
        if Colors.supports_color():
            print(f"\n{Colors.BOLD}=== NO LOGS FOR ERROR ID: '{args.error_code}' ==={Colors.END}\n")
        else:
            print(f"\n=== NO LOGS FOR ERROR ID: '{args.error_code}' ===\n")

        print(f"The error code '{args.error_code}' was not found in the logs from the past {args.time}.")
        print("\nTips:")
        print(" - Try increasing the time window with --time parameter (e.g., --time 24h)")
        print(" - Check if the error code is correct")
        print(" - Use 'opencli error --list' to see all error codes in the logs")
    else:
        if Colors.supports_color():
            print(f"\n{Colors.BOLD}=== LOGS FOR ERROR ID: '{args.error_code}' ==={Colors.END}\n")
        else:
            print(f"\n=== LOGS FOR ERROR ID: '{args.error_code}' ===\n")

        # Check for known explanation
        explanation = get_error_explanation(args.error_code)
        if explanation:
            if Colors.supports_color():
                print(f"{Colors.YELLOW}Explanation:{Colors.END} {explanation}\n")
            else:
                print(f"Explanation: {explanation}\n")

        formatted_output = format_log_output(error_log, args.error_code)
        print(formatted_output)

        if Colors.supports_color():
            print(f"\nShowing {len(error_log)} log lines containing error code '{args.error_code}'")
        else:
            print(f"\nShowing {len(error_log)} log lines containing error code '{args.error_code}'")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nOperation cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}")
        sys.exit(1)
