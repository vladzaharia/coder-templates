output "agent_id" {
  description = "Coder agent ID"
  value       = coder_agent.main.id
}

output "init_script" {
  description = "Coder final init script"
  value       = coder_agent.main.init_script
}

output "token" {
  description = "Coder agent token"
  value       = coder_agent.main.token
  sensitive   = true
}