import json
import mysql.connector

CONFIG_FILE_PATH = '/usr/local/admin/config.json'

def load_config():
    try:
        with open(CONFIG_FILE_PATH, 'r') as config_file:
            config_data = json.load(config_file)
            return config_data
    except FileNotFoundError:
        raise Exception(f"Config file not found at {CONFIG_FILE_PATH}")
    except json.JSONDecodeError:
        raise Exception(f"Invalid JSON format in config file: {CONFIG_FILE_PATH}")

def connect_to_database():
    config_data = load_config()
    conn = mysql.connector.connect(
        host=config_data['mysql_host'],
        user=config_data['mysql_user'],
        password=config_data['mysql_password'],
        database=config_data['mysql_database']
    )
    return conn

def close_database_connection(conn):
    if conn:
        conn.close()
