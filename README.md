# EdutechAI E-Learning Platform Infrastructure

A secure, scalable, and cost-effective AWS infrastructure built with Terraform to support a modern AI-powered e-learning platform.

## 🏗️ Architecture Overview

This infrastructure provides:

- **Frontend Hosting**: S3 + CloudFront for React-based frontend
- **Backend API**: ECS Fargate with Application Load Balancer
- **Authentication**: Amazon Cognito for user management
- **Database**: RDS PostgreSQL with encryption
- **CI/CD**: CodePipeline with GitHub integration
- **Monitoring**: CloudWatch dashboards and alerts
- **Security**: KMS encryption, VPC isolation, IAM roles

## 💰 Cost Estimation

- **Development Environment**: $40-70/month
- **Production Environment**: $400-800/month (with scaling)

## 🚀 Quick Start

### Prerequisites

1. AWS CLI configured with appropriate permissions
2. Terraform >= 1.0 installed
3. GitHub repository with your application code

### Deployment Steps

1. **Clone this repository**
   ```bash
   git clone <repository-url>
   cd EdutechAI-Inc
   ```

2. **Configure variables** (optional)
   ```bash
   # Edit terraform.tfvars
   aws_region = "us-east-1"
   project_name = "edutechai"
   ```

3. **Initialize and deploy**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Set up GitHub integration**
   ```bash
   # Add your GitHub OAuth token to SSM Parameter Store
   aws ssm put-parameter \
     --name "/edutechai/github_oauth_token" \
     --value "your-github-token" \
     --type "SecureString"
   ```

5. **Deploy your application**
   - Frontend: Upload React build to the S3 bucket
   - Backend: Push code to trigger CodePipeline

## 📁 Module Structure

```
modules/
├── cloudfront_distribution/   # CDN for frontend
├── cloudwatch_alerts/        # Monitoring and alerting
├── codepipeline_ci/         # CI/CD pipeline
├── cognito_auth/            # User authentication
├── ecs_api_task/            # Backend API containers
├── rds_postgres/            # Database
├── s3_static_site/          # Frontend hosting
├── ssm_secrets/             # Secrets management
└── vpc/                     # Networking
```

## 🔧 Configuration

### Environment Variables

Your backend containers will have access to:

- `DB_HOST`: RDS endpoint
- `DB_NAME`: Database name
- `COGNITO_USER_POOL_ID`: Cognito User Pool ID
- `COGNITO_CLIENT_ID`: Cognito Client ID

### Build Specifications

Create these files in your repository root:

#### `buildspec-frontend.yml`
```yaml
version: 0.2
phases:
  install:
    runtime-versions:
      nodejs: 18
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - npm install
  build:
    commands:
      - echo Build started on `date`
      - npm run build
  post_build:
    commands:
      - echo Build completed on `date`
artifacts:
  files:
    - '**/*'
  base-directory: 'build'
```

#### `buildspec-backend.yml`
```yaml
version: 0.2
phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
  build:
    commands:
      - echo Build started on `date`
      - echo Building the Docker image...
      - docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .
      - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker image...
      - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
      - echo Writing image definitions file...
      - printf '[{"name":"edutechai-container","imageUri":"%s"}]' $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG > imagedefinitions.json
artifacts:
  files: imagedefinitions.json
```

## 🔐 Security Features

- **Encryption at Rest**: All storage encrypted with KMS
- **Network Security**: Private subnets for databases and containers
- **Access Control**: IAM roles with least privilege
- **Public Access**: Blocked on S3 buckets (CloudFront only)
- **HTTPS**: Enforced on all public endpoints

## 📊 Monitoring

After deployment, access your monitoring dashboard:
- CloudWatch Dashboard: Available in Terraform outputs
- SNS Alerts: Configured for high CPU, memory, and error rates
- Log Aggregation: Centralized in CloudWatch Logs

## 🔧 Customization

### Scaling Configuration

To modify capacity:

```hcl
# In main.tf
module "ecs_api_task" {
  # ...
  desired_count = 3  # Increase for more containers
  cpu           = 512  # Increase for more CPU
  memory        = 1024  # Increase for more memory
}
```

### Adding Custom Domains

1. Request ACM certificate for your domain
2. Update CloudFront configuration:

```hcl
module "cloudfront_distribution" {
  # ...
  acm_certificate_arn = "arn:aws:acm:us-east-1:account:certificate/..."
}
```

## 🆘 Troubleshooting

### Common Issues

1. **ECS Tasks Not Starting**
   - Check container image exists and is accessible
   - Verify security group rules allow ALB → ECS communication

2. **Database Connection Issues**
   - Ensure RDS security group allows connections from ECS
   - Verify database credentials in SSM Parameter Store

3. **CI/CD Pipeline Failures**
   - Check GitHub OAuth token is valid
   - Verify buildspec files exist in repository

### Getting Help

1. Check CloudWatch Logs for application errors
2. Review CloudTrail for API call issues
3. Use Systems Manager Session Manager for secure instance access

## 🏁 Next Steps

1. **Set up Route 53** for custom domains
2. **Configure AWS WAF** for additional security
3. **Add Auto Scaling** policies for ECS services
4. **Implement Blue/Green deployments** with CodeDeploy
5. **Add SageMaker** for AI model inference
6. **Configure AWS X-Ray** for distributed tracing

## 📚 Additional Resources

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)

---

**Built with ❤️ for EdutechAI Inc.**
