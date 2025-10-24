pipeline {
    // Agent configuration: Specifies where the pipeline runs
    agent any
    
    // Environment variables: Defines reusable values
    environment {
        DOCKER_HUB_USER = "shaikafzalhussain"
        DOCKER_IMAGE_NAME = "simple-webpage" 
        IMAGE_TAG = "latest"
        // ID of your Username with password credential
        DOCKER_CREDENTIAL_ID = 'DockerKey' 
    }
    
    stages{
        
        stage("Code Clone"){
            steps{
                echo "Starting Code Clone."
                // Clones your specific repository
                git url: "https://github.com-shaikafzalhussain/JenkinsToDocker.git", branch: "main"
            }
        }
        
        stage("Clear Docker Session"){
            steps{
                // FIX for 401 Unauthorized pull error
                echo "Logging out of Docker to ensure anonymous pull for base images."
                sh 'docker logout || true' 
            }
        }

        stage("Code Build & Test"){
            steps{
                echo "Building Docker image."
                
                // 🚀 FIX for "context deadline exceeded" error: Disable BuildKit
                sh 'export DOCKER_BUILDKIT=0'
                
                // Build the image locally
                sh "docker build -t ${DOCKER_IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage("Push To DockerHub"){
            steps{
                // Loads 'DockerKey' as Username and Password variables
                withCredentials([usernamePassword(
                    credentialsId: env.DOCKER_CREDENTIAL_ID,
                    usernameVariable: "dockerHubUser",  
                    passwordVariable: "dockerHubPass")]){
                        
                    // 1. Log in to Docker Hub
                    sh 'echo $dockerHubPass | docker login -u $dockerHubUser --password-stdin'
                    
                    // 2. Tag (Ensures proper remote naming)
                    sh "docker image tag ${DOCKER_IMAGE_NAME}:${IMAGE_TAG} ${env.DOCKER_HUB_USER}/${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
                    
                    // 3. Push the image to Docker Hub
                    echo "Pushing image to Docker Hub..."
                    sh "docker push ${env.DOCKER_HUB_USER}/${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }
        
        stage("Deploy"){
            steps{
                echo "Deploying container, accessible on host port 8081."
                
                // 1. FIX for changes not reflecting: Explicitly pull the latest image
                sh "docker pull ${env.DOCKER_HUB_USER}/${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"

                // 2. Stop and remove the old container
                sh 'docker stop simple-webpage || true'
                sh 'docker rm simple-webpage || true'

                // 3. Run the new container (Port 8081 is the fix for "address already in use")
                sh "docker run -d --name simple-webpage -p 8081:80 ${env.DOCKER_HUB_USER}/${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
            }
        }
    }

    post {
        always {
            // Always ensure logout for security
            sh 'docker logout || true' 
        }
        success {
            echo '✅ Pipeline execution successful! Access your app on port 8081.'
        }
        failure {
            echo '❌ Pipeline execution failed! Check logs for errors.'
        }
    }
}
