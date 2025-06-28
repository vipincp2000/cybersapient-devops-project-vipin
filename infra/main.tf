provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "app_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "app_igw" {
  vpc_id = aws_vpc.app_vpc.id
}

resource "aws_subnet" "app_public_subnet" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "app_public_rt" {
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_igw.id
  }
}

resource "aws_route_table_association" "app_public_assoc" {
  subnet_id      = aws_subnet.app_public_subnet.id
  route_table_id = aws_route_table.app_public_rt.id
}

resource "aws_security_group" "app_ec2_sg" {
  name   = "app-ec2-sg"
  vpc_id = aws_vpc.app_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app_rds_sg" {
  name   = "app-rds-sg"
  vpc_id = aws_vpc.app_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "app_ec2_role" {
  name = "app-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "app_secrets_policy" {
  name = "app-SecretsAccessPolicy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "app_attach" {
  role       = aws_iam_role.app_ec2_role.name
  policy_arn = aws_iam_policy.app_secrets_policy.arn
}

resource "aws_iam_instance_profile" "app_ec2_profile" {
  name = "app-ec2-instance-profile"
  role = aws_iam_role.app_ec2_role.name
}


resource "aws_instance" "app_server" {
  ami                         = aws_ami.ubuntu.id
  instance_type               = "t3.medium"
  key_name                    = var.ec2_key_name
  subnet_id                   = aws_subnet.app_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.app_ec2_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.app_ec2_profile.name

  user_data = file("${path.module}/install.sh")

  tags = {
    Name = "prod-app-server"
  }
}

resource "aws_db_subnet_group" "app_db_subnet_group" {
  name       = "app-db-subnet-group"
  subnet_ids = [aws_subnet.app_public_subnet.id]
}

resource "aws_db_instance" "app_postgres" {
  allocated_storage       = 20
  engine                  = "postgres"
  engine_version          = "15.2"
  instance_class          = "db.t3.medium"
  name                    = "appdb"
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.app_db_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.app_rds_sg.id]
  skip_final_snapshot     = true
  publicly_accessible     = false
}

resource "aws_s3_bucket" "app_bucket" {
  bucket = var.s3_bucket_name
  acl    = "private"

  versioning {
    enabled = true
  }
}

resource "aws_secretsmanager_secret" "app_secrets" {
  name = "prod/app-secrets"
}

resource "aws_secretsmanager_secret_version" "app_secrets_version" {
  secret_id     = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    DB_USERNAME = var.db_username,
    DB_PASSWORD = var.db_password
  })
}
