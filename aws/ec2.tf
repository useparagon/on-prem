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
  ami                         = "ami-0739f8cdb239fe9ae"
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

resource "null_resource" "install" {
  triggers = {
    run_once = "2021-01-01"
  }

  connection {
    user        = "ubuntu"
    private_key = var.private_key
    host        = aws_instance.ec2.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y redis-tools",
      "sudo apt install docker.io=18.09.7-0ubuntu1~16.04.6",
      "sudo -E curl -L https://github.com/docker/compose/releases/download/1.27.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "sudo usermod -aG docker $USER",
      "sudo apt-get install postgresql postgresql-contrib"
    ]
  }

  depends_on = [aws_instance.ec2]
}

resource "null_resource" "update" {
  triggers = {
    run_always = "${timestamp()}"
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

  provisioner "remote-exec" {
    inline = [
       "chmod 777 ~/paragon/scripts/build.sh",
       "chmod 777 ~/paragon/scripts/setup.sh",
       "chmod 777 ~/paragon/scripts/start.sh",
       "chmod 777 ~/paragon/scripts/stop.sh",
       "~/paragon/scripts/stop.sh",
       "~/paragon/scripts/start.sh -d",
    ]
  }

  depends_on = [aws_instance.ec2, null_resource.install]
}