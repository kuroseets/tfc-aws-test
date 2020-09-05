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
      name = "ec2-test"
    }
  }
}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

data "aws_vpc" "test" {
  tags = {
    Name = "test"
  }
}

data "aws_subnet" "test_subnet" {
  vpc_id = data.aws_vpc.test.id

  tags = {
    Name = "test-a"
  }
}

#resource "aws_instance" "test-ec2-1" {
#  ami           = "ami-0053d11f74e9e7f52"
#  instance_type = "t3.micro"
#  subnet_id     = data.aws_subnet.test_subnet.id
#  tags = {
#    Name = "test-ec2-1"
#  }
#}

#resource "aws_instance" "test-ec2-2" {
#  ami           = "ami-0053d11f74e9e7f52"
#  instance_type = "t3.micro"
#  subnet_id     = data.aws_subnet.test_subnet.id
#  tags = {
#    Name = "test-ec2-2"
#  }
#}
