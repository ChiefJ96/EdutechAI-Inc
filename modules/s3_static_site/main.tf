// modules/s3_static_site/main.tf
variable "project_name" { type = string }
variable "bucket_name" { type = string }
variable "enable_versioning" {
  type    = bool
  default = false
}
variable "enable_encryption" {
  type    = bool
  default = true
}

resource "aws_s3_bucket" "site" {
  bucket = var.bucket_name

  tags = {
    Name = var.project_name
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.site.bucket
}

resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}