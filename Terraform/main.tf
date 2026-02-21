provider "aws" {
  region = var.region
}

# VPC
resource "aws_vpc" "boomibulls_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Public Subnet
resource "aws_subnet" "boomibulls_public" {
  vpc_id                  = aws_vpc.boomibulls_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# Internet Gateway
resource "aws_internet_gateway" "boomibulls_gw" {
  vpc_id = aws_vpc.boomibulls_vpc.id
}

# Route Table
resource "aws_route_table" "boomibulls_rt" {
  vpc_id = aws_vpc.boomibulls_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.boomibulls_gw.id
  }
}

resource "aws_route_table_association" "boomibulls_assoc" {
  subnet_id      = aws_subnet.boomibulls_public.id
  route_table_id = aws_route_table.boomibulls_rt.id
}

# Security Group
resource "aws_security_group" "boomibulls_sg" {
  vpc_id = aws_vpc.boomibulls_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}

# EC2 Instance
resource "aws_instance" "boomibulls_web" {
  ami           = "ami-0c55b159cbfafe1f0" # change per region
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.boomibulls_public.id
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.boomibulls_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.profile.name

  user_data = file("user_data.sh")

  tags = {
    Name = "boomibulls-web"
  }
}


# IAM Role for EC2 
resource "aws_iam_role" "ec2_role" {
  name = "ec2-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


resource "aws_iam_instance_profile" "profile" {
  name = "ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# ECR Repository
resource "aws_ecr_repository" "boomibulls_repo" {
  name = "boomibulls-app"
}