
variable "project_name" { type = string }
variable "vpc_id" { type = string }
variable "private_subnets" { type = list(string) }
variable "db_name" { type = string }
variable "db_username" { type = string }
variable "db_password_ssm" { type = string }
variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}
variable "allocated_storage" {
  type    = number
  default = 20
}
variable "multi_az" {
  type    = bool
  default = false
}
variable "publicly_accessible" {
  type    = bool
  default = false
}
variable "storage_encrypted" {
  type    = bool
  default = true
}

data "aws_ssm_parameter" "db_password" {
  name = var.db_password_ssm
}

resource "aws_db_subnet_group" "default" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnets

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {
  identifier           = "${var.project_name}-postgres"
  engine               = "postgres"
  engine_version       = "15.7"  # Updated to supported version
  instance_class       = var.instance_class
  db_name              = var.db_name
  username             = var.db_username
  password             = data.aws_ssm_parameter.db_password.value
  db_subnet_group_name = aws_db_subnet_group.default.name
  multi_az             = var.multi_az
  publicly_accessible  = var.publicly_accessible
  storage_encrypted    = var.storage_encrypted
  allocated_storage    = var.allocated_storage
  skip_final_snapshot  = true
  deletion_protection  = false
  apply_immediately    = true

  tags = {
    Name = "${var.project_name}-rds"
  }
}

output "endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "database_name" {
  value = aws_db_instance.postgres.db_name
}

output "port" {
  value = aws_db_instance.postgres.port
}