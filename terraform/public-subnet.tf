resource "aws_subnet" "public-subnet" {
  assign_ipv6_address_on_creation                = false
  availability_zone_id                           = "use1-az6"
  cidr_block                                     = "10.0.1.0/24"
  enable_dns64                                   = false
  enable_resource_name_dns_a_record_on_launch    = false
  enable_resource_name_dns_aaaa_record_on_launch = false
  ipv6_native                                    = false
  map_public_ip_on_launch                        = false
  private_dns_hostname_type_on_launch            = "ip-name"
  tags = {
    Name = "vpn-subnet"
  }
  tags_all = {
    Name = "vpn-subnet"
  }
  vpc_id = aws_vpc.vpn-network.id
}
