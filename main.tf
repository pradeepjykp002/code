provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

# To Fetch the latest AMI of amazon and Ubuntu

data "aws_ami" "amazon" {
     most_recent = true

     filter {
        name   = "name"
        values = ["amzn2-ami-hvm-2.0.20210617.0-x86_64-gp2"]
 }
     filter {
       name   = "virtualization-type"
       values = ["hvm"]
 }
     owners = ["amazon"]
 }

 data "aws_ami" "ubuntu" {
     most_recent = true

     filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/*"]
 }
     filter {
       name   = "virtualization-type"
       values = ["hvm"]
 }
     owners = ["099720109477"]
 }

# Creation of VPC
resource "aws_vpc" "nonprod_vpc" {
cidr_block = "${var.vpc_cidr}"
enable_dns_hostnames = true
tags = {
Name = "nonprod_vpc"
}
}

# Creation of Public subnet
resource "aws_subnet" "nonprod_public_subnet" {
    vpc_id = "${aws_vpc.nonprod_vpc.id}"
    cidr_block = "${var.public_cidr}"
    availability_zone = "${var.availability_zone}"
    map_public_ip_on_launch = true
    tags = {
        Name = "nonprod_public_subnet"
    }
}

# Creation of Private subnet
resource "aws_subnet" "nonprod_private_subnet" {
    vpc_id = "${aws_vpc.nonprod_vpc.id}"
    cidr_block = "${var.private_cidr}"
    availability_zone = "${var.availability_zone}"
    tags = {
        Name = "nonprod_private_subnet"
    }
}

# Creation of Internet Gateway for public subnet
resource "aws_internet_gateway" "nonprod_internet_gateway" {
vpc_id = "${aws_vpc.nonprod_vpc.id}"
tags= {
Name = "nonprod_internet_gateway"
}
}

## create public route table (assosiated with internet gateway)
resource "aws_route_table" "nonprod_public_subnet_route_table" {
vpc_id = "${aws_vpc.nonprod_vpc.id}"
route {
cidr_block = "${var.route_table_cidr}"
gateway_id = "${aws_internet_gateway.nonprod_internet_gateway.id}"
}
tags = {
Name = "nonprod_public_subnet_route_table"
}
}

## create private subnet route table
resource "aws_route_table" "nonprod_private_subnet_route_table" {
vpc_id = "${aws_vpc.nonprod_vpc.id}"
tags = {
Name = "nonprod_private_subnet_route_table"
}
}

## associate public subnet with public route table
resource "aws_route_table_association" "nonprod_public_subnet_route_table" {
subnet_id = "${aws_subnet.nonprod_public_subnet.id}"
route_table_id = "${aws_route_table.nonprod_public_subnet_route_table.id}"
}


## associate private subnets with private route table
resource "aws_route_table_association" "nonprod_private_subnet_one_route_table_assosiation" {
        subnet_id = "${aws_subnet.nonprod_private_subnet.id}"
        route_table_id = "${aws_route_table.nonprod_private_subnet_route_table.id}"
}

# Creation of security group for public instance
resource "aws_security_group" "public_instance_security_group" {
  name        = "public_instance_security_group"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.nonprod_vpc.id}"
  tags = {
    Name = "public_instance_security_group"
  }
}

#Adding inbound rules for public security group
resource "aws_security_group_rule" "instance_ingress" {
count = "${length(var.instance_ports)}"
type = "ingress"
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
from_port = "${element(var.instance_ports, count.index)}"
to_port = "${element(var.instance_ports, count.index)}"
security_group_id = "${aws_security_group.public_instance_security_group.id}"
}

#Adding outbound rules for public security group
resource "aws_security_group_rule" "instance_egress" {
count = "${length(var.instance_ports)}"
type = "egress"
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
from_port = "${element(var.instance_ports, count.index)}"
to_port = "${element(var.instance_ports, count.index)}"
security_group_id = "${aws_security_group.public_instance_security_group.id}"
}

#Creation of  security group for private instance
resource "aws_security_group" "private_instance_security_group" {
  name        = "private_instance_security_group"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.nonprod_vpc.id}"
  tags = {
    Name = "private_instance_security_group"
  }
}

#Adding inbound rules for private security group
resource "aws_security_group_rule" "private_instance_ingress" {
count = "${length(var.instance_ports)}"
type = "ingress"
protocol = "tcp"
cidr_blocks = ["10.0.0.0/16"]
from_port = "${element(var.instance_ports, count.index)}"
to_port = "${element(var.instance_ports, count.index)}"
security_group_id = "${aws_security_group.private_instance_security_group.id}"
}

#Creation of public micro instance - Amazon AMI
resource "aws_instance" "nonprod_public_instance" {
  ami = data.aws_ami.amazon.id
  instance_type          = "t2.micro"
  key_name               = "instance_login"
  vpc_security_group_ids = ["${aws_security_group.public_instance_security_group.id}"]
  subnet_id              = "${aws_subnet.nonprod_public_subnet.id}"
  tags = {
    Name = "nonprod_public_instance"
  }
  volume_tags = {
    Name = "nonprod_public_instance_volume"
  }
}

#Creation of private micro instance - Ubuntu AMI
resource "aws_instance" "nonprod_private_instance" {
  ami = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = "instance_login"
  vpc_security_group_ids = ["${aws_security_group.private_instance_security_group.id}"]
  subnet_id              = "${aws_subnet.nonprod_private_subnet.id}"
  tags = {
    Name = "nonprod_private_instance"
  }
  volume_tags = {
    Name = "nonprod_private_instance_volume"
  }
}
