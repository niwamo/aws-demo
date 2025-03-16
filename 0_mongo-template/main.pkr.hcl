packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.4"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "build" {
  ami_name              = "aws-demo_mongovm"
  force_deregister      = true
  force_delete_snapshot = true
  instance_type         = "t2.micro"
  region                = "us-east-2"
  # https://cloud-images.ubuntu.com/locator/ec2/
  source_ami   = "ami-05803413c51f242b7"
  ssh_username = "ubuntu"
}

build {
  sources = [
    "source.amazon-ebs.build"
  ]
  provisioner "file" {
    source      = "./artifacts/mongod.conf"
    destination = "/tmp/mongod.conf"
  }
  provisioner "file" {
    source      = "./artifacts/pre-mongo.service"
    destination = "/tmp/pre-mongo.service"
  }
  provisioner "file" {
    source      = "./artifacts/override.conf"
    destination = "/tmp/override.conf"
  }
  provisioner "file" {
    source      = "./artifacts/aws-demo-startup.sh"
    destination = "/tmp/aws-demo-startup.sh"
  }
  provisioner "shell" {
    scripts = [
      "./artifacts/install-mongo.sh"
    ]
  }
  provisioner "shell" {
    inline = [
      "sudo mv /tmp/mongod.conf /etc/mongod.conf",
      "sudo mv /tmp/pre-mongo.service /lib/systemd/system/pre-mongo.service",
      "sudo mkdir /etc/systemd/system/mongod.service.d",
      "sudo mv /tmp/override.conf /etc/systemd/system/mongod.service.d/override.conf",
      "sudo mv /tmp/aws-demo-startup.sh /opt/aws-demo-startup.sh",
      "sudo systemctl enable pre-mongo"
    ]
  }
}
