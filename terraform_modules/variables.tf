variable "AMI" {
    default = "ami-0e001c9271cf7f3b9"
    type = string
    description = "The Type of AMI"
}

variable "KEYPAIR" {
    default = "keypair"
    type = string
    description = "Keypair to Access EC2 instances SSH"
}

variable "INSTANCETYPE" {
    default = "t2.micro" 
    type = string
    description = "Type of the ec2 instances"  
}

variable "EC2Volume" {
    default = "30"
    description = "the volume size of ec2 instances"
}

variable "BUCKETNAME" {
    default = "statefilebucketdemo"
    description = "the s3 bucket name which you will save the statefile in"
  
}

// default values are simply a placeholder for the actual values that will be passed in via a .tfvars file or a -var argument via the CLI.