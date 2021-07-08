provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

data "aws_ami" "amazon" {
     most_recent = true

     filter {
        name   = "name"
        values = ["amzn2-ami-hvm-*"]
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

resource "aws_vpc" "myvpc" {
cidr_block = "${var.vpc_cidr}"
enable_dns_hostnames = true
tags = {
Name = "myvpc"
}
}

# data "aws_availability_zones" "available" {}

resource "aws_subnet" "myvpc_public_subnet" {
    vpc_id = "${aws_vpc.myvpc.id}"
    cidr_block = "${var.subnet_one_cidr}"
    availability_zone = "${var.availability_zone}"
#     availability_zone = "${data.aws_availability_zones.availability_zones.ap-southeast-2a[0]}"
    map_public_ip_on_launch = true
    tags = {
        Name = "myvpc_public_subnet"
    }
}

resource "aws_subnet" "myvpc_private_subnet" {
    vpc_id = "${aws_vpc.myvpc.id}"
    cidr_block = "${var.subnet_two_cidr}"
    availability_zone = "${var.availability_zone}"
#     availability_zone = "${data.aws_availability_zones.availability_zones.ap-southeast-2a[0]}"
    # map_public_ip_on_launch = true
    tags = {
        Name = "myvpc_private_subnet"
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
# resource "aws_default_route_table" "myvpc_main_route_table" {
# default_route_table_id = "${aws_vpc.myvpc.default_route_table_id}"
# tags = {
# Name = "myvpc_main_route_table"
# }
# }


## associate public subnet with public route table
resource "aws_route_table_association" "myvpc_public_subnet_route_table" {
subnet_id = "${aws_subnet.myvpc_public_subnet.id}"
route_table_id = "${aws_route_table.myvpc_public_subnet_route_table.id}"
}


## associate private subnets with private route table
resource "aws_route_table_association" "myvpc_private_subnet_one_route_table_assosiation" {
        subnet_id = "${aws_subnet.myvpc_private_subnet.id}"
        route_table_id = "${aws_route_table.myvpc_private_subnet_route_table.id}"
}


# resource "aws_route_table_association" "myvpc_private_subnet_two_route_table_assosiation" {
# subnet_id = "${aws_subnet.myvpc_private_subnet_two.id}"
# route_table_id = "${aws_route_table.myvpc_private_subnet_route_table.id}"
# }

#Security Group Creation

resource "aws_security_group" "web_security_group" {
  name        = "web_security_group"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.myvpc.id}"
  tags = {
    Name = "myvpc_web_security_group"
  }
}

resource "aws_security_group_rule" "web_ingress" {
count = "${length(var.web_ports)}"
type = "ingress"
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
from_port = "${element(var.web_ports, count.index)}"
to_port = "${element(var.web_ports, count.index)}"
security_group_id = "${aws_security_group.web_security_group.id}"
}

resource "aws_security_group_rule" "web_egress" {
count = "${length(var.web_ports)}"
type = "egress"
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
from_port = "${element(var.web_ports, count.index)}"
to_port = "${element(var.web_ports, count.index)}"
security_group_id = "${aws_security_group.web_security_group.id}"
}

resource "aws_security_group" "web1_security_group" {
  name        = "web1_security_group"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.myvpc.id}"
  tags = {
    Name = "myvpc_web1_security_group"
  }
}

resource "aws_security_group_rule" "web1_ingress" {
count = "${length(var.web_ports)}"
type = "ingress"
protocol = "tcp"
cidr_blocks = ["10.0.0.0/16"]
from_port = "${element(var.web_ports, count.index)}"
to_port = "${element(var.web_ports, count.index)}"
security_group_id = "${aws_security_group.web1_security_group.id}"
}

#Pulic Micro Instance Creation

resource "aws_instance" "my_web_instance" {
#   ami                    = "${lookup(var.images, var.region)}"
  ami = data.aws_ami.amazon.id
  instance_type          = "t2.micro"
  key_name               = "instance_login"
  vpc_security_group_ids = ["${aws_security_group.web_security_group.id}"]
  subnet_id              = "${aws_subnet.myvpc_public_subnet.id}"
  tags = {
    Name = "my_web_instance"
  }
  volume_tags = {
    Name = "my_web_instance_volume"
  }

  provisioner "remote-exec" {
   inline = [
     "pip3 install ansible --user",
     "echo ansible_user=${var.ansible_user} ansible_ssh_private_key_file=${var.private_key}",
     "export ANSIBLE_HOST_KEY_CHECKING=False",
   ]
  }
  connection {
      type        = "ssh"
      user        = "ec2-user"
      host     = self.public_ip 
      private_key = "${file("d:\\code\\instance_login.pem")}"
    }
  provisioner "remote-exec" {
    inline = ["ansible-playbook -b -v -u ${var.ansible_user} --private-key ${var.private_key} ./provision.yml"]
  }
  

  # provisioner "local-exec" {
	#   command = <<EOT
	#   echo  "ansible_user=${var.ansible_user} ansible_ssh_private_key_file=${var.private_key}";
  #   export ANSIBLE_HOST_KEY_CHECKING=False;
  #   ansible-playbook -b -v -u ec2-user --private-key instance_login.pem provision.yml
  #   EOT
  # }
}


#Private Micro Instance Creation

resource "aws_instance" "private_instance" {
#   ami                    = "${lookup(var.images, var.region)}"
  ami = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = "instance_login"
  vpc_security_group_ids = ["${aws_security_group.web1_security_group.id}"]
  subnet_id              = "${aws_subnet.myvpc_private_subnet.id}"
  tags = {
    Name = "private_instance"
  }
  volume_tags = {
    Name = "private_volume"
  }
#   connection {
#     type     = "ssh"
#     user     = "centos"
#     password = ""
#     host     = self.public_ip
#     #copy <private.pem> to your local instance to the home directory
#     #chmod 600 id_rsa.pem
#     private_key = "${file("d:\\code\\instance_login.pem")}"
#     }
}

