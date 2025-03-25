# Project Overview 

**And now for the main course!**

This is my most comprehensive repostitory as it focuses entirely on the Continious Delivery/Deployment of my property app - https://github.com/TankEngine-ish/property_management_system_full_stack_app 

Let's dive in!

## Architecture Overview

I have implemented a secure, scalable infrastructure that (hopefully) follows the best practices of many areas including cloud, IaC and credential security. In a nutshell it's a Kubernetes infrastructure on AWS for hosting my application, provisioned with Terraform and configured with Ansible. It also includes:

- Kubernetes (kubeadm) cluster on AWS EC2 instances
- Network isolation with public/private subnets
- HAProxy load balancer for ingress traffic
- Istio service mesh for the communication between the three layers (presentation (user interface), logic(business logic), and data (data storage))
- ArgoCD for GitOps-style continuous delivery
- HashiCorp Vault for secrets management
- Helm charts for application deployment

Here's a diagram I made to illustrate all the crazy trains of thought I had when making the project. Apologies for not compressing the chart's size.

![alt text](<assets/Data Flow Diagram (Copy) (2).jpg>)


## Creating & Configuring the Resources via Terraform

First and foremost I used Terraform to provision my AWS infrastructure and make my environment reproducible and version-controllable. On top of that, I used Ansible for configuring HAProxy on the public subnet and my two K8s nodes on the private subnet along with Jinja2 templates utilization (not just simple bash scripting). 

Via Terraform I've tried to implement a proper network isolation pattern with:

* a VPC (10.0.0.0/16) that serves as the container for all resources
* a public subnet (10.0.0.0/24) that hosts the HAProxy load balancer
* a private subnet (10.0.1.0/24) that hosts the Kubernetes nodes
* an Internet Gateway for public subnet internet access
* a NAT Gateway to allow private subnet resources to access the internet without being directly accessible
* also two separate route tables for public and private subnets

This design follows the AWS well-architected framework by placing public-facing components in the public subnet while keeping my critical infrastructure in the private subnet.

### Enabling encryption by default 

Encryption by default allows me to ensure that all new EBS volumes created in my account are always encrypted, even if I don’t specify **encrypted=true** request parameter. I have the option to choose the default key to be AWS managed or a key that I create. If I use IAM policies that require the use of encrypted volumes, I can use this feature to avoid launch failures that would occur if unencrypted volumes were inadvertently referenced when an instance is launched. 

### Security Groups

My *Security Group Architecture* implements the principle of least privilege:
I've created two main security groups with carefully scoped permissions:

**HAProxy Security Group (haproxy_sg)**

This security group controls access to my HAProxy instance in the public subnet:

```
terraformCopyresource "aws_security_group" "haproxy_sg" {
  name        = "haproxy-sg"
  vpc_id      = aws_vpc.kubernetesVPC.id
  description = "security group for the HAProxy instance in the public subnet"
}
```

Access rules for this group include:

- SSH (port 22) from a single specific IP (185.240.147.99/32) - not from anywhere on the internet
- Kubernetes API (port 6443) from anywhere - needed for remote kubectl access

I've limited SSH access to a single IP address and I've only opened the specific ports needed for the HAProxy to function. All other ports remain closed by default.

**Kubernetes Security Group (kubernetes_sg)**

* This security group protects my Kubernetes nodes in the private subnet:

```
terraformCopyresource "aws_security_group" "kubernetes_sg" {
  name        = "kubernetes-SG"
  vpc_id      = aws_vpc.kubernetesVPC.id
  description = "security group for Kubernetes master and worker nodes (private subnet only)"
}
```

* Below, I've defined a security group ingress rule, allowing HAProxy to communicate with the Kubernetes API server on port 6443.

```
terraformCopyresource "aws_vpc_security_group_ingress_rule" "allow_haproxy_to_k8s_api" {
  security_group_id            = aws_security_group.kubernetes_sg.id
  referenced_security_group_id = aws_security_group.haproxy_sg.id
  from_port                    = 6443
  to_port                      = 6443
  ip_protocol                  = "tcp"
  description                  = "allow HAProxy to communicate with Kubernetes API"
}
```

The above block states that the Kubernetes API is only accessible from instances that **belong** to the HAProxy security group, not just from any IP.

* Private subnet scoping: For internal Kubernetes communication, I've limited access to the private subnet CIDR:

```
terraformCopyresource "aws_vpc_security_group_ingress_rule" "allow_internal_k8s" {
  security_group_id = aws_security_group.kubernetes_sg.id
  cidr_ipv4         = "10.0.1.0/24" # Private subnet
  ip_protocol       = "-1"
  description       = "allow internal Kubernetes communication between nodes"
}
```

* Bastion pattern for SSH: SSH access to Kubernetes nodes is only allowed from the HAProxy (functioning as a bastion host):

```
terraformCopyresource "aws_vpc_security_group_ingress_rule" "allow_ssh_from_haproxy" {
  security_group_id            = aws_security_group.kubernetes_sg.id
  referenced_security_group_id = aws_security_group.haproxy_sg.id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  description                  = "llow SSH access from HAProxy"
}
```

