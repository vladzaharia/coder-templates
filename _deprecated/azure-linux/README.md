---
name: Azure Linux VM
description: Run an Ubuntu VM on Azure
tags: [cloud, azure, linux, dotfiles]
icon: /icon/azure.png
---

# Azure Linux VM (Deprecated)

> ⚠️ **DEPRECATED**: This template is deprecated and may not receive updates. Consider using other templates.

This template creates an Ubuntu virtual machine on Microsoft Azure for development.

## Features

- Azure VM running Ubuntu
- Automatic provisioning and configuration
- Integrated code-server (VS Code in browser)
- Dotfiles support for personalization

## Getting Started

Run `coder templates init` and select this template to get started.

## Configuration

When creating a workspace, you'll need to provide:

- Azure authentication credentials
- VM size
- Region
- Dotfiles repository (optional)

## Customization

Edit the `main.tf` file to modify the template configuration or add new features.

## Authentication

This template requires Azure credentials. Run `az login` then `az account set --subscription=<id>`
to authenticate on the system running Coder. See the [Terraform Azure Provider docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure) for more authentication options.
