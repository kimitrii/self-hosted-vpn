resource "aws_instance" "vpn-server" {
  ami                                  = "ami-00e73ddc3a6fc7dfe"
  availability_zone                    = var.EC2_AV_ZONE
  disable_api_stop                     = false
  disable_api_termination              = false
  ebs_optimized                        = true
  get_password_data                    = false
  hibernation                          = false
  instance_initiated_shutdown_behavior = "stop"
  instance_type                        = var.EC2_TYPE
  key_name                             = aws_key_pair.vpn.key_name
  monitoring                           = false
  placement_partition_number           = 0
  private_ip                           = "10.0.1.51"
  source_dest_check                    = false
  subnet_id                            = aws_subnet.public-subnet.id
  tags = {
    Name = "vpn-server"
  }
  tags_all = {
    Name = "vpn-server"
  }
  tenancy = "default"
  user_data = templatefile("../scripts/wireguard-installer.sh", {
    SERVER_PRIVATE_KEY   = "${var.SERVER_PRIVATE_KEY}"
    CLIENT_PUBLIC_KEY    = "${var.CLIENT_PUBLIC_KEY}"
    CLIENT_PRESHARED_KEY = "${var.CLIENT_PRESHARED_KEY}"
  })
  vpc_security_group_ids = [aws_security_group.public-sg.id]
  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }
  cpu_options {
    core_count       = 2
    threads_per_core = 1
  }
  credit_specification {
    cpu_credits = "standard"
  }
  enclave_options {
    enabled = false
  }
  maintenance_options {
    auto_recovery = "default"
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_protocol_ipv6          = "disabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
    instance_metadata_tags      = "disabled"
  }
  private_dns_name_options {
    enable_resource_name_dns_a_record    = false
    enable_resource_name_dns_aaaa_record = false
    hostname_type                        = "ip-name"
  }
  root_block_device {
    delete_on_termination = true
    encrypted             = false
    iops                  = 3000
    throughput            = 125
    volume_size           = 8
    volume_type           = "gp3"
  }
}
