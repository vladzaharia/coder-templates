output "data" {
  description = "Final Vault data"
  value       = data.vault_generic_secret.path.data
}
