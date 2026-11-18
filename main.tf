terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ------------------------------------------------------------------------------
# 1. Data Sources (Default VPC & Latest Amazon Linux 2023 AMI)
# ------------------------------------------------------------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# ------------------------------------------------------------------------------
# 2. Security Groups (EC2 & RDS)
# ------------------------------------------------------------------------------
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-app-sg"
  description = "Allow SSH and HTTP inbound traffic to EC2"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict to your IP in production
  }

  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-db-sg"
  description = "Allow database access only from EC2 Security Group"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "PostgreSQL from EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ------------------------------------------------------------------------------
# 3. EC2 Instance (with Security Group Attached)
# ------------------------------------------------------------------------------
resource "aws_instance" "web" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name = "app-server"
  }
}

# ------------------------------------------------------------------------------
# 4. S3 Bucket (Globally Unique Name + Block Public Access)
# ------------------------------------------------------------------------------
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "app_bucket" {
  bucket        = "my-app-storage-${random_id.bucket_suffix.hex}"
  force_destroy = true # Allows terraform destroy even if bucket has objects
}

resource "aws_s3_bucket_public_access_block" "app_bucket_access" {
  bucket = aws_s3_bucket.app_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------
# 5. RDS Instance (PostgreSQL)
# ------------------------------------------------------------------------------
resource "aws_db_instance" "database" {
  identifier             = "app-postgres-db"
  engine                 = "postgres"
  engine_version         = "16.3"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "appdb"
  username               = "dbadmin"
  password               = "ChangeMe12345!" # Use AWS Secrets Manager or variables in prod
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
}

# ------------------------------------------------------------------------------
# 6. Outputs
# ------------------------------------------------------------------------------
output "ec2_public_ip" {
  value = aws_instance.web.public_ip
}

output "s3_bucket_name" {
  value = aws_s3_bucket.app_bucket.bucket
}

output "rds_endpoint" {
  value = aws_db_instance.database.endpoint
}
