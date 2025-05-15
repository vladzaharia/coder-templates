---
name: Azure Windows VM
description: Run a Windows VM on Azure
tags: [cloud, azure, windows]
icon: /icon/azure.png
---

# Azure Windows VM (Deprecated)

> ⚠️ **DEPRECATED**: This template is deprecated and may not receive updates. Consider using newer templates.

This template creates a Windows virtual machine on Microsoft Azure for development.

## Features

- Azure VM running Windows
- Automatic provisioning and configuration
- Remote Desktop Protocol (RDP) access
- Windows-native development environment

## Getting Started

Run `coder templates init` and select this template to get started.

## Configuration

When creating a workspace, you'll need to provide:

- Azure authentication credentials
- VM size
- Region
- Windows version

## Customization

Edit the `main.tf` file to modify the template configuration or add new features.

## Authentication

This template requires Azure credentials. Run `az login` then `az account set --subscription=<id>`
to authenticate on the system running Coder. See the [Terraform Azure Provider docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure) for more authentication options.

## Dependencies

This template requires the Azure CLI tool (`az`) to start and stop the Windows VM.