At this stage I was really wondering if I should use something like OpenVPN or even an actual bastion host (one of my other laptops at home) so I kept thinking about it and finally remembered that HAProxy could very well do the trick without much overhead.

* NodePort access control: NodePorts are only accessible from the HAProxy, not directly from the internet:

```
terraformCopyresource "aws_vpc_security_group_ingress_rule" "allow_nodeport_from_haproxy" {
  security_group_id            = aws_security_group.kubernetes_sg.id
  referenced_security_group_id = aws_security_group.haproxy_sg.id
  from_port                    = 30000
  to_port                      = 32767
  ip_protocol                  = "tcp"
  description                  = "allow NodePort range access from HAProxy"
}
```

The reason behind the usage of NodePort was that HAProxy couldn't connect to the Istio Gateway due to security group configurations. But even prior to that, the root cause of all this was that whenever I wanted to visit my application via an IP URL I had to forward two different ports - one for the backend and one for the frontend. I could've just as easily used nginx to create a single point of entry but I'm always up for a challenge. So I modified the HAProxy template in Ansible:

```
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

```

Now Istio and its Gateway portion serve as a single entry point that routes traffic based on URL paths to different services (in my case - the backend and the frontend). After that my backend connects to PostgreSQL using in-cluster DNS names.

![alt text](<assets/Screenshot from 2025-03-10 17-13-19.png>)

This is the output of my istio deploy script.

## Compute Resources

I've provisioned three EC2 instances:

* Master Node: A t3.medium instance in the private subnet for the Kubernetes control plane
* Worker Node: A t3.xlarge instance in the private subnet for running workloads
* HAProxy Server: A t3.micro instance in the public subnet for load balancing and SSH access

### State Management

I'm using a remote S3 backend for Terraform state management. It's best practice. That's about it.


## Ansible Deployment of kubeadm and HAProxy

Directory Structure:

* Inventory (inventory/hosts.ini)
* Playbooks (playbooks/)
* Roles (roles/common, roles/master-node, etc.)


Role-Based Organization:

* common: Base configuration for all Kubernetes nodes
* master-node: Control plane setup
* worker-node: Worker node configuration
* haproxy: Load balancer setup

I can talk about my configuration for an hour but I would just like to focus on one thing. And that is the ***fetch*** module.

So, at some point I had to ***join*** the worker node to the cluster (or in my case - just to the master node). The command is created after the master node is initialized with **kubeadm init**. Without this command, worker nodes cannot securely authenticate and join the cluster because there is a token involved which acts as a one-time secret that allows secure bootstrapping of the cluster.


My use of the fetch module is to retrieve that **join command** from the master node:

```
yamlCopy- name: Fetch join command to control machine
  fetch:
    src: /home/ubuntu/joincommand.sh
    dest: /tmp/joincommand.sh
    flat: yes
```

This is more elegant than directly using SSH or SCP commands. It **pulls** the join command to my Ansible control machine first, then in a separate task, sends it to the worker. This is a very scalable approach in my opinion.

## Helm Charts



## HashiCorp Vault


![alt text](<assets/Screenshot from 2025-03-13 20-18-37.png>)

**Been there - done all three!**
Note: I'm not getting sponsored by HashiCorp (I wish I was).


## ArgoCD

A Story in 3 Acts

![alt text](<assets/Screenshot from 2025-03-18 21-42-20.png>)

First Act - my Jenkins build creates a new temp branch with the latest versions of the property app in the infra repo.

![alt text](<assets/Screenshot from 2025-03-18 21-41-39.png>)

Second Act - it's up to the hypothetical DevOps team to review the Pull Request and merge the change to their "prod" branch.

![alt text](<assets/Screenshot from 2025-03-18 21-48-22.png>)

Third Act - it's been approved and ArgoCD has been flawlessly synced with the repo.

## All the King's Namespaces

![alt text](<assets/Screenshot from 2025-03-16 22-02-01.png>)

At one point this became a sort of an experiment on how many different (**but working**) software components I can fit into a single t3.medium EC2 instance before I power through the limits of the resources. Well, I sadly failed this experiement and I even had to resort to a t3.xlarge which fortunately was very comfortable for everybody involved. Mostly me, though.

![alt text](<assets/Screenshot from 2025-03-10 17-16-08.png>)

In my case, all these namespaces are necessary because:

- argocd: It also includes redis to serve as cache and storage, the repo-server to manage Git repositories and the main server to provide the ArgoCD API and UI.

- istio-system: It includes the istio-ingressgateway for the entry point for external traffic and istiod as the control plane for the service mesh. As this is a minimal installation there's no Egress Gateway, Telemetry Collection Components or the Istio CNI Plugin.

- kube-system: it contains calico-node and kube-proxy of which you simply can't escape.

- property-app: this is ***me***.

- vault-0: it holds the main Vault server and vault-agent-injector which injects secrets into pods.

## Issues I've faced and how I solved them

- 





