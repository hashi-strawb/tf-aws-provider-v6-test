terraform {
  cloud {
    organization = "fancycorp"
    workspaces {
      name = "aws-provider-v6-test"
    }
  }
}

locals {
  tags = {
    Name      = "StrawbTest - ${terraform.workspace}"
    Owner     = "lucy.davinhart@hashicorp.com"
    Purpose   = "AWS Provider v6 Testing"
    TTL       = "1h"
    Terraform = "true"
    Source    = "https://github.com/hashi-strawb/tf-aws-provider-v6-test"
    Workspace = terraform.workspace
  }
}

provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = local.tags
  }
}

provider "aws" {
  alias  = "peer"
  region = "eu-west-2"

  default_tags {
    tags = local.tags
  }
}

# Hub VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Spoke VPC
resource "aws_vpc" "peer" {
  # Need to use the other AWS provider here, to specify the region
  provider = aws.peer

  cidr_block = "10.1.0.0/16"
}

# Requester's side of the connection.
resource "aws_vpc_peering_connection" "main" {
  vpc_id      = aws_vpc.main.id
  peer_vpc_id = aws_vpc.peer.id
  peer_region = "eu-west-2"
  auto_accept = false
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "peer" {
  # Need to use the other AWS provider here, to specify the region
  provider = aws.peer

  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
  auto_accept               = true
}
