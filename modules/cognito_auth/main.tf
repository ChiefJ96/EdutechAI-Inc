// modules/cognito_auth/main.tf
variable "project_name" { type = string }
variable "user_pool_name" {
  type    = string
  default = null
}
variable "domain_prefix" {
  type    = string
  default = null
}
variable "callback_urls" {
  type    = list(string)
  default = []
}
variable "logout_urls" {
  type    = list(string)
  default = []
}
variable "supported_identity_providers" {
  type    = list(string)
  default = ["COGNITO"]
}

resource "aws_cognito_user_pool" "this" {
  name = var.user_pool_name != null ? var.user_pool_name : "${var.project_name}-user-pool"

  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
    require_lowercase = true
  }
}

resource "aws_cognito_user_pool_client" "this" {
  name         = "${var.project_name}-client"
  user_pool_id = aws_cognito_user_pool.this.id

  explicit_auth_flows = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]

  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  allowed_oauth_flows_user_pool_client = true

  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  supported_identity_providers = var.supported_identity_providers

  prevent_user_existence_errors = "ENABLED"
}

resource "aws_cognito_user_pool_domain" "this" {
  domain       = var.domain_prefix
  user_pool_id = aws_cognito_user_pool.this.id
}

output "user_pool_id" {
  value = aws_cognito_user_pool.this.id
}

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.this.id
}

output "user_pool_domain" {
  value = aws_cognito_user_pool_domain.this.domain
}

output "domain" {
  value = aws_cognito_user_pool_domain.this.domain
}

output "user_pool_arn" {
  value = aws_cognito_user_pool.this.arn
}