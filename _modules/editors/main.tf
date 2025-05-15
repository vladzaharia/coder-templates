terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
  }
}

data "coder_workspace" "main" {}
data "coder_workspace_owner" "me" {}

module "code-server" {
  source                  = "registry.coder.com/modules/code-server/coder"
  version                 = ">= 1.0.0"
  count                   = var.code_server.enabled ? 1 : 0
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
  count                   = var.code_web.enabled ? 1 : 0
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
  count          = var.jetbrains.enabled && var.jetbrains.default != "FL" ? 1 : 0
  agent_id       = var.agent_id
  jetbrains_ides = setsubtract(var.jetbrains.products, ["FL"])
  default        = var.jetbrains.default
  latest         = true
  folder         = var.path
  order          = 50
}

resource "coder_app" "fleet" {
  agent_id     = var.agent_id
  count        = var.jetbrains.enabled && var.jetbrains.default == "FL" ? 1 : 0
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
  count    = var.cursor.enabled ? 1 : 0
  agent_id = var.agent_id
  folder   = var.path
  order    = 70
}

module "windsurf" {
  source   = "registry.coder.com/modules/windsurf/coder"
  version  = ">= 1.0.0"
  count    = var.windsurf.enabled ? 1 : 0
  agent_id = var.agent_id
  folder   = var.path
  order    = 75
}

resource "coder_app" "blink" {
  agent_id     = var.agent_id
  count        = var.blink.enabled ? 1 : 0
  slug         = "blink"
  display_name = "Blink Shell"
  url          = "blinkshell://run?key=12BA15&cmd=code ${data.coder_workspace.main.access_url}/@${data.coder_workspace_owner.me.name}/${data.coder_workspace.main.name}.main/apps/code-server/"
  icon         = "https://assets.polaris.rest/Logos/blink_alt.svg"
  external     = true
  order        = 100
}
