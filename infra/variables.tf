variable "aws_region" {
  default = "us-east-1"
}

variable "ec2_key_name" {
  description = "EC2 SSH key pair name"
  type        = string
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "appuser"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "allowed_ssh_cidr" {
  description = "MY IP to allow SSH access"
}

variable "s3_bucket_name" {
  description = "S3 bucket name"
  type        = string
}