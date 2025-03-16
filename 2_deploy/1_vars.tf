variable "AWS_REGION" {}
variable "DB_EBS_ID" {}

locals {
  az1                   = "${var.AWS_REGION}a"
  az2                   = "${var.AWS_REGION}b"
  allowed_IPs_for_admin = "72.213.117.8/32"
  public_key            = file("../key.pub")
  unsafe_app            = "0" # set to 1 to enable stored XSS on web app
}