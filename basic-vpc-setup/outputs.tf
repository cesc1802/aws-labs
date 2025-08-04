output "ec2_instance_public_ip" {
  value = aws_instance.public_instance.public_ip
}

output "ec2_instance_private_ip" {
  value = aws_instance.private_instance.private_ip
}

output "ssh_private_key" {
  description = "ssh private key dev env"
  value       = module.key_pair.private_key_pem
  sensitive = true
}