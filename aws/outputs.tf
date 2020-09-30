output "albs" { 
  value = {
    for key, value in aws_alb.microservice:
    key => value.dns_name
  }
}

output "ec2" {
  value = {
    public_dns  = aws_eip.ec2.public_dns
    public_ip   = aws_eip.ec2.public_ip
    keys        = aws_key_pair.ec2.key_name
  }
}

output "workflows_s3_bucket" {
  value = aws_s3_bucket.workflows.id
}