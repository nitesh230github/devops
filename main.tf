# Create Security Group for aws ec2
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    description = "SSH from restricted IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"] # 0.0.0.0/0 ki jagah restricted CIDR
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "allow_ssh"
    Environment = "dev"
    Owner       = "nitesh"
  }
}

# Create EC2 Instance
resource "aws_instance" "my_ec2" {
  ami                    = "ami-0de716d6197524dd9"
  instance_type          = "t3.micro" # t2.micro ki jagah cheaper & newer t3.micro
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  root_block_device {
    encrypted = true # Security policy ke liye EBS encryption
  }

  tags = {
    Name        = "MyTerraformEC2"
    Environment = "dev"
    Owner       = "nitesh"
  }
}
