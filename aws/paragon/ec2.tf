# Get the list of official Canonical Ubuntu 16.04 AMIs
data "aws_ami" "ubuntu-1604" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "template_file" "startup" {
  template = file("${path.module}/../templates/startup-ec2.tpl.sh")
}

resource "aws_key_pair" "ec2" {
  key_name      = "${var.environment}-${var.app_name}-ec2-key"
  public_key    = var.public_key

  tags = {
    Name        = "${var.environment}-${var.app_name}-ec2-keypair"
    Environment = var.environment
    Terraform   = "true"
  }
}

resource "aws_instance" "ec2" {
  ami                     = data.aws_ami.ubuntu-1604.id
  instance_type           = "c6g.large"
  key_name                = element(aws_key_pair.bastion.*.id, count.index)
  user_data               = data.template_file.startup.rendered

  subnet_id               = element(aws_subnet.public.*.id, count.index)
  vpc_security_group_ids  = [aws_security_group.bastion.id]

  tags = {
    Name                  = "${var.environment}-${var.app_name}-ec2"
    Environment           = var.environment
    Terraform             = "true"
  }
}