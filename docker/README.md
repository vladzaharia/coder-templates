---
name: Docker Workspace
description: Run empty workspace on a Docker host using registry images
tags: [local, docker, dotfiles, vault]
icon: /icon/docker.png
---

# Docker Workspace

This template creates a Docker-based workspace using registry images for development.

## Features

- Docker-based development environment
- Integrated code-server (VS Code in browser)
- Dotfiles support for personalization
- HashiCorp Vault integration for secrets management
- Git configuration and utilities
- AI integration capabilities

## Getting Started

Run `coder templates init` and select this template to get started.

## Configuration

When creating a workspace, you can configure:

- Container size
- Base image (Ubuntu, Debian, language-specific images)
- Docker-in-Docker support
- Dotfiles repository

## Customization

Edit the `main.tf` file to modify the template configuration or add new features.
See the [kreuzwerker/docker](https://registry.terraform.io/providers/kreuzwerker/docker) Terraform provider documentation for additional options.
