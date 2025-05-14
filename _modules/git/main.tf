terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
  }
}

data "coder_external_auth" "github" {
  id    = "github"
  count = var.github.enabled ? 1 : 0
}

data "coder_parameter" "github_repo" {
  count = var.github.enabled ? 1 : 0
  order        = 100
  name         = "github_repo"
  display_name = "GitHub repo"
  description  = "GitHub repository to clone, as owner/repository"
  icon         = "/icon/github.svg"
  mutable      = false
}

module "git_config" {
  source                = "registry.coder.com/modules/git-config/coder"
  version               = ">= 1.0.0"
  agent_id              = var.agent_id
  allow_username_change = false
  allow_email_change    = false
}

module "git_commit_signing" {
  source   = "registry.coder.com/modules/git-commit-signing/coder"
  version  = ">= 1.0.0"
  agent_id = var.agent_id
}

module "git_clone" {
  count    = var.github.enabled ? 1 : 0
  source   = "registry.coder.com/modules/git-clone/coder"
  version  = ">= 1.0.0"
  agent_id = var.agent_id
  url      = "https://github.com/${var.repo != null ? var.repo : data.coder_parameter.github_repo[0].value}"
}
