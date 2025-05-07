variable "agent_id" {
  description = "Coder agent ID"
  type        = string
}

variable "github" {
  description = "GitHub authentication settings"

  type = object({
    enabled = bool
  })
  default = {
    enabled = false
  }
}

variable "repo" {
  description = "GitHub repository to clone, as owner/repository"
  type        = string
  nullable    = true
  default     = null
}
