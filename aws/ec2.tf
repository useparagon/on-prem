data "template_file" "startup" {
  template = file("${path.module}/templates/startup-ec2.tpl.sh")
}

resource "aws_key_pair" "ec2" {
  key_name      = "${var.environment}-${var.app_name}-ec2-key"
  public_key    = var.public_key

  tags          = merge(local.default_tags, {
    Name        = "${var.environment}-${var.app_name}-ec2-keypair"
  })
}

resource "aws_instance" "ec2" {
  for_each                    = local.ec2s
  ami                         = "ami-0739f8cdb239fe9ae"
  instance_type               = var.ec2_instance_type
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

  tags                    = merge(local.default_tags, {
    Name                  = "${var.environment}-${var.app_name}-ec2-${each.key}"
  })
}

resource "null_resource" "install" {
  for_each                    = local.ec2s

  triggers = {
    run_once = "2021-01-01"
  }

  connection {
    user        = "ubuntu"
    private_key = var.private_key
    host        = element(values(aws_instance.ec2).*.public_ip, index(keys(local.ec2s), each.key))
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y redis-tools",
      "sudo apt-get install -y docker.io",
      "sudo -E curl -L https://github.com/docker/compose/releases/download/1.27.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "sudo groupadd docker",
      "sudo usermod -aG docker $USER",
      "sudo chmod 666 /var/run/docker.sock",
      "sudo apt-get -y install postgresql postgresql-contrib"
    ]
  }

  depends_on = [aws_instance.ec2]
}

resource "null_resource" "update" {
  for_each                    = local.ec2s

  triggers = {
    run_always = "${timestamp()}"
  }

  connection {
    user        = "ubuntu"
    private_key = var.private_key
    host        = element(values(aws_instance.ec2).*.public_ip, index(keys(local.ec2s), each.key))
  }

  provisioner "file" {
    source      = "../../"
    destination = "~/paragon"
  }

  provisioner "remote-exec" {
    inline = flatten([
      "cd ~/paragon",
      "chmod 777 scripts/build.sh",
      "chmod 777 scripts/setup.sh",
      "chmod 777 scripts/start.sh",
      "chmod 777 scripts/stop.sh",
      flatten([
        for microservice in each.value : [
          "scripts/stop.sh -s ${microservice}"
        ]
      ]),
      flatten([
        for microservice in each.value : [
          "scripts/start.sh -d -s ${microservice}"
        ]
      ])
    ])
  }

  depends_on = [aws_instance.ec2, null_resource.install]
}