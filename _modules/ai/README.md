# AI Module

This module provides AI integration capabilities for Coder templates, including Claude Code and Goose AI assistants.

## Features

- Integrates Claude Code AI assistant
- Integrates Goose AI assistant
- Configures AI tools with appropriate environment variables
- Securely retrieves AI credentials from HashiCorp Vault

## Usage

```hcl
module "coder_ai" {
  source = "./_modules/ai"

  agent_id = module.coder_coder.agent_id
  path     = "/home/user/workspace"
  vault_role_id   = var.vault_role_id
  vault_secret_id = var.vault_secret_id

  claude = {
    enabled = true
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| agent_id | Coder agent ID | `string` | n/a | yes |
| path | Starting path for AI agent | `string` | n/a | yes |
| vault_role_id | Role ID for Vault lookup | `string` | n/a | yes |
| vault_secret_id | Secret ID for Vault lookup | `string` | n/a | yes |
| vault_url | URL of Vault instance | `string` | `"https://vault.polaris.rest"` | no |
| multiplexer | Which terminal multiplexer to use | `string` | `"screen"` | no |
| claude | Claude Code configuration | `object({ enabled = bool })` | `{ enabled = false }` | no |
| goose | Goose configuration | `object({ enabled = bool })` | `{ enabled = false }` | no |

## Outputs

| Name | Description |
|------|-------------|
| data | Merged AI environment variables |

## Dependencies

- Coder registry modules:
  - `registry.coder.com/modules/claude-code/coder`
  - `registry.coder.com/modules/goose/coder`
  - `registry.coder.com/modules/coder-login/coder`
- Local vault module (`../vault`)
