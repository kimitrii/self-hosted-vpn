resource "aws_security_group" "public-sg" {
  description = "VPN Security Group Firewall"
  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "-1"
    security_groups  = []
    self             = false
    to_port          = 0
  }]
  ingress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 51820
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "udp"
    security_groups  = []
    self             = false
    to_port          = 51820
  }]
  name   = "vpn-sg"
  vpc_id = aws_vpc.vpn-network.id
}
