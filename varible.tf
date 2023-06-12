variable "region" {
  default = "ap-southeast-1"
}

variable "vpc_name" {
  default = "Enterprice-VPC"
}

variable "vpc_cidr" {
  default = "192.168.0.0/24"
}

variable "hostname" {
  default = "nahilcloud.sa"
}

variable "user_data_script_file" {
  default = "./nextcloud.sh"
}