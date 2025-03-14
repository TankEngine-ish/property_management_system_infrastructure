resource "aws_security_group" "kubernetes_sg" {
  name        = "kubernetes-SG"
  vpc_id      = aws_vpc.kubernetesVPC.id
  description = "Security group for Kubernetes master and worker nodes (private subnet only)"

  tags = {
    Name = "kubernetes_sg"
  }
}

# HAProxy talking with the Kubernetes API (6443)
resource "aws_vpc_security_group_ingress_rule" "allow_haproxy_to_k8s_api" {
  security_group_id            = aws_security_group.kubernetes_sg.id
  referenced_security_group_id = aws_security_group.haproxy_sg.id // this property allows me to specify another security group as the allowed source of traffic instead of using a CIDR range
  from_port                    = 6443
  to_port                      = 6443
  ip_protocol                  = "tcp"
  description                  = "Allow HAProxy to communicate with Kubernetes API"
}

# Kubernetes internal communication (Nodes & etcd)
resource "aws_vpc_security_group_ingress_rule" "allow_internal_k8s" {
  security_group_id = aws_security_group.kubernetes_sg.id
  cidr_ipv4         = "10.0.1.0/24" # Private subnet
  ip_protocol       = "-1"  # Allow all protocols (TCP, UDP, ICMP)
  description       = "Allow internal Kubernetes communication between nodes"
}

# ICMP (ping) only within the private subnet
resource "aws_vpc_security_group_ingress_rule" "allow_icmp_private" {
  security_group_id = aws_security_group.kubernetes_sg.id
  cidr_ipv4         = "10.0.1.0/24"
  from_port         = -1
  to_port           = -1
  ip_protocol       = "icmp"
  description       = "Allow ping within the private subnet"
}

# all outbound traffic open (for updates, package installs, etc.)
resource "aws_vpc_security_group_egress_rule" "allow_all_egress" {
  security_group_id = aws_security_group.kubernetes_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic"
}

# SSH access from HAProxy to Kubernetes nodes
resource "aws_vpc_security_group_ingress_rule" "allow_ssh_from_haproxy" {
  security_group_id            = aws_security_group.kubernetes_sg.id
  referenced_security_group_id = aws_security_group.haproxy_sg.id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  description                  = "Allow SSH access from HAProxy"
}

# Allow Istio webhook traffic. VERY IMPORTANT AS THIS FIXED THE ISSUE OF THE WEBHOOK NOT BEING ABLE TO COMMUNICATE WITH THE KUBERNETES API
resource "aws_vpc_security_group_ingress_rule" "allow_istio_webhook" {
  security_group_id = aws_security_group.kubernetes_sg.id
  cidr_ipv4         = "0.0.0.0/0"  # Temporarily open to diagnose
  from_port         = 15017
  to_port           = 15017
  ip_protocol       = "tcp"
  description       = "Allow Istio webhook traffic"
}











































# resource "aws_security_group" "kubernetes_sg" {
#   name        = "kubernetes-SG"
#   vpc_id      = aws_vpc.kubernetesVPC.id
#   description = "Base security group for Kubernetes nodes"

#   tags = {
#     Name = "kubernetes_sg"
#   }
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
#   security_group_id = aws_security_group.kubernetes_sg.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = 22
#   to_port           = 22
#   ip_protocol       = "tcp"
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_k8s_api" {
#   security_group_id = aws_security_group.kubernetes_sg.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = 6443
#   to_port           = 6443
#   ip_protocol       = "tcp"
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_etcd" {
#   security_group_id = aws_security_group.kubernetes_sg.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = 2379
#   to_port           = 2380
#   ip_protocol       = "tcp"
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_kubelet" {
#   security_group_id = aws_security_group.kubernetes_sg.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = 10250
#   to_port           = 10252
#   ip_protocol       = "tcp"
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_nodeport" {
#   security_group_id = aws_security_group.kubernetes_sg.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = 30000
#   to_port           = 32767
#   ip_protocol       = "tcp"
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_http" {
#   security_group_id = aws_security_group.kubernetes_sg.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = 8080
#   to_port           = 8080
#   ip_protocol       = "tcp"
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_custom_port" {
#   security_group_id = aws_security_group.kubernetes_sg.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = 6109
#   to_port           = 6109
#   ip_protocol       = "tcp"
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_icmp" {
#   security_group_id = aws_security_group.kubernetes_sg.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = -1
#   to_port           = -1
#   ip_protocol       = "icmp"
# }

# resource "aws_vpc_security_group_egress_rule" "allow_all_egress" {
#   security_group_id = aws_security_group.kubernetes_sg.id
#   cidr_ipv4         = "0.0.0.0/0"
#   ip_protocol       = "-1"  # -1 means all protocols (i.e., all ports)
# }
