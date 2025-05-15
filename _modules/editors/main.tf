terraform {
  required_providers {
    coder = {
      source = "coder/coder"
      version = ">= 2.4.0"
    }
  }
}

data "coder_workspace" "main" {}
data "coder_workspace_owner" "me" {}

locals {
  # Default selections based on enabled settings
  default_editors = concat(
    var.code_server.enabled ? ["code-server"] : [],
    var.code_web.enabled ? ["code-web"] : [],
    var.jetbrains.enabled && var.jetbrains.default != "FL" ? ["jetbrains"] : [],
    var.jetbrains.enabled && var.jetbrains.default == "FL" ? ["fleet"] : [],
    var.cursor.enabled ? ["cursor"] : [],
    var.windsurf.enabled ? ["windsurf"] : [],
    var.blink.enabled ? ["blink"] : []
  )

  # Parse the selected editors from the parameter
  selected_editors = var.ask_editors ? jsondecode(data.coder_parameter.editors[0].value) : local.default_editors

  # Check if each editor is selected
  code_server_enabled = var.code_server.enabled && (contains(local.selected_editors, "code-server") || !var.ask_editors)
  code_web_enabled = var.code_web.enabled && (contains(local.selected_editors, "code-web") || !var.ask_editors)
  jetbrains_enabled = var.jetbrains.enabled && (contains(local.selected_editors, "jetbrains") || !var.ask_editors) && var.jetbrains.default != "FL"
  fleet_enabled = var.jetbrains.enabled && (contains(local.selected_editors, "fleet") || !var.ask_editors) && var.jetbrains.default == "FL"
  cursor_enabled = var.cursor.enabled && (contains(local.selected_editors, "cursor") || !var.ask_editors)
  windsurf_enabled = var.windsurf.enabled && (contains(local.selected_editors, "windsurf") || !var.ask_editors)
  blink_enabled = var.blink.enabled && (contains(local.selected_editors, "blink") || !var.ask_editors)
}

data "coder_parameter" "editors" {
  count        = var.ask_editors ? 1 : 0
  name         = "editors"
  display_name = "Code Editors"
  description  = "Select which code editors you want to use in your workspace."
  type         = "list(string)"
  default      = jsonencode(local.default_editors)
  mutable      = true
  icon         = "/icon/widgets.svg"
  form_type    = "multi-select"
  order        = 400

  option {
    name  = "VS Code Server"
    value = "code-server"
    icon  = "/icon/code.svg"
  }

  option {
    name  = "VS Code Web"
    value = "code-web"
    icon  = "/icon/code.svg"
  }

  option {
    name  = "JetBrains Gateway"
    value = "jetbrains"
    icon  = "/icon/gateway.svg"
  }

  option {
    name  = "Fleet"
    value = "fleet"
    icon  = "/icon/fleet.svg"
  }

  option {
    name  = "Cursor"
    value = "cursor"
    icon  = "/icon/cursor.svg"
  }

  option {
    name  = "Windsurf"
    value = "windsurf"
    icon  = "/icon/windsurf.svg"
  }

  option {
    name  = "Blink Shell"
    value = "blink"
    icon  = "https://assets.polaris.rest/Logos/blink_alt.svg"
  }
}

module "code-server" {
  source                  = "registry.coder.com/modules/code-server/coder"
  version                 = ">= 1.0.0"
  count                   = local.code_server_enabled ? 1 : 0
  display_name            = "VS Code Server"
  order                   = 10
  agent_id                = var.agent_id
  auto_install_extensions = true
  folder                  = var.path
  settings = {
    "workbench.activityBar.location" = "top",
    "editor.fontFamily"              = "'MonoLisa Nerd Font', MonoLisa, Menlo, Monaco, 'Courier New', monospace",
    "workbench.iconTheme"            = "material-icon-theme",
    "git.enableSmartCommit"          = true,
    "git.autofetch"                  = true,
    "git.confirmSync"                = false,
  }
}

module "vscode-web" {
  source                  = "registry.coder.com/modules/vscode-web/coder"
  version                 = ">= 1.0.0"
  count                   = local.code_web_enabled ? 1 : 0
  order                   = 25
  agent_id                = var.agent_id
  accept_license          = true
  auto_install_extensions = true
  folder                  = var.path
  settings = {
    "workbench.activityBar.location" = "top",
    "editor.fontFamily"              = "'MonoLisa Nerd Font', MonoLisa, Menlo, Monaco, 'Courier New', monospace",
    "workbench.iconTheme"            = "material-icon-theme",
    "git.enableSmartCommit"          = true,
    "git.autofetch"                  = true,
    "git.confirmSync"                = false,
  }
}

module "jetbrains_gateway" {
  source         = "registry.coder.com/modules/jetbrains-gateway/coder"
  version        = ">= 1.0.0"
  count          = local.jetbrains_enabled ? 1 : 0
  agent_id       = var.agent_id
  jetbrains_ides = setsubtract(var.jetbrains.products, ["FL"])
  default        = var.jetbrains.default
  latest         = true
  folder         = var.path
  order          = 50
}

resource "coder_app" "fleet" {
  agent_id     = var.agent_id
  count        = local.fleet_enabled ? 1 : 0
  slug         = "fleet"
  display_name = "Jetbrains Fleet"
  url          = "fleet://fleet.ssh/coder.${data.coder_workspace.main.name}?pwd=${var.path}"
  icon         = "/icon/fleet.svg"
  external     = true
  order        = 55
}

module "cursor" {
  source   = "registry.coder.com/modules/cursor/coder"
  version  = ">= 1.0.0"
  count    = local.cursor_enabled ? 1 : 0
  agent_id = var.agent_id
  folder   = var.path
  order    = 70
}

module "windsurf" {
  source   = "registry.coder.com/modules/windsurf/coder"
  version  = ">= 1.0.0"
  count    = local.windsurf_enabled ? 1 : 0
  agent_id = var.agent_id
  folder   = var.path
  order    = 75
}

resource "coder_app" "blink" {
  agent_id     = var.agent_id
  count        = local.blink_enabled ? 1 : 0
  slug         = "blink"
  display_name = "Blink Shell"
  url          = "blinkshell://run?key=12BA15&cmd=code ${data.coder_workspace.main.access_url}/@${data.coder_workspace_owner.me.name}/${data.coder_workspace.main.name}.main/apps/code-server/"
  icon         = "https://assets.polaris.rest/Logos/blink_alt.svg"
  external     = true
  order        = 100
}
