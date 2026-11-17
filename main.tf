provider "aws" {
  region = "us-east-1"
}

# Create EC2 Instance
resource "aws_instance" "my_ec2" {
  ami           = "ami-0de716d6197524dd9" # Amazon Linux 2 in us-east-1
  instance_type = "t2.micro"
  ##key_name      = aws_key_pair.my_key.key_name
#security_groups = [aws_security_group.allow_ssh.name]

  tags = {
    Name = "MyTerraformnewEC2"
  }
}
