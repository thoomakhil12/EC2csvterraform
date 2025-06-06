provider "aws" {
  region = var.instances[0].region
}
 
variable "instances" {
  type = list(object({
    name               = string
    instance_type      = string
    region             = string
    vpc_cidr           = string
    subnet_cidr        = string
    availability_zone  = string
  }))
}
 
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
 
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
 
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
 
resource "aws_vpc" "vpc" {
  for_each = { for inst in var.instances : inst.name => inst }
 
  cidr_block = each.value.vpc_cidr
 
  tags = {
    Name = "${each.key}-vpc"
  }
}
 
resource "aws_subnet" "subnet" {
  for_each = { for inst in var.instances : inst.name => inst }
 
  vpc_id            = aws_vpc.vpc[each.key].id
  cidr_block        = each.value.subnet_cidr
  availability_zone = each.value.availability_zone
  map_public_ip_on_launch = false
 
  tags = {
    Name = "${each.key}-subnet"
  }
}
 
resource "aws_security_group" "ec2_sg" {
  for_each = { for inst in var.instances : inst.name => inst }
 
  name        = "${each.key}-sg"
  description = "Allow SSH only"
  vpc_id      = aws_vpc.vpc[each.key].id
 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Replace with VPN/jumpbox CIDR in production
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "${each.key}-sg"
  }
}
 
resource "aws_instance" "ec2" {
  for_each = { for inst in var.instances : inst.name => inst }
 
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = each.value.instance_type
  subnet_id                   = aws_subnet.subnet[each.key].id
  vpc_security_group_ids      = [aws_security_group.ec2_sg[each.key].id]
  associate_public_ip_address = false
 
  tags = {
    Name = each.value.name
  }
 
  provider = aws
}
 
output "private_ips" {
  value = { for k, inst in aws_instance.ec2 : k => inst.private_ip }
}
 