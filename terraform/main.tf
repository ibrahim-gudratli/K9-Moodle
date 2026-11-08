resource "aws_vpc" "moodle" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.moodle.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "moodle-public-1"
  }
}