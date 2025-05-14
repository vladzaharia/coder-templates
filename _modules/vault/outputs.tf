output "data" {
  description = "Merged Vault data"
  value       = merge(var.path != null ? data.vault_generic_secret.path[0].data : {}, data.coder_parameter.vault_project.value != "" ? data.vault_generic_secret.dotenv[0].data : {})
  depends_on  = [data.vault_generic_secret.path, data.vault_generic_secret.dotenv]
}
