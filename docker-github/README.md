---
name: GitHub Workspace
description: Run a Docker workspace using a GitHub repository
tags: [local, docker, github, dotfiles, vault]
icon: https://static-00.iconduck.com/assets.00/github-icon-512x497-oppthre2.png
---

# GitHub Workspace

This template creates a Docker-based workspace that automatically clones and sets up a GitHub repository.

## Features

- Automatic GitHub repository cloning
- Docker-based development environment
- Integrated code-server (VS Code in browser)
- Dotfiles support for personalization
- HashiCorp Vault integration for secrets management
- Git configuration and utilities

## Getting Started

Run `coder templates init` and select this template to get started.

## Configuration

When creating a workspace, you'll need to provide:

- GitHub repository URL
- Container size
- Base image (optional)
- Dotfiles repository (optional)
- Vault credentials (if using Vault integration)

## Customization

Edit the `main.tf` file to modify the template configuration or add new features.
