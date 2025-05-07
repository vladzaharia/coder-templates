output "dotfiles_uri" {
  description = "Dotfiles URI"
  value       = local.selected_dotfiles_uri != "" ? "https://github.com/${local.selected_dotfiles_uri}" : var.dotfiles_uri != null ? var.dotfiles_uri : null
}

