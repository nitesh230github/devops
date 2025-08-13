provider "aws" {
  region = "us-east-1"
}

# Create Security Group
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
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

# Create EC2 Instance
resource "aws_instance" "my_ec2" {
  ami           = "ami-0de716d6197524dd9" # Amazon Linux 2 in us-east-1
  instance_type = "t2.micro"
  ##key_name      = aws_key_pair.my_key.key_name
  security_groups = [aws_security_group.allow_ssh.name]

  tags = {
    Name = "MyTerraformEC2"
  }
}
