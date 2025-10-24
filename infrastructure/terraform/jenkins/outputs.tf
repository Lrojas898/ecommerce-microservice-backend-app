output "jenkins_public_ip" {
  description = "Public IP of Jenkins server"
  value       = aws_eip.jenkins.public_ip
}

output "jenkins_url" {
  description = "URL to access Jenkins"
  value       = "http://${aws_eip.jenkins.public_ip}:8080"
}

output "jenkins_instance_id" {
  description = "Instance ID of Jenkins server"
  value       = aws_instance.jenkins.id
}

output "jenkins_ssh_command" {
  description = "SSH command to connect to Jenkins"
  value       = "ssh ec2-user@${aws_eip.jenkins.public_ip}"
}

output "get_jenkins_password_command" {
  description = "Command to get Jenkins initial password"
  value       = "ssh ec2-user@${aws_eip.jenkins.public_ip} 'cat /home/ec2-user/jenkins-password.txt'"
}

# Jenkins Agent Outputs
output "jenkins_agent_public_ip" {
  description = "Public IP of Jenkins agent"
  value       = aws_eip.jenkins_agent.public_ip
}

output "jenkins_agent_instance_id" {
  description = "Instance ID of Jenkins agent"
  value       = aws_instance.jenkins_agent.id
}

output "jenkins_agent_ssh_command" {
  description = "SSH command to connect to Jenkins agent"
  value       = "ssh ec2-user@${aws_eip.jenkins_agent.public_ip}"
}
