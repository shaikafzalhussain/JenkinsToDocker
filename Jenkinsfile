pipeline {
    // Agent configuration
    agent any
    
    // Environment variables
    environment {
        // Your Docker Hub username
        DOCKER_HUB_USER = "shaikafzalhussain"
        // Your specific repository and image name
        DOCKER_IMAGE_NAME = "simple-webpage" 
        IMAGE_TAG = "latest"
        // The ID of your Username with password credential (DockerKey)
        DOCKER_CREDENTIAL_ID = 'DockerKey' 
    }
    
    stages{
        
        stage("Code Clone"){
            steps{
                echo "Code Clone Stage"
                // Your repository URL and branch
                git url: "https://github.com/shaikafzalhussain/JenkinsToDocker.git", branch: "main"
            }
        }
        
        stage("Clear Docker Session"){
            steps{
                // Fix for 401 Unauthorized pull error: log out to clear stale credentials
                echo "Logging out of Docker to ensure anonymous pull for NGINX base image."
                sh 'docker logout || true' 
            }
        }

        stage("Code Build & Test"){
            steps{
                echo "Code Build Stage"
                // Build the image with a temporary local tag
                sh "docker build -t ${DOCKER_IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage("Push To DockerHub"){
            steps{
                // Using 'usernamePassword' to load credentials for login
                withCredentials([usernamePassword(
                    credentialsId: env.DOCKER_CREDENTIAL_ID,
                    usernameVariable: "dockerHubUser",  
                    passwordVariable: "dockerHubPass")]){
                        
                    // 1. Login
                    sh 'echo $dockerHubPass | docker login -u $dockerHubUser --password-stdin'
                    
                    // 2. Tag (if needed, but using the full path is cleaner for push)
                    // We can reuse the existing local tag structure for the remote tag
                    
                    // 3. Push the image
                    echo "Pushing image to Docker Hub as ${env.DOCKER_HUB_USER}/${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker push ${env.DOCKER_HUB_USER}/${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }
        
        stage("Deploy"){
            steps{
                echo "Deploying container, accessible on host port 8081."
                // Stop/remove previous container before running the new one
                sh 'docker stop simple-webpage || true'
                sh 'docker rm simple-webpage || true'

                // 🚀 FIX for "address already in use" error: Mapped container port 80 to HOST port 8081
                sh "docker run -d --name simple-webpage -p 8081:80 ${env.DOCKER_HUB_USER}/${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
            }
        }
    }

    post {
        always {
            // Log out after the pipeline is complete
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
