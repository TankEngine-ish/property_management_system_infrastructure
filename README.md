# property_management_system_infrastructure
Infrastructure repo for provisioning and configuring a Kubernetes cluster on AWS using Terraform and Ansible. 

Unlike S3, you don’t create EC2 instances manually if they’re defined in your Terraform configuration. Terraform will automatically create them when you run terraform apply.

Overall:
Terraform intends to create 19 resources. No changes or deletions of existing resources are planned.

Resources to Be Created:

VPC (aws_vpc.kubernetesVPC)
Internet Gateway (aws_internet_gateway.IGW_TF)
Public Subnet (aws_subnet.public_subnet)
Route Table (aws_route_table.PublicRouteTable) and its association (aws_route_table_association.PublicRouteTableAssociate)
Security Group (aws_security_group.kubernetes_sg) plus the individual rule resources:
Egress rule: aws_vpc_security_group_egress_rule.allow_all_egress
Ingress rules for SSH (port 22), Kubernetes API (6443), etcd (2379–2380), Kubelet (10250–10252), NodePort range (30000–32767), HTTP (8080), custom port (6109), ICMP.
EC2 Instances (aws_instance.master_node and aws_instance.worker_node) with attached root volumes of 10 GB each, launched in the public subnet.
Elastic IPs (aws_eip.master_eip and aws_eip.worker_eip) for each instance.