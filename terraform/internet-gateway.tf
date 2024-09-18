resource "aws_internet_gateway" "ig-vpn" {
  tags = {
    Name = "vpn-ig"
  }
  tags_all = {
    Name = "vpn-ig"
  }
  vpc_id = aws_vpc.vpn-network.id
}
