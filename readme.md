
# Varnish API Caching Example

This project demonstrates how to configure **Varnish Cache** to handle API requests efficiently, including authentication and caching strategies for secure and non-secure endpoints.

## Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Setup and Running](#setup-and-running)
  - [1. Start the NGINX Backend](#1-start-the-nginx-backend)
  - [2. Start Varnish Cache](#2-start-varnish-cache)
- [Testing the Setup](#testing-the-setup)
  - [Test Commands](#test-commands)
- [Viewing Logs](#viewing-logs)
- [Configuration Details](#configuration-details)
  - [NGINX Configuration](#nginx-configuration)
  - [Varnish Configuration](#varnish-configuration)
- [References](#references)

---

## Overview

This project includes:
- **NGINX Backend**: Acts as the API server, serving static files and handling API requests.
- **Varnish Cache**: Acts as a reverse proxy and caching layer, handling authentication and caching responses based on defined rules.

Varnish is configured to:
- Authenticate requests to certain endpoints.
- Cache both secure and non-secure API responses based on URL rules.
- Use custom headers to indicate cache status.

---

## Project Structure

```
.
├── README.md
├── start_nginx.sh
├── start_cache.sh
├── log.sh
├── nginx.conf
├── default.vcl
└── html/
    ├── authenticate.html
    ├── index.html
    ├── secure.html
    ├── secure_cached.html
    ├── unsecure.html
    └── unsecure_cached.html
```

---

## Prerequisites

- **Docker** installed on your system.
- Basic knowledge of command-line operations.

---

## Setup and Running

### 1. Start the NGINX Backend

Run the following script to start the NGINX backend:

```bash
./start_nginx.sh
```

This script:
- Stops and removes any existing NGINX container.
- Starts a new NGINX container named `nginx-server`.
- Maps port 9080 on the host to port 80 in the container.
- Mounts `html/` and `nginx.conf` into the container.

---

### 2. Start Varnish Cache

Run the following script to start Varnish:

```bash
./start_cache.sh
```

This script:
- Stops and removes any existing Varnish container.
- Starts a new Varnish container named `varnish-appcache`.
- Maps port 9090 on the host to port 80 in the container.
- Mounts `default.vcl` into the container.

---

## Testing the Setup

After starting both NGINX and Varnish, test the caching behavior.

### Test Commands

#### 1. Unauthenticated, Non-Cached:

```bash
curl -i http://localhost:9090/unsecure.html
```

Expected Output:
- **X-Cache**: uncached
- Static content from `unsecure.html`.

#### 2. Unauthenticated, Cached:

```bash
curl -i http://localhost:9090/unsecure_cached.html
```

Expected Output:
- **X-Cache**: cached (on subsequent requests)
- Static content from `unsecure_cached.html`.

#### 3. Authenticated, Non-Cached:

```bash
curl -i -H "x-client-certificate: token" http://localhost:9090/secure.html
```

Expected Output:
- **X-Cache**: uncached
- Static content from `secure.html`.

#### 4. Authenticated, Cached:

```bash
curl -i -H "x-client-certificate: token" http://localhost:9090/secure_cached.html
```

Expected Output:
- **X-Cache**: cached (on subsequent requests)
- Static content from `secure_cached.html`.

---

## Viewing Logs

Use the following script to view Varnish logs:

```bash
./log.sh
```

This displays Varnish log output filtered for `std.log` entries from `default.vcl`.

---

## Configuration Details

### NGINX Configuration

File: `nginx.conf`

- Serves static content from the `html/` directory.
- Listens on port 80 within the container.

---

### Varnish Configuration

File: `default.vcl`

- **Backend Configuration**:
  - Points to the NGINX server running on `host.docker.internal` port `9080`.

- **Request Handling** (`vcl_recv`):
  - Logs incoming requests.
  - Differentiates between secure and non-secure requests.
  - Handles authentication for secure requests and passes them to the backend if required.
  - Determines caching strategy (pass or hash) based on URL patterns.

- **Response Handling** (`vcl_backend_response`):
  - Caches responses for a defined duration (e.g., 20 seconds) unless they are manifest files.

- **Delivery Handling** (`vcl_deliver`):
  - Adds the `X-Cache` header to indicate caching status.
  - Restarts requests with proper authentication if needed.

---

## References

- [Varnish Cache Documentation](https://varnish-cache.org/docs/)
- [NGINX Documentation](https://nginx.org/)
- [Docker Documentation](https://docs.docker.com/)
