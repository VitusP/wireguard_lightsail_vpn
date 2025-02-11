# WireGuard VPN on AWS Lightsail

This project provides a simple setup for deploying a WireGuard VPN server on an AWS Lightsail instance running Ubuntu. WireGuard is a modern, fast, and secure VPN solution.

## Table of Contents

- [WireGuard VPN on AWS Lightsail](#wireguard-vpn-on-aws-lightsail)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Configuration](#configuration)
  - [Usage](#usage)
  - [Testing the VPN](#testing-the-vpn)
  - [License](#license)

## Prerequisites

Before you begin, ensure you have the following:

- An AWS account with access to Lightsail.
- AWS CLI installed and configured on your local machine.
- SSH key pair generated (public and private keys).
- Basic knowledge of shell scripting and command line usage.

## Installation

1. **Clone the repository** (if applicable):
   ```bash
   git clone <repository-url>
   cd <repository-directory>
   ```

2. **Create a Lightsail VM**:
   Use the `create_lightsail_vm.sh` script to create a new Lightsail instance. You need to provide a machine name and region as arguments:
   ```bash
   chmod +x create_lightsail_vm.sh
   ./create_lightsail_vm.sh <MACHINENAME> <REGION>
   ```

3. **Set Up WireGuard**:
   After the instance is created, run the `setup_wireguard_lightsail_ubuntu.sh` script to install and configure WireGuard on the instance:
   ```bash
   chmod +x setup_wireguard_lightsail_ubuntu.sh
   ./setup_wireguard_lightsail_ubuntu.sh SERVER_IP
   ```

## Configuration

- The WireGuard configuration file is located at `/etc/wireguard/wg0.conf` on the server.
- You will need to replace the peer public key in the `setup_wireguard_lightsail_ubuntu.sh` script with the actual public key from your WireGuard client.

## Usage

- To connect to the VPN, you will need to create a client configuration file. A sample client configuration is generated at the end of the `setup_wireguard_lightsail_ubuntu.sh` script.
- Save the generated client configuration as `wg0.conf` on your client device and use the WireGuard client to connect.

## Testing the VPN

To verify that your WireGuard VPN is working correctly:

1. **Check the WireGuard Service**:
   Ensure that the WireGuard service is running on your server:
   ```bash
   sudo systemctl status wg-quick@wg0
   ```

2. **Check Your Public IP Address**:
   After connecting to the VPN, check your public IP address to see if it has changed to the IP address of your WireGuard server:
   ```bash
   curl ifconfig.me
   ```

3. **Test Connectivity**:
   You can also test connectivity to a service or website that is only accessible from your server.

4. **Check for DNS Leaks**:
   Use a DNS leak test website (like [dnsleaktest.com](https://www.dnsleaktest.com/)) to verify that your DNS requests are being resolved by the DNS servers specified in your WireGuard configuration.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
