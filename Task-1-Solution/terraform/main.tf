terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.79.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_instance" "devops_project_instance" {
  ami= terraform.workspace != "default" ? lookup(var.myami, terraform.workspace) : data.aws_ami.al2023.id
  instance_type = var.ec2_type
  count = var.num_of_instance
  iam_instance_profile = "devops-project-profile-techpro"
  key_name = var.ec2_key
  vpc_security_group_ids = [aws_security_group.devops-project-sgr.id]
  tags = {
    Project = "Devops-Project-Server"
    Name = "${terraform.workspace}_server"
  }
}
data "aws_ami" "al2023" {
  most_recent      = true
  owners           = ["amazon"]

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name = "architecture"
    values = ["x86_64"]
  }
  filter {
    name = "name"
    values = ["al2023-ami-2023*"]
  }
}

resource "aws_security_group" "devops-project-sgr" {
  name        = "${terraform.workspace}-Security-Group"
  description = "Devops Project Security Group"

  dynamic "ingress" {
    for_each = lookup(var.ports, terraform.workspace)
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"] 
    }
  }
  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}