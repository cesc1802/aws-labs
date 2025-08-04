provider "aws" {
  region = var.region
  profile = "vmo"
}

locals {
  tags = {
    Environment = "dev"
    Project = "basic-vpc"
    managed_by = "terraform"
  }
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"
  version = "2.1.0"

  key_name = "basic-vpc-key-pair"
  create_private_key = true
  private_key_algorithm = "RSA"
  private_key_rsa_bits = 2048
}

resource "aws_vpc" "basic_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = local.tags
}

resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.basic_vpc.id
  cidr_block = "10.0.1.0/24"
  tags = local.tags
}

resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.basic_vpc.id
  cidr_block = "10.0.2.0/24"
  tags = local.tags
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id = aws_vpc.basic_vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-southeast-1a"
  tags = local.tags
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id = aws_vpc.basic_vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "ap-southeast-1b"
  tags = local.tags
}

resource "aws_eip" "ngw" {
  domain = "vpc"
  tags   = local.tags
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.ngw.id
  subnet_id     = aws_subnet.public_subnet.id
  tags          = local.tags

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.basic_vpc.id
  tags   = local.tags
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.basic_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.tags, {
    Name = "public-rtb"
  })
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.basic_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }

  tags = merge(local.tags, {
    Name = "private-rtb"
  })
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_security_group" "public_sg" {
  name = "public-sg"
  description = "Basic VPC Security Group"
  vpc_id = aws_vpc.basic_vpc.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Ping from anywhere"
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Get latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "public_instance" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.public_sg.id]
  key_name                    = module.key_pair.key_pair_name

  tags = merge(local.tags, {
    Name = "public-instance"
  })
}

resource "aws_instance" "private_instance" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.private_subnet_2.id
  key_name                    = module.key_pair.key_pair_name

  tags = local.tags
}