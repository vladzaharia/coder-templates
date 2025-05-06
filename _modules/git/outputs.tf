output "folder_name" {
  description = "Folder name"
  value       = var.repo != null || data.coder_parameter.github_repo[0].value != "" ? data.coder_parameter.github_repo[0].value : null
}

output "github_access_token" {
  description = "GitHub access token"
  value       = var.github.enabled ? data.coder_external_auth.github[0].access_token : null
  sensitive = true
}