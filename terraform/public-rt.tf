resource "aws_default_route_table" "public-rt" {
  default_route_table_id = aws_vpc.vpn-network.default_route_table_id
  propagating_vgws       = []
  route = [{
    cidr_block                 = "0.0.0.0/0"
    core_network_arn           = null
    destination_prefix_list_id = null
    egress_only_gateway_id     = null
    gateway_id                 = "${aws_internet_gateway.ig-vpn.id}"
    instance_id                = null
    ipv6_cidr_block            = null
    nat_gateway_id             = null
    network_interface_id       = null
    transit_gateway_id         = null
    vpc_endpoint_id            = null
    vpc_peering_connection_id  = null
  }]
}
