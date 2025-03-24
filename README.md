# Project Overview 

**And now for the main course!**

This is my most comprehensive repostitory as it focuses entirely on the Continious Delivery/Deployment of my property app - https://github.com/TankEngine-ish/property_management_system_full_stack_app 

Let's dive in!

## Architecture Overview

I have implemented a secure, scalable infrastructure that (hopefully) follows the best practices of many areas including cloud, IaC and credential security. In a nutshell it's a Kubernetes infrastructure on AWS for hosting my application, provisioned with Terraform and configured with Ansible. It also includes:

- Kubernetes (kubeadm) cluster on AWS EC2 instances
- Network isolation with public/private subnets
- HAProxy load balancer for ingress traffic
- Istio service mesh for microservices communication
- ArgoCD for GitOps-style continuous delivery
- HashiCorp Vault for secrets management
- Helm charts for application deployment

Here's a diagram I made to illustrate all the trains of thought I had when making the project. 

![alt text](<assets/Data Flow Diagram (Copy) (2).jpg>)


## Creating & Configuring the Resources via Terraform

First and foremost I used Terraform to provision my AWS infrastructure and make my environment reproducible and version-controllable. This is a cornerstone of modern DevOps practices. On top of that, I used Ansible for configuring HAProxy on the public subnet and my two K8s nodes on the private subnet along with Jinja2 templates utilization (not just simple bash scripting). 

Via Terraform I've tried to implement a proper network isolation pattern with:

* a VPC (10.0.0.0/16) that serves as the container for all resources
* a public subnet (10.0.0.0/24) that hosts the HAProxy load balancer
* a private subnet (10.0.1.0/24) that hosts the Kubernetes nodes
* an Internet Gateway for public subnet internet access
* a NAT Gateway to allow private subnet resources to access the internet without being directly accessible
* also two separate route tables for public and private subnets

This design follows the AWS well-architected framework by placing public-facing components in the public subnet while keeping my critical infrastructure in the private subnet.

### Security Groups

My *Security Group Architecture* implements the principle of least privilege:
I've created two main security groups with carefully scoped permissions:

**HAProxy Security Group (haproxy_sg)**

This security group controls access to my HAProxy instance in the public subnet:

terraformCopyresource "aws_security_group" "haproxy_sg" {
  name        = "haproxy-sg"
  vpc_id      = aws_vpc.kubernetesVPC.id
  description = "Security group for the HAProxy instance in the public subnet"
}

Access rules for this group include:

- SSH (port 22) from a single specific IP (185.240.147.99/32) - not from anywhere on the internet
- Kubernetes API (port 6443) from anywhere - needed for remote kubectl access

This shows least privilege because:

I've limited SSH access to a single IP address and I've only opened the specific ports needed for the HAProxy to function. All other ports remain closed by default.

**Kubernetes Security Group (kubernetes_sg)**

* This security group protects your Kubernetes nodes in the private subnet:

terraformCopyresource "aws_security_group" "kubernetes_sg" {
  name        = "kubernetes-SG"
  vpc_id      = aws_vpc.kubernetesVPC.id
  description = "Security group for Kubernetes master and worker nodes (private subnet only)"
}

* Here, I've implemented RBAC or Reference-based access control: Instead of using CIDR blocks, I am using security group references:

terraformCopyresource "aws_vpc_security_group_ingress_rule" "allow_haproxy_to_k8s_api" {
  security_group_id            = aws_security_group.kubernetes_sg.id
  referenced_security_group_id = aws_security_group.haproxy_sg.id
  from_port                    = 6443
  to_port                      = 6443
  ip_protocol                  = "tcp"
  description                  = "Allow HAProxy to communicate with Kubernetes API"
}

The above block states that the Kubernetes API is only accessible from instances that belong to the HAProxy security group, not from any IP.

* Private subnet scoping: For internal Kubernetes communication, I've limited access to the private subnet CIDR:

terraformCopyresource "aws_vpc_security_group_ingress_rule" "allow_internal_k8s" {
  security_group_id = aws_security_group.kubernetes_sg.id
  cidr_ipv4         = "10.0.1.0/24" # Private subnet
  ip_protocol       = "-1"
  description       = "Allow internal Kubernetes communication between nodes"
}

* Bastion pattern for SSH: SSH access to Kubernetes nodes is only allowed from the HAProxy (functioning as a bastion host):

