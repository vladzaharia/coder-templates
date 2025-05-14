output "folder_name" {
  description = "Folder name"
  value = module.git_clone[0].folder_name
}

output "github_access_token" {
  description = "GitHub access token"
  value       = var.github.enabled ? data.coder_external_auth.github[0].access_token : null
  sensitive   = true
}