#VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "voting-app-vpc-nata"
  }
}
#SUBNETS
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-nata"
  }
}
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-subnet-nata"
  }
}
#ROUTE TABLE
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt-nata"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
#IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "voting-app-igw-nata"
  }
}
#SECURITY GROUP for Instance A (Vote + Result) - public facing
resource "aws_security_group" "vote_result_sg" {
  name        = "vote-result-sg-nata"
  description = "Allow HTTP/HTTPS from internet and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Vote app port"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Result app port"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vote-result-sg-nata"
  }
}
#SECURITY GROUP for Instance B (Redis + Worker) - private
resource "aws_security_group" "redis_worker_sg" {
  name        = "redis-worker-sg-nata"
  description = "Allow Redis from Vote/Result SG and SSH from public"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Redis"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.vote_result_sg.id]
  }

  ingress {
    description     = "SSH from Instance A"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.vote_result_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "redis-worker-sg-nata"
  }
}
# SECURITY GROUP for Instance C (PostgreSQL) - private
resource "aws_security_group" "postgres_sg" {
  name        = "postgres-sg-nata"
  description = "Allow PostgreSQL from Worker SG only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from Worker"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.redis_worker_sg.id]
  }

  ingress {
    description     = "PostgreSQL from Result"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.vote_result_sg.id]
  }

  ingress {
    description     = "SSH from Instance A"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.vote_result_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "postgres-sg-nata"
  }
}

# Instance A - Frontend (public subnet) + Bastion Host
resource "aws_instance" "instance_a" {
  ami                    = "ami-098e39bafa7e7303d"  
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.vote_result_sg.id]
  key_name               = "nata_ed"    

  tags = {
    Name = "instance-a-frontend-nata"
  }
}

# Instance B - Redis + Worker (private subnet)
resource "aws_instance" "instance_b" {
  ami                    = "ami-098e39bafa7e7303d" 
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.redis_worker_sg.id]
  key_name               = "nata_ed"    

  tags = {
    Name = "instance-b-backend-nata"
  }
}

# Instance C - PostgreSQL (private subnet)
resource "aws_instance" "instance_c" {
  ami                    = "ami-098e39bafa7e7303d"  
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.postgres_sg.id]
  key_name               = "nata_ed"     

  tags = {
    Name = "instance-c-database-nata"
  }
}
# ELASTIC IP for NAT GATEWAY
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "nat-eip-nata"
  }
}
# NAT GATEWAY (in public subnet)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "voting-app-nat-nata"
  }

  depends_on = [aws_internet_gateway.igw]
}
# PRIVATE ROUTE TABLE (routes traffic to NAT)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-rt-nata"
  }
}
# Associate private route table with private subnet
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}