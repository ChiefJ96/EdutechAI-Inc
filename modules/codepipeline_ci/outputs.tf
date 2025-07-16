output "pipeline_name" {
  description = "CodePipeline name"
  value       = aws_codepipeline.main.name
}

output "pipeline_arn" {
  description = "CodePipeline ARN"
  value       = aws_codepipeline.main.arn
}

output "artifacts_bucket_name" {
  description = "S3 artifacts bucket name"
  value       = aws_s3_bucket.artifacts.bucket
}

output "codebuild_frontend_project_name" {
  description = "CodeBuild frontend project name"
  value       = aws_codebuild_project.frontend.name
}

output "codebuild_backend_project_name" {
  description = "CodeBuild backend project name"
  value       = aws_codebuild_project.backend.name
}
