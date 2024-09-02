# Configure the AWS provider
provider "aws" {
  region  = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "MainVPC"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "MainInternetGateway"
  }
}

# Create a Subnet
resource "aws_subnet" "main_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "MainSubnet"
  }
}

# Create a Route Table
resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "MainRouteTable"
  }
}

# Associate the Route Table with the Subnet
resource "aws_route_table_association" "main_route_table_assoc" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_route_table.id
}

# Create a Security Group that allows all inbound and outbound traffic
resource "aws_security_group" "allow_all" {
  vpc_id = aws_vpc.main_vpc.id

  # Ingress rule to allow all inbound traffic
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rule to allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "AllowAllTraffic"
  }
}

# Create an EC2 instance
resource "aws_instance" "example" {
  ami           = "ami-066784287e358dad1"  # Example AMI ID (Amazon Linux 2 in us-east-1)
  instance_type = "t2.micro"

  # Use the Security Group created above
  # security_groups = [aws_security_group.allow_all.name]

  # Attach the instance to the Subnet
  subnet_id = aws_subnet.main_subnet.id

  # Create a tag for the instance
  tags = {
    Name = "Terraform-EC2"
  }

  # Key pair for SSH access (replace with your key pair name)
  key_name = "keypair"

  # EBS volume for the instance
  root_block_device {
    volume_size = 8  # 8 GB root volume
    volume_type = "gp2"
  }
}

# Outputs
output "instance_id" {
  value = aws_instance.example.id
}

output "public_ip" {
  value = aws_instance.example.public_ip
}

output "subnet_id" {
  value = aws_subnet.main_subnet.id
}
