variable "env" {
  description = "Additional data to pass to the agent"
  type        = map(string)
  default     = {}
}

variable "init_script" {
  description = "Startup script to run in the workspace after the generic Coder one."
  type        = string
  default     = ""
}