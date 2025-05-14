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

variable "paths" {
  type        = list(string)
  description = "Paths of secrets to get from Vault"
  default     = []
}
