variable "image" {
  description = "Image to use for this workspace. If provided, user will not be shown Docker image selector."
  type        = string
  nullable    = true
  default     = null
}

variable "size" {
  description = "Size of the container. If provided, user will not be shown Docker size selector."
  type        = string
  nullable    = true
  default     = null

  validation {
    condition     = var.size == null || var.size == "small" || var.size == "medium" || var.size == "large" || var.size == "xlarge"
    error_message = "Size must be one of: small, medium, large, xlarge"
  }
}

variable "enable_dind" {
  description = "Enable Docker-in-Docker support. If provided, user will not be shown Docker DinD checkbox."
  type        = bool
  default     = false
}

variable "build" {
  description = "Build the image from the Dockerfile."
  type        = bool
  default     = true
}

variable "init_script_extra" {
  description = "Init script to run in the workspace after the generic Coder one."
  type        = string
  default     = ""
}

variable "coder_token" {
  description = "Coder agent token"
  type        = string
  sensitive   = true
}