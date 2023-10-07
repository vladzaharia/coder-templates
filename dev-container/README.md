---
name: Dev Container
description: Runs a container based on devcontainer.json specification from a GitHub repo
tags: [local, docker, github, vault]
icon: /icon/docker.png
---

# dev-container

To get started, run `coder templates init`. When prompted, select this template.
Follow the on-screen instructions to proceed.

## Editing the image

Edit the `Dockerfile` and run `coder templates push` to update workspaces.

## code-server

`code-server` is installed via the `startup_script` argument in the `coder_agent`
resource block. The `coder_app` resource is defined to access `code-server` through
the dashboard UI over `localhost:13337`.
