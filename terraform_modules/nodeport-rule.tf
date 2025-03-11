resource "aws_vpc_security_group_ingress_rule" "allow_nodeport_from_haproxy" {
  security_group_id            = aws_security_group.kubernetes_sg.id
  referenced_security_group_id = aws_security_group.haproxy_sg.id
  from_port                    = 30000
  to_port                      = 32767
  ip_protocol                  = "tcp"
  description                  = "Allow NodePort range access from HAProxy"
}

# allows traffic from the HAProxy server to reach any NodePort (ports 30000-32767) on Kubernetes nodes. 
# This is important because it permits HAProxy to forward requests to the Istio Gateway's NodePort service, which can be accessed
# through any node in the cluster.