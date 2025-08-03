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

# resource "aws_network_acl" "public" {
#   vpc_id = aws_vpc.basic_vpc.id
# }

# resource "aws_network_acl_rule" "inbound_icmp" {
#   network_acl_id = aws_network_acl.public.id
#   rule_number    = 100
#   egress         = false
#   protocol       = "icmp"
#   rule_action    = "allow"
#   cidr_block     = "0.0.0.0/0"
#   from_port      = -1  # All types
#   to_port        = -1
# }

# resource "aws_network_acl_rule" "outbound_icmp" {
#   network_acl_id = aws_network_acl.public.id
#   rule_number    = 100
#   egress         = true
#   protocol       = "icmp"
#   rule_action    = "allow"
#   cidr_block     = "0.0.0.0/0"
#   from_port      = -1  # All types
#   to_port        = -1
# }

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

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.basic_vpc.id
  tags = local.tags
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.basic_vpc.id
  tags = local.tags
}

resource "aws_route" "public_route" {
  route_table_id = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_route_table_association" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_security_group" "allow_ssh_basic_instance" {
  name = "basic-vpc-sg"
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

# resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
#   security_group_id = aws_security_group.allow_ssh_basic_instance.id
#   ip_protocol = "tcp"
#   from_port = 22
#   to_port = 22
#   cidr_ipv4 = "0.0.0.0/0"
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_icmp" {
#   security_group_id = aws_security_group.allow_ssh_basic_instance.id
#   ip_protocol = "icmp"
#   from_port = 0
#   to_port = 0
#   cidr_ipv4 = "0.0.0.0/0"
# }


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

resource "aws_instance" "basic_instance" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids = [ aws_security_group.allow_ssh_basic_instance.id ]
  key_name = module.key_pair.key_pair_name

  tags = local.tags
}