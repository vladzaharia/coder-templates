terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
  }
}

module "coder-login" {
  source   = "registry.coder.com/modules/coder-login/coder"
  version  = ">= 1.0.0"
  agent_id = var.agent_id
}

data "coder_parameter" "ai_prompt" {
  type        = "string"
  name        = "AI Prompt"
  default     = ""
  description = "Write a prompt for the AI tools"
  mutable     = true
}

module "claude-code" {
  source   = "registry.coder.com/modules/claude-code/coder"
  version  = ">= 1.0.0"
  count    = var.claude.enabled ? 1 : 0
  agent_id = var.agent_id

  folder              = var.path
  install_claude_code = true
  claude_code_version = "latest"

  experiment_use_screen   = var.multiplexer == "screen"
  experiment_use_tmux     = var.multiplexer == "tmux"
  experiment_report_tasks = true
}

module "claude-vault" {
  source = "../vault"

  vault_role_id   = var.vault_role_id
  vault_secret_id = var.vault_secret_id

  paths = ["dotenv/coder-claude-code/dev"]
}

module "goose" {
  source   = "registry.coder.com/modules/goose/coder"
  version  = ">= 1.0.0"
  count    = var.goose.enabled ? 1 : 0
  agent_id = var.agent_id

  folder = var.path

  install_goose = true
  goose_version = "stable"

  experiment_report_tasks = true
  experiment_use_screen   = (var.multiplexer == "screen")

  experiment_auto_configure = true
  experiment_goose_provider = module.goose-vault.data["GOOSE_PROVIDER"]
  experiment_goose_model    = module.goose-vault.data["GOOSE_MODEL"]

  depends_on = [ module.goose-vault ]
}

module "goose-vault" {
  source = "../vault"

  vault_role_id   = var.vault_role_id
  vault_secret_id = var.vault_secret_id

  paths = ["dotenv/coder-goose/dev"]
}
