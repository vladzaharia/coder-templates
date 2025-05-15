# Dotfiles Module

This module provides dotfiles integration for Coder templates, allowing users to automatically clone and install their personal dotfiles from GitHub repositories.

## Features

- Allows users to specify a GitHub repository containing dotfiles
- Automatically clones and installs dotfiles in the workspace
- Provides a UI parameter for selecting dotfiles repository
- Can be pre-configured with a specific dotfiles repository

## Usage

```hcl
module "coder_dotfiles" {
  source = "./_modules/dotfiles"

  agent_id = module.coder_coder.agent_id
  dotfiles_uri = "username/dotfiles-repo"  # Optional
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| agent_id | Coder agent ID | `string` | n/a | yes |
| dotfiles_uri | GitHub repository to download and install dotfiles | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| dotfiles_uri | The full URI of the dotfiles repository |

## Dependencies

- Coder registry module: `registry.coder.com/modules/dotfiles/coder`
