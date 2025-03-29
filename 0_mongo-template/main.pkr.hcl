packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.4"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "region" {
  default = env("AWS_REGION")
}

source "amazon-ebs" "build" {
  ami_name              = "aws-demo_mongovm"
  force_deregister      = true
  force_delete_snapshot = true
  instance_type         = "t2.micro"
  region                = var.region
  source_ami            = lookup(var.sourceAMIs, var.region, "")
  ssh_username          = "ubuntu"
}

build {
  sources = [
    "source.amazon-ebs.build"
  ]
  provisioner "file" {
    source      = "./artifacts/"
    destination = "/tmp/"
  }
  provisioner "shell" {
    inline = [
      "sudo dos2unix /tmp/*", # just in case
      "sudo mv /tmp/mongod.conf /etc/mongod.conf",
      "sudo mv /tmp/pre-mongo.service /lib/systemd/system/pre-mongo.service",
      "sudo mkdir /etc/systemd/system/mongod.service.d",
      "sudo mv /tmp/override.conf /etc/systemd/system/mongod.service.d/override.conf",
      "sudo mv /tmp/aws-demo-startup.sh /opt/aws-demo-startup.sh",
      "sudo systemctl enable pre-mongo"
    ]
  }
}
