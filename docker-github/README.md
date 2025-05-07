---
name: GitHub Workspace
description: Run a Docker workspace using a GitHub repository
tags: [local, docker, github, dotfiles, vault]
icon: https://static-00.iconduck.com/assets.00/github-icon-512x497-oppthre2.png
---

# docker-github

To get started, run `coder templates init`. When prompted, select this template.
Follow the on-screen instructions to proceed.

## Editing the image

Edit the `Dockerfile` and run `coder templates push` to update workspaces.

## code-server

`code-server` is installed via the `init_script` argument in the `coder_agent`
resource block. The `coder_app` resource is defined to access `code-server` through
the dashboard UI over `localhost:13337`.
