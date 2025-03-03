# security group for HAProxy in the Public Subnet
resource "aws_security_group" "haproxy_sg" {
  name        = "haproxy-sg"
  vpc_id      = aws_vpc.kubernetesVPC.id
  description = "Security group for the HAProxy instance in the public subnet"

  tags = {
    Name = "haproxy_sg"
  }
}

# HTTP traffic to HAProxy
resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.haproxy_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Allow HTTP access"
}

# HTTPS traffic to HAProxy
resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.haproxy_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Allow HTTPS access"
}

# SSH access 
resource "aws_vpc_security_group_ingress_rule" "allow_ssh_vpn" {
  security_group_id = aws_security_group.haproxy_sg.id
  cidr_ipv4         = "185.240.147.99/32" 
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "Allow SSH access for VPN server"
}

resource "aws_vpc_security_group_egress_rule" "haproxy_allow_all_egress" {
  security_group_id = aws_security_group.haproxy_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"  # -1 means all protocols (i.e., all ports)
  description       = "Allow all outbound traffic from HAProxy"
}

resource "aws_vpc_security_group_ingress_rule" "allow_k8s_api_access" {
  security_group_id = aws_security_group.haproxy_sg.id
  cidr_ipv4         = "0.0.0.0/0"  
  from_port         = 6443
  to_port           = 6443
  ip_protocol       = "tcp"
  description       = "Allow external access to Kubernetes API through HAProxy"
}




































































# # New security group for HAProxy and OpenVPN (public)
# resource "aws_security_group" "haproxy_openvpn_sg" {
#   name        = "haproxy-openvpn-sg"
#   vpc_id      = aws_vpc.kubernetesVPC.id
#   description = "Security group for HAProxy & OpenVPN in the public subnet"
#   tags = {
#     Name = "haproxy_openvpn_sg"
#   }
# }

# # Example ingress rules for HAProxy/OpenVPN SG
# resource "aws_vpc_security_group_ingress_rule" "allow_http" {
#   security_group_id = aws_security_group.haproxy_openvpn_sg.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = 80
#   to_port           = 80
#   ip_protocol       = "tcp"
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_https" {
#   security_group_id = aws_security_group.haproxy_openvpn_sg.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = 443
#   to_port           = 443
#   ip_protocol       = "tcp"
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_openvpn" {
#   security_group_id = aws_security_group.haproxy_openvpn_sg.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = 1194
#   to_port           = 1194
#   ip_protocol       = "udp"
# }