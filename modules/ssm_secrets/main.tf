// modules/ssm_secrets/main.tf
variable "project_name" { type = string }
variable "secrets" {
  description = "Map of secret names and properties (description, overwrite, generate_password, etc.)"
  type = map(object({
    description       = string
    overwrite         = bool
    generate_password = optional(bool, false)
    password_length   = optional(number, 16)
  }))
}

// Random password generator helper
resource "random_password" "passwords" {
  for_each = { for k, v in var.secrets : k => v if v.generate_password }

  length  = lookup(each.value, "password_length", 16)
  special = true
}

resource "aws_ssm_parameter" "secrets" {
  for_each = var.secrets

  name        = "/${var.project_name}/${each.key}"
  type        = "SecureString"
  value       = each.value.generate_password ? random_password.passwords[each.key].result : "PLACEHOLDER_VALUE_REPLACE_AFTER_DEPLOYMENT"
  description = each.value.description
  overwrite   = true # Always allow overwrite to prevent conflicts

  tags = {
    Name = "${var.project_name}-${each.key}"
  }
}

output "secrets_names" {
  value = [for k, v in var.secrets : "/${var.project_name}/${k}"]
}

output "secret_arns" {
  value = { for k, v in aws_ssm_parameter.secrets : k => v.arn }
}