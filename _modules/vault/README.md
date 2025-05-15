# Vault Module

This module provides HashiCorp Vault integration for Coder templates, allowing secure access to secrets and environment variables.

## Features

- Securely retrieves secrets from HashiCorp Vault
- Injects environment variables into workspaces
- Supports project-specific secret paths
- Uses AppRole authentication for secure access

## Usage

```hcl
module "coder_vault" {
  source = "./_modules/vault"

  vault_role_id   = var.vault_role_id
  vault_secret_id = var.vault_secret_id
  path            = "my-project"  # Optional
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vault_url | URL of Vault instance | `string` | `"https://vault.polaris.rest"` | no |
| vault_role_id | Role ID for Vault lookup | `string` | n/a | yes |
| vault_secret_id | Secret ID for Vault lookup | `string` | n/a | yes |
| path | Path of secrets to get from Vault | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| data | Merged Vault data as environment variables |

## Dependencies

- HashiCorp Vault Terraform provider (`hashicorp/vault`)
