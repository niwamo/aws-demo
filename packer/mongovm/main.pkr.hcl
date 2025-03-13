packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.4"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "build" {
  ami_name      = "aws-demo_mongovm"
  instance_type = "t2.micro"
  region        = "us-east-2"
  source_ami    = "ami-05803413c51f242b7"
  ssh_username  = "ubuntu"
}

build {
  sources = [
    "source.amazon-ebs.build"
  ]
  provisioner "shell" {
    inline = ["echo Connected via SSH at '${build.User}@${build.Host}:${build.Port}'"]
  }
}
