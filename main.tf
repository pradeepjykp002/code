provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}


resource "aws_vpc" "myvpc" {
cidr_block = "${var.vpc_cidr}"
enable_dns_hostnames = true
tags = {
Name = "myvpc"
}
}

resource "aws_subnet" "myvpc_public_subnet" {
    vpc_id = "${aws_vpc.myvpc.id}"
    cidr_block = "${var.subnet_one_cidr}"
    availability_zone = "${data.aws_availability_zones.availability_zones.names[0]}"
    map_public_ip_on_launch = true
    tags = {
        Name = "myvpc_public_subnet"
    }
}

resource "aws_internet_gateway" "myvpc_internet_gateway" {
vpc_id = "${aws_vpc.myvpc.id}"
tags= {
Name = "myvpc_internet_gateway"
}
}
## create public route table (assosiated with internet gateway)
resource "aws_route_table" "myvpc_public_subnet_route_table" {
vpc_id = "${aws_vpc.myvpc.id}"
route {
cidr_block = "${var.route_table_cidr}"
gateway_id = "${aws_internet_gateway.myvpc_internet_gateway.id}"
}
tags = {
Name = "myvpc_public_subnet_route_table"
}
}
## create private subnet route table
resource "aws_route_table" "myvpc_private_subnet_route_table" {
vpc_id = "${aws_vpc.myvpc.id}"
tags = {
Name = "myvpc_private_subnet_route_table"
}
}
## create default route table
resource "aws_default_route_table" "myvpc_main_route_table" {
default_route_table_id = "${aws_vpc.myvpc.default_route_table_id}"
tags = {
Name = "myvpc_main_route_table"
}
}
## associate public subnet with public route table
resource "aws_route_table_association" "myvpc_public_subnet_route_table" {
subnet_id = "${aws_subnet.myvpc_public_subnet.id}"
route_table_id = "${aws_route_table.myvpc_public_subnet_route_table.id}"
}
## associate private subnets with private route table
resource "aws_route_table_association" "myvpc_private_subnet_one_route_table_assosiation" {
subnet_id = "${aws_subnet.myvpc_private_subnet_one.id}"
route_table_id = "${aws_route_table.myvpc_private_subnet_route_table.id}"
}
resource "aws_route_table_association" "myvpc_private_subnet_two_route_table_assosiation" {
subnet_id = "${aws_subnet.myvpc_private_subnet_two.id}"
route_table_id = "${aws_route_table.myvpc_private_subnet_route_table.id}"
}
