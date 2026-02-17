output "project_name" {
  description = "Generated project name"
  value       = local.project_name
}

output "environment" {
  description = "Selected environment"
  value       = var.environment
}
