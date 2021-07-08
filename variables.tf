variable "access_key" { default = "" }
variable "secret_key" { default = ""}
variable "region" { default = "ap-southeast-2" }
variable "vpc_cidr" { default = "10.0.0.0/16" }
variable "subnet_one_cidr" { default = "10.0.1.0/24" }
variable "subnet_two_cidr" { default = "10.0.2.0/24" }
variable "route_table_cidr" { default = "0.0.0.0/0" }
variable "host" {default = "aws_instance.my_web_instance.public_dns"}
variable "web_ports" { default = ["22", "80", "443", "3306"] }
variable "db_ports" { default = ["22", "3306"] }
variable "availability_zone" { default = "" }
variable "ansible_user" {
  default = "ec2-user"
}
variable "private_key" {
  default = "/d/code/instance_login.pem"
}
