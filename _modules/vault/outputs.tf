output "data" {
  description = "Final Vault data"
  value       = merge(var.path != null ? data.vault_generic_secret.path.data : {}, try(data.coder_parameter.vault_project[0].value, "") != "" ? data.vault_generic_secret.dotenv.data : {})
}
