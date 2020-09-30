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
  template = file("${path.module}/templates/startup-ec2.tpl.sh")
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
  ami                         = data.aws_ami.ubuntu-1604.id
  instance_type               = "t3.medium"
  key_name                    = aws_key_pair.ec2.id
  user_data                   = data.template_file.startup.rendered
  associate_public_ip_address = true
  
  subnet_id                   = element(aws_subnet.public.*.id, 0)
  vpc_security_group_ids      = [aws_security_group.ec2.id]

  connection {
    user        = "ubuntu"
    private_key = var.private_key
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
       "sudo mkdir ~/paragon",
       "sudo chmod 777 ~/paragon"
    ]
  }

  tags = {
    Name                  = "${var.environment}-${var.app_name}-ec2"
    Environment           = var.environment
    Terraform             = "true"
  }
}

resource "null_resource" "provisioner_container" {
  triggers = {
    always_run = "${timestamp()}"
  }

  connection {
    user        = "ubuntu"
    private_key = var.private_key
    host        = aws_instance.ec2.public_ip
  }

  provisioner "file" {
    source      = "../../"
    destination = "~/paragon"
  }

  depends_on = [aws_instance.ec2]
}