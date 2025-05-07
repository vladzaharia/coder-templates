terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

data "coder_workspace" "main" {}
data "coder_workspace_owner" "me" {}

locals {
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

  # Use the variable if provided, otherwise use the UI parameter
  size = var.size != null ? var.size : try(data.coder_parameter.size[0].value, "medium")

  # Use the variable if provided, otherwise use the UI parameters
  image = var.image != null ? var.image : (
    try(data.coder_parameter.custom_base_image[0].value, "") != "" ?
    try(data.coder_parameter.custom_base_image[0].value, "") :
    try(data.coder_parameter.base_image[0].value, "ubuntu:24.04")
  )

  # Use the variable if provided, otherwise use the UI parameter
  enable_dind = var.enable_dind || try(data.coder_parameter.enable_dind[0].value, false)
}

data "coder_parameter" "size" {
  count        = var.size == null ? 1 : 0
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

data "coder_parameter" "base_image" {
  count       = var.image == null ? 1 : 0
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
  count       = var.image == null ? 1 : 0
  order       = 13
  name        = "Custom base image"
  description = "Overrides selected image above, if needed"
  icon        = "/icon/docker-white.svg"
  default     = ""
  mutable     = false
}

data "coder_parameter" "enable_dind" {
  count       = var.enable_dind == false ? 1 : 0
  order       = 15
  name        = "Enable DinD?"
  description = "Enables Docker-in-Docker support, if needed"
  icon        = "/icon/docker.svg"
  default     = false
  type        = "bool"
  mutable     = false
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
    value = "/home/${data.coder_workspace_owner.me.name}"
  }
}

resource "docker_image" "main" {
  name  = "coder-${data.coder_workspace.main.id}"
  count = var.build ? 1 : 0
  build {
    context = "../_modules/docker/build"
    build_args = {
      IMAGE       = local.image
      USER        = data.coder_workspace_owner.me.name
      ENABLE_DIND = "${local.enable_dind}"
    }
  }
  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset(path.module, "../_modules/docker/build/*") : filesha1(f)]))
  }
}

resource "coder_metadata" "main_image" {
  count       = var.build ? 1 : 0
  resource_id = docker_image.main[0].id
  item {
    key   = "base"
    value = local.image
  }
}

resource "docker_network" "dind_network" {
  name  = "network-${data.coder_workspace.main.id}"
  count = local.enable_dind ? 1 : 0
}

resource "coder_metadata" "dind_network" {
  resource_id = docker_network.dind_network[0].id
  item {
    key   = "name"
    value = docker_network.dind_network[0].name
  }
  count = local.enable_dind ? 1 : 0
}

resource "docker_container" "dind" {
  image      = "docker:dind"
  privileged = true
  name       = "dind-${data.coder_workspace.main.id}"
  entrypoint = ["dockerd", "-H", "tcp://0.0.0.0:2375"]
  networks_advanced {
    name = docker_network.dind_network[0].name
  }
  count = local.enable_dind ? 1 : 0
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.main.start_count
  image = var.build ? docker_image.main[0].name : local.image
  # Uses lower() to avoid Docker restriction on container names.
  name = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.main.name)}"
  # Hostname makes the shell more user friendly: coder@my-workspace:~$
  hostname = data.coder_workspace.main.name
  # Use the docker gateway if the access URL is 127.0.0.1
  entrypoint = ["sh", "-c", replace(var.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")]
  env = [
    "CODER_AGENT_TOKEN=${var.coder_token}",
    "CODER_ENV=true",
    local.enable_dind ? "DOCKER_HOST=${docker_container.dind[0].name}:2375" : "DOCKER_HOST="
  ]

  cpu_set = local.size_mapping[local.size].cores
  memory  = local.size_mapping[local.size].memory

  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }
  volumes {
    container_path = "/home/${data.coder_workspace_owner.me.name}"
    volume_name    = docker_volume.home_volume.name
    read_only      = false
  }

  dynamic "networks_advanced" {
    for_each = local.enable_dind ? [1] : []
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
