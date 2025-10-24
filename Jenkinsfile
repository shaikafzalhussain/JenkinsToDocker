pipeline {
    agent any

    environment {
        IMAGE_NAME = "shaikafzalhussain/simple-webpage"
        DOCKERHUB_CREDENTIALS_ID = 'DockerKey'
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/shaikafzalhussain/JenkinsToDocker.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:latest ."
            }
        }

        stage('Push Image to DockerHub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: env.DOCKERHUB_CREDENTIALS_ID, 
                    passwordVariable: 'dockerPassword', 
                    usernameVariable: 'dockerUser'
                )]) {
                    // 1. Login to DockerHub
                    sh "echo ${dockerPassword} | docker login -u ${dockerUser} --password-stdin"
                    
                    // 2. Push the built image
                    sh "docker push ${IMAGE_NAME}:latest"
                    
                    // 3. LOGOUT HERE - This is secure and runs only after the successful login/push
                    sh 'docker logout'
                }
            }
        }

        stage('Run Container') {
            steps {
                script {
                    sh 'docker rm -f simple-webpage-container || true'
                    sh "docker run -d -p 8080:80 --name simple-webpage-container ${IMAGE_NAME}:latest"
                }
            }
        }
    }
    
    // ---
    
    post {
        success {
            echo '✅ Deployment completed successfully! Visit: http://<your-server-ip>:8080'
        }
        failure {
            echo '❌ Build or deployment failed! Check the console output for details.'
        }
        // REMOVED THE FAULTY sh 'docker logout || true' from the always block
    }
}
