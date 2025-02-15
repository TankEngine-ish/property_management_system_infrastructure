# property_management_system_infrastructure
Infrastructure repo for provisioning and configuring a Kubernetes cluster on AWS using Terraform and Ansible. 

Unlike S3, you don’t create EC2 instances manually if they’re defined in your Terraform configuration. Terraform will automatically create them when you run terraform apply.