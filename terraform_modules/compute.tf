##################################################
# MASTER NODE (Private Subnet)
##################################################
resource "aws_instance" "master_node" {
  ami           = var.AMI
  instance_type = var.INSTANCETYPE
  key_name      = var.KEYPAIR

  root_block_device {
    volume_size = var.EC2Volume
    volume_type = "gp2" // gp2 is a General Purpose SSD (GP2) volume on AWS EBS (Elastic Block Store)
  }

  # Master in private subnet
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.kubernetes_sg.id]

  tags = {
    Name = "Master-Node"
  }
}

##################################################
# WORKER NODE (Private Subnet)
##################################################
resource "aws_instance" "worker_node" {
  ami           = var.AMI
  instance_type = var.INSTANCETYPE
  key_name      = var.KEYPAIR

  root_block_device {
    volume_size = var.EC2Volume
    volume_type = "gp2"
  }

  # Worker in private subnet
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.kubernetes_sg.id]

  tags = {
    Name = "Worker-Node"
  }
}

##################################################
# HAPROXY SERVER (Public Subnet)
##################################################
resource "aws_instance" "haproxy_server" {
  ami           = var.AMI
  instance_type = var.HAPROXY_INSTANCE_TYPE
  key_name      = var.KEYPAIR

  root_block_device {
    volume_size = 8
    volume_type = "gp2"
  }

  # HAProxy in public subnet (map_public_ip_on_launch = true)
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true // new change
  vpc_security_group_ids      = [aws_security_group.haproxy_openvpn_sg.id]

  tags = {
    Name = "HAProxy-Server"
  }
}





//BELOW IS THE OLD EC2 INSTANCE CONFIGURATION


# resource "aws_instance" "master_node" { 
#   ami           = var.AMI
#   instance_type = var.INSTANCETYPE
#   key_name      = var.KEYPAIR
#   root_block_device {
#     volume_size = var.EC2Volume 
#     volume_type = "gp2"
#   }
#   subnet_id = aws_subnet.public_subnet.id 
#   vpc_security_group_ids = [aws_security_group.kubernetes_sg.id]
#   tags = { 
#     Name = "Master-Node" 
#   } 
# }

# resource "aws_instance" "worker_node" { 
#   ami           = var.AMI
#   instance_type = var.INSTANCETYPE
#   key_name      = var.KEYPAIR
#   root_block_device {
#     volume_size = var.EC2Volume 
#     volume_type = "gp2"
#   }
#   vpc_security_group_ids = [aws_security_group.kubernetes_sg.id]
#   subnet_id = aws_subnet.public_subnet.id 
#   tags = { 
#     Name = "Worker-Node" 
#   }
# }

# resource "aws_eip" "master_eip" {
#   domain   = "vpc"
#   instance = aws_instance.master_node.id
# }

# resource "aws_eip" "worker_eip" {
#   domain   = "vpc"
#   instance = aws_instance.worker_node.id
# }



