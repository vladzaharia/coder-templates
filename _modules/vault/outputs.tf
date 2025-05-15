output "data" {
  description = "Final Vault data"
  value       = var.path != null || length(data.coder_parameter.vault_project) > 0 ? data.vault_generic_secret.path[0].data : {}
}
