terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
    vault = {
      source = "hashicorp/vault"
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

provider "docker" {}

data "coder_external_auth" "github" {
  id = "github"
}

data "coder_provisioner" "me" {}
data "coder_workspace" "main" {}
data "coder_workspace_owner" "me" {}

data "coder_parameter" "size" {
  order        = 0
  name         = "size"
  display_name = "Container size"
  description  = "Amount of resources to dedicate to this container"
  default      = "medium"
  icon         = "${data.coder_workspace.main.access_url}/icon/docker.png"
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

data "coder_parameter" "base_image" {
  order       = 10
  name        = "Base image"
  description = "Base docker image to use for this workspace"
  default     = "ubuntu:24.04"
  icon        = "/icon/docker.svg"
  type        = "string"
  mutable     = false

  option {
    name  = "Ubuntu 24.04 LTS"
    value = "ubuntu:24.04"
    icon  = "/icon/ubuntu.svg"
  }

  option {
    name  = "Ubuntu 23.10"
    value = "ubuntu:23.10"
    icon  = "/icon/ubuntu.svg"
  }

  option {
    name  = "Ubuntu 22.04 LTS"
    value = "ubuntu:22.04"
    icon  = "/icon/ubuntu.svg"
  }

  option {
    name  = "Debian Bookworm"
    value = "debian:bookworm"
    icon  = "/icon/debian.svg"
  }

  option {
    name  = "Fedora 40"
    value = "fedora:40"
    icon  = "/icon/fedora.svg"
  }

  option {
    name  = "Golang"
    value = "golang:bookworm"
    icon  = "/icon/go.svg"
  }

  option {
    name  = "Node LTS"
    value = "node:lts-bookworm"
    icon  = "/icon/nodejs.svg"
  }

  option {
    name  = "Node Current"
    value = "node:current-bookworm"
    icon  = "/icon/nodejs.svg"
  }

  option {
    name  = "OpenJDK 22"
    value = "eclipse-temurin:22-jammy"
    icon  = "/icon/java.svg"
  }

  option {
    name  = "PHP"
    value = "php:bookworm"
    icon  = "/icon/php.svg"
  }

  option {
    name  = "Python"
    value = "python:bookworm"
    icon  = "/icon/python.svg"
  }

  option {
    name  = "Ruby"
    value = "ruby:bookworm"
    icon  = "/icon/ruby.png"
  }
}

data "coder_parameter" "custom_base_image" {
  order       = 13
  name        = "Custom base image"
  description = "Overrides selected image above, if needed"
  icon        = "/icon/docker-white.svg"
  default     = ""
  mutable     = false
}

data "coder_parameter" "enable_dind" {
  order       = 15
  name        = "Enable Docker?"
  description = "Enables Docker-in-Docker support, if needed"
  icon        = "/icon/docker.svg"
  default     = false
  type        = "bool"
  mutable     = false
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

data "coder_parameter" "github_repo" {
  order        = 100
  name         = "github_repo"
  display_name = "GitHub repo"
  description  = "GitHub repository to clone, as owner/repository"
  icon         = "/icon/github.svg"
  mutable      = false
}

data "vault_generic_secret" "dotenv" {
  path = "dotenv/${data.coder_parameter.vault_project.value != "" ? data.coder_parameter.vault_project.value : "_empty"}/dev"
}

data "vault_generic_secret" "claude_code" {
  path = "dotenv/coder-claude-code/dev"
}

module "claude-code" {
  source                  = "registry.coder.com/modules/claude-code/coder"
  version                 = ">= 1.0.0"
  agent_id                = coder_agent.main.id
  folder                  = "/home/${local.username}/${data.coder_workspace.main.name}"
  install_claude_code     = true
  claude_code_version     = "latest"
  experiment_use_screen   = true
  experiment_report_tasks = true
}

module "git-config" {
  source                = "registry.coder.com/modules/git-config/coder"
  version               = ">= 1.0.0"
  agent_id              = coder_agent.main.id
  allow_username_change = false
  allow_email_change    = false
}

module "git_clone" {
  source   = "registry.coder.com/modules/git-clone/coder"
  version  = ">= 1.0.0"
  agent_id = coder_agent.main.id
  url      = "https://github.com/${data.coder_parameter.github_repo.value}"
}

module "git-commit-signing" {
  source   = "registry.coder.com/modules/git-commit-signing/coder"
  version  = ">= 1.0.0"
  agent_id = coder_agent.main.id
}

module "dotfiles" {
  source       = "registry.coder.com/modules/dotfiles/coder"
  version      = ">= 1.0.0"
  agent_id     = coder_agent.main.id
  dotfiles_uri = "https://github.com/${data.coder_parameter.dotfiles_repo.value}"
}

module "code-server" {
  source                  = "registry.coder.com/modules/code-server/coder"
  version                 = ">= 1.0.0"
  display_name            = "VS Code Server"
  order                   = 10
  agent_id                = coder_agent.main.id
  auto_install_extensions = true
  folder                  = "/home/${local.username}/${module.git_clone.folder_name}"
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
  order                   = 25
  agent_id                = coder_agent.main.id
  accept_license          = true
  auto_install_extensions = true
  folder                  = "/home/${local.username}/${module.git_clone.folder_name}"
  settings = {
    "workbench.activityBar.location" = "top",
    "editor.fontFamily"              = "'MonoLisa Nerd Font', MonoLisa, Menlo, Monaco, 'Courier New', monospace",
    "workbench.iconTheme"            = "material-icon-theme",
    "git.enableSmartCommit"          = true,
    "git.autofetch"                  = true,
    "git.confirmSync"                = false,
  }
}

module "windsurf" {
  source   = "registry.coder.com/modules/windsurf/coder"
  version  = ">= 1.0.0"
  agent_id = coder_agent.main.id
  folder   = "/workspaces/${data.coder_workspace.main.name}.git"
  order    = 40
}

module "jetbrains_gateway" {
  source  = "registry.coder.com/modules/jetbrains-gateway/coder"
  version = ">= 1.0.0"

  jetbrains_ides = ["IU", "PS", "WS", "PY", "CL", "GO", "RM", "RD", "RR"]
  default        = "IU"

  # Default folder to open when starting a JetBrains IDE
  folder = "/home/${local.username}/${module.git_clone.folder_name}"


  agent_id   = coder_agent.main.id
  agent_name = "main"
  order      = 50
}

resource "coder_script" "npm" {
  agent_id           = coder_agent.main.id
  display_name       = "Running NPM install"
  icon               = "/icon/nodejs.svg"
  run_on_start       = strcontains(data.coder_parameter.base_image.value, "node:")
  start_blocks_login = strcontains(data.coder_parameter.base_image.value, "node:")
  cron               = !strcontains(data.coder_parameter.base_image.value, "node:") ? "0 6 * * *" : null
  script             = <<-EOT
    set -e
    echo "Running npm install..."
    cd ~/workspace
    npm install
  EOT
}

module "coder-login" {
  source   = "registry.coder.com/modules/coder-login/coder"
  version  = ">= 1.0.0"
  agent_id = coder_agent.main.id
}

data "coder_parameter" "ai_prompt" {
  type        = "string"
  name        = "AI Prompt"
  default     = ""
  description = "Write a prompt for Claude Code"
  mutable     = true
}

resource "coder_agent" "main" {
  arch = data.coder_provisioner.me.arch
  os   = "linux"

  env = merge({
    GIT_AUTHOR_NAME              = "${data.coder_workspace_owner.me.full_name}"
    GIT_COMMITTER_NAME           = "${data.coder_workspace_owner.me.full_name}"
    GIT_AUTHOR_EMAIL             = "${data.coder_workspace_owner.me.email}"
    GIT_COMMITTER_EMAIL          = "${data.coder_workspace_owner.me.email}"
    GITHUB_TOKEN                 = "${data.coder_external_auth.github.access_token}"
    CODER_MCP_APP_STATUS_SLUG    = "claude-code"
    CODER_MCP_CLAUDE_TASK_PROMPT = data.coder_parameter.ai_prompt.value
    DOTFILES_URI                 = data.coder_parameter.dotfiles_repo.value != "" ? data.coder_parameter.dotfiles_repo.value : null
  }, data.vault_generic_secret.dotenv.data, data.vault_generic_secret.claude_code.data)

  startup_script = <<-EOT
    set -e

    # Prepare user home with default files on first start.
    if [ ! -f ~/.init_done ]; then
      cp -rT /etc/skel ~
      touch ~/.init_done
    fi

    # Add any commands that should be executed at workspace startup (e.g install requirements, start a program, etc) here
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

resource "coder_app" "blink" {
  agent_id     = coder_agent.main.id
  slug         = "blink"
  display_name = "Blink Shell"
  url          = "blinkshell://run?key=12BA15&cmd=code ${data.coder_workspace.main.access_url}/@${data.coder_workspace_owner.me.name}/${data.coder_workspace.main.name}.main/apps/code-server/"
  icon         = "https://assets.polaris.rest/Logos/blink_alt.svg"
  external     = true
  order        = 100
}

resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace.main.id}-home"
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

resource "coder_metadata" "home_volume" {
  resource_id = docker_volume.home_volume.id
  item {
    key   = "home"
    value = "/home/${local.username}"
  }
  item {
    key   = "workspace"
    value = "/home/${local.username}/workspace"
  }
}

resource "docker_image" "main" {
  name = "coder-${data.coder_workspace.main.id}"
  build {
    context = "./build"
    build_args = {
      IMAGE       = data.coder_parameter.custom_base_image.value != "" ? data.coder_parameter.custom_base_image.value : data.coder_parameter.base_image.value
      USER        = local.username
      ENABLE_DIND = "${data.coder_parameter.enable_dind.value}"
    }
  }
  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset(path.module, "build/*") : filesha1(f)]))
  }
}

