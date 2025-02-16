terraform {
  backend "s3" {
   region = "eu-north-1"
   bucket = var.BUCKETNAME
   key = "statefilebucket"
  }
}