# WireGuard VPN Server on AWS with Terraform

This project provides an automated setup for deploying a WireGuard VPN server on an EC2 instance running Amazon Linux 2023 using Terraform. This guide will walk you through the process of deploying the VPN server and connecting a single client, with instructions on how to add more clients if needed.

## Sumary

- [Requirements](#requirements)
- [Getting Started](#getting-started)
  - [Environment Variables](#1-environment-variables)
  - [Infrastructure Overview](#2-infrastructure-overview)
  - [Deployment](#3-deployment)
    - [Running Locally](#running-locally)
    - [Running with GitHub Actions](#running-with-github-actions)
    - [Connecting Your Device to the VPN](#connecting-your-device-to-the-vpn)
  - [VPN Configuration](#4-vpn-configuration)
  - [Connecting Additional Clients](#5-connecting-additional-clients)
  - [Remote State with S3](#6-remote-state-with-s3)
- [Troubleshooting](#troubleshooting)
- [Disclaimer](#disclaimer)

## Requirements

- AWS account with permissions to manage EC2, S3, and VPC resources.
- SSH key pair for connecting to the EC2 instance.
- Terraform installed on your local machine or a CI/CD pipeline.
- `wg` (WireGuard) tool installed locally for key generation.


## Getting Started

### 1. Environment Variables

The following environment variables need to be set before running `terraform apply`:

- `SERVER_PRIVATE_KEY`: (required) Private key of the WireGuard server.
- `CLIENT_PUBLIC_KEY`: (required) Public key of the client connecting to the VPN.
- `CLIENT_PRESHARED_KEY`: (required) Preshared key for extra encryption between the server and client.
- `VPN_PUBLIC_KEYPAIR`: (required) SSH public key for EC2 instance access.
- `EC2_TYPE`: (required) EC2 instance type (default: `t4g.nano` for a low-cost option).
- `EC2_AV_ZONE`: (required) Availability zone for the EC2 instance (example: `us-east-1a`).
- `VPN_ZONE`: (required) AWS region for the VPN (example: `us-east-1`).

Obs: For the CI/CD pipeline, ensure that these environment variables are set as secrets in GitHub Actions.

##### Key Generation Commands

To generate the necessary keys for WireGuard, run the following commands:

```bash
# Server Private Key
wg genkey | tee server_private.key | wg pubkey > server_public.key

# Client Public and Private Keys
wg genkey | tee client_private.key | wg pubkey > client_public.key

# Preshared Key for Extra Security
wg genpsk | tee client_preshared.key

For SSH access to the EC2 instance, generate the public key pair with:
ssh-keygen -t rsa -b 2048 -f /aws_ec2_key.pem
```

### 2. Infrastructure Overview

The Terraform configuration will create the following AWS architecture:

![AWS diagram](/img/aws-diagram.jpg)

### 3. Deployment

##### Running Locally


To deploy the infrastructure from local machine, ensure you have the required environment variables set in a `/terraform/terraform.tfvars` file and Terraform and AWS CLI installed.
`terraform.tfvars` exemple:
````
SERVER_PRIVATE_KEY   = "<your-server-privete-key>"
CLIENT_PUBLIC_KEY    = "<your-client-public-key>"
CLIENT_PRESHARED_KEY = "<your-client-preshared-key>"
VPN_PUBLIC_KEYPAIR   = "<your-SSH-public-key>"
EC2_TYPE             = "t4g.nano"
EC2_AV_ZONE          = "us-east-1a"
VPN_ZONE             = "us-east-1"
````

If you wish to remove the remote state backend for local deployment, remove the following block from `/terraform/main.tf`:
````
backend "s3" {
    bucket  = "tf-remote-state-vpn"
    key     = "state/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
````
Them inside `/terraform/` run:
````
terraform init && terraform apply -auto-approve
````

##### Running with GitHub Actions
To automate the deployment with GitHub Actions, the following additional environment variables need to be set for the CI/CD pipeline:

- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY

The user behind these credentials should have the following policies attached:

- `AmazonEC2FullAccess`
- `AmazonS3FullAccess`

Obs: Is required to follow the [Remote State with S3](#6-remote-state-with-s3) step to deploy with git actions

##### Connecting Your Device to the VPN

After successfully deploying the VPN server, follow these steps to connect your client device:

1. Retrieve the EC2 Public IP: 
   - Go to the AWS Management Console.
   - Navigate to EC2 Dashboard and locate the instance you just deployed.
   - Copy the `Public IPv4 address` of the EC2 instance.

2. Configure Your Client:
   - Open your WireGuard client application (on your device).
   - In the `[Peer]` the `Endpoint` field, paste the public IP address followed by `:51820` (which is the default port for WireGuard).

Example:

If the public IP of your EC2 instance is `54.123.45.67`, set the endpoint in your client as:
`54.123.45.67:51820`


Now, your device should be able to connect to the VPN.


### 4. VPN Configuration

The WireGuard configuration is automatically generated in the `/etc/wireguard/wg0.conf` file during the EC2 instance deployment.

The configuration file is created by the `/scripts/wireguard-installer.sh` script, which is executed when you launch the instance. If you need to customize the VPN settings to meet your specific requirements, you should modify the `scripts/wireguard-installer.sh` file before launch the instance with terraform.

### 5. Connecting Additional Clients
If you want to add more clients after the VPN is running, you need to SSH into the EC2 instance and modify the /etc/wireguard/wg0.conf file. Add a new [Peer] section with the new client's PublicKey, PresharedKey, and AllowedIPs configuration.

Alternatively, if you're modifying the configuration before deploying the server, you can add the new client directly in the wireguard-installer.sh file under the # Create and write VPN configuration section.

### 6. Remote State with S3

If using GitHub Actions or a remote state for Terraform when deploy locally, ensure you have created an S3 bucket with versioning and access control configured. You can run `terraform apply -auto-approve` for the example configuration bellow:

````
resource "aws_s3_bucket" "tf-remote-state" {
  bucket = "tf-remote-state-vpn" # Change the bucket name

  tags = {
    Name        = "Terraform Remote State"
    Environment = "Prod"
  }
}

resource "aws_s3_bucket_acl" "tf-s3-acl" {
  bucket = aws_s3_bucket.tf-remote-state.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.tf-remote-state.id
  versioning_configuration {
    status = "Enabled"
  }
}
````

And the `main.tf`file will look like this:
````
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "tf-remote-state-vpn" # same bucket as aws_s3_bucket.tf-remote-state
    key     = "state/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.VPN_ZONE
}
````

## Troubleshooting
### Common Issues

- Client Unable to Connect to the Internet: Ensure that the `Address` specified in the `[Interface]` section of `/etc/wireguard/wg0.conf` is within the range of the CIDR block of your subnet. If the address is not within this range, the client may connect to the VPN but not access the internet. For example, if your subnet CIDR block is `10.0.0.0/24`, the VPN address should be within this range, such as `10.0.0.2/32`.

- Invalid Key Configuration: Double-check that all keys (server private key, client public key, and preshared key) are correctly generated and applied. Misconfigured or incorrect keys can prevent successful VPN connections.

## Disclaimer

This project was created solely for personal use and educational purposes. I do not recommend or endorse its use for commercial or enterprise environments. If you choose to deploy this project in such environments, you do so at your own risk.

