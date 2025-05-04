# Editor starting path
variable "path" {
  description = "Starting path for editor"
  type        = string
}

# Coder Agent ID
variable "agent_id" {
  description = "Coder agent ID"
  type        = string
}

# VS Code Desktop
variable "code_desktop" {
  description = "VS Code Desktop"

  type = object({
    enabled = bool
  })
  default = {
    enabled = true
  }
}

# VS Code Server
variable "code_server" {
  description = "VS Code Server"

  type = object({
    enabled = bool
  })
  default = {
    enabled = true
  }
}

# VS Code Web
variable "code_web" {
  description = "VS Code Web"

  type = object({
    enabled = bool
  })
  default = {
    enabled = false
  }
}

# Jetbrains
variable "jetbrains" {
  description = "Jetbrains"

  type = object({
    enabled  = bool
    products = list(string)
    default  = string
  })
  default = {
    enabled  = true
    products = ["IU", "PS", "WS", "PY", "CL", "GO", "RM", "RD", "RR"]
    default  = "IU"
  }

  validation {
    condition     = !var.jetbrains.enabled || (var.jetbrains.enabled && var.jetbrains.products != [])
    error_message = "If Jetbrains Gateway is enabled, a list of Jetbrains products is needed."
  }

  validation {
    condition = !var.jetbrains.enabled || (
      alltrue([
        for code in var.jetbrains.products : contains(["IU", "PS", "WS", "PY", "CL", "GO", "RM", "RD", "RR"], code)
      ])
    )
    error_message = "If Jetbrains Gateway is enabled, the list must contain valid product codes. Valid product codes are ${join(",", ["IU", "PS", "WS", "PY", "CL", "GO", "RM", "RD", "RR"])}."
  }

  validation {
    condition     = !var.jetbrains.enabled || (length(var.jetbrains.products) > 0)
    error_message = "If Jetbrains Gateway is enabled, the list must not be empty."
  }

  validation {
    condition     = !var.jetbrains.enabled || (length(var.jetbrains.products) == length(toset(var.jetbrains.products)))
    error_message = "If Jetbrains Gateway is enabled, the list must not contain duplicates."
  }

  validation {
    condition     = !var.jetbrains.enabled || (var.jetbrains.enabled && var.jetbrains.default != "")
    error_message = "If Jetbrains Gateway is enabled, a default product is needed."
  }

  validation {
    condition     = !var.jetbrains.enabled || (contains(var.jetbrains.products, var.jetbrains.default))
    error_message = "If Jetbrains Gateway is enabled, the default product must be a valid product code defined in `products`."
  }
}

# Cursor
variable "cursor" {
  description = "Cursor (Desktop)"
  type = object({
    enabled = bool
  })
  default = {
    enabled = false
  }
}

# Windsurf
variable "windsurf" {
  description = "Windsurf (Desktop)"
  type = object({
    enabled = bool
  })
  default = {
    enabled = true
  }
}

# Blink Shell
variable "blink" {
  description = "Blink Shell (iOS)"
  type = object({
    enabled = bool
  })
  default = {
    enabled = true
  }
}
