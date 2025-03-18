variable "DB_EBS_ID" {}

data "aws_region" "current" {}

locals {
  az1                   = "${data.aws_region.current.name}a"
  az2                   = "${data.aws_region.current.name}b"
  allowed_IPs_for_admin = "72.213.117.8/32"
  public_key            = file("../key.pub")
  unsafe_app            = "0" # set to 1 to enable stored XSS on web app
}
