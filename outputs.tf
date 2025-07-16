# Frontend Outputs
output "cloudfront_distribution_domain_name" {
  description = "CloudFront distribution domain name for frontend"
  value       = module.cloudfront_distribution.distribution_domain_name
}

output "s3_bucket_name" {
  description = "S3 bucket name for frontend static files"
  value       = module.s3_static_site.bucket_name
}

# Backend API Outputs
output "api_load_balancer_dns_name" {
  description = "Load balancer DNS name for backend API"
  value       = module.ecs_api_task.load_balancer_dns_name
}

output "api_endpoint" {
  description = "Backend API endpoint URL"
  value       = "http://${module.ecs_api_task.load_balancer_dns_name}"
}

# Database Outputs
output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.rds_postgres.endpoint
  sensitive   = true
}

output "rds_database_name" {
  description = "RDS database name"
  value       = module.rds_postgres.database_name
}

# Authentication Outputs
output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito_auth.user_pool_id
}

output "cognito_user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = module.cognito_auth.user_pool_client_id
}

output "cognito_domain" {
  description = "Cognito hosted UI domain"
  value       = module.cognito_auth.domain
}

# Infrastructure Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc_core.vpc_id
}

output "kms_key_id" {
  description = "KMS key ID for encryption"
  value       = aws_kms_key.main.key_id
}

output "kms_key_arn" {
  description = "KMS key ARN for encryption"
  value       = aws_kms_key.main.arn
}

# Monitoring Outputs
output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = module.cloudwatch_alerts.dashboard_url
}

output "sns_alerts_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = module.cloudwatch_alerts.sns_topic_arn
}

# CI/CD Outputs
output "codepipeline_name" {
  description = "CodePipeline name"
  value       = module.codepipeline_ci.pipeline_name
}

# Cost Estimation Notice
output "estimated_monthly_cost" {
  description = "Estimated monthly cost range for this infrastructure"
  value       = "Development: $40-70/month | Production (scaled): $400-800/month"
}

# Getting Started Instructions
output "getting_started_instructions" {
  description = "Instructions to get started with the deployed infrastructure"
  value       = <<-EOT
  🚀 EdutechAI Infrastructure Deployed Successfully!
  
  Frontend URL: https://${module.cloudfront_distribution.distribution_domain_name}
  API Endpoint: http://${module.ecs_api_task.load_balancer_dns_name}
  
  Next Steps:
  1. Deploy your React frontend to S3: ${module.s3_static_site.bucket_name}
  2. Configure your backend API to use:
     - Database: ${module.rds_postgres.endpoint}
     - Cognito User Pool: ${module.cognito_auth.user_pool_id}
  3. Set up CI/CD by configuring GitHub OAuth token in SSM Parameter Store
  4. Monitor your application: ${module.cloudwatch_alerts.dashboard_url}
  
  🔐 Security Notes:
  - All resources are encrypted with KMS
  - S3 buckets have public access blocked
  - RDS is in private subnets only
  - ALB enforces HTTPS redirects
  EOT
}