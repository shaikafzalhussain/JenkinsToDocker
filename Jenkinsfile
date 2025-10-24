pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('DockerKey')
        IMAGE_NAME = ‘shaikafzalhussain/simple-webpage'
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/yourusername/simple-webpage.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh 'docker build -t $IMAGE_NAME:latest .'
                }
            }
        }

        stage('Login to DockerHub') {
            steps {
                script {
                    sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
                }
            }
        }

        stage('Push Image to DockerHub') {
            steps {
                script {
                    sh 'docker push $IMAGE_NAME:latest'
                }
            }
        }

        stage('Run Container') {
            steps {
                script {
                    // Stop old container if running
                    sh 'docker rm -f simple-webpage-container || true'

                    // Run new container from Docker Hub image
                    sh 'docker run -d -p 8080:80 --name simple-webpage-container $IMAGE_NAME:latest'
                }
            }
        }

        stage('Cleanup') {
            steps {
                script {
                    sh 'docker logout'
                }
            }
        }
    }

    post {
        success {
            echo '✅ Deployment completed successfully!'
            echo 'Visit: http://<your-server-ip>:8080'
        }
        failure {
            echo '❌ Build or deployment failed!'
        }
    }
}

