# AI Assistant Instructions

This document provides system instructions for AI assistants (ChatGPT, Claude, etc.) working on this project.

## Environment

| Environment | Platform           | Description                          |
|-------------|--------------------|--------------------------------------|
| Local       | Docker Compose     | Development on local PC              |
| Production  | Coolify on Pi4     | Deployed on Raspberry Pi 4 (ARM64)   |

## Development Rules

### 1. Build Configuration

- **Do NOT write Dockerfile manually** - Rely on Nixpacks for automatic build detection
- Nixpacks configuration can be customized in `nixpacks.toml` if needed
- Coolify handles the build and deployment process automatically

### 2. Data Persistence

- **Always use Docker volumes** for persistent data
- Never store persistent data inside the container filesystem
- Define volumes in `compose.yaml` for local development

### 3. Logging

- **Output all logs to stdout** - Do not write to log files
- Use structured logging (JSON format) when possible
- Coolify and Docker will capture stdout/stderr automatically

### 4. Environment Variables

- Use `.env` file for local development (copy from `.env.example`)
- Configure environment variables in Coolify dashboard for production
- Never commit `.env` files to the repository

### 5. Port Configuration

- Default application port: `3000`
- Expose ports through Docker Compose for local development
- Coolify handles port mapping in production

## Architecture Overview

```
┌─────────────────┐     Git Push     ┌─────────────────┐
│   Local PC      │ ───────────────► │    GitHub       │
│ (Docker Compose)│                  │                 │
└─────────────────┘                  └────────┬────────┘
                                              │
                                              │ Webhook
                                              ▼
                                     ┌─────────────────┐
                                     │  Raspberry Pi 4 │
                                     │    (Coolify)    │
                                     └────────┬────────┘
                                              │
                                              │ Tailscale
                                              ▼
                                     ┌─────────────────┐
                                     │  Mesh Network   │
                                     │   (Private)     │
                                     └─────────────────┘
```
