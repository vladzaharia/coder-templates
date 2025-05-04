locals {
  claude_code_vars = var.claude.enabled ? {
    CODER_MCP_CLAUDE_TASK_PROMPT   = data.coder_parameter.ai_prompt.value
    CODER_MCP_APP_STATUS_SLUG      = "claude-code"
  } : {}
  claude_code_secrets = var.claude.enabled ? module.claude-vault.data : {}

  goose_vars = var.goose.enabled ? {
    GOOSE_TASK_PROMPT   = data.coder_parameter.ai_prompt.value
  } : {}
  goose_secrets = var.goose.enabled ? module.goose-vault.data : {}
}

output "data" {
  description = "Merged AI environment variables"
  value       = merge(claude_code_vars, claude_code_secrets, goose_vars, goose_secrets)
  depends_on  = [data.vault_generic_secret.secrets]
}
