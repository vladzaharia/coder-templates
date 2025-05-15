# Utilities Module

This module provides various utility applications for Coder templates, including desktop environments, file browsers, Jupyter notebooks, and RDP access.

## Features

- KasmVNC for browser-based desktop environments
- File Browser for web-based file management
- JupyterLab for interactive notebooks
- RDP support for Windows environments

## Usage

```hcl
module "coder_utilities" {
  source = "./_modules/utilities"

  agent_id = module.coder_coder.agent_id

  kasm = {
    enabled = true
    de      = "xfce"
  }

  file = {
    enabled = true
    path    = "/home/user/workspace"
  }

  jupyter = {
    enabled = true
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| agent_id | Coder agent ID | `string` | n/a | yes |
| kasm | KasmVNC configuration | `object({ enabled = bool, de = string })` | `{ enabled = false, de = "" }` | no |
| file | File Browser configuration | `object({ enabled = bool, path = string })` | `{ enabled = false, path = "~" }` | no |
| jupyter | JupyterLab configuration | `object({ enabled = bool })` | `{ enabled = false }` | no |
| rdp | RDP configuration | `object({ enabled = bool, resource_id = string })` | `{ enabled = false, resource_id = "" }` | no |

## Dependencies

- Coder registry modules:
  - `registry.coder.com/modules/kasmvnc/coder`
  - `registry.coder.com/modules/filebrowser/coder`
  - `registry.coder.com/modules/jupyterlab/coder`
  - `registry.coder.com/modules/windows-rdp/coder`
