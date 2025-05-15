# Docker Module

This module provides Docker-specific functionality for Coder templates, including container configuration, resource allocation, and Docker-in-Docker (DinD) support.

## Features

- Creates and configures Docker containers for Coder workspaces
- Supports various container sizes (small, medium, large, xlarge)
- Provides a selection of base images (Ubuntu, Debian, Fedora, language-specific)
- Enables Docker-in-Docker (DinD) support
- Creates persistent home volumes for workspaces

## Usage

```hcl
module "coder_docker" {
  source = "./_modules/docker"

  init_script = module.coder_coder.init_script
  coder_token = module.coder_coder.token

  size = "medium"
  image = "ubuntu:24.04"
  enable_dind = true
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| init_script | Initialization script from the coder module | `string` | n/a | yes |
| coder_token | Coder agent token | `string` | n/a | yes |
| size | Container size (small, medium, large, xlarge) | `string` | `null` | no |
| image | Docker image to use | `string` | `null` | no |
| enable_dind | Whether to enable Docker-in-Docker | `bool` | `false` | no |
| build | Whether to build a custom image | `bool` | `true` | no |

## Dependencies

- Docker Terraform provider (`kreuzwerker/docker`)
