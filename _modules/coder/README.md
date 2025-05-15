# Coder Module

This module provides core Coder functionality for templates, including agent configuration, environment variables, and system monitoring.

## Features

- Creates and configures a Coder agent
- Sets up Git author information automatically
- Configures system monitoring (CPU, memory, disk usage)
- Provides initialization scripts for workspace setup

## Usage

```hcl
module "coder_coder" {
  source = "./_modules/coder"

  env = {
    EXAMPLE_VAR = "example_value"
  }

  init_script = "echo 'Custom initialization script'"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| env | Additional environment variables to pass to the agent | `map(string)` | `{}` | no |
| init_script | Startup script to run in the workspace after the generic Coder one | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| agent_id | Coder agent ID |
| init_script | Coder final init script |
| token | Coder agent token (sensitive) |

## Dependencies

- Coder registry module: `registry.coder.com/modules/coder-login/coder`
