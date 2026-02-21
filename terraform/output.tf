output "public_ip" {
  value = aws_instance.boomibulls_web.public_ip
}

output "ecr_url" {
  value = aws_ecr_repository.boomibulls_repo.repository_url
}