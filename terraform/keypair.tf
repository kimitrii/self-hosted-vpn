resource "aws_key_pair" "vpn" {
  key_name   = "vpn-public-key"
  public_key = var.VPN_PUBLIC_KEYPAIR
}
