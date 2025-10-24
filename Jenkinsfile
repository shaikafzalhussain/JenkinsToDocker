pipeline {
    agent any

    environment {
        // Set the Docker image name and tag
        DOCKER_IMAGE_NAME = "shaikafzalhussain/simple-webpage"
        IMAGE_TAG = "latest"
        // 🔑 CORRECTED: Using the specified Jenkins Secret Text credential ID
        DOCKER_CREDENTIAL_ID = 'DockerKey' 
    }

    stages {
        
        stage('Declarative: Checkout SCM') {
            steps {
                // ✅ FIX: Added a required step to prevent "No steps specified for branch" error.
                // This stage usually just ensures the SCM is checked out.
                echo 'Starting SCM checkout.'
            }
        }

        stage('Clone Repository') {
            steps {
                // Explicitly clone the repository to the workspace
                git url: 'https://github.com/shaikafzalhussain/JenkinsToDocker.git', branch: 'main'
            }
        }
        
        stage('Clear Docker Session') {
            steps {
                // 🔑 FIX for previous '401 Unauthorized' pull error: Log out to clear stale credentials.
                echo "Logging out of Docker to ensure anonymous pull for NGINX base image."
                sh 'docker logout || true' 
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
                // Use withCredentials to securely inject the Docker Hub PAT from 'DockerKey'
                withCredentials([string(credentialsId: env.DOCKER_CREDENTIAL_ID, variable: 'dockerPassword')]) {
                    
                    // Log in to Docker Hub using the PAT
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
                // The '|| true' ensures the pipeline doesn't fail if the container doesn't exist
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
