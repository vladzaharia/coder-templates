terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

provider "docker" {}

variable "vault_role_id" {
  type        = string
  description = "Role ID for Vault lookup"

  validation {
    condition     = length(var.vault_role_id) == 36
    error_message = "Invalid Vault Role ID."
  }
}

variable "vault_secret_id" {
  type        = string
  description = "Secret ID for Vault lookup"
  sensitive   = true

  validation {
    condition     = length(var.vault_secret_id) == 36
    error_message = "Invalid Vault Secret ID."
  }
}

data "coder_workspace" "main" {}
data "coder_workspace_owner" "me" {}


module "coder_coder" {
  source = "./_modules/coder"

  env = merge({ GITHUB_ACCESS_TOKEN : module.coder_git.github_access_token, DOTFILES_URI : module.coder_dotfiles.dotfiles_uri }, module.coder_ai.data, module.coder_vault.data)
}

module "coder_git" {
  source = "./_modules/git"

  agent_id = module.coder_coder.agent_id
  github = {
    enabled = true
  }
}

module "coder_docker" {
  source = "./_modules/docker"

  init_script = module.coder_coder.init_script
  coder_token = module.coder_coder.token
}

module "coder_dotfiles" {
  source = "./_modules/dotfiles"

  agent_id = module.coder_coder.agent_id
}

module "coder_vault" {
  source = "./_modules/vault"

  vault_role_id   = var.vault_role_id
  vault_secret_id = var.vault_secret_id
}

module "coder_editors" {
  source   = "./_modules/editors"
  agent_id = module.coder_coder.agent_id

  path = "/home/${data.coder_workspace_owner.me.name}/${module.coder_git.folder_name}"
}

module "coder_ai" {
  source = "./_modules/ai"

  agent_id = module.coder_coder.agent_id
  path     = "/home/${data.coder_workspace_owner.me.name}/${module.coder_git.folder_name}"

  vault_role_id   = var.vault_role_id
  vault_secret_id = var.vault_secret_id

  claude = {
    enabled = true
  }
}
