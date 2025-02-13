terraform {
  backend "s3" {
   region = "eu-north-1"
   bucket = var.terraform-remote-state-devopsguy-001
   key = "statefilebucket"
  }
}