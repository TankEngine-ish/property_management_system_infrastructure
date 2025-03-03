// I am fetching all available AZs in the region, selecting the first for the public subnet and the second for the private subnet.
// The private subnet uses the NAT Gateway for internet access. It will hold the EC2 instance with my k8s deployment.
// The public subnet will hold the ELB for the k8s API server. In my case it's HAProxy.
// The AZs are determined dynamically via the aws_availability_zones data source.

#####################################
# Data source: Get Availability Zones
#####################################
data "aws_availability_zones" "available" {
  state = "available"
}


# Define the VPC
resource "aws_vpc" "kubernetesVPC" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "Kubernetes VPC"
  }
}

# Define the Internet Gateway
resource "aws_internet_gateway" "IGW_TF" {
  vpc_id = aws_vpc.kubernetesVPC.id
  tags = {
    Name = "IGW_TF"
  }
}


# Public Subnet (for HAProxy / NAT Gateway)
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.kubernetesVPC.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "Public Subnet"
  }
}


# Private Subnet (for the Kubernetes Nodes)
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.kubernetesVPC.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "Private Subnet"
  }
}


# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "NAT-EIP"
  }
}


# NAT Gateway in Public Subnet
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  tags = {
    Name = "NAT-Gateway"
  }
}



// BELOW IS AN OLD CONFIGURATION OF JUST ONE PUBLIC SUBNET //

# resource "aws_vpc" "kubernetesVPC" {
#   cidr_block = "10.0.0.0/16"
#   instance_tenancy = "default" 
#   enable_dns_support = "true" 
#   enable_dns_hostnames = "true"
#   tags = { 
#     Name = "Kubernetes VPC" 
#   } 
#  }

# resource "aws_internet_gateway" "IGW_TF" { 
#   vpc_id = aws_vpc.kubernetesVPC.id
#   tags = { 
#     Name = "IGW_TF" 
#   }
# }

# resource "aws_subnet" "public_subnet" {
#   cidr_block = "10.0.0.0/24" 
#   map_public_ip_on_launch = "true" 
#   vpc_id = aws_vpc.kubernetesVPC.id
#   tags = { 
#     Name = "demo_public_subnet" 
#   }
# }
