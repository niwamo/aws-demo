# reference
# https://stackoverflow.com/questions/68658353/

variable "AWS_REGION" {}

resource "aws_ecr_repository" "aws-demo" {
  name = "aws-demo"
}

# get authorization credentials to push to ecr
data "aws_ecr_authorization_token" "token" {}

provider "docker" {
  registry_auth {
    address  = data.aws_ecr_authorization_token.token.proxy_endpoint
    username = data.aws_ecr_authorization_token.token.user_name
    password = data.aws_ecr_authorization_token.token.password
  }
}

# build docker image
resource "docker_image" "aws-demo" {
  name = "${aws_ecr_repository.aws-demo.repository_url}:latest"
  build {
    context = "../0_src"
  }
}

# push image to ecr repo
resource "docker_registry_image" "upload" {
  name = docker_image.aws-demo.name
}
