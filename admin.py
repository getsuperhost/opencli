#!/usr/bin/env python3

import subprocess
import sqlite3
import os
import sys

CONFIG_FILE_PATH = "/usr/local/panel/conf/panel.config"
SERVICE_NAME = "admin"
# logins_file_path="/usr/local/admin/config.py"
DB_FILE_PATH = "/usr/local/admin/users.db"
CONFIG_FILE = "/usr/local/admin/service/notifications.ini"
GREEN = "\033[0;32m"
RED = "\033[0;31m"
RESET = "\033[0m"


def main(args):
    if len(sys.argv) == 2:
        detect_service_status()
    elif len(sys.argv) > 2:
        command = sys.argv[2]
        #print(command)

        if command == "on":
            print("Enabling the AdminPanel...")
            subprocess.run(["systemctl", "enable", "--now", SERVICE_NAME], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            detect_service_status()
        elif command == "off":
            print("Disabling the AdminPanel...")
            subprocess.run(["systemctl", "disable", "--now", SERVICE_NAME], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            detect_service_status()
        elif command == "password":
            user_flag = sys.argv[3]
            new_password = sys.argv[4]
            if os.path.isfile(DB_FILE_PATH):
                if new_password:
                    update_password(user_flag, new_password)
            else:
                print(f"Error: File {DB_FILE_PATH} does not exist, password not changed for user.")
        elif command == "rename":
            old_username = sys.argv[3]
            new_username = sys.argv[4]
            update_username(old_username, new_username)
        elif command == "list":
            list_current_users()
        elif command == "suspend":
            username = sys.argv[3]
            suspend_user(username)
        elif command == "unsuspend":
            username = sys.argv[3]
            unsuspend_user(username)
        elif command == "new":
            new_username = sys.argv[3]
            new_password = sys.argv[4]
            add_new_user(new_username, new_password)
        elif command == "notifications":
            subcommand = sys.argv[3]
            param_name = sys.argv[4]
            if subcommand == "get":
                get_config(param_name)
            elif subcommand == "update":
                if len(sys.argv) != 6:
                    print(f"Usage: {sys.argv[0]} notifications update <parameter_name> <new_value>")
                    sys.exit(1)
                new_value = sys.argv[5]
                update_config(param_name, new_value)
            else:
                print("Invalid command. Usage: {sys.argv[0]} [get|update] <parameter_name> [new_value]")
                sys.exit(1)
        elif command == "delete":
            username = sys.argv[3]
            delete_existing_users(username)
        else:
            print_usage()
    else:
        print("Incorrect number of arguments provided.")
        print_usage()


def read_config():
    with open(CONFIG_FILE_PATH, "r") as f:
        config_lines = f.readlines()

    config = {}
    parsing_default_section = (
        True
    )  # Flag to indicate whether currently parsing the [DEFAULT] section

    for line in config_lines:
        if line.startswith("[DEFAULT]"):
            parsing_default_section = True
            continue

        if parsing_default_section and "=" in line:
            key, value = line.strip().split("=")
            config[key.strip()] = value.strip()
        elif parsing_default_section and line.startswith("["):
            parsing_default_section = False  # Exiting the [DEFAULT] section

    return config


def get_ssl_status():
    config = read_config()
    ssl_status = config.get("ssl", "no")
    return ssl_status.lower() == "yes"


def get_force_domain():
    config = read_config()
    force_domain = config.get("force_domain", "")

    if not force_domain:
        ip = get_public_ip()
        force_domain = ip

    return force_domain


def get_public_ip():
    try:
        ip = (
            subprocess.check_output(["curl", "-s", "https://ip.openpanel.co"])
            .decode()
            .strip()
        )
    except subprocess.CalledProcessError:
        ip = (
            subprocess.check_output(["wget", "-qO-", "https://ip.openpanel.co"])
            .decode()
            .strip()
        )
    return ip


def detect_service_status():
    try:
        subprocess.check_output(["systemctl", "is-active", "--quiet", SERVICE_NAME])
        is_active = True
    except subprocess.CalledProcessError:
        is_active = False

    if is_active:
        if get_ssl_status():
            hostname = get_force_domain()
            admin_url = f"https://{hostname}:2087/"
        else:
            ip = get_public_ip()
            admin_url = f"http://{ip}:2087/"
        print(f"{GREEN}●{RESET} AdminPanel is running and is available on: {admin_url}")
    else:
        print(
            f"{RED}×{RESET} AdminPanel is not running. To enable it run 'opencli admin on' "
        )


def add_new_user(username, password):
    password_hash = (
        subprocess.check_output(
            ["python3", "/usr/local/admin/core/users/hash", password]
        )
        .decode()
        .strip()
    )
    conn = sqlite3.connect(DB_FILE_PATH)
    cursor = conn.cursor()

    cursor.execute(f"SELECT COUNT(*) FROM user WHERE username='{username}'")
    user_exists = cursor.fetchone()[0]

    if user_exists > 0:
        print(f"{RED}Error{RESET}: Username '{username}' already exists.")
    else:
        try:
            cursor.execute(
                "CREATE TABLE IF NOT EXISTS user (id INTEGER PRIMARY KEY, username TEXT UNIQUE NOT NULL, password_hash TEXT NOT NULL, role TEXT NOT NULL DEFAULT 'user', is_active BOOLEAN DEFAULT 1 NOT NULL)"
            )
            cursor.execute(
                f"INSERT INTO user (username, password_hash) VALUES ('{username}', '{password_hash}')"
            )
            conn.commit()
            print(f"User '{username}' created.")
        except Exception as e:
            print(f"User not created: {e}")
    conn.close()


def update_username(old_username, new_username):
    conn = sqlite3.connect(DB_FILE_PATH)
    cursor = conn.cursor()

    cursor.execute(f"SELECT COUNT(*) FROM user WHERE username='{old_username}'")
    user_exists = cursor.fetchone()[0]

    cursor.execute(f"SELECT COUNT(*) FROM user WHERE username='{new_username}'")
    new_user_exists = cursor.fetchone()[0]

    if user_exists > 0:
        if new_user_exists > 0:
            print(f"{RED}Error{RESET}: Username '{new_username}' already taken.")
        else:
            cursor.execute(
                f"UPDATE user SET username='{new_username}' WHERE username='{old_username}'"
            )
            conn.commit()
            print(f"User '{old_username}' renamed to '{new_username}'.")
    else:
        print(f"{RED}Error{RESET}: User '{old_username}' not found.")
    conn.close()


def update_password(username, new_password):
    password_hash = (
        subprocess.check_output(
            ["python3", "/usr/local/admin/core/users/hash.py", new_password]
        )
        .decode()
        .strip()
    )
    conn = sqlite3.connect(DB_FILE_PATH)
    cursor = conn.cursor()

    cursor.execute(f"SELECT COUNT(*) FROM user WHERE username='{username}'")
    user_exists = cursor.fetchone()[0]

    if user_exists > 0:
        cursor.execute(
            f"UPDATE user SET password_hash='{password_hash}' WHERE username='{username}'"
        )
        conn.commit()
        print(f"Password for user '{username}' changed.")
        print()
        print("=" * 63)
        print()
        detect_service_status()
        print()
        print(f"- username: {username}")
        print(f"- password: {new_password}")
        print()
        print("=" * 63)
        print()
    else:
        print(f"{RED}Error{RESET}: User '{username}' not found.")
    conn.close()


def list_current_users():
    conn = sqlite3.connect(DB_FILE_PATH)
    cursor = conn.cursor()

    cursor.execute("SELECT username, role, is_active FROM user")
    users = cursor.fetchall()

    for user in users:
        print(user)

    conn.close()


def suspend_user(username):
    conn = sqlite3.connect(DB_FILE_PATH)
    cursor = conn.cursor()

    cursor.execute(f"SELECT COUNT(*) FROM user WHERE username='{username}'")
    user_exists = cursor.fetchone()[0]

    cursor.execute(
        f"SELECT COUNT(*) FROM user WHERE username='{username}' AND role='admin'"
    )
    is_admin = cursor.fetchone()[0]

    if user_exists > 0:
        if is_admin > 0:
            print(
                f"{RED}Error{RESET}: Cannot suspend user '{username}' with 'admin' role."
            )
        else:
            cursor.execute(f"UPDATE user SET is_active='0' WHERE username='{username}'")
            conn.commit()
            print(f"User '{username}' suspended successfully.")
    else:
        print(f"{RED}Error{RESET}: User '{username}' does not exist.")

    conn.close()


def unsuspend_user(username):
    conn = sqlite3.connect(DB_FILE_PATH)
    cursor = conn.cursor()

    cursor.execute(f"SELECT COUNT(*) FROM user WHERE username='{username}'")
    user_exists = cursor.fetchone()[0]

    if user_exists > 0:
        cursor.execute(f"UPDATE user SET is_active='1' WHERE username='{username}'")
        conn.commit()
        print(f"User '{username}' unsuspended successfully.")
    else:
        print(f"{RED}Error{RESET}: User '{username}' does not exist.")

    conn.close()


def delete_existing_users(username):
    conn = sqlite3.connect(DB_FILE_PATH)
    cursor = conn.cursor()

    cursor.execute(f"SELECT COUNT(*) FROM user WHERE username='{username}'")
    user_exists = cursor.fetchone()[0]

    cursor.execute(
        f"SELECT COUNT(*) FROM user WHERE username='{username}' AND role='admin'"
    )
    is_admin = cursor.fetchone()[0]

    if user_exists > 0:
        if is_admin > 0:
            print(
                f"{RED}Error{RESET}: Cannot delete user '{username}' with 'admin' role."
            )
        else:
            cursor.execute(f"DELETE FROM user WHERE username='{username}'")
            conn.commit()
            print(f"User '{username}' deleted successfully.")
    else:
        print(f"{RED}Error{RESET}: User '{username}' does not exist.")

    conn.close()


def get_config(param_name):
    with open(CONFIG_FILE, "r") as f:
        lines = f.readlines()

    for line in lines:
        if line.startswith(param_name):
            param_value = line.split("=")[1].strip()
            print(param_value)
            break
    else:
        print(
            f"Parameter {param_name} does not exist. Docs: https://openpanel.co/docs/admin/scripts/openpanel_config#get"
        )


def update_config(param_name, new_value):
    lines = []
    updated = False
    with open(CONFIG_FILE, "r") as f:
        lines = f.readlines()

    for i, line in enumerate(lines):
        if line.startswith(param_name):
            lines[i] = f"{param_name}={new_value}\n"
            updated = True
            break

    if not updated:
        print(
            f"Parameter {param_name} not found in the configuration file. Docs: https://openpanel.co/docs/admin/scripts/openpanel_config#update"
        )
        return

    with open(CONFIG_FILE, "w") as f:
        f.writelines(lines)
    print(f"Updated {param_name} to {new_value}")


    sys.exit(0)
