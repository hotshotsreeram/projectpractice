provider "aws" {
  region  = "us-east-1"
}

resource "aws_vpc" "QA_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "QA_vpc"
  }
}

resource "aws_subnet" "QA_public_subnet" {
  vpc_id            = aws_vpc.QA_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "QA Public Subnet"
  }
}

resource "aws_subnet" "QA_private_subnet" {
  vpc_id            = aws_vpc.QA_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "QA Private Subnet"
  }
}

resource "aws_internet_gateway" "QA_ig" {
  vpc_id = aws_vpc.QA_vpc.id

  tags = {
    Name = "Some Internet Gateway"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.QA_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.QA_ig.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.QA_ig.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "public_1_rt_a" {
  subnet_id      = aws_subnet.QA_public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "web_sg" {
  name   = "HTTP and SSH"
  vpc_id = aws_vpc.QA_vpc.id

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
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_instance" {
  ami           = "ami-052efd3df9dad4825"
  instance_type = "t2.nano"
  key_name      = "My_practice"

  subnet_id                   = aws_subnet.QA_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
  #!/bin/bash -ex
  
  sudo apt-get update
  sudo apt install nginx -y
  echo "<h1>$(curl https://api.QA.rest/?format=text)</h1>" >  /usr/share/nginx/html/index.html 
  systemctl enable nginx
  systemctl start nginx
  EOF

  tags = {
    "Name" : "QA"
  }
}
