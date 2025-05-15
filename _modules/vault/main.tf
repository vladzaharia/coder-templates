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
  count = var.path == null ? 1 : 0
  order        = 200
  name         = "vault_project"
  display_name = "Vault project name"
  description  = "Name of the project to retrieve and inject environment variables from"
  icon         = "/icon/vault.svg"
  default      = ""
  mutable      = false
}

data "vault_generic_secret" "path" {
  count = var.path != null || len(data.coder_parameter.vault_project) > 0 && data.coder_parameter.vault_project[0].value != "" ? 1 : 0
  path  = "dotenv/${var.path != null ? var.path : data.coder_parameter.vault_project[0].value}/dev"
}