terraformCopyresource "aws_vpc_security_group_ingress_rule" "allow_ssh_from_haproxy" {
  security_group_id            = aws_security_group.kubernetes_sg.id
  referenced_security_group_id = aws_security_group.haproxy_sg.id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  description                  = "Allow SSH access from HAProxy"
}

At this stage I was really wondering if I should use something like OpenVPN or even an actual bastion host (one of my other laptops at home) so I kept thinking about it and finally remembered that HAProxy could very well do the trick without much overhead.

* NodePort access control: NodePorts are only accessible from the HAProxy, not directly from the internet:

terraformCopyresource "aws_vpc_security_group_ingress_rule" "allow_nodeport_from_haproxy" {
  security_group_id            = aws_security_group.kubernetes_sg.id
  referenced_security_group_id = aws_security_group.haproxy_sg.id
  from_port                    = 30000
  to_port                      = 32767
  ip_protocol                  = "tcp"
  description                  = "Allow NodePort range access from HAProxy"
}

The reason behind the usage of NodePort was that HAProxy couldn't connect to the Istio Gateway due to security group configurations. But even prior to that the root cause of all this was that whenever I wanted to visit my application via an IP URL I had to forward two different ports - one for the backend and one for the frontend. I could've just as easily use nginx for that matter but I'm always up for a challenge. So I modified the HAProxy template in Ansible:

**Application Frontend**
frontend app-frontend
    bind *:80
    mode http
    default_backend istio-gateway

**Application Backend (pointing to Istio Gateway)**
backend istio-gateway
    mode http
    balance roundrobin
    server istio-gateway 10.0.1.190:30080 check

Now Istio Gateway serves as a single entry point that routes traffic based on URL paths to different services (in my case - the backend and the frontend). After that my backend connects to PostgreSQL using in-cluster DNS names.


Applied the configuration using Ansible:
ansible-playbook -i inventory/hosts.ini playbooks/haproxy.yaml

## Compute Resources
I've provisioned three EC2 instances:

Master Node: A t3.medium instance in the private subnet for the Kubernetes control plane
Worker Node: A t3.xlarge instance in the private subnet for running workloads
HAProxy Server: A t3.micro instance in the public subnet for load balancing and SSH access

### State Management
I'm using a remote S3 backend for Terraform state management, which is a best practice for team collaboration and state persistence.


## Ansible Deployment of kubeadm and HAProxy

My Ansible playbooks handle the configuration of the EC2 instances, setting up the Kubernetes cluster and HAProxy. 

Loads necessary kernel modules (overlay, br_netfilter)
Configures sysctl settings for Kubernetes networking
Disables swap (required for Kubernetes)
Installs CRI-O as the container runtime
Sets up the Kubernetes repositories and installs kubelet, kubectl, and kubeadm
Configures the kubelet to use the correct node IP

This provides a consistent baseline for both master and worker nodes.
Master Node Role
This role:

Creates a kubeadm configuration file with proper certSANs for the API server
Initializes the Kubernetes cluster with the specified pod network CIDR
Sets up kubeconfig for both root and ubuntu users
Deploys Calico CNI for pod networking
Creates a join command for worker nodes

The configuration properly sets the control plane endpoint to the HAProxy IP, enabling high availability in the future.
Worker Node Role
This role:

Copies the join command from the master
Runs the command to join the cluster

This simple but effective approach ensures worker nodes become part of the cluster.
HAProxy Role
This role:

Installs HAProxy
Configures it to load balance the Kubernetes API (6443)
Sets up a stats page
Configures frontend/backend for application traffic pointing to the Istio Gateway

The HAProxy configuration serves dual purposes: load balancing the Kubernetes API and providing external access to your applications.


## Helm Charts



## HashiCorp Vault






## Istio



## ArgoCD




## Issues I've faced and how I solved them

- 














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

Enabling encryption by default
Encryption by default allows you to ensure that all new EBS volumes created in your account are always encrypted, even if you don’t specify encrypted=true request parameter. You have the option to choose the default key to be AWS managed or a key that you create. If you use IAM policies that require the use of encrypted volumes, you can use this feature to avoid launch failures that would occur if unencrypted volumes were inadvertently referenced when an instance is launched. Before turning on encryption by default, make sure to go through some of the limitations in the consideration section at the end of this blog.

potential use of image updater.
