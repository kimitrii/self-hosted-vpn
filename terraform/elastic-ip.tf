resource "aws_eip" "public-ip" {
  domain               = "vpc"
  instance             = aws_instance.vpn-server.id
  network_border_group = var.VPN_ZONE
  network_interface    = aws_instance.vpn-server.primary_network_interface_id
  public_ipv4_pool     = "amazon"
}
