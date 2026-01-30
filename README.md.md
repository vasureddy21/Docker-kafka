# Confluent Platform on Docker (RHEL VM)

This repository contains everything required to install Docker on a **RHEL-based VM**, build a **custom Confluent Platform Docker image**, and run Kafka ecosystem services using Docker Compose.

Read this once. If something breaks after this, it’s because you skipped a step or made assumptions.

---

## 📁 File Overview

```
Dockerfile-rhel
 docker-compose.yml
 docker-compose-restart.yml
 docker-install.sh
 start-confluent.sh
```

Each file has a **very specific responsibility**. Mixing concerns or running them out of order will break things.

---

## 1️⃣ docker-install.sh

### Purpose
Installs **Docker Engine** and **Docker Compose** on a RHEL VM with pinned, compatible versions.

### What it does
- Configures Docker CE repository
- Installs Docker Engine and CLI
- Installs Docker Compose plugin
- Enables and starts Docker service
- Verifies installation

### When to use
Run this **once per VM**, before anything else.

### How to run
```
chmod +x docker-install.sh
./docker-install.sh
```

If Docker is not running after this, stop. Don’t proceed.

---

## 2️⃣ Dockerfile-rhel

### Purpose
Builds a **custom Docker image** based on **RHEL** with:
- Confluent Platform installed
- Required OS dependencies
- Runtime utilities (curl, netcat, jq, etc.)

This image is the **base image** used by all Kafka-related containers.

### What it does
- Uses a RHEL base image
- Installs Java and system dependencies
- Extracts Confluent Platform package
- Sets directory structure
- Prepares runtime environment

### What it does NOT do
- Does NOT start Kafka
- Does NOT start services automatically
- Does NOT format storage

That is intentional. Startup is controlled explicitly.

### Build command
```
docker build -f Dockerfile-rhel -t confluent-rhel:latest .
```

If this build fails, Docker Compose is irrelevant — fix this first.

---

## 3️⃣ docker-compose.yml

### Purpose
Defines **all Confluent services** **WITHOUT auto-restart**.

This file is meant for:
- Manual control
- Debugging
- First-time validation

### Services included
- Kafka Broker(s)
- KRaft Controller(s)
- Schema Registry
- Kafka Connect
- Confluent Control Center (C3)

### Important behavior
- ❌ No `restart:` policy
- Containers will **NOT** auto-start after reboot
- Containers will **NOT** recover automatically if stopped

This is intentional. If you don’t understand why, you’re not ready for production yet.

### How to start
```
docker compose -f docker-compose.yml up -d
```

### When to use this file
- Initial bring-up
- Configuration validation
- Debugging startup issues

---

## 4️⃣ docker-compose-restart.yml

### Purpose
Same services as `docker-compose.yml`, **WITH restart policies enabled**.

### Key difference
- Uses `restart: always` (or equivalent)
- Containers automatically:
  - Restart on failure
  - Start after VM reboot

### When to use
- Stable environments
- Long-running setups
- After validation using the non-restart compose file

### How to start
```
docker compose -f docker-compose-restart.yml up -d
```

Do NOT use this file until you are confident your configs are correct.

---

## 5️⃣ start-confluent.sh

### Purpose
Manually starts **Confluent services inside running containers**.

Docker bringing up a container ≠ Kafka services running.
This script bridges that gap.

### What it starts
- Kafka (KRaft mode)
- Schema Registry
- Kafka Connect
- Confluent Control Center

### Why this exists
- Allows controlled startup order
- Prevents race conditions
- Makes troubleshooting sane

### How to run
```
chmod +x start-confluent.sh
./start-confluent.sh
```

If containers are not running, this script will fail — as it should.

---

## 🔄 Recommended Execution Flow

Follow this order. Deviate and you’re on your own.

1. Install Docker
   ```
   ./docker-install.sh
   ```

2. Build Confluent image
   ```
   docker build -f Dockerfile-rhel -t confluent-rhel:latest .
   ```

3. Bring up containers (no restart)
   ```
   docker compose -f docker-compose.yml up -d
   ```

4. Start Confluent services
   ```
   ./start-confluent.sh
   ```

5. Validate everything works

6. (Optional) Switch to restart-enabled compose
   ```
   docker compose down
   docker compose -f docker-compose-restart.yml up -d
   ```

---

## ⚠️ Common Mistakes (Don’t Make Them)

- Running `start-confluent.sh` before containers are up
- Expecting Kafka to start just because the container is running
- Using restart-enabled compose before validation
- Modifying multiple files at once and not knowing what broke

---

## ✅ Outcome

After successful execution:
- Docker is installed and stable
- Custom Confluent image is built
- Kafka ecosystem runs inside Docker on RHEL
- Startup behavior is **explicit and controlled**

If something fails, inspect logs instead of guessing.

---

## 🧠 Final Note

This setup is **deliberately strict**.
Automation comes *after* understanding.
If you want one-click magic, this is not it.

