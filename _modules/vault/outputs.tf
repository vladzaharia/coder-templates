output "data" {
  description = "Merged Vault data"
  value       = merge({ for k1, v1 in { for k, v in data.vault_generic_secret.secrets : k => v.data } : k1.key => k1.value }, data.coder_parameter.vault_project != "" ? data.vault_generic_secret.dotenv[0].data : {})
  depends_on  = [data.vault_generic_secret.secrets, data.vault_generic_secret.dotenv]
}
