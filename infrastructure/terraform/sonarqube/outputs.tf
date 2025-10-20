output "sonarqube_url" {
  description = "SonarQube server URL"
  value       = "http://${aws_eip.sonarqube.public_ip}:9000"
}

output "sonarqube_public_ip" {
  description = "SonarQube public IP"
  value       = aws_eip.sonarqube.public_ip
}

output "sonarqube_instance_id" {
  description = "SonarQube EC2 instance ID"
  value       = aws_instance.sonarqube.id
}

output "sonarqube_ssh_command" {
  description = "SSH command to connect to SonarQube"
  value       = "ssh ec2-user@${aws_eip.sonarqube.public_ip}"
}

output "default_credentials" {
  description = "Default SonarQube credentials"
  value       = "Username: admin | Password: admin (change on first login)"
}