resource "coder_metadata" "main_image" {
  resource_id = docker_image.main.id
  item {
    key   = "base"
    value = data.coder_parameter.custom_base_image.value != "" ? data.coder_parameter.custom_base_image.value : data.coder_parameter.base_image.value
  }
  item {
    key   = "repo"
    value = data.coder_parameter.github_repo.value
  }
}

resource "docker_network" "dind_network" {
  name  = "network-${data.coder_workspace.main.id}"
  count = data.coder_parameter.enable_dind.value ? 1 : 0
}

resource "coder_metadata" "dind_network" {
  resource_id = docker_network.dind_network[0].id
  item {
    key   = "name"
    value = docker_network.dind_network[0].name
  }
  count = data.coder_parameter.enable_dind.value ? 1 : 0
}

resource "docker_container" "dind" {
  image      = "docker:dind"
  privileged = true
  name       = "dind-${data.coder_workspace.main.id}"
  entrypoint = ["dockerd", "-H", "tcp://0.0.0.0:2375"]
  networks_advanced {
    name = docker_network.dind_network[0].name
  }
  count = data.coder_parameter.enable_dind.value ? 1 : 0
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.main.start_count
  image = docker_image.main.name
  # Uses lower() to avoid Docker restriction on container names.
  name = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.main.name)}"
  # Hostname makes the shell more user friendly: coder@my-workspace:~$
  hostname = data.coder_workspace.main.name
  # Use the docker gateway if the access URL is 127.0.0.1
  entrypoint = ["sh", "-c", replace(coder_agent.main.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")]
  env = [
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
    "CODER_ENV=true",
    data.coder_parameter.enable_dind.value ? "DOCKER_HOST=${docker_container.dind[0].name}:2375" : "DOCKER_HOST="
  ]

  cpu_set = local.size_mapping[data.coder_parameter.size.value].cores
  memory  = local.size_mapping[data.coder_parameter.size.value].memory

  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }
  volumes {
    container_path = "/home/${local.username}"
    volume_name    = docker_volume.home_volume.name
    read_only      = false
  }

  dynamic "networks_advanced" {
    for_each = data.coder_parameter.enable_dind.value ? [1] : []
    content {
      name = docker_network.dind_network[0].name
    }
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
