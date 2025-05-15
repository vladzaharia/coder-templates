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
  # Check if each utility is selected
  kasm_enabled = var.kasm.enabled && (var.ask_utilities ? try(data.coder_parameter.kasm_enabled[0].value, var.kasm.enabled) : var.kasm.enabled)
  file_enabled = var.file.enabled && (var.ask_utilities ? try(data.coder_parameter.file_enabled[0].value, var.file.enabled) : var.file.enabled)
  jupyter_enabled = var.jupyter.enabled && (var.ask_utilities ? try(data.coder_parameter.jupyter_enabled[0].value, var.jupyter.enabled) : var.jupyter.enabled)
  rdp_enabled = var.rdp.enabled && (var.ask_utilities ? try(data.coder_parameter.rdp_enabled[0].value, var.rdp.enabled) : var.rdp.enabled)
}

data "coder_parameter" "kasm_enabled" {
  count        = var.ask_utilities && var.kasm.enabled ? 1 : 0
  name         = "kasm_enabled"
  display_name = "VNC Viewer"
  description  = "Enable VNC Viewer for desktop environment"
  type         = "bool"
  default      = var.kasm.enabled
  mutable      = true
  icon         = "/icon/desktop.svg"
  order        = 475
}

data "coder_parameter" "file_enabled" {
  count        = var.ask_utilities && var.file.enabled ? 1 : 0
  name         = "file_enabled"
  display_name = "File Browser"
  description  = "Enable File Browser"
  type         = "bool"
  default      = var.file.enabled
  mutable      = true
  icon         = "/icon/folder.svg"
  order        = 480
}

data "coder_parameter" "jupyter_enabled" {
  count        = var.ask_utilities && var.jupyter.enabled ? 1 : 0
  name         = "jupyter_enabled"
  display_name = "JupyterLab"
  description  = "Enable JupyterLab"
  type         = "bool"
  default      = var.jupyter.enabled
  mutable      = true
  icon         = "/icon/jupyter.svg"
  order        = 485
}

data "coder_parameter" "rdp_enabled" {
  count        = var.ask_utilities && var.rdp.enabled ? 1 : 0
  name         = "rdp_enabled"
  display_name = "Remote Desktop (RDP)"
  description  = "Enable Remote Desktop"
  type         = "bool"
  default      = var.rdp.enabled
  mutable      = true
  icon         = "/icon/rdp.svg"
  order        = 490
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
