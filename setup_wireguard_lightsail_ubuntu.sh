#!/bin/zsh
# ssh and configure wireguard
EXTERNALIP=$1
ssh -i ~/.ssh/id_rsa ubuntu@$EXTERNALIP "bash -s" <<'ENDSSH'
# Update and install wireguard
sudo apt update -y && sudo apt install wireguard -y

# Switch to root and setup wireguard
sudo -i

# Create wireguard directory and set permissions
mkdir -m 0700 /etc/wireguard/
cd /etc/wireguard/
umask 077; wg genkey | tee privatekey | wg pubkey > publickey

# Get the correct interface name (for Lightsail, usually ens5)
ETHINT=$(ip route | grep default | awk '{print $5}')
SRVRIP="10.99.99.1"
ALLOWEDIPS_MAC="10.99.99.0/24"
ALLOWEDIPS_IPHONE="10.99.99.2/24"
PEERPUBKEY_MAC='p2/52akk8elscUXNe2FEtKbf37QS1zUF8Sshz6KWnnc='
PEERPUBKEY_IPHONE='tUcSPou6KX6xTX59/4kth5zWBXECc7MT15LnsBg+fxg='


# Create WireGuard configuration
tee /etc/wireguard/wg0.conf <<EOF
[Interface]
Address = $SRVRIP/24
ListenPort = 41194
PrivateKey = $(cat privatekey)
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $ETHINT -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $ETHINT -j MASQUERADE

[Peer]
PublicKey = $PEERPUBKEY_MAC
AllowedIPs = $ALLOWEDIPS_MAC

[Peer]
PublicKey = $PEERPUBKEY_IPHONE
AllowedIPs = $ALLOWEDIPS_IPHONE
EOF

# Configure firewall
ufw allow 41194/udp
ufw allow ssh
ufw status

# Enable IP forwarding
echo 'net.ipv4.ip_forward=1' | tee /etc/sysctl.d/99-wireguard.conf
echo 'net.ipv6.conf.all.forwarding=1' | tee -a /etc/sysctl.d/99-wireguard.conf
sysctl -p /etc/sysctl.d/99-wireguard.conf

# Start WireGuard
# systemctl restart wg-quick@wg0 (restart)
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0
systemctl status wg-quick@wg0

# Show connection info
wg
ip a show wg0

# Display the public key for client setup
echo -e "\nSetup Complete. Server Public Key Below. Please use this in your client config:"
cat publickey

# Create a sample client config
echo -e "\nSample client configuration (save as wg0.conf on client):"
echo "
[Interface]
PrivateKey = <INSERT_CLIENT_PRIVATE_KEY>
Address = 10.99.99.2/24
DNS = 8.8.8.8, 8.8.4.4

[Peer]
PublicKey = $(cat publickey)
Endpoint = $HOSTNAME:41194
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
"
ENDSSH