variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "region" {
  default = "ap-northeast-1"
}
variable "availability_zone_list" {
  default = [
    "ap-northeast-1a",
    "ap-northeast-1c",
    "ap-northeast-1d"
  ]
}

terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "exnoa-pf-kurose"

    workspaces {
      name = "vpc-test"
    }
  }
}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

output "account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.account.id
}

data "aws_caller_identity" "account" {}

resource "aws_vpc" "test" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "test"
  }
}

resource "aws_subnet" "test_subnet" {
  for_each = {for i, j in var.availability_zone_list : i => j} #toset(var.availability_zone_list)

  vpc_id            = aws_vpc.test.id
  cidr_block        = cidrsubnet("10.0.0.0/16", 8, each.key)
  availability_zone = each.value

  tags = {
    Name = each.value
  }
}
