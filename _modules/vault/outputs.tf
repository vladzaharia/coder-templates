output "data" {
  description = "Final Vault data"
  value       = merge(var.path != null ? data.vault_generic_secret.path[0].data : data.vault_generic_secret.dotenv[0].data)
}
