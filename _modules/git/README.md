# Git Module

This module provides Git integration for Coder templates, including configuration, commit signing, and repository cloning.

## Features

- Configures Git with user information from Coder
- Sets up Git commit signing for secure commits
- Provides GitHub repository cloning functionality
- Integrates with GitHub authentication

## Usage

```hcl
module "coder_git" {
  source = "./_modules/git"

  agent_id = module.coder_coder.agent_id

  github = {
    enabled = true
  }

  repo = "owner/repository"  # Optional
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| agent_id | Coder agent ID | `string` | n/a | yes |
| github | GitHub authentication settings | `object({ enabled = bool })` | `{ enabled = false }` | no |
| repo | GitHub repository to clone | `string` | `null` | no |

## Dependencies

- Coder registry modules:
  - `registry.coder.com/modules/git-config/coder`
  - `registry.coder.com/modules/git-commit-signing/coder`
  - `registry.coder.com/modules/git-clone/coder`
