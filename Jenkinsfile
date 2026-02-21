pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
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
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: '75554f9b-2440-44ec-bd43-af2014f25797'
                    ]]) {
                        sh 'terraform init'
                    }
                }
            }
        }

        stage('Approval Before Terraform Apply') {
            steps {
                script {
                    def applyApproval = input(
                        message: 'Do you want to APPLY Terraform?',
                        parameters: [
                            choice(name: 'CONFIRM', choices: 'NO\nYES', description: 'Select YES to apply')
                        ]
                    )
                    if (applyApproval != 'YES') {
                        error("Terraform Apply Skipped by User")
                    }
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
        }

        stage('Get Terraform Outputs') {
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

                    echo "ECR Repo: ${env.ECR_REPO}"
                    echo "EC2 IP: ${env.EC2_IP}"
                }
            }
        }

        stage('Wait for EC2 Ready') {
            steps {
                script {
                    echo "Waiting 60 seconds for EC2 to finish initializing..."
                    sleep(time: 60, unit: 'SECONDS')
                }
            }
        }

        // stage('Check SSH availability') {
        //     steps {
        //         script {
        //             echo "Checking SSH connectivity..."
        //             retry(10) {
        //             sh "nc -zv ${EC2_IP} 22"
        //             }
        //         }
        //     }
        // }

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
                    sh """
                    aws ecr get-login-password --region ${AWS_REGION} | \
                    docker login --username AWS --password-stdin ${ECR_REPO}
                    """
                }
            }
        }

        stage('Push Image') {
            steps {
                sh """
                docker tag devops-app:latest ${ECR_REPO}:latest
                docker push ${ECR_REPO}:latest
                """
            }
        }

        stage('Approval Before Deployment') {
            steps {
                script {
                    def deployApproval = input(
                        message: 'Do you want to DEPLOY to EC2?',
                        parameters: [
                            choice(name: 'CONFIRM', choices: 'NO\nYES', description: 'Select YES to deploy')
                        ]
                    )
                    if (deployApproval != 'YES') {
                        error("Deployment Skipped by User")
                    }
                }
            }
        }

        stage('Deploy to EC2') {
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
            steps {
                script {
                    def destroyApproval = input(
                        message: 'Do you want to DESTROY infrastructure?',
                        parameters: [
                            choice(name: 'CONFIRM', choices: 'NO\nYES', description: 'Select YES to destroy')
                        ]
                    )
                    if (destroyApproval != 'YES') {
                        echo "Terraform Destroy Skipped by User"
                        return
                    }
                }
            }
        }

        stage('Terraform Destroy') {
            steps {
                dir('terraform') {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: '75554f9b-2440-44ec-bd43-af2014f25797'
                    ]]) {
                        sh 'terraform destroy -auto-approve'
                    }
                }
            }
        }

    }
}
