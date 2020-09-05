variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "region" {
  default = "ap-northeast-1"
}

terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "kuroseets"

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

resource "aws_vpc" "test" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "test"
  }
}

resource "aws_subnet" "test_subnet" {
  vpc_id            = aws_vpc.test.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "test-a"
  }
}

resource "aws_subnet" "test_subnet2" {
  vpc_id            = aws_vpc.test.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "test-c"
  }
}
