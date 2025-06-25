terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">= 2.4.0"
    }
  }
}

module "coder-login" {
  source   = "registry.coder.com/modules/coder-login/coder"
  version  = ">= 1.0.0"
  agent_id = var.agent_id
}

locals {
  # Check if each AI tool is selected
  claude_enabled = var.claude.enabled && (var.ask_ai ? try(data.coder_parameter.claude_enabled[0].value, var.claude.enabled) : var.claude.enabled)
  goose_enabled = var.goose.enabled && (var.ask_ai ? try(data.coder_parameter.goose_enabled[0].value, var.goose.enabled) : var.goose.enabled)
}

data "coder_parameter" "claude_enabled" {
  count        = var.ask_ai && var.claude.enabled ? 1 : 0
  name         = "claude_enabled"
  display_name = "Claude Code"
  description  = "Enable Claude Code AI assistant"
  type         = "bool"
  default      = var.claude.enabled
  mutable      = true
  icon         = "/icon/claude.svg"
  order        = 450
}

data "coder_parameter" "goose_enabled" {
  count        = var.ask_ai && var.goose.enabled ? 1 : 0
  name         = "goose_enabled"
  display_name = "Goose"
  description  = "Enable Goose AI assistant"
  type         = "bool"
  default      = var.goose.enabled
  mutable      = true
  icon         = "/icon/goose.svg"
  order        = 455
}

data "coder_parameter" "ai_prompt" {
  type        = "string"
  name        = "AI Prompt"
  default     = ""
  description = "Write a prompt for the AI tools"
  mutable     = true
}

# resource "coder_ai_task" "ai" {
#   count = local.claude_enabled || local.goose_enabled ? 1 : 0
#   sidebar_app = {
#     id = local.claude_enabled ? resource.coder_app.claude_code.id : resource.coder_app.goose.id
#   }
# }

module "claude-code" {
  source   = "registry.coder.com/modules/claude-code/coder"
  version  = ">= 1.0.0"
  count    = local.claude_enabled ? 1 : 0
  agent_id = var.agent_id

  folder              = var.path
  install_claude_code = true
  claude_code_version = "latest"

  # Enable tmux with session persistence
  experiment_use_screen   = var.multiplexer == "screen"
  experiment_use_tmux     = var.multiplexer == "tmux"
  experiment_tmux_session_persistence   = var.multiplexer == "tmux"
  experiment_tmux_session_save_interval = "10"
  experiment_report_tasks               = true

  depends_on = [module.claude-vault]

  order = 30
}

module "claude-vault" {
  source = "../vault"

  vault_role_id   = var.vault_role_id
  vault_secret_id = var.vault_secret_id

  path = "coder-claude-code"
}

module "goose" {
  source   = "registry.coder.com/modules/goose/coder"
  version  = ">= 1.0.0"
  count    = local.goose_enabled ? 1 : 0
  agent_id = var.agent_id

  folder = var.path

  install_goose = true
  goose_version = "stable"

  experiment_report_tasks = true
  experiment_use_screen   = (var.multiplexer == "screen")

  experiment_auto_configure = true
  experiment_goose_provider = module.goose-vault.data["GOOSE_PROVIDER"]
  experiment_goose_model    = module.goose-vault.data["GOOSE_MODEL"]

  experiment_pre_install_script = <<-EOT
  npm i -g @wonderwhy-er/desktop-commander@latest
  EOT

  experiment_additional_extensions = <<-EOT
  desktop-commander:
    args: []
    cmd: desktop-commander
    description: Ideal for background tasks
    enabled: true
    envs: {}
    name: desktop-commander
    timeout: 300
    type: stdio
  EOT

  depends_on = [module.goose-vault]

  order = 35
}

module "goose-vault" {
  source = "../vault"

  vault_role_id   = var.vault_role_id
  vault_secret_id = var.vault_secret_id

  path = "coder-goose"
}
