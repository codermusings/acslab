locals {
  default_tags = merge(var.default_tags, { "env" = var.env })
  name_prefix  = "${var.prefix}-${var.env}"
}

provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "terraform_remote_state" "remote_network_state" {
  backend = "s3"
  config = {
    bucket = "sanahbucket"
    key    = "dev/network/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "ec2_instance" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = lookup(var.instance_type, var.env)
  key_name                    = aws_key_pair.rsa_key.key_name
  subnet_id                   = data.terraform_remote_state.remote_network_state.outputs.subnet_ids[0]
  security_groups             = [aws_security_group.security_group_rules.id]
  associate_public_ip_address = true
  user_data = templatefile("~/environment/webserver/install_httpd.sh.tpl", {
    prefix = var.prefix,
    env    = var.env
  })
  root_block_device {
    encrypted = var.env == "prod" ? true : false
  }
  tags = merge(local.default_tags, { "Name" = "${var.prefix}-EC2-Machine" })
}

resource "aws_eip" "static_eip" {
  instance = aws_instance.ec2_instance.id
  tags = merge(local.default_tags,
    {
      "Name" = "${var.prefix}-eip"
    }
  )
}

resource "aws_ebs_volume" "ebs_volume" {
  count             = var.env == "prod" ? 1 : 0
  availability_zone = data.aws_availability_zones.available.names[1]
  size              = 40
  tags = merge(
    var.default_tags,
    {
      "Name" = "${var.prefix}-EBS"
    }
  )
}

resource "aws_volume_attachment" "ebs_att" {
  count       = var.env == "prod" ? 1 : 0
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebs_volume[count.index].id
  instance_id = aws_instance.ec2_instance.id
}

resource "aws_key_pair" "rsa_key" {
  key_name   = "${var.env}-sanahkey"
  public_key = file("~/environment/webserver/${var.prefix}key.pub")
}

resource "aws_security_group" "security_group_rules" {
  name        = "allow_http_ssh"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = data.terraform_remote_state.remote_network_state.outputs.vpc_id
  ingress {
    description      = "HTTP from everywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "SSH from everywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = merge(local.default_tags, { "Name" = "${var.prefix}-SG" })
}

