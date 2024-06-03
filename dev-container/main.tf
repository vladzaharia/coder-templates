terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "> 0.7.0, < 1.0.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "> 3.0.0, < 4.0.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "> 3.20.0, < 4.0.0"
    }
  }
}

variable "vault_role_id" {
  type        = string
  description = "Role ID for Vault lookup"

  validation {
    condition     = length(var.vault_role_id) == 36
    error_message = "Invalid Vault Role ID."
  }
}

variable "vault_secret_id" {
  type        = string
  description = "Secret ID for Vault lookup"
  sensitive   = true

  validation {
    condition     = length(var.vault_secret_id) == 36
    error_message = "Invalid Vault Secret ID."
  }
}

provider "vault" {
  address          = "https://vault.polaris.rest"
  skip_child_token = true

  auth_login {
    path = "auth/approle/login"

    parameters = {
      role_id   = var.vault_role_id
      secret_id = var.vault_secret_id
    }
  }
}

locals {
  username = data.coder_workspace_owner.me.name
  size_mapping = {
    small = {
      cores  = "0"
      memory = 1024
    },
    medium = {
      cores  = "0-1"
      memory = 2048
    },
    large = {
      cores  = "0-3"
      memory = 4096
    },
    xlarge = {
      cores  = "0-7"
      memory = 8192
    },
  }
}

data "coder_provisioner" "me" {
}

data "coder_external_auth" "github" {
  id = "github"
}

provider "docker" {
}

data "coder_workspace" "main" {
}

data "coder_workspace_owner" "me" {
}

data "coder_parameter" "size" {
  order        = 0
  name         = "size"
  display_name = "Container size"
  description  = "Amount of resources to dedicate to this container"
  default      = "medium"
  icon         = "/icon/memory.svg"
  type         = "string"
  mutable      = false

  option {
    name  = "Small (1c / 1024MB)"
    value = "small"
  }

  option {
    name  = "Medium (2c / 2048MB)"
    value = "medium"
  }

  option {
    name  = "Large (4c / 4096MB)"
    value = "large"
  }

  option {
    name  = "XLarge (8c / 8192MB)"
    value = "xlarge"
  }
}

data "coder_parameter" "github_repo" {
  order        = 100
  name         = "github_repo"
  display_name = "GitHub repo"
  description  = "GitHub repository to clone, as owner/repository"
  icon         = "/icon/github.svg"
  mutable      = false
}

data "coder_parameter" "dotfiles_repo" {
  order        = 150
  name         = "dotfiles_repo"
  display_name = "Dotfiles repo"
  description  = "GitHub repository to download and install dotfiles, if provided."
  icon         = "/icon/dotfiles.svg"
  default      = ""
  mutable      = false
}

data "coder_parameter" "vault_project" {
  order        = 200
  name         = "vault_project"
  display_name = "Vault project name"
  description  = "Name of the project to retrieve and inject environment variables from"
  icon         = "/icon/vault.svg"
  default      = ""
  mutable      = false
}

data "vault_generic_secret" "dotenv" {
  path = "dotenv/${data.coder_parameter.vault_project.value != "" ? data.coder_parameter.vault_project.value : "_empty"}/dev"
}

module "git-config" {
  source                = "registry.coder.com/modules/git-config/coder"
  version               = "1.0.12"
  agent_id              = coder_agent.main.id
  allow_username_change = false
  allow_email_change    = false
}

module "git-commit-signing" {
  source   = "registry.coder.com/modules/git-commit-signing/coder"
  version  = "1.0.11"
  agent_id = coder_agent.main.id
}

module "github-upload-public-key" {
  source           = "registry.coder.com/modules/github-upload-public-key/coder"
  version          = "1.0.14"
  agent_id         = coder_agent.main.id
  external_auth_id = data.coder_external_auth.github.id
}

module "code-server" {
  source                  = "registry.coder.com/modules/code-server/coder"
  version                 = "1.0.14"
  display_name            = "VS Code in Browser"
  order                   = 10
  agent_id                = coder_agent.main.id
  auto_install_extensions = true
  folder                  = "/home/${local.username}/workspace"
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
  version                 = "1.0.14"
  agent_id                = coder_agent.main.id
  order                   = 25
  accept_license          = true
  auto_install_extensions = true
  folder                  = "/home/${local.username}/workspace"
  settings = {
    "workbench.activityBar.location" = "top",
    "editor.fontFamily"              = "'MonoLisa Nerd Font', MonoLisa, Menlo, Monaco, 'Courier New', monospace",
    "workbench.iconTheme"            = "material-icon-theme",
    "git.enableSmartCommit"          = true,
    "git.autofetch"                  = true,
    "git.confirmSync"                = false,
  }
}

