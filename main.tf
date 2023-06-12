data "alicloud_zones" "az" {
  available_resource_creation = "VSwitch"
}

resource "alicloud_vpc" "demo" {
  vpc_name       = "${var.vpc_name}"
  description      = "NextCloud Demo VPC"
  cidr_block = "${var.vpc_cidr}"
}

resource "alicloud_vswitch" "vswitch-az1" {
  vswitch_name      = "Enterprice-vswitch-az1"
  vpc_id            = alicloud_vpc.demo.id
  cidr_block        = "192.168.0.0/27"
  availability_zone = data.alicloud_zones.az.zones.0.id
  depends_on = [alicloud_vpc.demo]
  }

resource "alicloud_vswitch" "vswitch-az2" {
  vswitch_name      = "Enterprice-vswitch-az2"
  vpc_id            = alicloud_vpc.demo.id
  cidr_block        = "192.168.0.32/27"
  availability_zone = data.alicloud_zones.az.zones.1.id
  depends_on = [alicloud_vpc.demo]
  }

resource "alicloud_security_group" "application_security_group" {
  name = "Application-security-group"
  vpc_id = "${alicloud_vpc.demo.id}"
}

resource "alicloud_security_group_rule" "rule_ssh" {
  security_group_id = "${alicloud_security_group.application_security_group.id}"
  type = "ingress"
  ip_protocol = "tcp"
  nic_type = "intranet"
  policy = "accept"
  port_range = "22/22"
  priority = 1
  cidr_ip = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "rule_http" {
  security_group_id = "${alicloud_security_group.application_security_group.id}"
  type = "ingress"
  ip_protocol = "tcp"
  nic_type = "intranet"
  policy = "accept"
  port_range = "80/80"
  priority = 1
  cidr_ip = "0.0.0.0/0"
}

data "alicloud_images" "ubuntu" {
  most_recent = true
  name_regex  = "^ubuntu_20.*64"
}

resource "alicloud_eip" "ecs_eip" {
  count = 2
}

resource "alicloud_eip_association" "ecs_eip_associate" {
  count         = 2
  allocation_id = alicloud_eip.ecs_eip[count.index].id
  instance_id   = alicloud_instance.instance1[count.index].id
}

resource "alicloud_instance" "instance1" {
  count = 2
  availability_zone  = count.index % 2 == 0 ? alicloud_vswitch.vswitch-az1.availability_zone : alicloud_vswitch.vswitch-az2.availability_zone
  security_groups    = [alicloud_security_group.application_security_group.id]
  instance_type              = "ecs.ic5.large"
  system_disk_category       = "cloud_ssd"
  image_id                   = data.alicloud_images.ubuntu.ids.0
  instance_name              = "enterprice-stack-instance-${count.index + 1}"
  host_name                  = "enterpricevm-${count.index + 1}"
  vswitch_id                 = count.index % 2 == 0 ? alicloud_vswitch.vswitch-az1.id : alicloud_vswitch.vswitch-az2.id
  password                   = "${var.enterprice-stack-instance-password}"
  data_disks {
    name        = "disk" 
    size        = 20
    category    = "cloud_ssd"
    description = "disk"
    encrypted   = false
  }
  user_data = file(var.user_data_script_file)
}