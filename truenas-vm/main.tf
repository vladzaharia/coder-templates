terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "> 0.7.0, < 1.0.0"
    }
    macaddress = {
      source  = "ivoronin/macaddress"
      version = "> 0.3.0, < 1.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "> 3.5.0, < 4.0.0"
    }
    truenas = {
      source  = "dariusbakunas/truenas"
      version = "> 0.11.0, < 1.0.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "> 3.20.0, < 4.0.0"
    }
  }
}

locals {
  username = data.coder_workspace.me.owner
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

data "coder_provisioner" "me" {
}

data "coder_workspace" "me" {
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

data "coder_parameter" "truenas_debug" {
  order        = 200
  name         = "truenas_debug"
  display_name = "Debug TrueNAS requests?"
  # icon        = "${data.coder_workspace.me.access_url}/icon/docker.png"
  default   = false
  type      = "bool"
  ephemeral = true
  mutable   = true
}

data "vault_generic_secret" "dotenv" {
  path = "dotenv/${data.coder_parameter.vault_project.value != "" ? data.coder_parameter.vault_project.value : "_empty"}/dev"
}

resource "coder_agent" "main" {
  arch                   = data.coder_provisioner.me.arch
  os                     = "linux"
    startup_script         = <<-EOT
    set -e

    # install and start code-server
    curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/tmp/code-server
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

provider "random" {
}

resource "random_id" "vm_id" {
  byte_length = 8
}

resource "random_integer" "vm_vnc_port" {
  min = 5911
  max = 5949
}

provider "macaddress" {
}

resource "macaddress" "vm_mac" {
  // 00:a0:98
  prefix = [0, 160, 152]
}

data "vault_generic_secret" "truenas_token" {
  path = "ci-cd/coder/truenas"
}

provider "truenas" {
  api_key  = data.vault_generic_secret.truenas_token.data["TRUENAS_TOKEN"]
  base_url = "https://truenas.polaris.rest/api/v2.0"
  debug    = data.coder_parameter.truenas_debug.value
}

resource "truenas_vm" "vm" {
  name             = "coder-${random_id.vm_id.hex}}"
  description      = "Coder VM for ${lower(data.coder_workspace.me.owner)}'s ${lower(data.coder_workspace.me.name)} workspace"
  vcpus            = 1
  bootloader       = "UEFI"
  autostart        = true
  time             = "UTC"
  shutdown_timeout = "10"
  cores            = 4
  threads          = 2
  memory           = 1024 * 1024 * 1024 * 4 // 4GB

  device {
    type = "NIC"
    attributes = {
      type       = "VIRTIO"
      mac        = macaddress.vm_mac.address
      nic_attach = "br411"
    }
  }

  device {
    type = "DISK"
    attributes = {
      path                = "/dev/zvol/nvme/vm-images"
      type                = "VIRTIO"
      physical_sectorsize = null
      logical_sectorsize  = null
    }
  }

  device {
    type = "CDROM"
    attributes = {
      path = "/mnt/nvme/vm-isos/UbuntuServer-2204.iso"
    }
  }

  device {
    type = "DISPLAY"
    attributes = {
      wait       = false
      port       = random_integer.vm_vnc_port.result
      resolution = "1024x768"
      bind       = "0.0.0.0"
      password   = ""
      web        = true
      type       = "VNC"
    }
  }
}

resource "coder_app" "vnc" {
  agent_id     = coder_agent.main.id
  slug         = "vnc"
  display_name = "VNC"
  #   icon         = "https://yoolk.ninja/wp-content/uploads/2020/06/Apps-Ms-Remote-Desktop-1024x1024.png"
  url      = "vnc://truenas.polaris.rest:${random_integer.vm_vnc_port.result}"
  external = true
}