module "coder-login" {
  source   = "registry.coder.com/modules/coder-login/coder"
  version  = "1.0.2"
  agent_id = coder_agent.main.id
}

module "dotfiles" {
  source   = "registry.coder.com/modules/dotfiles/coder"
  version  = "1.0.14"
  agent_id = coder_agent.main.id
  dotfiles_uri = "https://github.com/${data.coder_parameter.dotfiles_repo.value}"
}

resource "coder_agent" "main" {
  arch           = data.coder_provisioner.me.arch
  os             = "linux"
  startup_script = <<-EOT
    set -e

    if [ ! -d ~/.ssh ]; then
      mkdir -p ~/.ssh && chmod 700 ~/.ssh
      ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts
    fi
  EOT

  env = merge({
    GIT_AUTHOR_NAME     = "${data.coder_workspace_owner.me.full_name}"
    GIT_COMMITTER_NAME  = "${data.coder_workspace_owner.me.full_name}"
    GIT_AUTHOR_EMAIL    = "${data.coder_workspace_owner.me.email}"
    GIT_COMMITTER_EMAIL = "${data.coder_workspace_owner.me.email}"
  }, data.vault_generic_secret.dotenv.data)

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

resource "coder_app" "blink" {
  agent_id     = coder_agent.main.id
  slug         = "blink"
  display_name = "Blink Shell"
  url          = "blinkshell://run?key=12BA15&cmd=code ${data.coder_workspace.main.access_url}/@${data.coder_workspace_owner.me.name}/${data.coder_workspace.main.name}.main/apps/code-server/"
  icon         = "https://assets.polaris.rest/Logos/blink_alt.svg"
  external     = true
  order        = 50
}

resource "docker_volume" "workspaces" {
  name = "coder-${data.coder_workspace.main.id}-workspaces"
  # Protect the volume from being deleted due to changes in attributes.
  lifecycle {
    ignore_changes = all
  }
  # Add labels in Docker to keep track of orphan resources.
  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace_owner.me.id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.main.id
  }
  # This field becomes outdated if the workspace is renamed but can
  # be useful for debugging or cleaning out dangling volumes.
  labels {
    label = "coder.workspace_name_at_creation"
    value = data.coder_workspace.main.name
  }
}

resource "docker_volume" "image_cache" {
  name = "coder-image-cache"
  lifecycle {
    ignore_changes  = all
    prevent_destroy = true
  }
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.main.start_count
  image = "ghcr.io/coder/envbuilder:0.2.9"
  # Uses lower() to avoid Docker restriction on container names.
  name = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.main.name)}"
  # Hostname makes the shell more user friendly: coder@my-workspace:~$
  hostname = data.coder_workspace.main.name
  # Use the docker gateway if the access URL is 127.0.0.1
  env = concat([
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
    "CODER_AGENT_URL=${replace(data.coder_workspace.main.access_url, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")}",
    "GIT_URL=https://github.com/${data.coder_parameter.github_repo.value}.git",
    "INIT_SCRIPT=${replace(coder_agent.main.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")}",
    "FALLBACK_IMAGE=ubuntu:latest"
  ], [for k, v in data.vault_generic_secret.dotenv.data : "${k}=${v}"])

  cpu_set = local.size_mapping[data.coder_parameter.size.value].cores
  memory  = local.size_mapping[data.coder_parameter.size.value].memory

  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }
  volumes {
    container_path = "/workspaces"
    volume_name    = docker_volume.workspaces.name
    read_only      = false
  }

  volumes {
    container_path = "/cache"
    volume_name    = docker_volume.image_cache.name
    read_only      = true
  }
  # Add labels in Docker to keep track of orphan resources.
  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace_owner.me.id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.main.id
  }
  labels {
    label = "coder.workspace_name"
    value = data.coder_workspace.main.name
  }
}
