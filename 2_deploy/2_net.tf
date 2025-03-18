# VPC

resource "aws_vpc" "main" {
  cidr_block = "10.1.0.0/16"
  tags = {
    "kubernetes.io/cluster/app" = "shared"
  }
}

# SUBNETS

resource "aws_subnet" "public1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.1.1.0/24"
  tags = {
    Name                     = "Public1"
    "kubernetes.io/role/elb" = "1"
  }
  availability_zone = local.az1
}

resource "aws_subnet" "public2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.1.2.0/24"
  tags = {
    Name                     = "Public2"
    "kubernetes.io/role/elb" = "1"
  }
  availability_zone = local.az2
}

resource "aws_subnet" "private1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.1.11.0/24"
  tags = {
    Name                              = "Private #1"
    "kubernetes.io/role/internal-elb" = "1"
  }
  availability_zone = local.az1
}

resource "aws_subnet" "private2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.1.12.0/24"
  tags = {
    Name                              = "Private #2"
    "kubernetes.io/role/internal-elb" = "1"
  }
  availability_zone = local.az2
}

# IGW + PUBLIC SUBNET ROUTE

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "igw" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "IGW Route"
  }
}

resource "aws_route_table_association" "igw1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.igw.id
}

resource "aws_route_table_association" "igw2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.igw.id
}

# NGW + PRIVATE SUBNET ROUTE

resource "aws_eip" "ngw" {
  depends_on = [aws_internet_gateway.igw]
  domain     = "vpc"
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.ngw.id
  subnet_id     = aws_subnet.public1.id
  tags = {
    "Name" = "NAT Gateway"
  }
}

output "nat_gateway_ip" {
  value = aws_eip.ngw.public_ip
}

resource "aws_route_table" "ngw" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }
}

resource "aws_route_table_association" "ngw1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.ngw.id
}

resource "aws_route_table_association" "ngw2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.ngw.id
}
