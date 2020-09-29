output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet" {
  value = aws_subnet.public
}

output "private_subnet" {
  value = aws_subnet.private
}

output "bastions" {
  value = {
    public_ips  = aws_eip.bastion.*.public_ip
    keys        = aws_key_pair.bastion.*.key_name
  }
}

output "security_groups" {
  value = {
    bastion = aws_security_group.bastion
  }
}