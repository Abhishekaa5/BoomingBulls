# BoomingBulls - Online Trading & Investing Platform

A containerized Flask application deployed on AWS using Jenkins CI/CD pipeline and Terraform Infrastructure as Code.

## 📋 Project Overview

BoomingBulls is a modern trading and investing platform with automated deployment infrastructure. The application is containerized using Docker, deployed to AWS EC2 via AWS ECR, and orchestrated through a Jenkins CI/CD pipeline.

## ⚡ Quick Start

### For First-Time Infrastructure Deployment
1. Create EC2 keypair in AWS (`test`)
2. Configure AWS credentials in Jenkins
3. Set up GitHub webhook in Jenkins job
4. Run Jenkins pipeline → Answer **YES** to Terraform → Answer **YES** to Deploy

### For Code Updates (Redeployment)
```bash
git push origin main  # Push code to GitHub
# Pipeline triggers automatically via webhook
# Approve deployment prompts in Jenkins
```

---

## 🏗️ Architecture

```
Internet Browser (http://EC2_IP:80)
           ↓
    AWS EC2 Instance (t3.micro)
    - Security Group (Port 80, 22 open)
    - VPC (10.0.0.0/16)
           ↓
    Docker Container
    - Flask App (Port 5000)
    - Image from AWS ECR
           ↓
    AWS CloudWatch (Logging & Monitoring)
```

**Components:**
- **VPC**: Virtual Private Cloud with public subnet
- **EC2 Instance**: t3.micro running Docker
- **ECR**: Docker image registry
- **Jenkins**: CI/CD automation
- **CloudWatch**: Centralized logging
- **IAM Roles**: EC2 permissions for ECR access

---

## 🔧 Prerequisites

### On Your Local Machine
- Git
- AWS Account with credentials configured
- Jenkins Server with Docker installed

### AWS Requirements
- AWS Account with `ap-south-1` region access
- EC2 keypair created in `ap-south-1`
- IAM user/role with permissions for:
  - EC2
  - ECR
  - VPC & Security Groups
  - IAM Roles
  - CloudWatch

### Jenkins Requirements
- Jenkins server running
- AWS Credentials configured in Jenkins (Credential ID: `75554f9b-***-af2014f25797`)
- SSH key configured in Jenkins (Credential ID: `ec2-key`)
- Docker installed on Jenkins agent
- Plugins:
  - Pipeline
  - AWS Credentials
  - SSH Agent

---

## 📦 Project Structure

```
BoomingBulls/
├── Jenkinsfile                 # CI/CD Pipeline configuration
├── README.md                   # This file
├── app/
│   ├── app.py                  # Flask application
│   ├── Dockerfile              # Docker image configuration
│   └── templates/
│       └── index.html          # Frontend HTML
└── terraform/
    ├── main.tf                 # AWS infrastructure (VPC, EC2, ECR, IAM)
    ├── variables.tf            # Terraform variables
    ├── output.tf               # Terraform outputs
    ├── terraform.tfvars        # Variable values
    └── user_data.sh            # EC2 bootstrap script
```

---

## 🎯 CI/CD Deployment Workflow

### Overview

```
Developer pushes code to GitHub
         ↓
GitHub webhook notifies Jenkins
         ↓
Jenkins pipeline starts automatically
         ↓
Checkout code from GitHub repository
         ↓
Terraform Init & Approval Gate
         ↓
(Optional) Create/Update AWS Infrastructure
         ↓
Wait 60 seconds for EC2 initialization
         ↓
Deployment Approval Gate
         ↓
Build Docker image
         ↓
Push image to AWS ECR
         ↓
Deploy to EC2 via SSH
         ↓
Application live on http://EC2_IP:80
```

### Trigger Methods

#### 1. Automatic Trigger (Recommended)
- Developer pushes code to `main` branch
- GitHub webhook automatically notifies Jenkins
- Pipeline executes without manual intervention
- **Setup**: Configure GitHub webhook (see Infrastructure Deployment section)

#### 2. Manual Trigger
- Go to Jenkins Dashboard
- Click "Build Now" on the job
- Useful for testing or emergency deployments

### Approval Gates in Pipeline

The pipeline has two critical approval points:

| Stage | Prompt | Default | Action |
|-------|--------|---------|--------|
| **Terraform** | "Do you want to APPLY Terraform?" | NO | Creates/updates AWS infrastructure (VPC, EC2, ECR, IAM) |
| **Deployment** | "Do you want to DEPLOY to EC2?" | NO | Builds Docker image and deploys to EC2 |

**First Deployment**: Answer YES to both  
**Redeployment**: Answer NO to Terraform, YES to Deployment

---

## 🚀 Deployment Guide

### Step 1: Infrastructure Deployment (Terraform)

#### Prerequisites Setup
1. **Create EC2 Keypair** (if not already created):
   - Go to AWS EC2 Console → Keypairs
   - Create keypair named `test` in `ap-south-1` region
   - Download and save the `.pem` file securely

