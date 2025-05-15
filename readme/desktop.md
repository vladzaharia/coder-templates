---
name: Desktop Environment
description: Run a Linux desktop environment in Docker with various desktop options
tags: [local, docker, desktop, dotfiles, vault]
icon: /icon/desktop.svg
---

# Desktop Environment

This template provides a Linux desktop environment running in Docker with various desktop environment options.

## Features

- Multiple desktop environment options (XFCE, Gnome, KDE)
- Configurable container sizes
- Docker-in-Docker support
- Dotfiles integration
- Git configuration and commit signing
- Persistent home directory

## Getting Started

Run `coder templates init` and select this template to get started.

## Configuration

When creating a workspace, you can configure:

- Container size (Small, Medium, Large, XLarge)
- Desktop environment (XFCE, Gnome, KDE)
- Dotfiles repository (optional)

The desktop environment can be accessed through the Coder dashboard using the built-in web interface.

## Customization

Edit the `main.tf` file to modify the template configuration or add new features.
You can also modify the Dockerfile in the `build` directory to customize the base image.
