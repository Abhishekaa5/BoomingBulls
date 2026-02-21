pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['APPLY', 'DESTROY'],
            description: 'Choose Terraform action'
        )
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/Abhishekaa5/boomingbull.git'
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Plan') {
            when {
                expression { params.ACTION == 'APPLY' }
            }
            steps {
                dir('terraform') {
                    sh 'terraform plan -out=tfplan'
                }
                archiveArtifacts artifacts: 'terraform/tfplan', fingerprint: true
            }
        }

        stage('Approval Before Apply') {
            when {
                expression { params.ACTION == 'APPLY' }
            }
            steps {
                script {
                    def approval = timeout(time: 5, unit: 'MINUTES') {
                        input(
                            message: "Apply Terraform changes?",
                            parameters: [
                                choice(name: 'CONFIRM', choices: 'NO\nYES', description: 'Select YES to apply')
                            ]
                        )
                    }

                    if (approval != 'YES') {
                        error("Terraform Apply Skipped by User")
                    }
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'APPLY' }
            }
            steps {
                dir('terraform') {
                    sh 'terraform apply tfplan'
                }
            }
        }

        stage('Get Terraform Outputs') {
            when {
                expression { params.ACTION == 'APPLY' }
            }
            steps {
                script {
                    env.ECR_REPO = sh(
                        script: "cd terraform && terraform output -raw ecr_url",
                        returnStdout: true
                    ).trim()

                    env.EC2_IP = sh(
                        script: "cd terraform && terraform output -raw public_ip",
                        returnStdout: true
                    ).trim()

                    echo "ECR Repo: ${ECR_REPO}"
                    echo "EC2 IP: ${EC2_IP}"
                }
            }
        }

        stage('Build Docker Image') {
            when {
                expression { params.ACTION == 'APPLY' }
            }
            steps {
                sh 'docker build -t devops-app ./app'
            }
        }

        stage('Login & Push to ECR') {
            when {
                expression { params.ACTION == 'APPLY' }
            }
            steps {
                sh """
                aws ecr get-login-password --region ${AWS_REGION} | \
                docker login --username AWS --password-stdin ${ECR_REPO}

                docker tag devops-app:latest ${ECR_REPO}:latest
                docker push ${ECR_REPO}:latest
                """
            }
        }

        stage('Approval Before Deployment') {
            when {
                expression { params.ACTION == 'APPLY' }
            }
            steps {
                script {
                    def deployApproval = timeout(time: 5, unit: 'MINUTES') {
                        input(
                            message: "Deploy to EC2?",
                            parameters: [
                                choice(name: 'CONFIRM', choices: 'NO\nYES', description: 'Select YES to deploy')
                            ]
                        )
                    }

                    if (deployApproval != 'YES') {
                        error("Deployment Skipped by User")
                    }
                }
            }
        }

        stage('Deploy to EC2') {
            when {
                expression { params.ACTION == 'APPLY' }
            }
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ec2-user@${EC2_IP} "
                    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO} &&
                    docker pull ${ECR_REPO}:latest &&
                    docker stop app || true &&
                    docker rm app || true &&
                    docker run -d -p 80:80 --name app --restart always ${ECR_REPO}:latest
                    "
                    """
                }
            }
        }

        stage('Approval Before Destroy') {
            when {
                expression { params.ACTION == 'DESTROY' }
            }
            steps {
                script {
                    def destroyApproval = timeout(time: 5, unit: 'MINUTES') {
                        input(
                            message: "Are you sure you want to destroy infrastructure?",
                            parameters: [
                                choice(name: 'CONFIRM', choices: 'NO\nYES', description: 'Select YES to destroy')
                            ]
                        )
                    }

                    if (destroyApproval != 'YES') {
                        error("Destroy Skipped by User")
                    }
                }
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'DESTROY' }
            }
            steps {
                dir('terraform') {
                    sh 'terraform destroy -auto-approve'
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline executed successfully 🚀"
        }
        failure {
            echo "Pipeline failed ❌"
        }
        aborted {
            echo "Pipeline aborted by user ⚠️"
        }
    }
}
