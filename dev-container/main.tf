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
  username = data.coder_workspace.me.owner
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

provider "docker" {
}

data "coder_workspace" "me" {
}

data "coder_parameter" "size" {
  order        = 0
  name         = "size"
  display_name = "Container size"
  description  = "Amount of resources to dedicate to this container"
  default      = "medium"
  icon         = "${data.coder_workspace.me.access_url}/icon/memory.svg"
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
  icon         = "https://static-00.iconduck.com/assets.00/github-icon-512x497-oppthre2.png"
  mutable      = false
}

data "coder_parameter" "vault_project" {
  order        = 200
  name         = "vault_project"
  display_name = "Vault project name"
  description  = "Name of the project to retrieve and inject environment variables from"
  # icon        = "${data.coder_workspace.me.access_url}/icon/docker.png"
  default = ""
  mutable = false
}

data "vault_generic_secret" "dotenv" {
  path = "dotenv/${data.coder_parameter.vault_project.value != "" ? data.coder_parameter.vault_project.value : "_empty"}/dev"
}

resource "coder_agent" "main" {
  arch                   = data.coder_provisioner.me.arch
  os                     = "linux"
  startup_script_timeout = 180
  startup_script         = <<-EOT
    set -e

    # install and start code-server
    curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/tmp/code-server --version 4.11.0
    /tmp/code-server/bin/code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &

    if [ ! -d ~/.ssh ]; then
      mkdir -p ~/.ssh && chmod 700 ~/.ssh
      ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts
    fi
  EOT

  env = merge({
    GIT_AUTHOR_NAME     = "${data.coder_workspace.me.owner}"
    GIT_COMMITTER_NAME  = "${data.coder_workspace.me.owner}"
    GIT_AUTHOR_EMAIL    = "${data.coder_workspace.me.owner_email}"
    GIT_COMMITTER_EMAIL = "${data.coder_workspace.me.owner_email}"
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

resource "coder_app" "code-server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "VS Code in Browser"
  url          = "http://localhost:13337/?folder=/home/${local.username}/workspace"
  icon         = "/icon/code.svg"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 5
    threshold = 6
  }
}

resource "docker_volume" "workspaces" {
  name = "coder-${data.coder_workspace.me.id}-workspaces"
  # Protect the volume from being deleted due to changes in attributes.
  lifecycle {
    ignore_changes = all
  }
  # Add labels in Docker to keep track of orphan resources.
  labels {
    label = "coder.owner"
    value = data.coder_workspace.me.owner
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace.me.owner_id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  # This field becomes outdated if the workspace is renamed but can
  # be useful for debugging or cleaning out dangling volumes.
  labels {
    label = "coder.workspace_name_at_creation"
    value = data.coder_workspace.me.name
  }
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = "ghcr.io/coder/envbuilder:0.2.1"
  # Uses lower() to avoid Docker restriction on container names.
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  # Hostname makes the shell more user friendly: coder@my-workspace:~$
  hostname = data.coder_workspace.me.name
  # Use the docker gateway if the access URL is 127.0.0.1
  env = concat([
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
    "CODER_AGENT_URL=${replace(data.coder_workspace.me.access_url, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")}",
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
  # Add labels in Docker to keep track of orphan resources.
  labels {
    label = "coder.owner"
    value = data.coder_workspace.me.owner
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace.me.owner_id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  labels {
    label = "coder.workspace_name"
    value = data.coder_workspace.me.name
  }
}
