provider "aws" {
    region = "us-east-1"
    profile = "default"
}
   
resource "random_id" "bucket_suffix" {
  byte_length = 4
}
resource "aws_s3_bucket" "test" {
    bucket = "terraform-bucket-${random_id.bucket_suffix.hex}"
}