# EdutechAI E-Learning Platform Infrastructure
# AWS Terraform Configuration for AI-Powered Learning Platform

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "edutechai"
}

# KMS key for encryption across all resources
resource "aws_kms_key" "main" {
  description             = "${var.project_name} KMS key for encrypting resources"
  deletion_window_in_days = 30

  tags = {
    Name = "${var.project_name}-kms"
  }
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.project_name}-kms"
  target_key_id = aws_kms_key.main.key_id
}

# Systems Manager Parameter Store secrets - Created first to avoid dependency issues
module "ssm_secrets" {
  source = "./modules/ssm_secrets"

  project_name = var.project_name

  secrets = {
    rds_password = {
      description       = "RDS Postgres master password"
      overwrite         = false
      generate_password = true
      password_length   = 16
    }
    github_oauth_token = {
      description = "GitHub OAuth token for CodePipeline"
      overwrite   = false
    }
    ecs_taskexec_role_arn = {
      description = "ECS task execution role ARN"
      overwrite   = false
    }
    ecs_task_role_arn = {
      description = "ECS task role ARN"
      overwrite   = false
    }
  }
}

# VPC and Networking Infrastructure
module "vpc_core" {
  source = "./modules/vpc"

  project_name       = var.project_name
  cidr_block         = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]   # Different AZs
  private_subnets    = ["10.0.11.0/24", "10.0.12.0/24"] # Different AZs
  enable_nat_gateway = true
}

# RDS PostgreSQL Database
module "rds_postgres" {
  source = "./modules/rds_postgres"

  depends_on = [module.ssm_secrets]

  project_name        = var.project_name
  vpc_id              = module.vpc_core.vpc_id
  private_subnets     = module.vpc_core.private_subnets
  db_name             = "edutechiadb"
  db_username         = "edutechiadbuser"
  db_password_ssm     = "/${var.project_name}/rds_password"
  instance_class      = "db.t4g.micro" # ARM-based for cost efficiency
  allocated_storage   = 20
  multi_az            = false
  publicly_accessible = false
  storage_encrypted   = true
}

# S3 Static Site for Frontend Hosting
module "s3_static_site" {
  source = "./modules/s3_static_site"

  project_name      = var.project_name
  bucket_name       = "${var.project_name}-frontend-static"
  enable_versioning = false
  enable_encryption = true
}

# CloudFront CDN for Frontend Distribution
module "cloudfront_distribution" {
  source = "./modules/cloudfront_distribution"

  depends_on = [module.s3_static_site]

  project_name        = var.project_name
  origin_bucket       = module.s3_static_site.bucket_name
  default_root_object = "index.html"
  enabled             = true
  acm_certificate_arn = null # Set this for custom domain
}

# ECS Fargate for Backend API
module "ecs_api_task" {
  source = "./modules/ecs_api_task"

  project_name    = var.project_name
  vpc_id          = module.vpc_core.vpc_id
  subnets         = module.vpc_core.private_subnets
  security_groups = [module.vpc_core.default_sg_id]

  desired_count = 1
  cpu           = 256 # Start small, scale as needed
  memory        = 512

  # Default to nginx, replace with your backend image
  container_image = "public.ecr.aws/nginx/nginx:latest"
  container_port  = 80

  task_execution_role_ssm_path = "/${var.project_name}/ecs_taskexec_role_arn"
  task_role_ssm_path           = "/${var.project_name}/ecs_task_role_arn"

  environment_variables = {
    NODE_ENV          = "production"
    DB_HOST           = module.rds_postgres.endpoint
    DB_NAME           = module.rds_postgres.database_name
    COGNITO_USER_POOL = module.cognito_auth.user_pool_id
    COGNITO_CLIENT_ID = module.cognito_auth.user_pool_client_id
  }
}

# Amazon Cognito for User Authentication
module "cognito_auth" {
  source = "./modules/cognito_auth"

  project_name                 = var.project_name
  user_pool_name               = "${var.project_name}-users"
  domain_prefix                = "${var.project_name}-auth"
  callback_urls                = ["https://${module.cloudfront_distribution.distribution_domain_name}/callback"]
  logout_urls                  = ["https://${module.cloudfront_distribution.distribution_domain_name}/logout"]
  supported_identity_providers = ["COGNITO"]
}

# CodePipeline for CI/CD
module "codepipeline_ci" {
  source = "./modules/codepipeline_ci"

  depends_on = [module.ssm_secrets, module.s3_static_site, module.ecs_api_task]

  project_name                = var.project_name
  github_owner                = "ChiefJ96" # Update with your GitHub username
  github_repo                 = "EdutechAI-Inc"
  github_branch               = "main"
  github_oauth_token_ssm_path = "/${var.project_name}/github_oauth_token"

  s3_bucket_name          = module.s3_static_site.bucket_name
  ecs_cluster_name        = module.ecs_api_task.cluster_name
  ecs_service_name        = module.ecs_api_task.service_name
  ecs_task_definition_arn = module.ecs_api_task.task_definition_arn
  codebuild_project_name  = "${var.project_name}-build"
}

# CloudWatch Monitoring and Alerts
module "cloudwatch_alerts" {
  source = "./modules/cloudwatch_alerts"

  project_name   = var.project_name
  alarm_email    = "alerts@edutechai.com" # Update with your email
  sns_topic_name = "${var.project_name}-alerts"
}
