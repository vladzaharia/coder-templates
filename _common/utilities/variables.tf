# Coder Agent ID
variable "agent_id" {
  description = "Coder agent ID"
  type        = string
}

# Kasm VNC Server
variable "kasm" {
  description = "Kasm VNC"

  type = object({
    enabled = bool
    de = string
  })
  default = {
    enabled = false
    de = ""
  }

  validation {
    condition = !var.kasm.enabled || (var.kasm.enabled && var.kasm.de != "")
    error_message = "If Kasm VNC is enabled, a Desktop Environment is needed."
  }
}

# File Browser
variable "file" {
  description = "File Browser"
  
  type = object({
    enabled = bool
    path = string
  })
  default = {
    enabled = false
    path = "~"
  }

  validation {
    condition = !var.file.enabled || (var.file.enabled && var.file.path != "")
    error_message = "If File Browser is enabled, a path is needed."
  }
}

# Jupyter
variable "jupyter" {
  description = "Jupyter"
  
  type = object({
    enabled = bool
  })
  default = {
    enabled = false
  }
}

# RDP Server/Client
variable "rdp" {
  description = "RDP"
  
  type = object({
    enabled = bool
    resource_id = string
  })
  default = {
    enabled = false
    resource_id = ""
  }

  validation {
    condition = !var.rdp.enabled || (var.rdp.enabled && var.rdp.resource_id != "")
    error_message = "If RDP is enabled, a resource ID is needed."
  }
}
