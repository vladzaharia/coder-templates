# Editors Module

This module provides code editor integration for Coder templates, supporting multiple editor options including VS Code, JetBrains IDEs, Cursor, Windsurf, and Blink Shell.

## Features

- Integrates multiple code editors and IDEs
- Configures editor settings and preferences
- Supports both web-based and desktop editors
- Provides JetBrains Gateway integration with multiple IDE options
- Includes AI-powered editors like Cursor

## Usage

```hcl
module "coder_editors" {
  source = "./_modules/editors"

  agent_id = module.coder_coder.agent_id
  path     = "/home/user/workspace"

  code_server = {
    enabled = true
  }

  jetbrains = {
    enabled  = true
    products = ["IU", "GO", "FL"]
    default  = "FL"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| agent_id | Coder agent ID | `string` | n/a | yes |
| path | Starting path for editor | `string` | n/a | yes |
| ask_editors | Ask user's editor choices | `bool` | `true` | no |
| code_server | VS Code Server configuration | `object({ enabled = bool })` | `{ enabled = true }` | no |
| code_web | VS Code Web configuration | `object({ enabled = bool })` | `{ enabled = false }` | no |
| jetbrains | JetBrains configuration | `object` | See variables.tf | no |
| cursor | Cursor editor configuration | `object({ enabled = bool })` | `{ enabled = false }` | no |
| windsurf | Windsurf editor configuration | `object({ enabled = bool })` | `{ enabled = false }` | no |
| blink | Blink Shell configuration | `object({ enabled = bool })` | `{ enabled = true }` | no |

## Dependencies

- Coder registry modules:
  - `registry.coder.com/modules/code-server/coder`
  - `registry.coder.com/modules/vscode-web/coder`
  - `registry.coder.com/modules/jetbrains-gateway/coder`
  - `registry.coder.com/modules/cursor/coder`
  - `registry.coder.com/modules/windsurf/coder`
