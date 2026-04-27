#Outputs
output "instance_a_public_ip" {
  description = "Public IP of Instance A (Bastion + Frontend)"
  value       = aws_instance.instance_a.public_ip
}

output "instance_b_private_ip" {
  description = "Private IP of Instance B (Redis + Worker)"
  value       = aws_instance.instance_b.private_ip
}

output "instance_c_private_ip" {
  description = "Private IP of Instance C (PostgreSQL)"
  value       = aws_instance.instance_c.private_ip
}