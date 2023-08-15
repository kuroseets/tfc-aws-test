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
variable "test_security_groups" {
  default = [
    "test1",
    "test2"
  ]
}


terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "exnoa-pf-kurose"

    workspaces {
      name = "tfc-aws-test"
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

output "random_sample" {
  description = "random string test"
  value       = random_id.sample.b64_std
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

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.test.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.test.cidr_block]
  }

  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.test.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_security_group" "allow_tls2" {
  name        = "allow_tls2"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.test.id

  dynamic "ingress" {
    for_each = [443, 80]
    content {
      description      = "TLS from VPC"
      from_port        = ingress.value
      to_port          = ingress.value
      protocol         = "tcp"
      cidr_blocks      = [aws_vpc.test.cidr_block]
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "random_id" "sample" {
  byte_length = 4
}

resource "aws_security_group" "allow_loop_test" {
  count = length(var.test_security_groups)

  name        = var.test_security_groups[count.index]
  description = "Loop Test Security Group"
  vpc_id      = aws_vpc.test.id
}

resource "aws_security_group_rule" "egress_test" {
  count = length(var.test_security_groups)

  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  security_group_id = aws_security_group.allow_loop_test[count.index].id
}

resource "aws_security_group_rule" "ingress_test" {
  count = length(var.test_security_groups)

  type              = "ingress"
  to_port           = 0
  protocol          = "-1"
  self              = true
  from_port         = 0
  security_group_id = aws_security_group.allow_loop_test[count.index].id
}

resource "aws_s3_bucket" "bucket_test1" {
  bucket = "exnoa-pf-kurose-test-bucket1"

  versioning {
    enabled = false
  }
}

resource "aws_s3_bucket" "bucket_test2" {
  bucket = "exnoa-pf-kurose-test-bucket2"
}

resource "aws_s3_bucket_versioning" "bucket_test2_versioning" {
  bucket = aws_s3_bucket.bucket_test2.id

  versioning_configuration {
    status = "Disabled"
  }
}

resource "null_resource" "release_lock" {
  triggers = {
    name = "null_resource_sample"
  }

  provisioner "local-exec" {
    command = "ls"
  }

  depends_on = [
    aws_s3_bucket.bucket_test1
  ]
}

resource "terraform_data" "release_lock" {
  triggers_replace = {
    name = "null_resource_sample"
  }

  provisioner "local-exec" {
    command = "ls"
  }

  depends_on = [
    aws_s3_bucket.bucket_test1
  ]
}

