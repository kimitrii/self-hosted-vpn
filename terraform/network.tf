resource "aws_vpc" "vpn-network" {
  assign_generated_ipv6_cidr_block     = false
  cidr_block                           = "10.0.0.0/16"
  enable_dns_hostnames                 = false
  enable_dns_support                   = true
  enable_network_address_usage_metrics = false
  instance_tenancy                     = "default"
  tags = {
    Name = "vpn"
  }
  tags_all = {
    Name = "vpn"
  }
}
