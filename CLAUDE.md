# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Docker-Compose Starter (DC-Starter) is an interactive menu-based launcher system for managing Docker Compose applications. It wraps docker-compose commands in user-friendly shell menus, eliminating the need to memorize complex Docker commands. The project includes a three-tier Java application template (Nginx + Tomcat/SpringBoot + MySQL).

## Key Architecture Concepts

### Modular Design
- **Main Project**: Defined by `docker-compose.yml` at root level
- **Sub-modules**: Independent sub-projects (e.g., `prj-dashboard/`) that can be loaded dynamically
- Sub-modules have their own `.env`, `docker-compose.yml`, and `run.sh` files
- The main `run.sh` automatically merges sub-module configurations via `laodSubModules()` function

### Configuration System
- **`.env`**: Central configuration file containing all environment variables
- **`PROJECT_NAME`**: Namespace for all containers (must be unique per project on same host)
- **`CONTAINER_LIST`**: Defines which services to manage (must match docker-compose service names)
- **Database separation**: System-level (`mysql-sys`) and application-level (`mysql-app`) containers
- **`IP_RANGE`**: Each project must use unique IP range (e.g., `192.168.225`)

### Launcher Framework
- **`launcher/default.sh`**: Core framework providing all interactive menu functions
- **`run.sh`**: Project-specific launcher that sources `default.sh` and `.env`
- **Custom actions**: Add via `ACTION_LIST` variable (format: "Menu Text functionName")
- Menu system uses letter-based navigation (a-z) automatically assigned to options

## Common Commands

### Starting the Application
```bash
./run.sh
```
Then select:
- `a` → `b` to start all services
- `b` to manage individual containers

### First Time Setup
```bash
# 1. Modify .env file (change PROJECT_NAME, passwords, IP_RANGE)
# 2. Initialize configuration
./run.sh
# Select "初始化配置" from custom actions menu

# 3. Start all services
# Select option a → b
```

### Development Workflow
```bash
# Replace JAR/WAR files in ./code directory
cp your-app.jar ./code/springboot/
cp your-app.war ./code/tomcat/

# Restart services
./run.sh
# Select a → a (restart all) or b → a (restart single service)
```

### Backup and Restore
```bash
# Backup
./run.sh
# Select "备份" from custom actions menu

# Restore
./run.sh restore.sh
# Follow restore menu options
```

### Database Access
```bash
./run.sh
# Select "e" to enter MySQL command line (auto-connects to mysql-app)
```

### Viewing Logs
```bash
./run.sh
# Select "c" → choose container
```

### Checking Container Status
```bash
./run.sh
# Select "f" to view status, uptime, IPs, ports
```

## Directory Structure

### Code Directories (Volume-mounted, not baked into images)
- **`code/springboot/`**: JAR files (modify entrypoint in docker-compose.yml if filename changes)
- **`code/tomcat/`**: WAR files
- **`code/nginx/`**: Static HTML files
- **`code/backups/preexecute/`**: Scripts to run before backup

### Configuration Directories
- **`config/nginx/`**: Nginx configuration files
- **`config/mysql_sys_init/`**: System MySQL initialization scripts (run once on first start)
- **`config/mysql_app_init/`**: Application MySQL initialization scripts
- **`config_repositry/`**: Template configurations for services like Redis

### Runtime Directories (Not in repo)
- **`data/`**: Persistent business data (MySQL files, user uploads)
- **`logs/`**: Application logs
- **`backup/`**: Backup files

## Extending the System

### Adding Custom Menu Functions
In `run.sh`, add to `ACTION_LIST`:
```bash
ACTION_LIST="
Menu Text functionName
Another Action anotherFunction
"

functionName(){
    # Your custom logic
    $DCC_COMMAND exec container-name some-command
}
```

### Adding a Sub-module
1. Create directory with `docker-compose.yml`, `.env`, and `run.sh`
2. In main `run.sh`, add to `subModules` variable:
```bash
subModules="prj-dashboard new-submodule"
```
3. Define `CONTAINER_LIST` and `ACTION_LIST` in sub-module's `run.sh`

### Adding a New Service
1. Add service definition to `docker-compose.yml`
2. Add container name to `CONTAINER_LIST` in `run.sh`
3. Add volumes for code/config as needed
4. Update `.env` if new environment variables are required

### Creating Custom Launcher Scripts
```bash
# Create custom-script.sh with specific services
./run.sh custom-script.sh
```
See `restore.sh` as example of alternate launcher for specific workflow.

## Important Notes

- Container service names in `docker-compose.yml` must match values in `CONTAINER_LIST` (with PROJECT_NAME prefix)
- Search for "TODO" comments in codebase to find required modifications for new projects
- `GLOBAL_NETWORK` can define external networks to create on startup
- The `init` container (philiphuang/config-injector) generates MySQL init files from templates using `.env` variables
- Backup container uses volumerize for scheduled backups
- When running multiple projects on same host, ensure unique `PROJECT_NAME` and `IP_RANGE`

## BMAD Core System

This project uses the BMAD (Build-Measure-Analyze-Deploy) agent framework located in `.bmad-core/`. Agent personas include:
- **@architect**: System architecture and design
- **@dev**: Development tasks
- **@qa**: Testing and quality assurance
- **@pm**: Project management
- **@po**: Product ownership
- **@sm**: Scrum master
- **@analyst**: Data analysis
- **@ux-expert**: UX design

Agents are activated via `@agent-name` mentions and have access to tasks, templates, checklists in `.bmad-core/`.