2. **Configure AWS Credentials**:
   ```bash
   # On your local machine or Jenkins server
   aws configure
   # Enter your AWS Access Key ID
   # Enter your AWS Secret Access Key
   # Default region: ap-south-1
   ```

3. **Fork/Clone the Repository**:
   ```bash
   git clone https://github.com/Abhishekaa5/BoomingBulls.git
   cd BoomingBulls
   ```

#### Deploy Infrastructure via Jenkins

1. **Open Jenkins Dashboard**
   - Navigate to `http://<jenkins-server>:8080`

2. **Create or Update Pipeline Job**
   - New Item → Pipeline
   - Name: `BoomingBulls-Deploy`
   - Pipeline → Definition: `Pipeline script from SCM`
   - SCM: Git
   - Repository URL: `https://github.com/Abhishekaa5/BoomingBulls.git`
   - Branch: `main`
   - Script Path: `Jenkinsfile`
   - **Build Triggers**: Enable `GitHub hook trigger for GITScm polling`

3. **Configure GitHub Webhook** (Optional - for automatic triggering)
   - Go to GitHub Repository Settings → Webhooks → Add webhook
   - Payload URL: `http://<jenkins-server>:8080/github-webhook/`
   - Content type: `application/json`
   - Events: Push events
   - Click "Add webhook"

4. **Build the Pipeline**
   - **Automatic**: Pipeline triggers automatically when code is pushed to GitHub
   - **Manual**: Or click "Build Now" for immediate execution
   - Monitor the console output

4. **Approve Infrastructure Creation**
   - When prompted: **"Do you want to APPLY Terraform?"** → Select **YES**
   - Terraform will create:
     - VPC with public subnet
     - Internet Gateway & Route Table
     - Security Group (ports 80, 22)
     - EC2 instance (t3.micro)
     - ECR repository
     - IAM role & instance profile
   - Wait ~60 seconds for EC2 to initialize

5. **Retrieve Outputs**
   - After the pipeline completes, check the logs for:
     - `ECR Repo`: Docker image repository URL
     - `EC2 IP`: Public IP address of the instance

---

### Step 2: Application Deployment (Docker & ECR)

#### Automatic Trigger via GitHub Push

The Jenkins pipeline is automatically triggered whenever code is pushed to the `main` branch:

```bash
# Developer workflow
git add .
git commit -m "Update app code"
git push origin main
# ↓ GitHub webhook automatically triggers Jenkins pipeline
```

#### Manual Trigger (Alternative)

If you need to manually trigger without pushing code:

1. Open Jenkins Dashboard: `http://<jenkins-server>:8080`
2. Click on your job: `BoomingBulls-Deploy`
3. Click "Build Now"

#### Deployment Stages

When the pipeline executes (automatic or manual), it will perform the following deployment steps:
#### Deployment Stages

When the pipeline executes (automatic or manual), it will perform the following deployment steps:

1. **Terraform Stage** (Infrastructure)
   - When prompted: **"Do you want to APPLY Terraform?"**
     - Select **YES** to create/update infrastructure (first deployment)
     - Select **NO** to skip infrastructure changes (for redeployment)

2. **Deployment Stage** (Application)
   - When prompted: **"Do you want to DEPLOY to EC2?"**
     - Select **YES** to build and deploy Docker container
     - Select **NO** to skip deployment

3. **Pipeline Execution**:
   - Build Docker image from `app/` directory
   - Login to AWS ECR
   - Tag and push image to ECR
   - SSH to EC2 instance
   - Pull image from ECR
   - Run container with port mapping `80:5000`
   - Set container to auto-restart on failure

4. **Monitor Deployment**:
   - Check Jenkins console logs for:
     - `docker build` success
     - `docker push` success
     - `docker run` command execution
     - Blue/green deployment indicators

#### Verify Deployment

SSH to your EC2 instance and verify:

```bash
# SSH into EC2
ssh -i /path/to/test.pem ec2-user@<EC2_PUBLIC_IP>

# Check running containers
docker ps -a

# View container logs
docker logs app

# Test locally
curl http://localhost:5000

# Check port binding
sudo netstat -tulpn | grep 80
```

---

## ✅ Verify Application

Once deployed, access the application:

```
http://<EC2_PUBLIC_IP>:80
```

You should see the BoomingBulls landing page with:
- Navigation bar with logo and links
- Hero section with call-to-action
- Features section
- Footer

### Health Check Endpoint
```bash
curl http://<EC2_PUBLIC_IP>/health
# Response: {"status": "ok"}
```

---

## 🔄 Redeployment Steps

### Automatic Redeployment (Recommended)

To automatically trigger redeployment when developers push code:

1. **Commit & Push Code Changes**:
   ```bash
   # Developer commits and pushes to main branch
   git add .
   git commit -m "Update app features"
   git push origin main
   ```

2. **GitHub Webhook Triggers Jenkins**:
   - Webhook automatically notifies Jenkins
   - Jenkins pipeline starts automatically
   - No manual action needed!

