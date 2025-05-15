---
name: Dev Container
description: Runs a container based on devcontainer.json specification from a GitHub repo
tags: [local, docker, github, vault]
icon: /icon/docker.png
---

# Dev Container

This template creates a development environment using the devcontainer.json specification from a GitHub repository.

## Features

- Uses devcontainer.json specifications for consistent environments
- Automatic GitHub repository cloning
- Docker-based development environment
- Integrated code-server (VS Code in browser)
- HashiCorp Vault integration for secrets management
- Compatible with Visual Studio Code Dev Containers

## Getting Started

Run `coder templates init` and select this template to get started.

## Configuration

When creating a workspace, you'll need to provide:

- GitHub repository URL containing a devcontainer.json file
- Vault credentials (if using Vault integration)

## Customization

The environment is defined by the devcontainer.json file in your GitHub repository.
To modify the environment, update this file in your repository.
