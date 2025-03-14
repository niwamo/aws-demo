resource "aws_vpc" "main" {
  cidr_block = "10.1.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.1.1.0/24"
  tags = {
    Name = "Public"
  }
  availability_zone = local.az
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.1.2.0/24"
  tags = {
    Name = "Private"
  }
  availability_zone = local.az
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "public_rt" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}