#!/bin/bash
dnf update && dnf upgrade -y

dnf install wireguard-tools iptables cronie -y

# Sets up a scheduled task to update and upgrade packages weekly
systemctl start crond
systemctl enable crond
echo "0 0 * * 6 /usr/bin/dnf update -y && /usr/bin/dnf upgrade -y" > cronupdateweekly
crontab cronupdateweekly

# Save keys to files
cd /etc/wireguard/
echo $SERVER_PRIVATE_KEY > /etc/wireguard/serverprivatekey
echo $CLIENT_PUBLIC_KEY > /etc/wireguard/clientpublickey
echo $CLIENT_PRESHARED_KEY > /etc/wireguard/clientpresharedkey

# Retrieve the default network interface
INTERFACE=$(ip route list default | awk '{print $5}')

# Create and write VPN configuration
cat <<EOF > /etc/wireguard/wg0.conf
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PostUp = wg set wg0 private-key /etc/wireguard/serverprivatekey
PostUp = iptables -A INPUT -i wg0 -j DROP; iptables -A INPUT -i wg0 -s 10.0.0.2 -j ACCEPT
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $INTERFACE -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $INTERFACE -j MASQUERADE

[Peer]
PublicKey =$(cat /etc/wireguard/clientpublickey)   
PresharedKey = $(cat /etc/wireguard/clientpresharedkey)
AllowedIPs = 10.0.0.2/32
EOF

# Enable IP forwarding in the system configuration
echo "net.ipv4.ip_forward = 1" | tee -a /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

# Start and enable the WireGuard service to run on boot
systemctl start wg-quick@wg0
systemctl enable wg-quick@wg0