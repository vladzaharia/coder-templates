module "kasmvnc" {
  source              = "registry.coder.com/modules/kasmvnc/coder"
  version             = ">= 1.0.0"
  count               = var.kasm.enabled ? 1 : 0
  agent_id            = var.agent_id
  desktop_environment = var.kasm.de
}

module "filebrowser" {
  source   = "registry.coder.com/modules/filebrowser/coder"
  version  = ">= 1.0.0"
  count    = var.file.enabled ? 1 : 0
  agent_id = var.agent_id
  folder   = var.file.path
}

module "jupyterlab" {
  source   = "registry.coder.com/modules/jupyterlab/coder"
  version  = ">= 1.0.0"
  count    = var.jupyter.enabled ? 1 : 0
  agent_id = var.agent_id
}

module "windows_rdp" {
  source      = "registry.coder.com/modules/windows-rdp/coder"
  version     = ">= 1.0.0"
  count       = var.rdp.enabled ? 1 : 0
  agent_id    = var.agent_id
  resource_id = var.rdp.resource_id
}
