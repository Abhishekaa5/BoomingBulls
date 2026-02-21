#!/bin/bash
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user
sudo yum install -y aws-cli
# Install CloudWatch Agent
sudo yum install -y amazon-cloudwatch-agent
