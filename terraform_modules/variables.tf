variable "AMI" {
  default     = "ami-0e001c9271cf7f3b9"
  type        = string
  description = "The Type of the Template AMI"
}

variable "KEYPAIR" {
  default     = "keypair"
  type        = string
  description = "Keypair to Access EC2 instances SSH"
}

variable "INSTANCETYPE" {
  default     = "t3.small"
  type        = string
  description = "Type of EC2 instances. Changed from t3.micro to t3.small"
}

variable "EC2Volume" {
  default     = 10
  type        = number
  description = "The Actual Size of the EC2 instance (in gigabytes)"
}

variable "BUCKETNAME" {
  default     = "terraform-remote-state-devopsguy-001"
  description = "the s3 bucket name which you will save the statefile in"

}

variable "HAPROXY_INSTANCE_TYPE" {
  default     = "t3.micro"
  description = "Instance type for the HAProxy server"
}


// default values are simply a placeholder for the actual values that will be passed in via a .tfvars file or a -var argument via the CLI.