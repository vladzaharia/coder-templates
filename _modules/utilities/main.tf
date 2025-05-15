terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">= 2.4.0"
    }
  }
}

data "coder_workspace" "main" {}

locals {
  # Default selections based on enabled settings
  default_utilities = concat(
    var.kasm.enabled ? ["kasm"] : [],
    var.file.enabled ? ["file"] : [],
    var.jupyter.enabled ? ["jupyter"] : [],
    var.rdp.enabled ? ["rdp"] : []
  )

  # Parse the selected utilities from the parameter
  selected_utilities = var.ask_utilities ? jsondecode(data.coder_parameter.utilities[0].value) : local.default_utilities

  # Check if each utility is selected
  kasm_enabled = var.kasm.enabled && (contains(local.selected_utilities, "kasm") || !var.ask_utilities)
  file_enabled = var.file.enabled && (contains(local.selected_utilities, "file") || !var.ask_utilities)
  jupyter_enabled = var.jupyter.enabled && (contains(local.selected_utilities, "jupyter") || !var.ask_utilities)
  rdp_enabled = var.rdp.enabled && (contains(local.selected_utilities, "rdp") || !var.ask_utilities)
}

data "coder_parameter" "utilities" {
  count        = var.ask_utilities ? 1 : 0
  name         = "utilities"
  display_name = "Utilities"
  description  = "Select which utilities you want to use in your workspace."
  type         = "list(string)"
  default      = jsonencode(local.default_utilities)
  mutable      = true
  icon         = "/icon/widgets.svg"
  form_type    = "multi-select"
  order        = 450

  option {
    name  = "VNC Viewer"
    value = "kasm"
    icon  = "/icon/desktop.svg"
  }

  option {
    name  = "File Browser"
    value = "file"
    icon  = "/icon/folder.svg"
  }

  option {
    name  = "JupyterLab"
    value = "jupyter"
    icon  = "/icon/jupyter.svg"
  }

  option {
    name  = "Remote Desktop (RDP)"
    value = "rdp"
    icon  = "/icon/rdp.svg"
  }
}

module "kasmvnc" {
  source              = "registry.coder.com/modules/kasmvnc/coder"
  version             = ">= 1.0.0"
  count               = local.kasm_enabled ? 1 : 0
  agent_id            = var.agent_id
  desktop_environment = var.kasm.de
}

module "filebrowser" {
  source   = "registry.coder.com/modules/filebrowser/coder"
  version  = ">= 1.0.0"
  count    = local.file_enabled ? 1 : 0
  agent_id = var.agent_id
  folder   = var.file.path
}

module "jupyterlab" {
  source   = "registry.coder.com/modules/jupyterlab/coder"
  version  = ">= 1.0.0"
  count    = local.jupyter_enabled ? 1 : 0
  agent_id = var.agent_id
}

module "windows_rdp" {
  source      = "registry.coder.com/modules/windows-rdp/coder"
  version     = ">= 1.0.0"
  count       = local.rdp_enabled ? 1 : 0
  agent_id    = var.agent_id
  resource_id = var.rdp.resource_id
}