3. **Approve Deployment Prompts**:
   - Choose **NO** for Terraform Apply (skip infrastructure changes)
   - Choose **YES** for Deploy (build and push new Docker image)

4. **Automatic Deployment**:
   - New image is built, pushed to ECR, and deployed to EC2
   - Old container is replaced with new one
   - Application is live with new code

### Manual Redeployment (Alternative)

If automatic trigger is not configured, manually trigger:

1. **Make Code Changes and Push**:
   ```bash
   git add .
   git commit -m "Changes to BoomingBulls"
   git push origin main
   ```

2. **Manually Trigger Jenkins Pipeline**:
   - Click "Build Now" on your Jenkins job
   - Choose **NO** for Terraform Apply (skip infrastructure)
   - Choose **YES** for Deploy

3. **Pipeline will**:
   - Build new Docker image
   - Push to ECR
   - Pull latest image on EC2
   - Recreate container with new code

---

## 🛑 Destroy Infrastructure

To remove all AWS resources:

1. **Trigger the Pipeline**
2. When prompted: **"Do you want to DESTROY infrastructure?"** → Select **YES**
3. Terraform will destroy:
   - EC2 instance
   - VPC & subnets
   - Security groups
   - IAM roles
   - ECR repository ⚠️ (force delete enabled)

---

## 📊 Monitoring

CloudWatch logs are configured to collect:
- Flask application logs from `/var/log/flask_app.log`
- Log Group: `FlaskAppLogs`
- Log Stream: EC2 instance ID

View logs in AWS CloudWatch console:
- CloudWatch → Log Groups → `FlaskAppLogs`

---

## � Estimated AWS Cost

### Cost Breakdown

Based on AWS Pricing Calculator (February 22, 2026):

| Item | Cost |
|------|------|
| **Upfront Cost** | $0.00 USD |
| **Monthly Cost** | $39.82 USD |
| **Cost per Day** | **$1.33 USD** |
| **Annual Cost (12 months)** | $477.84 USD |

### Configuration Details

**Services Used:**
- **Amazon EC2**: t3.small instance (AWS calculates for 2 instances in estimate)
  - Region: Asia Pacific (Mumbai) - `ap-south-1`
  - Tenancy: Shared Instances
  - Operating System: Linux
  - Workload: Consistent
  - Pricing Strategy: On-Demand
  - Utilization: 100% per month
  - Monitoring: Enabled
  - EBS Storage: 16 GB
  - Data Transfer: 0 TB (internal only)

**Cost Optimizations:**
- Using t3.micro instance reduces actual deployment cost (estimate shows t3.small)
- Reserved Instances could reduce cost by ~30-40% for long-term use
- Auto-scaling can reduce idle resource costs
- Free tier eligible for 12 months if new AWS account

### Notes
⚠️ **Disclaimer**: This is an estimate only. Actual costs may vary based on:
- Actual data transfer usage
- Additional services (CloudWatch logs, backup, etc.)
- Regional pricing variations
- Reserved Instance discounts
- AWS Free Tier eligibility

---

## ���🐛 Troubleshooting

### Container Keeps Restarting
```bash
# SSH to EC2 and check logs
docker logs app

# Common issues:
# - Flask app crashed: Check /var/log/flask_app.log
# - Missing dependencies: Rebuild image
```

### Port 80 Not Responding
```bash
# Check if container is running
docker ps | grep app

# Check if port 80 is bound
sudo netstat -tulpn | grep :80

# Check security group in AWS console
# Verify ingress rule: TCP 80 from 0.0.0.0/0
```

### ECR Login Issues
```bash
# On EC2, manually test ECR login
aws ecr get-login-password --region ap-south-1 | \
docker login --username AWS --password-stdin <ECR_REPO_URL>
```

### Jenkins SSH Connection Issues
```bash
# Verify ssh key is added to Jenkins credentials
# Check EC2 security group allows port 22 (SSH)
# Verify ec2-user can access the instance
```

---

## 📝 Configuration Files

### Key Variables (`terraform/terraform.tfvars`)
```terraform
region   = "ap-south-1"              # AWS Region
key_name = "test"                    # EC2 Keypair name
```

### Jenkins Credentials Required
1. **AWS Credentials**: ID `75554f9b-2440-44ec-bd43-af2014f25797`
2. **SSH Key**: ID `ec2-ssh-key` (for EC2 access)

### Terraform Outputs
- `public_ip`: EC2 instance public IP address
- `ecr_url`: ECR repository URL for Docker image

---


## 🔐 Security Notes

⚠️ **Important Security Considerations**:
- Security group allows SSH (port 22) from anywhere - restrict to your IP
- EC2 has public IP - consider using private subnet + bastion host for production
- Docker runs as root by default - consider non-root user in Dockerfile
- ECR force delete is enabled - configure retention policies in production
- Database credentials should use AWS Secrets Manager, not hardcoded



---

**Last Updated**: February 22, 2026  
**Version**: 1.0
