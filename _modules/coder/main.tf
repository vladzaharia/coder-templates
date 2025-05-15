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
  # Default features - vscode is always true
  default_features = ["ssh_helper", "port_forwarding_helper", "web_terminal"]

  # Parse the selected features from the parameter
  selected_features = var.ask_features ? jsondecode(data.coder_parameter.features[0].value) : local.default_features

  # Check if each feature is selected - vscode is always true
  ssh_helper_enabled = contains(local.selected_features, "ssh_helper")
  port_forwarding_helper_enabled = contains(local.selected_features, "port_forwarding_helper")
  web_terminal_enabled = contains(local.selected_features, "web_terminal")
}

data "coder_parameter" "features" {
  count        = var.ask_features ? 1 : 0
  name         = "features"
  display_name = "Coder Features"
  description  = "Select which Coder features you want to enable in your workspace."
  type         = "list(string)"
  default      = jsonencode(local.default_features)
  mutable      = true
  icon         = "/icon/widgets.svg"
  form_type    = "multi-select"
  order        = 475

  option {
    name  = "SSH"
    value = "ssh_helper"
    icon  = "/icon/ssh.svg"
  }

  option {
    name  = "Port Forwarding"
    value = "port_forwarding_helper"
    icon  = "/icon/port.svg"
  }

  option {
    name  = "Web Terminal"
    value = "web_terminal"
    icon  = "/icon/terminal.svg"
  }
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
    vscode = true
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