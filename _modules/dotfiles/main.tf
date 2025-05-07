terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
  }
}

locals {
  # Use the variable if provided, otherwise use the UI parameter
  selected_dotfiles_uri = var.dotfiles_uri != null ? var.dotfiles_uri : try(data.coder_parameter.dotfiles_repo[0].value, "")
}

data "coder_parameter" "dotfiles_repo" {
  count        = var.dotfiles_uri == null ? 1 : 0
  order        = 150
  name         = "dotfiles_repo"
  display_name = "Dotfiles repo"
  description  = "GitHub repository to download and install dotfiles, if provided."
  icon         = "/icon/dotfiles.svg"
  default      = ""
  mutable      = false
}

module "dotfiles" {
  source       = "registry.coder.com/modules/dotfiles/coder"
  version      = ">= 1.0.0"
  agent_id     = var.agent_id
  dotfiles_uri = local.selected_dotfiles_uri != "" ? "https://github.com/${local.selected_dotfiles_uri}" : ""
}