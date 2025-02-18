resource "aws_security_group" "kubernetes_sg" {
  name        = "kubernetes-SG"
  vpc_id      = aws_vpc.kubernetesVPC.id
  description = "Base security group for Kubernetes nodes"

  tags = {
    Name = "kubernetes_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.kubernetes_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_k8s_api" {
  security_group_id = aws_security_group.kubernetes_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 6443
  to_port           = 6443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_etcd" {
  security_group_id = aws_security_group.kubernetes_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 2379
  to_port           = 2380
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_kubelet" {
  security_group_id = aws_security_group.kubernetes_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 10250
  to_port           = 10252
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_nodeport" {
  security_group_id = aws_security_group.kubernetes_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 30000
  to_port           = 32767
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.kubernetes_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_custom_port" {
  security_group_id = aws_security_group.kubernetes_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 6109
  to_port           = 6109
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_icmp" {
  security_group_id = aws_security_group.kubernetes_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = -1
  to_port           = -1
  ip_protocol       = "icmp"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_egress" {
  security_group_id = aws_security_group.kubernetes_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"  # -1 means all protocols (i.e., all ports)
}
