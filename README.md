
# Terraform EC2 Setup with AWS

This repository provides a guide to setting up a simple EC2 instance on AWS using Terraform. The provided `main.tf` script configures a Virtual Private Cloud (VPC), Internet Gateway, Subnet, Route Table, Security Group, and an EC2 instance.

## Prerequisites

Ensure you have the following installed on your machine:
- **Git**: Version control system to clone repositories.
- **Terraform**: Infrastructure as Code (IaC) tool to manage AWS resources.
- **AWS CLI**: Command-line tool to interact with AWS services.

## Installation Guide

Follow the steps below to install the necessary tools and set up the environment:

1. **Update System Packages**:
   ```bash
   sudo apt-get update
   sudo apt-get upgrade
   ```

2. **Install Git**:
   ```bash
   sudo apt install git
   ```

3. **Install Terraform using tfenv**:
   ```bash
   git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv
   echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bash_profile
   source ~/.bash_profile
   tfenv install 1.9.5
   tfenv use 1.9.5
   ```

4. **Install AWS CLI**:
   ```bash
   sudo apt-get install awscli -y
   aws configure
   ```

## Terraform Setup

1. **Clone the Repository**:
   ```bash
   git clone <repository-url>
   cd <repository-directory>
   ```

2. **Create a Terraform Directory**:
   ```bash
   mkdir terraform-ec2
   cd terraform-ec2
   ```

3. **Create the Terraform Configuration File**:
   - Create a `main.tf` file with the content provided below.

4. **Initialize Terraform**:
   ```bash
   terraform init
   ```

5. **Plan and Apply the Terraform Configuration**:
   ```bash
   terraform plan
   terraform apply
   ```

6. **Verify the Setup**:
   - Check the Terraform output for the `instance_id` and `public_ip`.
   - Verify the EC2 instance in the AWS Management Console.

7. **Destroy Resources** (When you no longer need them):
   ```bash
   terraform destroy
   ```

## `main.tf` Configuration

Here's the configuration used to set up the AWS infrastructure, with detailed explanations provided as comments:

```hcl
# Specify the AWS provider, which tells Terraform to interact with AWS resources.
provider "aws" {
  # The AWS region where the resources will be created. Change this to your preferred region.
  region  = "us-east-1"
}

# Create a Virtual Private Cloud (VPC) to logically isolate resources within AWS.
resource "aws_vpc" "main_vpc" {
  # The CIDR block specifies the IP range for the VPC.
  cidr_block = "10.0.0.0/16"

  # Tagging helps identify and organize AWS resources. 
  tags = {
    Name = "MainVPC"
  }
}

# Create an Internet Gateway to allow communication between the VPC and the internet.
resource "aws_internet_gateway" "main_igw" {
  # The VPC ID this Internet Gateway is associated with.
  vpc_id = aws_vpc.main_vpc.id

  # Tagging the Internet Gateway for easy identification.
  tags = {
    Name = "MainInternetGateway"
  }
}

# Create a Subnet, which is a range of IP addresses in your VPC where you can launch resources.
resource "aws_subnet" "main_subnet" {
  # The VPC in which this subnet will be created.
  vpc_id                  = aws_vpc.main_vpc.id

  # The CIDR block for this subnet, a smaller range of IP addresses within the VPC's CIDR block.
  cidr_block              = "10.0.1.0/24"

  # This setting automatically assigns a public IP to instances launched in this subnet.
  map_public_ip_on_launch = true

  # Tagging the Subnet.
  tags = {
    Name = "MainSubnet"
  }
}

# Create a Route Table that directs network traffic from the subnet to the Internet Gateway.
resource "aws_route_table" "main_route_table" {
  # The VPC this Route Table is associated with.
  vpc_id = aws_vpc.main_vpc.id

  # Define a route that directs all outbound traffic (0.0.0.0/0) to the Internet Gateway.
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  # Tagging the Route Table.
  tags = {
    Name = "MainRouteTable"
  }
}

# Associate the Route Table with the Subnet, ensuring that the subnet uses this Route Table.
resource "aws_route_table_association" "main_route_table_assoc" {
  # The Subnet ID that will use this Route Table.
  subnet_id      = aws_subnet.main_subnet.id

  # The ID of the Route Table to associate with the Subnet.
  route_table_id = aws_route_table.main_route_table.id
}

# Create a Security Group to control the inbound and outbound traffic for the EC2 instances.
resource "aws_security_group" "allow_all" {
  # The VPC where this Security Group will be created.
  vpc_id = aws_vpc.main_vpc.id

  # Define an Ingress rule to allow all inbound traffic (not recommended for production).
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # -1 means all protocols.
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic from any IP.
  }

  # Define an Egress rule to allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # -1 means all protocols.
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic to any IP.
  }

  # Tagging the Security Group.
  tags = {
    Name = "AllowAllTraffic"
  }
}

# Create an EC2 instance, which is a virtual server in AWS.
resource "aws_instance" "example" {
  # The AMI ID is a template for the instance, containing the OS and applications.
  ami           = "ami-066784287e358dad1"  # Example AMI ID (Amazon Linux 2 in us-east-1)

  # The instance type defines the hardware configuration (e.g., CPU, memory).
  instance_type = "t2.micro"

  # Specify the Subnet where the instance will be launched.
  subnet_id = aws_subnet.main_subnet.id

  # Tag the EC2 instance for identification.
  tags = {
    Name = "Terraform-EC2"
  }

  # The name of the key pair used for SSH access to the instance (replace with your key pair name).
  key_name = "keypair"

  # Configure the EBS volume (block storage) attached to the instance.
  root_block_device {
    volume_size = 8  # 8 GB root volume.
    volume_type = "gp2"  # General Purpose SSD.
  }
}

# Output the instance ID of the created EC2 instance.
output "instance_id" {
  value = aws_instance.example.id
}

# Output the public IP address of the created EC2 instance.
output "public_ip" {
  value = aws_instance.example.public_ip
}

# Output the Subnet ID where the EC2 instance is running.
output "subnet_id" {
  value = aws_subnet.main_subnet.id
}
```

## Additional Notes

- Replace `"keypair"` in the EC2 instance configuration with your actual key pair name to enable SSH access to your instance.
- The `TF_LOG=DEBUG terraform apply` command can be used to debug any issues during the `apply` phase.
- For detailed documentation on Terraform, refer to the [Terraform official documentation](https://www.terraform.io/docs).

---

This `README.md` now includes detailed comments in the `main.tf` file to help explain the purpose of each resource and setting within the Terraform configuration. This should make it easier for users to understand how the setup works and customize it according to their needs.