output "ecs_global_ip" {
  value = alicloud_eip.ecs_eip[*].ip_address
}