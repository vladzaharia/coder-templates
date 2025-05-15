# Coder Templates

This repository contains a collection of [Coder](https://coder.com/) templates for creating development environments. These templates use Terraform to provision and configure development environments in various platforms.

## Repository Structure

- **Active Templates**: Top-level directories (except those prefixed with `_`) contain active Coder templates
- **Modules**: The `_modules` directory contains reusable Terraform modules
- **Deprecated Templates**: The `_deprecated` directory contains templates that are no longer actively maintained

## Available Templates

### Active Templates

- **docker**: Run workspaces on a Docker host using registry images
- **docker-github**: Run containers based on GitHub repositories with Docker
- **dev-container**: Run containers based on devcontainer.json specifications from GitHub repositories
- **desktop**: Desktop environment template with multiple DE options (XFCE, Gnome, KDE)

## Modules

The `_modules` directory contains reusable Terraform modules that provide common functionality across templates:

- **ai**: AI integration capabilities
- **coder**: Core Coder functionality
- **docker**: Docker-specific functionality
- **dotfiles**: Dotfiles configuration
- **editors**: Code editor setup
- **git**: Git configuration
- **utilities**: Common utility functions
- **vault**: HashiCorp Vault integration

## Getting Started

### Prerequisites

- [Coder](https://coder.com/) instance running
- [Coder CLI](https://github.com/coder/coder/releases) installed
- Docker (for local templates)
- Cloud provider credentials (for cloud templates)

### Using Templates

1. Install the Coder CLI
2. Authenticate with your Coder instance: `coder login <your-coder-url>`
3. Run `coder templates init` and select the desired template
4. Follow the on-screen instructions to configure the template
5. Create a workspace using the template: `coder create --template=<template-name> <workspace-name>`
6. Access your workspace through the Coder dashboard or CLI: `coder ssh <workspace-name>`

## Template Development

### Creating New Templates

To create a new template:

1. Create a new directory at the root level with a descriptive name
2. Add the necessary Terraform files (main.tf, variables.tf, etc.)
3. Create a README.md with frontmatter for Coder
4. Test your template locally

### Modifying Existing Templates

When modifying existing templates:

1. Make your changes to the template files
2. Test your changes locally with `coder templates init`
3. Push your changes to GitHub and create a pull request
4. The GitHub Actions workflow will automatically validate and plan your template
5. Changes will be deployed on merge to the `main` branch

### Best Practices

- Use modules from the `_modules` directory for common functionality
- Follow the established patterns in existing templates
- Include comprehensive documentation in your README.md
- Test templates thoroughly before submitting
- Keep deprecated templates in the `_deprecated` directory

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
