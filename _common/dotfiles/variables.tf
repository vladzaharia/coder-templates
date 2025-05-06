variable "agent_id" {
  description = "Coder agent ID"
  type        = string
}

variable "dotfiles_uri" {
  type        = string
  description = "GitHub repository to download and install dotfiles (e.g., 'username/repo'). If provided, user will not be shown dotfiles repo selector."
  nullable    = true
  default     = null
}