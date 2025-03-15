data "aws_ami" "mongo-server" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = ["aws-demo_mongovm"]
  }
}

resource "aws_security_group" "mongo-server" {
  vpc_id = aws_vpc.main.id
  egress {
    from_port = 0
    to_port   = 0
    protocol  = -1
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      local.allowed_IPs_for_admin
    ]
  }
  ingress {
    from_port = 27017
    to_port   = 27017
    protocol  = "tcp"
    cidr_blocks = [
      "10.1.0.0/16"
    ]
  }
  tags = {
    Name = "mongo-server"
  }
}

resource "aws_key_pair" "aws-demo" {
  key_name   = "aws-demo"
  public_key = local.public_key
}

resource "aws_instance" "mongo-server" {
  ami           = data.aws_ami.mongo-server.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public1.id
  vpc_security_group_ids = [
    aws_security_group.mongo-server.id
  ]
  key_name                    = aws_key_pair.aws-demo.id
  associate_public_ip_address = true
}

output "mongo-server-ip" {
  value = aws_instance.mongo-server.public_ip
}

resource "aws_volume_attachment" "db" {
  device_name = "/dev/xvdf"
  volume_id   = var.DB_EBS_ID
  instance_id = aws_instance.mongo-server.id
}