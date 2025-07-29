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

  peer_vpcs = {
    "eu-west-2"    = "10.1.0.0/16"
    "eu-west-3"    = "10.2.0.0/16"
    "eu-south-1"   = "10.3.0.0/16"
    "eu-south-2"   = "10.4.0.0/16"
    "eu-north-1"   = "10.5.0.0/16"
    "eu-central-1" = "10.6.0.0/16"
    "eu-central-2" = "10.7.0.0/16"
  }
}

provider "aws" {
  region = "eu-west-1"

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
  for_each = local.peer_vpcs

  region     = each.key
  cidr_block = each.value
}

# Requester's side of the connection.
resource "aws_vpc_peering_connection" "main" {
  for_each = local.peer_vpcs

  vpc_id      = aws_vpc.main.id
  peer_vpc_id = aws_vpc.peer[each.key].id
  peer_region = aws_vpc.peer[each.key].region
  auto_accept = false
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "peer" {
  for_each = local.peer_vpcs
  region   = each.key

  vpc_peering_connection_id = aws_vpc_peering_connection.main[each.key].id
  auto_accept               = true
}




# Migrate resources associated with our simple example with moved{} blocks
moved {
  from = aws_vpc.peer
  to   = aws_vpc.peer["eu-west-2"]
}
moved {
  from = aws_vpc_peering_connection.main
  to   = aws_vpc_peering_connection.main["eu-west-2"]
}
moved {
  from = aws_vpc_peering_connection_accepter.peer
  to   = aws_vpc_peering_connection_accepter.peer["eu-west-2"]
}
