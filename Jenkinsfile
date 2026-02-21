pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    withCredentials([[
                $class: 'AmazonWebServicesCredentialsBinding',
                credentialsId: '75554f9b-2440-44ec-bd43-af2014f25797'
            ]]) {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    withCredentials([[
                $class: 'AmazonWebServicesCredentialsBinding',
                credentialsId: '75554f9b-2440-44ec-bd43-af2014f25797'
            ]]) {
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Get Terraform Outputs') {
            steps {
                script {
                    env.ECR_REPO = sh(
                        script: "cd terraform && terraform output -raw ecr_repo_url",
                        returnStdout: true
                    ).trim()

                    env.EC2_IP = sh(
                        script: "cd terraform && terraform output -raw ec2_public_ip",
                        returnStdout: true
                    ).trim()

                    echo "ECR Repo: ${env.ECR_REPO}"
                    echo "EC2 IP: ${env.EC2_IP}"
                }
            }
        }

        stage('Build Docker') {
            steps {
                sh 'docker build -t devops-app ./app'
            }
        }

        stage('Login to ECR') {
            steps {
                withCredentials([[
                $class: 'AmazonWebServicesCredentialsBinding',
                credentialsId: '75554f9b-2440-44ec-bd43-af2014f25797'
            ]]) {
                sh '''
                aws ecr get-login-password --region $AWS_REGION | \
                docker login --username AWS --password-stdin $ECR_REPO
                '''
            }
        }

        stage('Push Image') {
            steps {
                sh '''
                docker tag devops-app:latest $ECR_REPO:latest
                docker push $ECR_REPO:latest
                '''
            }
        }

        stage('Deploy to EC2') {
            steps {
                sh '''
                ssh -o StrictHostKeyChecking=no ec2-user@$EC2_IP << EOF
                  aws ecr get-login-password --region $AWS_REGION | \
                  docker login --username AWS --password-stdin $ECR_REPO

                  docker pull $ECR_REPO:latest
                  docker stop app || true
                  docker rm app || true
                  docker run -d -p 80:80 --name app --restart always $ECR_REPO:latest
                EOF
                '''
            }
        }
    }
}
