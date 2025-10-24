pipeline {
    agent any

    environment {
        // Set the Docker image name and tag
        DOCKER_IMAGE_NAME = "shaikafzalhussain/simple-webpage"
        IMAGE_TAG = "latest"
        // 🔑 UPDATED: Use the ID of your Jenkins secret text credential for the Docker password/token
        DOCKER_CREDENTIAL_ID = 'DockerKey' 
    }

    stages {
        
        stage('Declarative: Checkout SCM') {
            steps {
                // The pipeline's initial checkout step
            }
        }

        stage('Clone Repository') {
            steps {
                // Ensure the working directory is set up correctly
                git url: 'https://github.com/shaikafzalhussain/JenkinsToDocker.git', branch: 'main'
            }
        }
        
        stage('Clear Docker Session') {
            steps {
                // ✅ FIX for '401 Unauthorized' on pull: Log out to clear potentially bad/stale credentials.
                // This ensures anonymous pull for public base images like NGINX succeeds.
                echo "Logging out of Docker to ensure anonymous pull for NGINX base image."
                sh 'docker logout || true' // The '|| true' prevents pipeline failure if not logged in
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image: ${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
                sh "docker build -t ${DOCKER_IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Push Image to DockerHub') {
            steps {
                // Use withCredentials to securely inject the Docker Hub password/token from 'DockerKey' credential
                withCredentials([string(credentialsId: env.DOCKER_CREDENTIAL_ID, variable: 'dockerPassword')]) {
                    
                    // Log in to Docker Hub using the credential
                    echo "Logging into Docker Hub as ${DOCKER_IMAGE_NAME.split('/')[0]}"
                    sh "echo \$dockerPassword | docker login -u ${DOCKER_IMAGE_NAME.split('/')[0]} --password-stdin"
                    
                    // Push the built image
                    echo "Pushing image to Docker Hub..."
                    sh "docker push ${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }

        stage('Run Container') {
            steps {
                echo "Stopping and removing any old container..."
                sh 'docker stop simple-webpage || true'
                sh 'docker rm simple-webpage || true'

                echo "Running new container from image: ${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
                sh "docker run -d --name simple-webpage -p 8080:80 ${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
            }
        }
    }

    post {
        always {
            // Log out after the push is done for security and to prevent future conflicts
            sh 'docker logout || true' 
        }
        success {
            echo '✅ Build and deployment successful!'
        }
        failure {
            echo '❌ Build or deployment failed! Check the console output for details.'
        }
    }
}
