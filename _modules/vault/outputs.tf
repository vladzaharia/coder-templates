output "data" {
  description = "Final Vault data"
  value       = var.path != null || data.coder_parameter.vault_project[0].value != "" ? data.vault_generic_secret.path[0].data : {}
}
