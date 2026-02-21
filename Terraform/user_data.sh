#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
usermod -aG docker ec2-user

# Install CloudWatch Agent
yum install -y amazon-cloudwatch-agent