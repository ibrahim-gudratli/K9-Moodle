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

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.moodle.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-north-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "moodle-public-2"
  }
}

resource "aws_internet_gateway" "moodle" {
  vpc_id = aws_vpc.moodle.id

  tags = {
    Name = "moodle-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.moodle.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.moodle.id
  }

  tags = {
    Name = "moodle-public-rt"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.moodle.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-north-1a"

  tags = {
    Name = "moodle-private-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.moodle.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-north-1b"

  tags = {
    Name = "moodle-private-2"
  }
}

resource "aws_security_group" "alb" {
  name        = "moodle-alb-sg"
  description = "Security group for Moodle Application Load Balancer"
  vpc_id      = aws_vpc.moodle.id

  tags = {
    Name = "moodle-alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "10.0.0.0/16"
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"
}

resource "aws_security_group" "ecs" {
  name        = "moodle-ecs-sg"
  description = "Security group for Moodle ECS containers"
  vpc_id      = aws_vpc.moodle.id

  tags = {
    Name = "moodle-ecs-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
}

resource "aws_security_group" "rds" {
  name        = "moodle-rds-sg"
  description = "Security group for Moodle PostgreSQL database"
  vpc_id      = aws_vpc.moodle.id

  tags = {
    Name = "moodle-rds-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_ecs" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_rds" {
  security_group_id            = aws_security_group.ecs.id
  referenced_security_group_id = aws_security_group.rds.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}