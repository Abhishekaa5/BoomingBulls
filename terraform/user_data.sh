#!/bin/bash
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user

# Install CloudWatch Agent
sudo yum install -y amazon-cloudwatch-agent
