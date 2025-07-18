variable "project_name" { type = string }
variable "cidr_block" { type = string }
variable "public_subnets" { type = list(string) }
variable "private_subnets" { type = list(string) }
variable "enable_nat_gateway" {
  type    = bool
  default = false
}
