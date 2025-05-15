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
  # Check if each editor is selected
  code_server_enabled = var.code_server.enabled && (var.ask_editors ? try(data.coder_parameter.code_server_enabled[0].value, var.code_server.enabled) : var.code_server.enabled)
  code_web_enabled = var.code_web.enabled && (var.ask_editors ? try(data.coder_parameter.code_web_enabled[0].value, var.code_web.enabled) : var.code_web.enabled)
  jetbrains_enabled = var.jetbrains.enabled && var.jetbrains.default != "FL" && (var.ask_editors ? try(data.coder_parameter.jetbrains_enabled[0].value, var.jetbrains.enabled) : var.jetbrains.enabled)
  fleet_enabled = var.jetbrains.enabled && var.jetbrains.default == "FL" && (var.ask_editors ? try(data.coder_parameter.fleet_enabled[0].value, var.jetbrains.enabled) : var.jetbrains.enabled)
  cursor_enabled = var.cursor.enabled && (var.ask_editors ? try(data.coder_parameter.cursor_enabled[0].value, var.cursor.enabled) : var.cursor.enabled)
  windsurf_enabled = var.windsurf.enabled && (var.ask_editors ? try(data.coder_parameter.windsurf_enabled[0].value, var.windsurf.enabled) : var.windsurf.enabled)
  blink_enabled = var.blink.enabled && (var.ask_editors ? try(data.coder_parameter.blink_enabled[0].value, var.blink.enabled) : var.blink.enabled)
}

data "coder_parameter" "code_server_enabled" {
  count        = var.ask_editors && var.code_server.enabled ? 1 : 0
  name         = "code_server_enabled"
  display_name = "VS Code Server"
  description  = "Enable VS Code Server"
  type         = "bool"
  default      = var.code_server.enabled
  mutable      = true
  icon         = "/icon/code.svg"
  order        = 410
}

data "coder_parameter" "code_web_enabled" {
  count        = var.ask_editors && var.code_web.enabled ? 1 : 0
  name         = "code_web_enabled"
  display_name = "VS Code Web"
  description  = "Enable VS Code Web"
  type         = "bool"
  default      = var.code_web.enabled
  mutable      = true
  icon         = "/icon/code.svg"
  order        = 415
}

data "coder_parameter" "fleet_enabled" {
  count        = var.ask_editors && var.jetbrains.enabled && var.jetbrains.default == "FL" ? 1 : 0
  name         = "fleet_enabled"
  display_name = "Fleet"
  description  = "Enable JetBrains Fleet"
  type         = "bool"
  default      = var.jetbrains.enabled
  mutable      = true
  icon         = "/icon/fleet.svg"
  order        = 420
}

data "coder_parameter" "jetbrains_enabled" {
  count        = var.ask_editors && var.jetbrains.enabled && var.jetbrains.default != "FL" ? 1 : 0
  name         = "jetbrains_enabled"
  display_name = "JetBrains Gateway"
  description  = "Enable JetBrains Gateway"
  type         = "bool"
  default      = var.jetbrains.enabled
  mutable      = true
  icon         = "/icon/gateway.svg"
  order        = 425
}

data "coder_parameter" "cursor_enabled" {
  count        = var.ask_editors && var.cursor.enabled ? 1 : 0
  name         = "cursor_enabled"
  display_name = "Cursor"
  description  = "Enable Cursor"
  type         = "bool"
  default      = var.cursor.enabled
  mutable      = true
  icon         = "/icon/cursor.svg"
  order        = 430
}

data "coder_parameter" "windsurf_enabled" {
  count        = var.ask_editors && var.windsurf.enabled ? 1 : 0
  name         = "windsurf_enabled"
  display_name = "Windsurf"
  description  = "Enable Windsurf"
  type         = "bool"
  default      = var.windsurf.enabled
  mutable      = true
  icon         = "/icon/windsurf.svg"
  order        = 435
}

data "coder_parameter" "blink_enabled" {
  count        = var.ask_editors && var.blink.enabled ? 1 : 0
  name         = "blink_enabled"
  display_name = "Blink Shell"
  description  = "Enable Blink Shell (for iOS)"
  type         = "bool"
  default      = var.blink.enabled
  mutable      = true
  icon         = "https://assets.polaris.rest/Logos/blink_alt.svg"
  order        = 440
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
