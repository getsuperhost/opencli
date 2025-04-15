# OpenCLI API Reference

This document provides detailed information about the OpenPanel API endpoints accessible through OpenCLI. The API allows programmatic access to OpenPanel functionality for automation and integration with external systems.

## Table of Contents

1. [Overview](#overview)
2. [Authentication](#authentication)
3. [Request Format](#request-format)
4. [Response Format](#response-format)
5. [Error Handling](#error-handling)
6. [Rate Limiting](#rate-limiting)
7. [API Endpoints](#api-endpoints)
8. [Integration Examples](#integration-examples)
9. [Best Practices](#best-practices)

## Overview

The OpenPanel API is a RESTful interface that allows you to manage all aspects of your OpenPanel installation. This includes user management, website management, database operations, and system monitoring.

> **Note:** API access is available only in the Enterprise Edition of OpenPanel. For information on upgrading to the Enterprise Edition, run `opencli license --upgrade`.

## Authentication

The API uses API keys for authentication. Each API key is associated with specific permissions and access levels.

### Obtaining an API Key

To generate a new API key:

```sh
# Only available in Enterprise Edition
opencli api-create-key --name "Integration Name" --permissions "user:read,user:write,website:read"
```

### Using API Keys

Include the API key in the `Authorization` header of your requests:

```
Authorization: Bearer YOUR_API_KEY_HERE
```

## Request Format

API requests should be made using HTTPS to your OpenPanel server's domain. The standard format is:

```
https://your-server.com:2300/api/v1/{endpoint}
```

### HTTP Methods

The API supports the following HTTP methods:

- **GET** - Retrieve resources
- **POST** - Create resources
- **PUT** - Update resources (full replacement)
- **PATCH** - Update resources (partial modification)
- **DELETE** - Remove resources

## Response Format

All API responses are returned in JSON format. A typical successful response structure is:

```json
{
  "success": true,
  "data": {
    // Response data here
  }
}
```

Error responses follow this structure:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message"
  }
}
```

## Error Handling

The API uses standard HTTP status codes to indicate the success or failure of requests:

- `2xx` - Success
- `4xx` - Client error (invalid request, authentication failure, etc.)
- `5xx` - Server error

Common error codes include:

| Status Code | Description | Common Causes |
|-------------|-------------|---------------|
| 400 | Bad Request | Malformed request syntax or invalid parameters |
| 401 | Unauthorized | Missing or invalid API key |
| 403 | Forbidden | Valid API key but insufficient permissions |
| 404 | Not Found | Resource does not exist |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server-side error |

## Rate Limiting

The API enforces rate limits to prevent abuse. Current limits are:

- 100 requests per minute per API key
- 5,000 requests per day per API key

When a rate limit is exceeded, the API returns a 429 status code with information about when the limit will reset.

## API Endpoints

### User Management

#### List Users

```
GET /api/v1/users
```

Query parameters:
- `limit` (optional) - Number of results per page (default: 20, max: 100)
- `page` (optional) - Page number (default: 1)
- `sort` (optional) - Sort field (default: "id")
- `order` (optional) - Sort order ("asc" or "desc", default: "asc")

Response:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "username": "user1",
      "email": "user1@example.com",
      "plan_id": 2,
      "plan_name": "Pro",
      "status": "active",
      "created_at": "2025-01-15T12:00:00Z"
    },
    // More users...
  ],
  "meta": {
    "total": 120,
    "page": 1,
    "limit": 20,
    "pages": 6
  }
}
```

#### Get User Details

```
GET /api/v1/users/{username}
```

Response:
```json
{
  "success": true,
  "data": {
    "id": 1,
    "username": "user1",
    "email": "user1@example.com",
    "plan_id": 2,
    "plan_name": "Pro",
    "status": "active",
    "created_at": "2025-01-15T12:00:00Z",
    "websites": 8,
    "domains": 12,
    "databases": 5,
    "disk_usage": {
      "used": "2.5 GB",
      "limit": "50 GB",
      "percentage": 5
    },
    "inodes_usage": {
      "used": 25000,
      "limit": 500000,
      "percentage": 5
    }
  }
}
```

#### Create User

```
POST /api/v1/users
```

Request body:
```json
{
  "username": "newuser",
  "email": "newuser@example.com",
  "password": "securepassword",
  "plan_id": 2
}
```

Response:
```json
{
  "success": true,
  "data": {
    "id": 121,
    "username": "newuser",
    "email": "newuser@example.com",
    "plan_id": 2,
    "plan_name": "Pro",
    "status": "active",
    "created_at": "2025-03-18T15:30:45Z"
  }
}
```

#### Update User

```
PATCH /api/v1/users/{username}
```

Request body:
```json
{
  "email": "updated@example.com",
  "plan_id": 3
}
```

Response:
```json
{
  "success": true,
  "data": {
    "id": 121,
    "username": "newuser",
    "email": "updated@example.com",
    "plan_id": 3,
    "plan_name": "Business",
    "status": "active",
    "updated_at": "2025-03-19T10:15:22Z"
  }
}
```

#### Delete User

```
DELETE /api/v1/users/{username}
```

Response:
```json
{
  "success": true,
  "message": "User successfully deleted"
}
```

### Website Management

#### List Websites

```
GET /api/v1/websites
```

Query parameters:
- `username` (optional) - Filter by username
- `status` (optional) - Filter by status ("active", "suspended", "all")

Response format similar to user listing.

#### Website Operations

The API supports all website management operations:
- `GET /api/v1/websites/{domain}` - Get website details
- `POST /api/v1/websites` - Create a new website
- `PATCH /api/v1/websites/{domain}` - Update website settings
- `DELETE /api/v1/websites/{domain}` - Delete website

#### SSL Certificates

- `GET /api/v1/websites/{domain}/ssl` - Get SSL certificate status
- `POST /api/v1/websites/{domain}/ssl` - Generate or install SSL certificate

### Database Management

Database API endpoints follow similar patterns to user and website management:

- `GET /api/v1/databases` - List databases
- `GET /api/v1/databases/{name}` - Get database details
- `POST /api/v1/databases` - Create database
- `DELETE /api/v1/databases/{name}` - Delete database

Database user management:
- `GET /api/v1/database-users` - List database users
- `POST /api/v1/database-users` - Create database user
- `PATCH /api/v1/database-users/{username}` - Change password or permissions
- `DELETE /api/v1/database-users/{username}` - Delete database user

### System Information

- `GET /api/v1/system/status` - Get system status
- `GET /api/v1/system/resources` - Get resource usage
- `GET /api/v1/system/plans` - List available plans

## Integration Examples

### cURL

Listing users:
```sh
curl -X GET \
  "https://your-server.com:2300/api/v1/users" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

Creating a new website:
```sh
curl -X POST \
  "https://your-server.com:2300/api/v1/websites" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "domain": "example.com",
    "username": "user1",
    "document_root": "/var/www/example.com"
  }'
```

### Python

```python
import requests

API_URL = "https://your-server.com:2300/api/v1"
API_KEY = "YOUR_API_KEY"
HEADERS = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json"
}

# List all active users
response = requests.get(f"{API_URL}/users", headers=HEADERS, params={"status": "active"})
if response.status_code == 200:
    users = response.json()["data"]
    for user in users:
        print(f"User: {user['username']}, Plan: {user['plan_name']}")
else:
    print(f"Error: {response.status_code}, {response.text}")
```

### PHP

```php
<?php
$apiUrl = "https://your-server.com:2300/api/v1";
$apiKey = "YOUR_API_KEY";

// Create a new database
$data = [
    "name" => "new_database",
    "username" => "user1",
    "charset" => "utf8mb4",
    "collation" => "utf8mb4_unicode_ci"
];

$ch = curl_init("$apiUrl/databases");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    "Authorization: Bearer $apiKey",
    "Content-Type: application/json"
]);

$response = curl_exec($ch);
curl_close($ch);

$result = json_decode($response, true);
if ($result["success"]) {
    echo "Database created successfully!\n";
} else {
    echo "Error: " . $result["error"]["message"] . "\n";
}
?>
```

## Best Practices

1. **Use HTTPS** - Always use HTTPS to ensure secure communication
2. **Handle Rate Limits** - Implement exponential backoff when rate limited
3. **Validate Input** - Validate input data before sending to the API
4. **Error Handling** - Implement robust error handling for all API calls
5. **Minimize Requests** - Batch operations when possible to reduce API calls
6. **Use Specific Permissions** - Create API keys with the minimum required permissions
7. **Authentication Security** - Store API keys securely and rotate them periodically

For more information about the API, run `opencli api-list` to see a complete list of available endpoints.
