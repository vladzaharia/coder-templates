# Editor starting path
variable "path" {
  description = "Starting path for AI agent"
  type        = string
}

# Coder Agent ID
variable "agent_id" {
  description = "Coder agent ID"
  type        = string
}

variable "vault_url" {
  type        = string
  description = "URL of Vault instance"
  default     = "https://vault.polaris.rest"

  validation {
    condition     = startswith(var.vault_url, "https://")
    error_message = "Vault URL must be https://<url>."
  }
}

variable "vault_role_id" {
  type        = string
  description = "Role ID for Vault lookup"

  validation {
    condition     = length(var.vault_role_id) == 36
    error_message = "Vault role ID must be 36 characters."
  }
}

variable "vault_secret_id" {
  type        = string
  description = "Secret ID for Vault lookup"
  sensitive   = true

  validation {
    condition     = length(var.vault_secret_id) == 36
    error_message = "Vault secret ID must be 36 characters."
  }
}

# Whether to use `screen` or `tmux`
variable "multiplexer" {
  description = "Screen or Tmux?"

  type    = string
  default = "screen"

  validation {
    condition     = contains(["screen", "tmux"], var.multiplexer)
    error_message = "Multiplexer must be `screen` or `tmux`."
  }
}

# Claude Code
variable "claude" {
  description = "Claude Code"

  type = object({
    enabled = bool
  })
  default = {
    enabled = false
  }
}

# Goose
variable "goose" {
  description = "Goose"

  type = object({
    enabled = bool
  })
  default = {
    enabled = false
  }
}
