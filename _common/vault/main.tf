terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    vault = {
      source = "hashicorp/vault"
    }
  }
}

provider "vault" {
  address          = var.vault_url
  skip_child_token = true

  auth_login {
    path = "auth/approle/login"

    parameters = {
      role_id   = var.vault_role_id
      secret_id = var.vault_secret_id
    }
  }
}

data "coder_parameter" "vault_project" {
  order        = 200
  name         = "vault_project"
  display_name = "Vault project name"
  description  = "Name of the project to retrieve and inject environment variables from"
  icon         = "/icon/vault.svg"
  default      = ""
  mutable      = false
}

data "vault_generic_secret" "secrets" {
  for_each = toset(var.paths)
  path     = "dotenv/${each.key}/dev"
}

data "vault_generic_secret" "dotenv" {
  count = data.coder_parameter.vault_project == "" ? 1 : 0
  path     = "dotenv/${data.coder_parameter.vault_project}/dev"
}
