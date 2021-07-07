variable "access_key" { default = "AKIAUQ4WWYCSHUFTLSMW" }
variable "secret_key" { default = "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" }
variable "region" { default = "ap-southeast-2" }
variable "vpc_cidr" { default = "10.0.0.0/16" }
variable "subnet_one_cidr" { default = "10.0.1.0/24" }
variable "subnet_two_cidr" { default = ["10.0.2.0/24", "10.0.3.0/24"] }
variable "route_table_cidr" { default = "0.0.0.0/0" }
variable "host" {default = "aws_instance.my_web_instance.public_dns"}
variable "web_ports" { default = ["22", "80", "443", "3306"] }
variable "db_ports" { default = ["22", "3306"] }
variable "images" {
  type = "map"
  default = {
    "ap-southeast-2"      = "ami-0a443decce6d88dc2"
  }
}
