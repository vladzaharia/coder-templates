---
name: AWS Linux VM
description: Run Ubuntu on AWS.
tags: [cloud, aws, linux, dotfiles]
icon: /icon/aws.png
---

# AWS Linux VM (Deprecated)

> ⚠️ **DEPRECATED**: This template is deprecated and may not receive updates. Consider using other templates.

This template creates an Ubuntu virtual machine on AWS for development.

## Features

- AWS EC2 instance running Ubuntu
- Automatic provisioning and configuration
- Integrated code-server (VS Code in browser)
- Dotfiles support for personalization

## Getting Started

Run `coder templates init` and select this template to get started.

## Configuration

When creating a workspace, you'll need to provide:

- AWS authentication credentials
- Instance type
- Region
- Dotfiles repository (optional)

## Customization

Edit the `main.tf` file to modify the template configuration or add new features.

## Authentication

This template requires AWS credentials. Run `aws configure import` to import credentials on the
system running Coder. See the [Terraform AWS Provider docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration) for more authentication options.
