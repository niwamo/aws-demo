variable "AWS_REGION" {}
variable "DB_EBS_ID" {}

locals {
  az          = "${var.AWS_REGION}a"
  allowed_ssh = "72.213.117.8/32"
  public_key  = file("../key.pub")
}