terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">= 2.4.0"
    }
  }
}

data "coder_provisioner" "me" {}
data "coder_workspace_owner" "me" {}

locals {
  # Check if each feature is selected - vscode web is always true
  ssh_helper_enabled = var.ask_features ? try(data.coder_parameter.ssh_enabled[0].value, true) : true
  port_forwarding_helper_enabled = var.ask_features ? try(data.coder_parameter.port_forwarding_enabled[0].value, true) : true
  web_terminal_enabled = var.ask_features ? try(data.coder_parameter.web_terminal_enabled[0].value, true) : true
  vscode_enabled = var.ask_features ? try(data.coder_parameter.vscode_enabled[0].value, true) : true
  vscode_insiders_enabled = var.ask_features ? try(data.coder_parameter.vscode_insiders_enabled[0].value, false) : false
}

data "coder_parameter" "vscode_enabled" {
  count        = var.ask_features ? 1 : 0
  name         = "vscode_enabled"
  display_name = "VS Code Desktop"
  description  = "Enable VS Code Desktop for your workspace"
  type         = "bool"
  default      = true
  mutable      = true
  icon         = "/icon/code.svg"
  order        = 400
}

data "coder_parameter" "vscode_insiders_enabled" {
  count        = var.ask_features ? 1 : 0
  name         = "vscode_insiders_enabled"
  display_name = "VS Code Insiders"
  description  = "Enable VS Code Insiders for your workspace"
  type         = "bool"
  default      = false
  mutable      = true
  icon         = "/icon/code-insiders.svg"
  order        = 405
}

data "coder_parameter" "ssh_enabled" {
  count        = var.ask_features ? 1 : 0
  name         = "ssh_enabled"
  display_name = "SSH"
  description  = "Enable SSH access to your workspace"
  type         = "bool"
  default      = true
  mutable      = true
  icon         = "/icon/terminal.svg"
  order        = 500
}

data "coder_parameter" "port_forwarding_enabled" {
  count        = var.ask_features ? 1 : 0
  name         = "port_forwarding_enabled"
  display_name = "Port Forwarding"
  description  = "Enable port forwarding for your workspace"
  type         = "bool"
  default      = true
  mutable      = true
  icon         = "/icon/database.svg"
  order        = 505
}

data "coder_parameter" "web_terminal_enabled" {
  count        = var.ask_features ? 1 : 0
  name         = "web_terminal_enabled"
  display_name = "Web Terminal"
  description  = "Enable web terminal for your workspace"
  type         = "bool"
  default      = true
  mutable      = true
  icon         = "/icon/terminal.svg"
  order        = 510
}

module "coder-login" {
  source   = "registry.coder.com/modules/coder-login/coder"
  version  = ">= 1.0.0"
  agent_id = coder_agent.main.id
}

resource "coder_agent" "main" {
  arch = data.coder_provisioner.me.arch
  os   = "linux"
  env = merge({
    GIT_AUTHOR_NAME     = "${data.coder_workspace_owner.me.full_name}"
    GIT_COMMITTER_NAME  = "${data.coder_workspace_owner.me.full_name}"
    GIT_AUTHOR_EMAIL    = "${data.coder_workspace_owner.me.email}"
    GIT_COMMITTER_EMAIL = "${data.coder_workspace_owner.me.email}"
  }, var.env)

  order = 10

  display_apps {
    vscode = local.vscode_enabled
    vscode_insiders = local.vscode_insiders_enabled
    ssh_helper = local.ssh_helper_enabled
    port_forwarding_helper = local.port_forwarding_helper_enabled
    web_terminal = local.web_terminal_enabled
  }

  startup_script = <<-EOT
    set -e

    # Prepare user home with default files on first start.
    if [ ! -f ~/.init_done ]; then
      cp -rT /etc/skel ~
      touch ~/.init_done
    fi

    ${var.init_script}
  EOT

  metadata {
    display_name = "CPU Usage"
    key          = "cpu"
    # Uses the coder stat command to get container CPU usage.
    script   = "coder stat cpu"
    interval = 1
    timeout  = 1
  }

  metadata {
    display_name = "Memory Usage"
    key          = "mem"
    # Uses the coder stat command to get container memory usage in GiB.
    script   = "coder stat mem --prefix Gi"
    interval = 1
    timeout  = 1
  }

  metadata {
    display_name = "Disk Usage"
    key          = "disk"
    script       = "df -h | awk '$6 ~ /^\\/$/ { print $5 }'"
    interval     = 1
    timeout      = 1
  }
}