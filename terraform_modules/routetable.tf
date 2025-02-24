// I associate the Public Route Table to the Internet Gateway.
// I associate the Private Route Table to the NAT Gateway.

#####################################
# Public Route Table (for Public Subnet)
#####################################
resource "aws_route_table" "PublicRouteTable" {
  vpc_id = aws_vpc.kubernetesVPC.id
  tags = {
    Name = "Public Route Table"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW_TF.id
  }
}

resource "aws_route_table_association" "PublicRouteTableAssociate" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.PublicRouteTable.id
}

#####################################
# Private Route Table (for Private Subnet)
#####################################
resource "aws_route_table" "PrivateRouteTable" {
  vpc_id = aws_vpc.kubernetesVPC.id
  tags = {
    Name = "Private Route Table"
  }
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "PrivateRouteTableAssociate" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.PrivateRouteTable.id
}






// BELOW IS THE OLD ROUTE TABLE CONFIGURATION //

# resource "aws_route_table" "PublicRouteTable" {
#   vpc_id = aws_vpc.kubernetesVPC.id
#   tags = {
#     Name = "PublicRouteTable"
#   }

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.IGW_TF.id
#   }
# }

# resource "aws_route_table_association" "PublicRouteTableAssociate" {
#   subnet_id      = aws_subnet.public_subnet.id
#   route_table_id = aws_route_table.PublicRouteTable.id
# }


# resource "aws_route_table" "PrivateRouteTable" {
#   vpc_id = aws_vpc.kubernetesVPC.id
#   tags   = {
#     Name = "PrivateRouteTable"
#   }

#   route {
#     cidr_block      = "0.0.0.0/0"
#     nat_gateway_id  = aws_nat_gateway.nat.id
#   }
# }

# resource "aws_route_table_association" "PrivateRouteTableAssociate" {
#   subnet_id      = aws_subnet.private_subnet.id
#   route_table_id = aws_route_table.PrivateRouteTable.id
# }
